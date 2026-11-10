import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

import '../models/task_item.dart';

class DatabaseService {
  DatabaseService({DatabaseFactory? factory, String? pathOverride})
    : _databaseFactory = factory ?? sqflite.databaseFactory,
      _databasePath = pathOverride;

  static final instance = DatabaseService();

  final DatabaseFactory _databaseFactory;
  final String? _databasePath;
  Future<sqflite.Database>? _databaseFuture;

  static const databaseName = 'dailyflow.db';
  static const databaseVersion = 2;
  static const tableName = 'tasks';

  Future<sqflite.Database> get database async {
    final existing = _databaseFuture;
    if (existing != null) return existing;
    final opening = _openDatabase();
    _databaseFuture = opening;
    try {
      return await opening;
    } on Object {
      if (identical(_databaseFuture, opening)) _databaseFuture = null;
      rethrow;
    }
  }

  Future<sqflite.Database> _openDatabase() async {
    final dbPath =
        _databasePath ??
        path.join(await _databaseFactory.getDatabasesPath(), databaseName);
    return _databaseFactory.openDatabase(
      dbPath,
      options: sqflite.OpenDatabaseOptions(
        version: databaseVersion,
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
  }

  Future<void> _createSchema(sqflite.Database database, int version) async {
    await database.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        priority TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
          CHECK (is_completed IN (0, 1)),
        reminder_date_time TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 0
          CHECK (reminder_enabled IN (0, 1)),
        notification_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeSchema(
    sqflite.Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1 && newVersion >= 1) {
      await _createSchema(database, newVersion);
      return;
    }
    if (oldVersion < 2 && newVersion >= 2) {
      await database.execute('''
        ALTER TABLE $tableName
        ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 0
          CHECK (reminder_enabled IN (0, 1))
      ''');
      await database.execute(
        'ALTER TABLE $tableName ADD COLUMN notification_id INTEGER',
      );
    }
  }

  Future<int> insertTask(TaskItem task) async {
    _validateTitle(task.title);
    final db = await database;
    return db.insert(tableName, _toColumns(task));
  }

  Future<List<TaskItem>> getTasks() async {
    final db = await database;
    final rows = await db.query(
      tableName,
      orderBy: 'date ASC, time ASC, id ASC',
    );
    return rows.map(_fromColumns).toList(growable: false);
  }

  Future<TaskItem?> getTaskById(String id) async {
    final db = await database;
    final rows = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [_databaseId(id)],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromColumns(rows.single);
  }

  Future<int> updateTask(TaskItem task) async {
    _validateTitle(task.title);
    final db = await database;
    return db.update(
      tableName,
      _toColumns(task),
      where: 'id = ?',
      whereArgs: [_databaseId(task.id)],
    );
  }

  Future<int> updateCompletion(String id, bool isCompleted) async {
    final db = await database;
    return db.update(
      tableName,
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [_databaseId(id)],
    );
  }

  Future<int> updateNotificationId(String id, int? notificationId) async {
    final db = await database;
    return db.update(
      tableName,
      {'notification_id': notificationId},
      where: 'id = ?',
      whereArgs: [_databaseId(id)],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return db.delete(tableName, where: 'id = ?', whereArgs: [_databaseId(id)]);
  }

  Future<int> deleteAllTasks() async {
    final db = await database;
    return db.delete(tableName);
  }

  Future<void> close() async {
    final openDatabase = _databaseFuture;
    _databaseFuture = null;
    if (openDatabase != null) {
      await (await openDatabase).close();
    }
  }

  Map<String, Object?> _toColumns(TaskItem task) {
    final scheduledAt = task.scheduledAt;
    final createdAt = task.createdAt ?? DateTime.now();
    return {
      'title': task.title.trim(),
      'description': task.description,
      'category': task.category.name,
      'date':
          '${scheduledAt.year.toString().padLeft(4, '0')}-'
          '${scheduledAt.month.toString().padLeft(2, '0')}-'
          '${scheduledAt.day.toString().padLeft(2, '0')}',
      'time':
          '${scheduledAt.hour.toString().padLeft(2, '0')}:'
          '${scheduledAt.minute.toString().padLeft(2, '0')}',
      'priority': task.priority.name,
      'is_completed': task.isCompleted ? 1 : 0,
      'reminder_date_time': task.reminderAt == null
          ? null
          : _localDateTimeString(task.reminderAt!),
      'reminder_enabled': task.reminderEnabled ? 1 : 0,
      'notification_id': task.notificationId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskItem _fromColumns(Map<String, Object?> row) {
    final date = (row['date']! as String).split('-').map(int.parse).toList();
    final time = (row['time']! as String).split(':').map(int.parse).toList();
    final categoryName = row['category']! as String;
    final priorityName = row['priority']! as String;
    final category = TaskCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () =>
          throw FormatException('Unknown task category: $categoryName'),
    );
    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == priorityName,
      orElse: () =>
          throw FormatException('Unknown task priority: $priorityName'),
    );

    return TaskItem(
      id: row['id'].toString(),
      title: row['title']! as String,
      description: row['description']! as String,
      category: category,
      scheduledAt: DateTime(date[0], date[1], date[2], time[0], time[1]),
      priority: priority,
      isCompleted: row['is_completed'] == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      reminderEnabled: row['reminder_enabled'] == 1,
      reminderAt: row['reminder_date_time'] == null
          ? null
          : DateTime.parse(row['reminder_date_time']! as String),
      notificationId: row['notification_id'] as int?,
    );
  }

  String _localDateTimeString(DateTime dateTime) {
    return dateTime.toLocal().toIso8601String();
  }

  int _databaseId(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null || parsed <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'Task ID must be a positive integer.',
      );
    }
    return parsed;
  }

  void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title is required.');
    }
  }
}
