import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../services/task_store.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/dailyflow_splash_screen.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'task_details_screen.dart';
import 'tasks_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({this.databaseService, this.notificationClient, super.key});

  final DatabaseService? databaseService;
  final LocalNotificationClient? notificationClient;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late final TaskStore _taskStore;
  late final ReminderService _reminderService;
  int _selectedIndex = 0;
  String? _pendingNotificationTaskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final databaseService = widget.databaseService ?? DatabaseService.instance;
    _reminderService = ReminderService(
      database: databaseService,
      notifications: widget.notificationClient ?? NotificationService.instance,
    );
    _taskStore = TaskStore(
      databaseService: databaseService,
      reminders: _reminderService,
    );
    unawaited(
      _taskStore
          .initialize(onNotificationTaskTap: _handleNotificationTaskTap)
          .then((_) {
            _showReminderErrorIfPresent();
            final taskId =
                _pendingNotificationTaskId ?? _reminderService.initialTaskId;
            _pendingNotificationTaskId = null;
            if (taskId != null) _handleNotificationTaskTap(taskId);
          }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskStore.dispose();
    _reminderService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _taskStore.isInitialized) {
      unawaited(_taskStore.rescheduleReminders());
    }
  }

  void _handleNotificationTaskTap(String taskId) {
    if (!_taskStore.isInitialized) {
      _pendingNotificationTaskId = taskId;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final task = _taskStore.taskById(taskId);
      if (task == null) {
        _showMessage('That task is no longer available.', isError: true);
        return;
      }
      _selectedIndex = 0;
      setState(() {});
      unawaited(_openTaskDetails(task));
    });
  }

  Future<void> _toggleTask(TaskItem task) async {
    await _runTaskOperation(() async {
      await _taskStore.toggleCompletion(task.id);
    });
  }

  Future<TaskItem?> _openTaskForm({TaskItem? task}) {
    return Navigator.of(context).push<TaskItem>(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          task: task,
          onEnableReminders: () => _taskStore.setNotificationsEnabled(true),
        ),
      ),
    );
  }

  Future<void> _addOrUpdateTask({TaskItem? task}) async {
    final result = await _openTaskForm(task: task);
    if (result == null || !mounted) return;

    await _runTaskOperation(() async {
      if (task == null) {
        await _taskStore.addTask(result);
      } else if (!await _taskStore.updateTask(result)) {
        throw StateError('The task no longer exists.');
      }
    }, successMessage: task == null ? 'Task saved.' : 'Task updated.');
  }

  Future<TaskItem?> _editTask(TaskItem task) async {
    final result = await _openTaskForm(task: task);
    if (result == null || !mounted) return null;

    try {
      if (!await _taskStore.updateTask(result)) {
        throw StateError('The task no longer exists.');
      }
      _showMessage('Task updated.');
      _showReminderErrorIfPresent();
      return _taskStore.taskById(result.id);
    } catch (error) {
      _showMessage('Could not update task: $error', isError: true);
      return null;
    }
  }

  Future<void> _openTaskDetails(TaskItem task) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          task: task,
          onEdit: _editTask,
          onToggle: (updatedTask) async {
            await _taskStore.setCompletion(
              updatedTask.id,
              updatedTask.isCompleted,
            );
          },
          onDelete: _deleteTask,
        ),
      ),
    );
  }

  Future<void> _deleteTask(String id) async {
    if (!await _taskStore.deleteTask(id)) {
      throw StateError('The task no longer exists.');
    }
    if (mounted) _showMessage('Task deleted.');
    _showReminderErrorIfPresent();
  }

  Future<void> _runTaskOperation(
    Future<void> Function() operation, {
    String? successMessage,
  }) async {
    try {
      await operation();
      if (successMessage != null && mounted) _showMessage(successMessage);
      _showReminderErrorIfPresent();
    } catch (error) {
      if (mounted) _showMessage('Task operation failed: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
        ),
      );
  }

  void _showReminderErrorIfPresent() {
    final error = _taskStore.takeReminderError();
    if (error != null && mounted) {
      _showMessage('Reminder not updated: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_taskStore, _reminderService]),
      builder: (context, _) {
        if (_taskStore.isLoading) {
          return const DailyFlowSplashScreen();
        }
        if (_taskStore.loadError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'DailyFlow could not load your tasks.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_taskStore.loadError}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          unawaited(_taskStore.retryInitialization()),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final tasks = _taskStore.tasks;
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeScreen(
                statistics: _taskStore.statistics(),
                onTaskToggle: _toggleTask,
                onTaskTap: _openTaskDetails,
                onViewAll: () => setState(() => _selectedIndex = 1),
              ),
              TasksScreen(
                tasks: tasks,
                onTaskToggle: _toggleTask,
                onTaskTap: _openTaskDetails,
              ),
              CalendarScreen(
                tasks: tasks,
                onTaskToggle: _toggleTask,
                onTaskTap: _openTaskDetails,
              ),
              ProgressScreen(tasks: tasks),
              SettingsScreen(
                notificationsEnabled: _reminderService.notificationsEnabled,
                notificationPermissionGranted:
                    _reminderService.permissionGranted,
                pendingReminderCount: _reminderService.pendingCount,
                onNotificationsChanged: _taskStore.setNotificationsEnabled,
                onOpenNotificationSettings: () async {
                  await _reminderService.openNotificationSettings();
                  await _reminderService.refreshPermissionStatus();
                },
                onClearData: _taskStore.clearAllTasks,
              ),
            ],
          ),
          floatingActionButton: _selectedIndex < 3
              ? FloatingActionButton.extended(
                  onPressed: () => _addOrUpdateTask(),
                  tooltip: 'Add task',
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add task'),
                )
              : null,
          bottomNavigationBar: BottomNavigation(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
        );
      },
    );
  }
}
