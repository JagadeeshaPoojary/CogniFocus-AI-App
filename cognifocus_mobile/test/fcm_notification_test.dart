import 'package:flutter_test/flutter_test.dart';
import 'package:cognifocus_mobile/core/network/api_client.dart';
import 'package:cognifocus_mobile/services/notification_service.dart';

class MockFcmApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastBody;

  MockFcmApiClient() : super(baseUrl: 'http://127.0.0.1:5000');

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
  }) async {
    lastPath = path;
    if (body is Map<String, dynamic>) {
      lastBody = body;
    }
    return {'success': true, 'message': 'Operation successful'};
  }
}

void main() {
  group('NotificationService FCM Integration Tests', () {
    test('registerDeviceToken sends token and platform to backend', () async {
      final mockClient = MockFcmApiClient();
      final service = NotificationService(apiClient: mockClient);

      const testToken = 'fcm_test_token_abc123xyz';
      final success = await service.registerDeviceToken(testToken, deviceId: 'test_phone_1');

      expect(success, isTrue);
      expect(mockClient.lastPath, '/api/notifications/register-device');
      expect(mockClient.lastBody?['fcm_token'], testToken);
      expect(mockClient.lastBody?['device_id'], 'test_phone_1');
      expect(mockClient.lastBody?['platform'], 'android');
    });

    test('unregisterDeviceToken sends deactivation request to backend', () async {
      final mockClient = MockFcmApiClient();
      final service = NotificationService(apiClient: mockClient);

      const testToken = 'fcm_test_token_abc123xyz';
      final success = await service.unregisterDeviceToken(fcmToken: testToken);

      expect(success, isTrue);
      expect(mockClient.lastPath, '/api/notifications/unregister-device');
      expect(mockClient.lastBody?['fcm_token'], testToken);
    });

    test('Notification tap value notifier notifies listeners with payload', () {
      String? tappedPayload;
      NotificationService.onNotificationTapped.addListener(() {
        tappedPayload = NotificationService.onNotificationTapped.value;
      });

      NotificationService.onNotificationTapped.value = '145';
      expect(tappedPayload, '145');

      NotificationService.onNotificationTapped.value = null;
      expect(tappedPayload, isNull);
    });
  });
}
