import 'package:dailyflow_billos/models/task_item.dart';
import 'package:dailyflow_billos/services/task_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);
  final tasks = [
    TaskItem(
      id: '1',
      title: 'Exam preparation',
      description: 'Review calculus notes',
      category: TaskCategory.school,
      scheduledAt: DateTime(2026, 11, 10, 9),
      priority: TaskPriority.high,
      createdAt: DateTime(2026, 11, 8),
    ),
    TaskItem(
      id: '2',
      title: 'Work plan',
      description: 'Prepare the quarterly roadmap',
      category: TaskCategory.work,
      scheduledAt: DateTime(2026, 11, 11, 9),
      priority: TaskPriority.low,
      isCompleted: true,
      createdAt: DateTime(2026, 11, 9),
    ),
    TaskItem(
      id: '3',
      title: 'Health walk',
      description: 'Take a break outside',
      category: TaskCategory.health,
      scheduledAt: DateTime(2026, 11, 10, 13),
      priority: TaskPriority.medium,
      isCompleted: true,
      createdAt: DateTime(2026, 11, 10),
    ),
  ];

  test('searches title and description without case sensitivity', () {
    expect(
      filterAndSortTasks(
        tasks,
        query: 'CALCULUS',
        now: now,
      ).map((task) => task.id),
      ['1'],
    );
    expect(
      filterAndSortTasks(
        tasks,
        query: 'health',
        now: now,
      ).map((task) => task.id),
      ['3'],
    );
  });

  test('combines status, category, priority, and search filters', () {
    final results = filterAndSortTasks(
      tasks,
      query: 'notes',
      status: TaskStatusFilter.pending,
      category: TaskCategory.school,
      priority: TaskPriority.high,
      now: now,
    );

    expect(results.map((task) => task.id), ['1']);
  });

  test(
    'distinguishes today from upcoming and supports completed filtering',
    () {
      expect(
        filterAndSortTasks(
          tasks,
          status: TaskStatusFilter.today,
          now: now,
        ).map((task) => task.id),
        ['1', '3'],
      );
      expect(
        filterAndSortTasks(
          tasks,
          status: TaskStatusFilter.upcoming,
          now: now,
        ).map((task) => task.id),
        ['2'],
      );
      expect(
        filterAndSortTasks(
          tasks,
          status: TaskStatusFilter.completed,
          now: now,
        ).map((task) => task.id),
        ['3', '2'],
      );
    },
  );

  test('sorts by priority and creation date without mutating input', () {
    final originalOrder = tasks.map((task) => task.id).toList();

    expect(
      filterAndSortTasks(
        tasks,
        sortOrder: TaskSortOrder.highPriorityFirst,
        now: now,
      ).map((task) => task.id),
      ['1', '3', '2'],
    );
    expect(
      filterAndSortTasks(
        tasks,
        sortOrder: TaskSortOrder.newestFirst,
        now: now,
      ).map((task) => task.id),
      ['3', '2', '1'],
    );
    expect(tasks.map((task) => task.id), originalOrder);
  });

  test('returns an empty result when active filters do not match', () {
    expect(
      filterAndSortTasks(
        tasks,
        query: 'missing',
        status: TaskStatusFilter.today,
        category: TaskCategory.personal,
        now: now,
      ),
      isEmpty,
    );
  });
}
