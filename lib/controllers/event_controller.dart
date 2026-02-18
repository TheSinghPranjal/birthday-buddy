import 'package:flutter_bday/service/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';

final eventListProvider = StateNotifierProvider<EventController, List<BirthdayEvent>>((ref) {
  return EventController();
});

class EventController extends StateNotifier<List<BirthdayEvent>> {
  static const _boxName = 'events';
  final NotificationService _notificationService = NotificationService();

  EventController() : super([]) {
    _initializeNotifications();
    _loadEvents();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  Future<Box<BirthdayEvent>> _box() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<BirthdayEvent>(_boxName);
    }
    return await Hive.openBox<BirthdayEvent>(_boxName);
  }

  Future<void> _loadEvents() async {
    final box = await _box();
    state = box.values.toList();

    // Reschedule all notifications on app start
    await _notificationService.rescheduleAllNotifications(state);
  }

  Future<void> addEvent(BirthdayEvent event) async {
    final box = await _box();
    final index = await box.add(event);
    state = [...box.values.toList()];

    // Schedule notifications for the new event
    if (event.isActive) {
      await _notificationService.scheduleEventReminders(event, index);
    }
  }

  Future<void> updateEvent(int index, BirthdayEvent event) async {
    final box = await _box();
    await box.putAt(index, event);
    state = [...box.values.toList()];

    // Reschedule notifications for updated event
    await _notificationService.cancelEventReminders(index);
    if (event.isActive) {
      await _notificationService.scheduleEventReminders(event, index);
    }
  }

  Future<void> deleteEvent(int index) async {
    final box = await _box();

    // Cancel notifications before deleting
    await _notificationService.cancelEventReminders(index);

    await box.deleteAt(index);
    state = [...box.values.toList()];

    // Reschedule all remaining notifications with updated indices
    await _notificationService.rescheduleAllNotifications(state);
  }

  Future<void> toggleEvent(int index) async {
    final box = await _box();
    final event = box.getAt(index);
    if (event != null) {
      event.isActive = !event.isActive;
      await box.putAt(index, event);
      state = [...box.values.toList()];

      // Update notifications based on active state
      if (event.isActive) {
        await _notificationService.scheduleEventReminders(event, index);
      } else {
        await _notificationService.cancelEventReminders(index);
      }
    }
  }

  Future<void> searchEvents(String query) async {
    final box = await _box();
    if (query.isEmpty) {
      state = box.values.toList();
    } else {
      state = box.values
          .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<void> filterByMonth(int month) async {
    final box = await _box();
    if (month == 0) {
      state = box.values.toList();
    } else {
      state = box.values.where((e) => e.birthday.month == month).toList();
    }
  }

  Future<void> clearFilters() async {
    final box = await _box();
    state = box.values.toList();
  }

  // Test notification
  Future<void> testNotification(String name) async {
    await _notificationService.showImmediateNotification(
      title: '🎉 Test Notification',
      body: 'This is how ${name}\'s birthday reminder will look!',
    );
  }

  // Get pending notifications count (for debugging)
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notificationService.getPendingNotifications();
    return pending.length;
  }
}