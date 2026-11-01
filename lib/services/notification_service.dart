// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/date_helpers.dart';

// Local (not push) reminders for registered events.
class NotificationService {
  static const _channelId = 'event_reminders';
  static const _channelName = 'Event reminders';
  static const _channelDescription = 'Reminders for events you registered for';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // False after the student denies the permission.
  static bool remindersAllowed = true;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // Keep the default time zone if the device value is not recognised.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    final android = _androidPlugin();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
  }

  static AndroidFlutterLocalNotificationsPlugin? _androidPlugin() {
    return _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
  }

  // One notification id per event, so it can always be cancelled again.
  static int idFor(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }

  static Future<bool> requestPermission() async {
    final granted = await _androidPlugin()?.requestNotificationsPermission();
    remindersAllowed = granted ?? true;
    return remindersAllowed;
  }

  static Future<bool> areEnabled() async {
    final enabled = await _androidPlugin()?.areNotificationsEnabled();
    return enabled ?? true;
  }

  static Future<void> scheduleReminder({
    required String eventId,
    required String eventName,
    required DateTime startAt,
    required String venueName,
  }) async {
    final reminderTime = startAt.subtract(const Duration(minutes: 60));
    if (!reminderTime.isAfter(DateTime.now())) {
      return; // The reminder time already passed.
    }

    await _plugin.zonedSchedule(
      id: idFor(eventId),
      title: eventName,
      body: '${formatEventTime(startAt)} at $venueName',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: eventId,
    );
  }

  static Future<void> cancelReminder(String eventId) async {
    await _plugin.cancel(id: idFor(eventId));
  }

  // Called on app launch: add missing reminders, drop reminders that no longer apply.
  static Future<void> resync(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
  ) async {
    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((item) => item.id).toSet();
    final keepIds = <int>{};

    for (final doc in registrations) {
      final data = doc.data();
      final eventId = data['eventId'] as String?;
      final startAt = (data['eventStartAt'] as Timestamp?)?.toDate();
      final endAt = (data['eventEndAt'] as Timestamp?)?.toDate();
      if (eventId == null || startAt == null || endAt == null) {
        continue;
      }
      if (data['status'] != 'registered' || !endAt.isAfter(DateTime.now())) {
        continue;
      }

      final id = idFor(eventId);
      if (data['reminderEnabled'] == false) {
        await cancelReminder(eventId);
        continue;
      }

      keepIds.add(id);
      if (!pendingIds.contains(id)) {
        await scheduleReminder(
          eventId: eventId,
          eventName: data['eventName'] as String? ?? '',
          startAt: startAt,
          venueName: data['venueName'] as String? ?? '',
        );
      }
    }

    for (final id in pendingIds) {
      if (!keepIds.contains(id)) {
        await _plugin.cancel(id: id);
      }
    }
  }
}
