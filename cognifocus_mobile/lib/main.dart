import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/network/api_client.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core & FCM background handler
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('[Firebase] Firebase Core initialized successfully.');
  } catch (e) {
    debugPrint(
      '[Firebase] Standby: Firebase initialization skipped or google-services.json not yet placed: $e',
    );
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF3F5F9),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize storage service
  final storageService = StorageService();
  final serverUrl = await storageService.getServerUrl();

  // Initialize API Client with stored endpoint URL
  final apiClient = ApiClient(baseUrl: serverUrl);

  // Initialize Notification Service (Local channels + FCM listeners)
  final notificationService = NotificationService(apiClient: apiClient);
  await notificationService.initialize();
  await notificationService.initializeFcm();

  runApp(
    CogniFocusApp(
      apiClient: apiClient,
      storageService: storageService,
      notificationService: notificationService,
    ),
  );
}
