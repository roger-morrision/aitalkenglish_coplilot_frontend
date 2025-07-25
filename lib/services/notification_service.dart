import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) {
      // Notifications not supported on web
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> scheduleDailyVocabReminder({
    DateTime? reminderTime,
  }) async {
    if (kIsWeb) return;
    
    await _notifications.show(
      1,
      'Daily Vocabulary Challenge',
      'Ready to learn new words today? Expand your vocabulary!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_vocab',
          'Daily Vocabulary',
          channelDescription: 'Daily vocabulary learning reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'vocab_reminder',
        ),
      ),
    );
  }

  static Future<void> scheduleStreakReminder({
    DateTime? reminderTime,
    int currentStreak = 0,
  }) async {
    if (kIsWeb) return;
    
    await _notifications.show(
      2,
      'Keep Your Streak!',
      'You have a $currentStreak day streak. Do not break it now!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder',
          'Streak Reminders',
          channelDescription: 'Learning streak maintenance reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'streak_reminder',
        ),
      ),
    );
  }

  static Future<void> scheduleReviewReminder({
    DateTime? reviewTime,
    String wordOrTopic = '',
  }) async {
    if (kIsWeb) return;
    
    await _notifications.show(
      3,
      'Time to Review!',
      wordOrTopic.isNotEmpty 
          ? 'Time to review: $wordOrTopic'
          : 'You have words ready for review!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'review_reminder',
          'Review Reminders',
          channelDescription: 'Spaced repetition review reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'review_reminder',
        ),
      ),
    );
  }

  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (kIsWeb) return;
    
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate',
          'Immediate Notifications',
          channelDescription: 'Immediate learning notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }
}
