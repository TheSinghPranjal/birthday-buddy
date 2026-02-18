import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/event.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // You can navigate to specific screens here based on payload
  }

  // Request permissions (especially for iOS)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return true; // Android doesn't need runtime permission for notifications
  }

  // Schedule all reminders for a birthday event
  Future<void> scheduleEventReminders(BirthdayEvent event, int eventIndex) async {
    await initialize();

    if (!event.isActive) {
      debugPrint('Event ${event.name} is not active, skipping notifications');
      return;
    }

    // Cancel existing notifications for this event
    await cancelEventReminders(eventIndex);

    final now = DateTime.now();

    for (int i = 0; i < event.reminderTimes.length; i++) {
      final reminderTime = event.reminderTimes[i];

      // Calculate next occurrence of this reminder
      DateTime scheduledDate = DateTime(
        now.year,
        event.birthday.month,
        event.birthday.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // If the date has passed this year, schedule for next year
      if (scheduledDate.isBefore(now)) {
        scheduledDate = DateTime(
          now.year + 1,
          event.birthday.month,
          event.birthday.day,
          reminderTime.hour,
          reminderTime.minute,
        );
      }

      // Generate unique notification ID
      final notificationId = _generateNotificationId(eventIndex, i);

      await _scheduleNotification(
        id: notificationId,
        title: '🎉 ${event.name}\'s Birthday!',
        body: 'Today is ${event.name}\'s birthday! Don\'t forget to wish them.',
        scheduledDate: scheduledDate,
        payload: 'birthday_$eventIndex',
        channelId: 'birthday_reminders',
        channelName: 'Birthday Reminders',
        channelDescription: 'Notifications for upcoming birthdays',
      );

      debugPrint(
        'Scheduled reminder for ${event.name} at $scheduledDate (ID: $notificationId)',
      );
    }
  }

  // Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // FIXED: Removed uiLocalNotificationDateInterpretation parameter
    // This parameter was removed in newer versions of flutter_local_notifications
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat yearly
      payload: payload,
    );
  }

  // Cancel all reminders for a specific event
  Future<void> cancelEventReminders(int eventIndex) async {
    // Assume max 10 reminders per event
    for (int i = 0; i < 10; i++) {
      final notificationId = _generateNotificationId(eventIndex, i);
      await _notifications.cancel(notificationId);
    }
    debugPrint('Cancelled all reminders for event index $eventIndex');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'immediate_notifications',
      'Immediate Notifications',
      channelDescription: 'Notifications shown immediately',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
    );
  }

  // Generate unique notification ID based on event index and reminder index
  int _generateNotificationId(int eventIndex, int reminderIndex) {
    // Event index * 100 + reminder index ensures unique IDs
    return eventIndex * 100 + reminderIndex;
  }

  // Get all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Reschedule all notifications for all events
  Future<void> rescheduleAllNotifications(List<BirthdayEvent> events) async {
    await cancelAllNotifications();

    for (int i = 0; i < events.length; i++) {
      if (events[i].isActive) {
        await scheduleEventReminders(events[i], i);
      }
    }

    debugPrint('Rescheduled notifications for ${events.length} events');
  }
}