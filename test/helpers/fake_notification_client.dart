import 'package:dailyflow_billos/models/task_item.dart';
import 'package:dailyflow_billos/services/notification_service.dart';

class FakeNotificationClient implements LocalNotificationClient {
  final Map<int, TaskItem> scheduledTasks = {};
  bool permissionGranted = true;
  String? launchTaskId;
  int permissionRequests = 0;
  int settingsOpened = 0;
  int timezoneRefreshes = 0;

  @override
  Future<String?> initialize(void Function(String taskId) onTaskTap) async =>
      launchTaskId;

  @override
  Future<bool> notificationsAllowed() async => permissionGranted;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleTask(TaskItem task, int notificationId) async {
    scheduledTasks[notificationId] = task;
  }

  @override
  Future<void> cancel(int notificationId) async {
    scheduledTasks.remove(notificationId);
  }

  @override
  Future<int> pendingCount() async => scheduledTasks.length;

  @override
  Future<void> openNotificationSettings() async {
    settingsOpened++;
  }

  @override
  Future<void> refreshLocalTimezone() async {
    timezoneRefreshes++;
  }
}
