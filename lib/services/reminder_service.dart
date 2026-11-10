import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';
import 'database_service.dart';
import 'notification_service.dart';

class ReminderService extends ChangeNotifier {
  ReminderService({required this.database, required this.notifications});

  static const _enabledPreference = 'notifications_enabled';

  final DatabaseService database;
  final LocalNotificationClient notifications;
  bool _notificationsEnabled = false;
  bool _permissionGranted = false;
  int _pendingCount = 0;
  String? _initialTaskId;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get permissionGranted => _permissionGranted;
  int get pendingCount => _pendingCount;
  String? get initialTaskId => _initialTaskId;

  Future<void> initialize({void Function(String taskId)? onTaskTap}) async {
    final preferences = await SharedPreferences.getInstance();
    _notificationsEnabled = preferences.getBool(_enabledPreference) ?? false;
    _initialTaskId = await notifications.initialize(onTaskTap ?? (_) {});
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    _permissionGranted = await notifications.notificationsAllowed();
    _pendingCount = await notifications.pendingCount();
    notifyListeners();
  }

  Future<bool> enableNotifications() async {
    if (_notificationsEnabled && _permissionGranted) return true;
    final granted = await notifications.requestPermission();
    _permissionGranted = granted;
    if (!granted) {
      _notificationsEnabled = false;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_enabledPreference, false);
      notifyListeners();
      return false;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledPreference, true);
    _notificationsEnabled = true;
    await refreshStatus();
    return true;
  }

  Future<void> disableNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledPreference, false);
    _notificationsEnabled = false;
    notifyListeners();
  }

  Future<TaskItem> synchronize(TaskItem task) async {
    final reminderAt = task.reminderAt;
    final shouldSchedule =
        _notificationsEnabled &&
        _permissionGranted &&
        task.reminderEnabled &&
        !task.isCompleted &&
        reminderAt != null;

    if (!shouldSchedule) {
      await _cancelAndClear(task);
      if (task.reminderEnabled &&
          reminderAt != null &&
          !task.isCompleted &&
          !_notificationsEnabled) {
        throw StateError(
          'Enable notifications in Settings to schedule reminders.',
        );
      }
      if (task.reminderEnabled &&
          reminderAt != null &&
          !task.isCompleted &&
          !_permissionGranted) {
        throw StateError(
          'Notification permission is off. Allow notifications in Settings.',
        );
      }
      return task.copyWith(clearNotificationId: true);
    }

    if (!reminderAt.isAfter(DateTime.now())) {
      await _cancelAndClear(task);
      throw ArgumentError('Reminder time must be in the future.');
    }

    final taskId = int.tryParse(task.id);
    if (taskId == null || taskId <= 0) {
      throw ArgumentError.value(task.id, 'task.id', 'Invalid task ID.');
    }
    if (task.notificationId != null) {
      await notifications.cancel(task.notificationId!);
    }
    await notifications.scheduleTask(task, taskId);
    await database.updateNotificationId(task.id, taskId);
    _pendingCount = await notifications.pendingCount();
    notifyListeners();
    return task.copyWith(notificationId: taskId);
  }

  Future<void> cancelTask(TaskItem task) async {
    await _cancelAndClear(task);
    await refreshStatus();
  }

  Future<void> refreshLocalTimezone() async {
    await notifications.refreshLocalTimezone();
  }

  Future<void> openNotificationSettings() =>
      notifications.openNotificationSettings();

  Future<void> refreshPermissionStatus() => refreshStatus();

  Future<void> _cancelAndClear(TaskItem task) async {
    if (task.notificationId != null) {
      await notifications.cancel(task.notificationId!);
    }
    if (task.id.isNotEmpty) {
      await database.updateNotificationId(task.id, null);
    }
    _pendingCount = await notifications.pendingCount();
  }
}
