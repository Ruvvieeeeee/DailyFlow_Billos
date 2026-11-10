import '../models/task_item.dart';
import 'date_helpers.dart';

class DailyProductivity {
  const DailyProductivity({
    required this.tasks,
    required this.completed,
    required this.pending,
  });

  final List<TaskItem> tasks;
  final int completed;
  final int pending;

  int get total => tasks.length;
  double get completion => total == 0 ? 0 : completed / total;
}

class DailyWeeklyProductivity {
  const DailyWeeklyProductivity({
    required this.date,
    required this.total,
    required this.completed,
  });

  final DateTime date;
  final int total;
  final int completed;

  int get pending => total - completed;
  double get completion => total == 0 ? 0 : completed / total;
}

class WeeklyProductivity {
  const WeeklyProductivity({required this.days});

  final List<DailyWeeklyProductivity> days;

  int get total => days.fold(0, (sum, day) => sum + day.total);
  int get completed => days.fold(0, (sum, day) => sum + day.completed);
  int get pending => total - completed;
  double get completion => total == 0 ? 0 : completed / total;
}

DailyProductivity calculateDailyProductivity(
  Iterable<TaskItem> tasks, {
  DateTime? date,
}) {
  final selectedDate = date ?? DateTime.now();
  final dayTasks = tasks
      .where((task) => isSameDay(task.scheduledAt, selectedDate))
      .toList(growable: false);
  final completed = dayTasks.where((task) => task.isCompleted).length;
  return DailyProductivity(
    tasks: dayTasks,
    completed: completed,
    pending: dayTasks.length - completed,
  );
}

WeeklyProductivity calculateWeeklyProductivity(
  Iterable<TaskItem> tasks, {
  DateTime? weekContaining,
}) {
  final selected = weekContaining ?? DateTime.now();
  final selectedDay = DateTime(selected.year, selected.month, selected.day);
  final firstDay = selectedDay.subtract(
    Duration(days: selectedDay.weekday - DateTime.monday),
  );
  final days = List<DailyWeeklyProductivity>.generate(7, (index) {
    final date = firstDay.add(Duration(days: index));
    final dayTasks = tasks.where((task) => isSameDay(task.scheduledAt, date));
    final total = dayTasks.length;
    final completed = dayTasks.where((task) => task.isCompleted).length;
    return DailyWeeklyProductivity(
      date: date,
      total: total,
      completed: completed,
    );
  }, growable: false);
  return WeeklyProductivity(days: days);
}
