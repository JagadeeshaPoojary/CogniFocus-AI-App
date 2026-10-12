import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Top-level background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Received message ID: ${message.messageId}');
  debugPrint('[FCM Background] Data payload: ${message.data}');
}

/// Notification Service for CogniFocus-AI
///
/// Implements:
/// 1. Firebase Cloud Messaging (FCM) integration for remote push notifications
///    (foreground, background, and cold start / terminated states).
/// 2. Local system notifications via flutter_local_notifications on Android.
/// 3. Device token registration and deactivation with the Flask backend.
/// 4. Android 13+ runtime notification permissions.
class NotificationService {
  final ApiClient _apiClient;
  final FlutterLocalNotificationsPlugin _localNotifications;
  bool _isInitialized = false;
  bool _isFcmInitialized = false;
  String? _fcmToken;

  static final ValueNotifier<String?> onNotificationTapped =
      ValueNotifier<String?>(null);

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool _permissionDenied = false;

  NotificationService({
    required ApiClient apiClient,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _apiClient = apiClient,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;
  bool get isFcmInitialized => _isFcmInitialized;
  bool get permissionDenied => _permissionDenied;
  String? get fcmToken => _fcmToken;

  /// Initialize local notification channels and settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
            '[NotificationService] Tapped local notification payload: ${response.payload}',
          );
          if (response.payload != null && response.payload!.isNotEmpty) {
            onNotificationTapped.value = response.payload;
          }
        },
      );

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final channel = AndroidNotificationChannel(
          'cognifocus_alerts_channel',
          'CogniFocus-AI Alerts',
          description:
              'High-priority classroom AI monitoring alerts and notifications',
          importance: Importance.max,
          enableVibration: vibrationEnabled,
          playSound: soundEnabled,
        );

        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      _isInitialized = true;
      debugPrint(
        '[NotificationService] Local notifications initialized successfully.',
      );
    } catch (e) {
      debugPrint('[NotificationService] Initialization warning: $e');
    }
  }

  /// Initialize Firebase Cloud Messaging (FCM) listeners, permissions, and token sync
  Future<void> initializeFcm() async {
    if (_isFcmInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint(
          '[NotificationService] Firebase.apps is empty. FCM is in standby mode.',
        );
        return;
      }

      // 1. Request notification permissions from user (Android 13+ / iOS)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      debugPrint(
        '[NotificationService] FCM Authorization status: ${settings.authorizationStatus}',
      );

      if (!isAuthorized) {
        _permissionDenied = true;
        return;
      }

      // 2. Configure foreground notification presentation
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Obtain initial FCM registration token
      try {
        _fcmToken = await FirebaseMessaging.instance.getToken();
        if (_fcmToken != null) {
          final suffix = _fcmToken!.length > 8
              ? _fcmToken!.substring(_fcmToken!.length - 8)
              : _fcmToken;
          debugPrint(
            '[NotificationService] Obtained FCM registration token (...$suffix)',
          );
          await registerDeviceToken(_fcmToken!);
        }
      } catch (tokenErr) {
        debugPrint(
          '[NotificationService] Could not obtain FCM token immediately: $tokenErr',
        );
      }

      // 4. Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        final suffix = newToken.length > 8
            ? newToken.substring(newToken.length - 8)
            : newToken;
        debugPrint(
          '[NotificationService] FCM token refreshed: ...$suffix',
        );
        registerDeviceToken(newToken);
      });

      // 5. Handle foreground messages: show high-priority local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[NotificationService] Foreground FCM message received: ${message.messageId}',
        );
        _handleIncomingRemoteMessage(message, isForeground: true);
      });

      // 6. Handle notification tap when app is opened from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '[NotificationService] FCM message opened app from background: ${message.messageId}',
        );
        _handleRemoteMessageTap(message);
      });

      // 7. Check for initial message on cold start (terminated state)
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[NotificationService] Cold launch triggered by FCM notification: ${initialMessage.messageId}',
        );
        _handleRemoteMessageTap(initialMessage);
      }

      _isFcmInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] FCM initialization warning: $e');
    }
  }

  void _handleIncomingRemoteMessage(
    RemoteMessage message, {
    bool isForeground = false,
  }) {
    final notification = message.notification;
    final data = message.data;

    final alertId = data['alert_id']?.toString() ?? '0';
    final title =
        notification?.title ?? 'Possible Mobile Phone Usage Detected';
    final body = notification?.body ??
        'Classroom ${data['classroom_id'] ?? 'CSE301'} • Camera ${data['camera_id'] ?? 'CAM001'}';

    if (isForeground) {
      showLocalAlert(
        title: title,
        body: body,
        id: int.tryParse(alertId) ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
        payload: alertId,
      );
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final alertId = message.data['alert_id']?.toString();
    if (alertId != null && alertId.isNotEmpty && alertId != '0') {
      onNotificationTapped.value = alertId;
    }
  }

  /// Request runtime permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    if (_permissionDenied) return false;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted =
              await androidPlugin.requestNotificationsPermission();
          final isGranted = granted ?? false;
          _permissionDenied = !isGranted;
          return isGranted;
        }
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Permission request warning: $e');
      return false;
    }
  }

  /// Sync device FCM token with backend (called upon teacher login)
  Future<void> syncTokenWithBackend() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      await registerDeviceToken(_fcmToken!);
    } else if (Firebase.apps.isNotEmpty) {
      try {
        _fcmToken = await FirebaseMessaging.instance.getToken();
        if (_fcmToken != null) {
          await registerDeviceToken(_fcmToken!);
        }
      } catch (_) {}
    }
  }

  /// Register FCM token with backend API
  Future<bool> registerDeviceToken(String token, {String? deviceId}) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.registerDevicePath,
        body: {
          'fcm_token': token,
          'device_id': deviceId ?? 'android_phone',
          'platform': 'android',
        },
      );
      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[NotificationService] Register device token error: $e');
      return false;
    }
  }

  /// Unregister FCM token from backend API on logout
  Future<bool> unregisterDeviceToken({String? fcmToken}) async {
    try {
      final token = fcmToken ?? _fcmToken;
      if (token == null) return true;
      final response = await _apiClient.post(
        ApiConfig.unregisterDevicePath,
        body: {'fcm_token': token},
      );
      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Trigger test push notification from backend
  Future<Map<String, dynamic>> triggerTestPush([String? message]) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.testPushNotificationPath,
        body: message != null ? {'message': message} : null,
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'success': false, 'message': 'Unknown response'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Show dedicated phone detection notification with classroom, seat, and duration
  Future<void> showPhoneDetectionNotification({
    required int alertId,
    required String classroom,
    required String seat,
    String? duration,
    String? alertType,
  }) async {
    final durText = (duration != null && duration.isNotEmpty)
        ? ' • Duration: $duration'
        : '';
    final body = 'Classroom: $classroom • Seat: $seat$durText';
    await showLocalAlert(
      title: 'Possible Mobile Phone Usage Detected',
      body: body,
      id: alertId,
      payload: '$alertId',
    );
  }

  /// Show instant local alert notification
  Future<void> showLocalAlert({
    required String title,
    required String body,
    int id = 100,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final androidDetails = AndroidNotificationDetails(
        'cognifocus_alerts_channel',
        'CogniFocus-AI Alerts',
        channelDescription:
            'High-priority classroom AI monitoring alerts and notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
        ticker: 'CogniFocus Alert',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        ),
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show alert error: $e');
    }
  }

  /// Fetch user notification preferences from backend
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.notificationsPreferencesPath,
      );
      if (response is Map<String, dynamic> &&
          response['preferences'] is Map<String, dynamic>) {
        return response['preferences'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Update user notification preferences
  Future<bool> updatePreferences({
    String? email,
    String? phone,
    bool? emailEnabled,
    bool? smsEnabled,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (email != null) {
        body['notification_email'] = email;
      }
      if (phone != null) {
        body['notification_phone'] = phone;
      }
      if (emailEnabled != null) {
        body['email_notifications_enabled'] = emailEnabled;
      }
      if (smsEnabled != null) {
        body['sms_notifications_enabled'] = smsEnabled;
      }

      final response = await _apiClient.put(
        ApiConfig.notificationsPreferencesPath,
        body: body,
      );
      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Dispatch backend test email
  Future<String> testEmail([String? email]) async {
    final body = email != null ? {'email': email} : null;
    final response = await _apiClient.post(
      ApiConfig.testEmailNotificationPath,
      body: body,
    );
    if (response is Map<String, dynamic>) {
      return response['message']?.toString() ?? 'Test email sent';
    }
    return 'Test email triggered';
  }

  /// Dispatch backend test SMS
  Future<String> testSms([String? phone]) async {
    final body = phone != null ? {'phone': phone} : null;
    final response = await _apiClient.post(
      ApiConfig.testSmsNotificationPath,
      body: body,
    );
    if (response is Map<String, dynamic>) {
      return response['message']?.toString() ?? 'Test SMS sent';
    }
    return 'Test SMS triggered';
  }
}
