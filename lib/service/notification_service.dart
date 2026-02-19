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

      // Generate base notification ID
      final baseId = _generateNotificationId(eventIndex, i);

      // If repeat disabled or set to 'none' -> schedule single occurrence
      if (!event.repeatEnabled || event.repeatType == 'none') {
        await _scheduleNotification(
          id: baseId,
          title: '🎉 ${event.name}\'s Birthday!',
          body: 'Today is ${event.name}\'s birthday! Don\'t forget to wish them.',
          scheduledDate: scheduledDate,
          payload: 'birthday_$eventIndex',
          channelId: 'birthday_reminders',
          channelName: 'Birthday Reminders',
          channelDescription: 'Notifications for upcoming birthdays',
        );
        debugPrint('Scheduled one-off reminder for ${event.name} at $scheduledDate (ID: $baseId)');
        continue;
      }

      // Handle repeating types
      if (event.repeatType == 'yearly') {
        await _scheduleNotification(
          id: baseId,
          title: '🎉 ${event.name}\'s Birthday!',
          body: 'Today is ${event.name}\'s birthday! Don\'t forget to wish them.',
          scheduledDate: scheduledDate,
          payload: 'birthday_$eventIndex',
          channelId: 'birthday_reminders',
          channelName: 'Birthday Reminders',
          channelDescription: 'Notifications for upcoming birthdays',
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        debugPrint('Scheduled yearly reminder for ${event.name} at $scheduledDate (ID: $baseId)');
        continue;
      }

      if (event.repeatType == 'day') {
        await _scheduleNotification(
          id: baseId,
          title: '🎉 ${event.name}\'s Birthday!',
          body: 'Today is ${event.name}\'s birthday! Don\'t forget to wish them.',
          scheduledDate: scheduledDate,
          payload: 'birthday_$eventIndex',
          channelId: 'birthday_reminders',
          channelName: 'Birthday Reminders',
          channelDescription: 'Notifications for upcoming birthdays',
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('Scheduled daily reminder for ${event.name} at $scheduledDate (ID: $baseId)');
        continue;
      }

      // For minute/hour/custom repeats we will schedule multiple future occurrences
      Duration interval;
      int occurrences;
      if (event.repeatType == 'minute') {
        interval = const Duration(minutes: 1);
        occurrences = 60; // schedule next 60 minutes
      } else if (event.repeatType == 'hour') {
        interval = const Duration(hours: 1);
        occurrences = 48; // next 48 hours
      } else if (event.repeatType == 'custom') {
        final unit = event.customUnit ?? 'minutes';
        final value = event.customInterval ?? 1;
        if (unit == 'minutes') {
          interval = Duration(minutes: value);
          occurrences = 60; // schedule next 60 occurrences
        } else if (unit == 'hours') {
          interval = Duration(hours: value);
          occurrences = 48;
        } else {
          interval = Duration(days: value);
          occurrences = 365;
        }
      } else {
        // fallback to single
        await _scheduleNotification(
          id: baseId,
          title: '🎉 ${event.name}\'s Birthday!',
          body: 'Today is ${event.name}\'s birthday! Don\'t forget to wish them.',
          scheduledDate: scheduledDate,
          payload: 'birthday_$eventIndex',
          channelId: 'birthday_reminders',
          channelName: 'Birthday Reminders',
          channelDescription: 'Notifications for upcoming birthdays',
        );
        continue;
      }

      // Schedule multiple occurrences using single-instance scheduled notifications
      for (int j = 0; j < occurrences; j++) {
        final scheduled = scheduledDate.add(interval * j);
        final id = baseId + (j + 1) * 1000 + i * 100;
        await _scheduleNotification(
          id: id,
          title: '🎉 ${event.name}\'s Birthday!',
          body: 'Today is ${event.name}\'s birthday! Don\'t forget to wish them.',
          scheduledDate: scheduled,
          payload: 'birthday_${eventIndex}_$j',
          channelId: 'birthday_reminders',
          channelName: 'Birthday Reminders',
          channelDescription: 'Notifications for upcoming birthdays',
        );
      }
      debugPrint('Scheduled $occurrences repeating reminders for ${event.name} starting at $scheduledDate (base ID: $baseId)');
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
    DateTimeComponents? matchDateTimeComponents,
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
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );
  }

  // Cancel all reminders for a specific event
  Future<void> cancelEventReminders(int eventIndex) async {
    // Cancel a wide range of possible notification IDs for this event
    // IDs are generated as: base = _generateNotificationId(eventIndex, reminderIndex)
    // and for repeating we added offsets. We'll cancel a broad range to be safe.
    for (int reminderIndex = 0; reminderIndex < 20; reminderIndex++) {
      final base = _generateNotificationId(eventIndex, reminderIndex);
      // cancel base ID
      await _notifications.cancel(base);
      // cancel a range of generated repeating IDs
      for (int j = 0; j < 100; j++) {
        final id = base + (j + 1) * 1000 + reminderIndex * 100;
        await _notifications.cancel(id);
      }
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