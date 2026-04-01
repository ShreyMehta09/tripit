import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';

/// Handles FCM background messages (must be a top-level function).
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op for now – background messages are handled silently.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel for trip alerts.
  static const AndroidNotificationChannel _tripChannel =
      AndroidNotificationChannel(
    'trip_notifications', // id
    'Trip Notifications', // name
    description: 'Notifications for new trip creation',
    importance: Importance.high,
  );

  // ─── Initialization ─────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Request FCM permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Set up local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // 4. Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_tripChannel);

    // 5. Get FCM token (useful for future server-side push)
    final token = await _fcm.getToken();
    // ignore: avoid_print
    print('FCM Token: $token');
  }

  // ─── Local Notification ─────────────────────────────────────────────

  /// Shows a local push notification when a trip is created.
  Future<void> showTripCreatedNotification(TripModel trip) async {
    final dateFormat = DateFormat('MMM d, yyyy');

    final androidDetails = AndroidNotificationDetails(
      _tripChannel.id,
      _tripChannel.name,
      channelDescription: _tripChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      '🎉 Trip Created: ${trip.destination}',
      '${trip.numberOfDays} days starting ${dateFormat.format(trip.startDate)} • '
          'Budget: ${trip.budgetCurrency ?? "INR"} ${trip.budget.toStringAsFixed(0)}',
      notificationDetails,
    );
  }

  // ─── Email Notification ─────────────────────────────────────────────

  /// Sends a trip confirmation email to [recipientEmail] via SMTP.
  ///
  /// Requires `SMTP_EMAIL` and `SMTP_PASSWORD` in .env.
  /// For Gmail: use an App Password with `smtp.gmail.com`.
  Future<void> sendTripEmailNotification(
    String recipientEmail,
    TripModel trip,
  ) async {
    try {
      final smtpEmail = dotenv.env['SMTP_EMAIL'];
      final smtpPassword = dotenv.env['SMTP_PASSWORD'];

      if (smtpEmail == null || smtpPassword == null) {
        // ignore: avoid_print
        print('SMTP credentials not configured – skipping email.');
        return;
      }

      final smtpServer = gmail(smtpEmail, smtpPassword);
      final dateFormat = DateFormat('EEE, MMM d, yyyy');

      final message = mailer.Message()
        ..from = mailer.Address(smtpEmail, 'TripIt')
        ..recipients.add(recipientEmail)
        ..subject = '🎉 Your Trip to ${trip.destination} is Ready!'
        ..html = '''
<div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #121212; color: #ffffff; border-radius: 16px; overflow: hidden;">
  <div style="background: linear-gradient(135deg, #6C63FF, #4ECDC4); padding: 32px; text-align: center;">
    <h1 style="margin: 0; font-size: 28px;">✈️ Trip Confirmed!</h1>
    <p style="margin: 8px 0 0; font-size: 16px; opacity: 0.9;">Your AI-powered itinerary is ready</p>
  </div>
  <div style="padding: 24px;">
    <h2 style="color: #6C63FF; margin-top: 0;">📍 ${trip.destination}</h2>
    <table style="width: 100%; border-collapse: collapse;">
      <tr>
        <td style="padding: 12px 0; border-bottom: 1px solid #333;">
          <strong>📅 Start Date</strong>
        </td>
        <td style="padding: 12px 0; border-bottom: 1px solid #333; text-align: right;">
          ${dateFormat.format(trip.startDate)}
        </td>
      </tr>
      <tr>
        <td style="padding: 12px 0; border-bottom: 1px solid #333;">
          <strong>⏱️ Duration</strong>
        </td>
        <td style="padding: 12px 0; border-bottom: 1px solid #333; text-align: right;">
          ${trip.numberOfDays} days
        </td>
      </tr>
      <tr>
        <td style="padding: 12px 0; border-bottom: 1px solid #333;">
          <strong>💰 Budget</strong>
        </td>
        <td style="padding: 12px 0; border-bottom: 1px solid #333; text-align: right;">
          ${trip.budgetCurrency ?? 'INR'} ${trip.budget.toStringAsFixed(0)}
        </td>
      </tr>
      ${trip.travelStyle != null ? '''
      <tr>
        <td style="padding: 12px 0; border-bottom: 1px solid #333;">
          <strong>🎒 Travel Style</strong>
        </td>
        <td style="padding: 12px 0; border-bottom: 1px solid #333; text-align: right;">
          ${trip.travelStyle}
        </td>
      </tr>''' : ''}
    </table>
    <div style="margin-top: 24px; padding: 16px; background: #1E1E1E; border-radius: 12px;">
      <h3 style="color: #4ECDC4; margin-top: 0;">📋 Your Itinerary</h3>
      <pre style="white-space: pre-wrap; font-size: 13px; line-height: 1.6; color: #ccc;">${trip.itinerary}</pre>
    </div>
    <p style="margin-top: 24px; text-align: center; color: #888; font-size: 13px;">
      This email was sent by TripIt — your AI travel planner.
    </p>
  </div>
</div>
''';

      await mailer.send(message, smtpServer);
      // ignore: avoid_print
      print('Trip confirmation email sent to $recipientEmail');
    } catch (e) {
      // Don't crash the app if email fails – just log it.
      // ignore: avoid_print
      print('Failed to send trip email: $e');
    }
  }
}
