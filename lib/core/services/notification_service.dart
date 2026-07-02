import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const Color _assistPurple = Color(0xFF7C6EF8);

  static AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'assist_channel',
        'ASSIST Reminders',
        channelDescription: 'Notifications for ASSIST reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: _assistPurple,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      );

  static NotificationDetails get _notificationDetails =>
      NotificationDetails(android: _androidDetails);

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request permissions on Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap - can be expanded with navigation
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await initialize();
    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(id, title, body, _notificationDetails);
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
