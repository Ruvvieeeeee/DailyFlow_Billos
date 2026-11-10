import '../models/task_item.dart';

List<TaskItem> createSampleTasks(DateTime today) {
  final date = DateTime(today.year, today.month, today.day);

  return [
    TaskItem(
      id: 'assignment',
      title: 'Complete programming assignment',
      description: 'Finish the app development exercises for class.',
      category: TaskCategory.school,
      scheduledAt: date.add(const Duration(hours: 9)),
      priority: TaskPriority.high,
    ),
    TaskItem(
      id: 'exercise',
      title: 'Morning exercise',
      description: 'A short workout to start the day with energy.',
      category: TaskCategory.health,
      scheduledAt: date.add(const Duration(hours: 11)),
      priority: TaskPriority.medium,
      isCompleted: true,
    ),
    TaskItem(
      id: 'networking',
      title: 'Review networking lessons',
      description: 'Go over the notes from this week.',
      category: TaskCategory.school,
      scheduledAt: date.add(const Duration(hours: 14)),
      priority: TaskPriority.medium,
    ),
    TaskItem(
      id: 'bedroom',
      title: 'Clean bedroom',
      description: 'Tidy up the desk and organize the bookshelf.',
      category: TaskCategory.personal,
      scheduledAt: date.add(const Duration(hours: 17)),
      priority: TaskPriority.low,
    ),
    TaskItem(
      id: 'documentation',
      title: 'Finish project documentation',
      description: 'Review and polish the project write-up.',
      category: TaskCategory.work,
      scheduledAt: date.add(const Duration(days: 1, hours: 10)),
      priority: TaskPriority.high,
    ),
    TaskItem(
      id: 'grocery',
      title: 'Plan weekly groceries',
      description: 'Make a shopping list for the week ahead.',
      category: TaskCategory.personal,
      scheduledAt: date.add(const Duration(days: 2, hours: 16)),
      priority: TaskPriority.low,
      isCompleted: true,
    ),
  ];
}
