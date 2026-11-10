import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/task_item.dart';

abstract interface class LocalNotificationClient {
  Future<String?> initialize(void Function(String taskId) onTaskTap);
  Future<bool> notificationsAllowed();
  Future<bool> requestPermission();
  Future<void> scheduleTask(TaskItem task, int notificationId);
  Future<void> cancel(int notificationId);
  Future<int> pendingCount();
  Future<void> openNotificationSettings();
  Future<void> refreshLocalTimezone();
}

class NotificationService implements LocalNotificationClient {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final instance = NotificationService();

  static const channelId = 'dailyflow_task_reminders';
  static const channelName = 'DailyFlow Reminders';
  static const channelDescription =
      'Notifications for scheduled daily activities.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  Future<void>? _initialization;
  void Function(String taskId)? _onTaskTap;

  @override
  Future<void> refreshLocalTimezone() async {
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    final identifier = localTimezone.identifier;
    final location = switch (identifier) {
      'GMT' || 'UTC' || 'Etc/UTC' => timezone.UTC,
      _ => timezone.getLocation(identifier),
    };
    timezone.setLocalLocation(location);
  }

  @override
  Future<String?> initialize(void Function(String taskId) onTaskTap) async {
    if (!_initialized) {
      _onTaskTap ??= onTaskTap;
      final initialization = _initialization ??= _initialize();
      try {
        await initialization;
      } finally {
        if (identical(_initialization, initialization)) {
          _initialization = null;
        }
      }
    }

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    return launchDetails?.didNotificationLaunchApp == true
        ? response?.payload
        : null;
  }

  @override
  Future<bool> notificationsAllowed() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return !kIsWeb;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> scheduleTask(TaskItem task, int notificationId) async {
    if (!_initialized) {
      await initialize(_onTaskTap ?? (_) {});
    }
    if (!_initialized) {
      throw StateError('The local notification plugin did not initialize.');
    }
    final reminderAt = task.reminderAt;
    if (reminderAt == null || !reminderAt.isAfter(DateTime.now())) {
      throw ArgumentError('Reminder time must be in the future.');
    }

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Task Reminder',
      body: 'You have a scheduled task: ${task.title}',
      scheduledDate: timezone.TZDateTime.from(reminderAt, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> _initialize() async {
    await refreshLocalTimezone();

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final taskId = response.payload;
        if (taskId != null && taskId.isNotEmpty) _onTaskTap?.call(taskId);
      },
    );
    if (initialized != true) {
      throw StateError('The local notification plugin did not initialize.');
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(id: notificationId);

  @override
  Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;

  @override
  Future<void> openNotificationSettings() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.openAppNotificationSettings();
  }
}
