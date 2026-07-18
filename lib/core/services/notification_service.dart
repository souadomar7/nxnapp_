import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level background message handler for FCM.
/// Must be a top-level function (outside any class) to run in a separate isolate.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background,
  // make sure you call Firebase.initializeApp() first.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  /// Initializes FCM Push Notifications.
  /// Gracefully catches errors if Firebase configurations are not yet set up.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Request user permissions (standard on iOS and Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User notification permission status: ${settings.authorizationStatus}');

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Get FCM Token (used to target notifications to this specific device)
      String? token = await _fcm.getToken();
      debugPrint('=== FCM REGISTRATION TOKEN ===');
      debugPrint(token ?? 'Could not retrieve token');
      debugPrint('==============================');

      // 4. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification!.title}');
          // In a real production app, you would trigger a local notification overlay here 
          // (e.g. using flutter_local_notifications) to show a heads-up alert.
        }
      });

      // 5. Handle user clicking notification to open the app from background/terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened via notification click!');
        debugPrint('Message data: ${message.data}');
      });

      // 6. Handle notification click that launches app from terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state via notification click!');
        debugPrint('Initial message data: ${initialMessage.data}');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Firebase messaging initialization warning: $e');
      debugPrint('Make sure google-services.json / GoogleService-Info.plist are correctly set up.');
    }
  }
}
