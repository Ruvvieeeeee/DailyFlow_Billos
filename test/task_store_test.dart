import 'dart:io';

import 'package:dailyflow_billos/models/task_item.dart';
import 'package:dailyflow_billos/services/database_service.dart';
import 'package:dailyflow_billos/services/reminder_service.dart';
import 'package:dailyflow_billos/services/task_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/fake_notification_client.dart';

void main() {
  late Directory directory;
  late DatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('dailyflow_sqlite_test_');
    databaseService = DatabaseService(
      factory: databaseFactoryFfi,
      pathOverride: path.join(directory.path, 'dailyflow_test.db'),
    );
  });

  tearDown(() async {
    await databaseService.close();
    await directory.delete(recursive: true);
  });

  TaskItem task({
    String id = '',
    String title = 'Read Dart chapter',
    String description = 'Review collections and examples',
    TaskCategory category = TaskCategory.school,
    TaskPriority priority = TaskPriority.high,
    bool completed = false,
    DateTime? scheduledAt,
    DateTime? createdAt,
    bool reminderEnabled = false,
    DateTime? reminderAt,
  }) {
    return TaskItem(
      id: id,
      title: title,
      description: description,
      category: category,
      scheduledAt: scheduledAt ?? DateTime(2026, 11, 10, 9, 30),
      priority: priority,
      isCompleted: completed,
      createdAt: createdAt ?? DateTime(2026, 11, 9),
      reminderEnabled: reminderEnabled,
      reminderAt: reminderAt,
    );
  }

  group('DatabaseService', () {
    test(
      'initializes the versioned schema and starts with no records',
      () async {
        final database = await databaseService.database;
        final version = await database.getVersion();
        final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          [DatabaseService.tableName],
        );
        final tasks = await databaseService.getTasks();

        expect(version, DatabaseService.databaseVersion);
        expect(tables, hasLength(1));
        expect(tasks, isEmpty);
      },
    );

    test(
      'inserts and retrieves task fields and generated database ID',
      () async {
        final input = task();
        final id = await databaseService.insertTask(input);
        final loaded = await databaseService.getTaskById('$id');
        final allTasks = await databaseService.getTasks();

        expect(id, greaterThan(0));
        expect(loaded?.id, '$id');
        expect(loaded?.title, input.title);
        expect(loaded?.description, input.description);
        expect(loaded?.category, input.category);
        expect(loaded?.priority, input.priority);
        expect(loaded?.scheduledAt, input.scheduledAt);
        expect(loaded?.isCompleted, isFalse);
        expect(allTasks, hasLength(1));
      },
    );

    test('updates fields without changing the existing row ID', () async {
      final id = await databaseService.insertTask(task());
      final changed = task(
        id: '$id',
        title: 'Updated title',
        description: '',
        category: TaskCategory.work,
        priority: TaskPriority.low,
        scheduledAt: DateTime(2026, 11, 12, 14, 5),
      );

      expect(await databaseService.updateTask(changed), 1);
      final loaded = await databaseService.getTaskById('$id');
      expect(loaded?.id, '$id');
      expect(loaded?.title, 'Updated title');
      expect(loaded?.description, isEmpty);
      expect(loaded?.category, TaskCategory.work);
      expect(loaded?.priority, TaskPriority.low);
      expect(loaded?.scheduledAt, DateTime(2026, 11, 12, 14, 5));
    });

    test(
      'updates completion status to integer values and deletes one row',
      () async {
        final firstId = await databaseService.insertTask(task());
        final secondId = await databaseService.insertTask(
          task(title: 'Second task'),
        );

        expect(await databaseService.updateCompletion('$firstId', true), 1);
        expect(
          (await databaseService.getTaskById('$firstId'))?.isCompleted,
          isTrue,
        );
        expect(await databaseService.deleteTask('$firstId'), 1);
        expect(await databaseService.getTaskById('$firstId'), isNull);
        expect(
          (await databaseService.getTaskById('$secondId'))?.title,
          'Second task',
        );
        expect(await databaseService.deleteTask('$firstId'), 0);
      },
    );

    test('rejects invalid IDs and blank task titles', () async {
      await expectLater(
        databaseService.getTaskById('sample-id'),
        throwsArgumentError,
      );
      await expectLater(
        databaseService.insertTask(task(title: '  ')),
        throwsArgumentError,
      );
    });

    test(
      'persists insert, update, completion, and delete across reopen',
      () async {
        final original = task();
        final id = await databaseService.insertTask(original);

        await databaseService.close();
        databaseService = DatabaseService(
          factory: databaseFactoryFfi,
          pathOverride: path.join(directory.path, 'dailyflow_test.db'),
        );
        var loaded = await databaseService.getTaskById('$id');
        expect(loaded?.title, original.title);

        expect(
          await databaseService.updateTask(
            original.copyWith(id: '$id', title: 'Saved edit'),
          ),
          1,
        );
        await databaseService.updateCompletion('$id', true);
        await databaseService.close();
        databaseService = DatabaseService(
          factory: databaseFactoryFfi,
          pathOverride: path.join(directory.path, 'dailyflow_test.db'),
        );

        loaded = await databaseService.getTaskById('$id');
        expect(loaded?.title, 'Saved edit');
        expect(loaded?.isCompleted, isTrue);
        expect(await databaseService.deleteTask('$id'), 1);
        await databaseService.close();
        databaseService = DatabaseService(
          factory: databaseFactoryFfi,
          pathOverride: path.join(directory.path, 'dailyflow_test.db'),
        );
        expect(await databaseService.getTasks(), isEmpty);
      },
    );

    test('migrates version one task data without deleting records', () async {
      final legacyDatabase = await databaseFactoryFfi.openDatabase(
        path.join(directory.path, 'legacy.db'),
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                category TEXT NOT NULL,
                date TEXT NOT NULL,
                time TEXT NOT NULL,
                priority TEXT NOT NULL,
                is_completed INTEGER NOT NULL DEFAULT 0,
                reminder_date_time TEXT,
                created_at TEXT NOT NULL
              )
            ''');
            await db.insert('tasks', {
              'title': 'Legacy record',
              'description': 'Keep this task',
              'category': 'school',
              'date': '2026-11-10',
              'time': '09:30',
              'priority': 'high',
              'is_completed': 0,
              'reminder_date_time': null,
              'created_at': '2026-11-09T00:00:00.000',
            });
          },
        ),
      );
      await legacyDatabase.close();

      final migrated = DatabaseService(
        factory: databaseFactoryFfi,
        pathOverride: path.join(directory.path, 'legacy.db'),
      );
      final loaded = await migrated.getTasks();
      expect(await migrated.database.then((db) => db.getVersion()), 2);
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Legacy record');
      expect(loaded.single.reminderEnabled, isFalse);
      expect(loaded.single.reminderAt, isNull);
      await migrated.close();
    });

    test('stores and retrieves reminder fields', () async {
      final reminder = DateTime.now().add(const Duration(days: 1));
      final id = await databaseService.insertTask(
        task(reminderEnabled: true, reminderAt: reminder),
      );
      final loaded = await databaseService.getTaskById('$id');
      expect(loaded?.reminderEnabled, isTrue);
      expect(loaded?.reminderAt, reminder);
      expect(loaded?.notificationId, isNull);
      await databaseService.updateNotificationId('$id', id);
      expect((await databaseService.getTaskById('$id'))?.notificationId, id);
    });
  });

  group('TaskStore', () {
    test(
      'loads database records and refreshes state after each CRUD operation',
      () async {
        final store = TaskStore(databaseService: databaseService);
        await store.initialize();
        expect(store.isInitialized, isTrue);
        expect(store.tasks, isEmpty);

        final added = await store.addTask(task());
        expect(added.id, isNotEmpty);
        expect(store.tasks, hasLength(1));

        final updated = added.copyWith(
          title: 'Updated in store',
          category: TaskCategory.work,
        );
        expect(await store.updateTask(updated), isTrue);
        expect(store.taskById(added.id)?.title, 'Updated in store');
        expect(store.taskById(added.id)?.id, added.id);

        expect(await store.setCompletion(added.id, true), isTrue);
        expect(store.taskById(added.id)?.isCompleted, isTrue);
        expect(await store.toggleCompletion(added.id), isTrue);
        expect(store.taskById(added.id)?.isCompleted, isFalse);

        expect(await store.deleteTask(added.id), isTrue);
        expect(store.tasks, isEmpty);
        store.dispose();
      },
    );

    test(
      'statistics use loaded database tasks and update after mutations',
      () async {
        final store = TaskStore(databaseService: databaseService);
        await store.initialize();
        final first = await store.addTask(
          task(completed: true, scheduledAt: DateTime.now()),
        );
        await store.addTask(
          task(
            title: 'Pending today',
            completed: false,
            scheduledAt: DateTime.now(),
          ),
        );
        await store.addTask(
          task(
            title: 'Future task',
            scheduledAt: DateTime.now().add(const Duration(days: 2)),
          ),
        );

        var stats = store.statistics();
        expect(stats.total, 3);
        expect(stats.completed, 1);
        expect(stats.pending, 2);
        expect(stats.todayTasks, hasLength(2));
        expect(stats.todayCompleted, 1);
        expect(stats.todayPending, 1);
        expect(stats.dailyCompletion, 0.5);

        await store.setCompletion(first.id, false);
        stats = store.statistics();
        expect(stats.completed, 0);
        expect(stats.dailyCompletion, 0);
        store.dispose();
      },
    );

    test('reports database load failures for the UI to show', () async {
      final brokenService = DatabaseService(
        factory: databaseFactoryFfi,
        pathOverride: directory.path,
      );
      final store = TaskStore(databaseService: brokenService);

      await store.initialize();
      expect(store.isLoading, isFalse);
      expect(store.isInitialized, isFalse);
      expect(store.loadError, isNotNull);

      store.dispose();
      await brokenService.close();
    });

    test(
      'schedules, updates, disables, completes, and deletes reminders',
      () async {
        final client = FakeNotificationClient();
        final reminders = ReminderService(
          database: databaseService,
          notifications: client,
        );
        final store = TaskStore(
          databaseService: databaseService,
          reminders: reminders,
        );
        await store.initialize();
        expect(await store.setNotificationsEnabled(true), isTrue);

        final reminderAt = DateTime.now().add(const Duration(hours: 2));
        var saved = await store.addTask(
          task(reminderEnabled: true, reminderAt: reminderAt),
        );
        final notificationId = int.parse(saved.id);
        expect(saved.notificationId, notificationId);
        expect(client.scheduledTasks[notificationId]?.reminderAt, reminderAt);

        final updatedReminder = reminderAt.add(const Duration(hours: 1));
        await store.updateTask(saved.copyWith(reminderAt: updatedReminder));
        expect(
          client.scheduledTasks[notificationId]?.reminderAt,
          updatedReminder,
        );

        expect(await store.setNotificationsEnabled(false), isTrue);
        expect(client.scheduledTasks, isEmpty);
        expect(store.taskById(saved.id)?.notificationId, isNull);
        expect(await store.setNotificationsEnabled(true), isTrue);
        expect(
          client.scheduledTasks[notificationId]?.reminderAt,
          updatedReminder,
        );

        saved = store.taskById(saved.id)!;
        await store.setCompletion(saved.id, true);
        expect(client.scheduledTasks, isEmpty);
        expect(store.taskById(saved.id)?.notificationId, isNull);

        await store.setCompletion(saved.id, false);
        expect(
          client.scheduledTasks[notificationId]?.reminderAt,
          updatedReminder,
        );

        saved = store.taskById(saved.id)!;
        await store.updateTask(
          saved.copyWith(reminderEnabled: false, clearReminderAt: true),
        );
        expect(client.scheduledTasks, isEmpty);
        expect(store.taskById(saved.id)?.reminderEnabled, isFalse);

        await store.deleteTask(saved.id);
        expect(await databaseService.getTaskById(saved.id), isNull);
        store.dispose();
        reminders.dispose();
      },
    );

    test('restores a saved reminder after reopening the database', () async {
      final client = FakeNotificationClient();
      var reminders = ReminderService(
        database: databaseService,
        notifications: client,
      );
      var store = TaskStore(
        databaseService: databaseService,
        reminders: reminders,
      );
      await store.initialize();
      await store.setNotificationsEnabled(true);
      final saved = await store.addTask(
        task(
          reminderEnabled: true,
          reminderAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      );
      final id = int.parse(saved.id);
      store.dispose();
      reminders.dispose();
      await databaseService.close();

      databaseService = DatabaseService(
        factory: databaseFactoryFfi,
        pathOverride: path.join(directory.path, 'dailyflow_test.db'),
      );
      reminders = ReminderService(
        database: databaseService,
        notifications: FakeNotificationClient(),
      );
      store = TaskStore(databaseService: databaseService, reminders: reminders);
      await store.initialize();

      expect(store.taskById(saved.id)?.notificationId, id);
      expect(
        (reminders.notifications as FakeNotificationClient).scheduledTasks[id],
        isNotNull,
      );
      store.dispose();
      reminders.dispose();
    });

    test('does not schedule past reminders and reports the reason', () async {
      final client = FakeNotificationClient();
      final reminders = ReminderService(
        database: databaseService,
        notifications: client,
      );
      final store = TaskStore(
        databaseService: databaseService,
        reminders: reminders,
      );
      await store.initialize();
      await store.setNotificationsEnabled(true);

      final saved = await store.addTask(
        task(
          reminderEnabled: true,
          reminderAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      expect(client.scheduledTasks, isEmpty);
      expect(saved.notificationId, isNull);
      expect(store.takeReminderError(), contains('future'));
      store.dispose();
      reminders.dispose();
    });

    test(
      'denied permission disables notifications without losing tasks',
      () async {
        final client = FakeNotificationClient()..permissionGranted = false;
        final reminders = ReminderService(
          database: databaseService,
          notifications: client,
        );
        final store = TaskStore(
          databaseService: databaseService,
          reminders: reminders,
        );
        await store.initialize();
        final saved = await store.addTask(task());

        expect(await store.setNotificationsEnabled(true), isFalse);
        expect(store.taskById(saved.id), isNotNull);
        expect(store.tasks, hasLength(1));
        store.dispose();
        reminders.dispose();
      },
    );
  });
}
