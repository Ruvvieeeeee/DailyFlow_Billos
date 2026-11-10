import 'package:dailyflow_billos/models/task_item.dart';
import 'package:dailyflow_billos/utils/productivity_calculations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskItem task({required DateTime date, bool completed = false}) {
    return TaskItem(
      id: '',
      title: 'Task',
      description: '',
      category: TaskCategory.personal,
      scheduledAt: date,
      priority: TaskPriority.medium,
      isCompleted: completed,
    );
  }

  test('daily productivity only counts the selected date', () {
    final selectedDate = DateTime(2026, 11, 10);
    final summary = calculateDailyProductivity([
      task(date: DateTime(2026, 11, 10, 9), completed: true),
      task(date: DateTime(2026, 11, 10, 13)),
      task(date: DateTime(2026, 11, 11)),
    ], date: selectedDate);

    expect(summary.total, 2);
    expect(summary.completed, 1);
    expect(summary.pending, 1);
    expect(summary.completion, 0.5);
  });

  test(
    'weekly productivity groups Monday through Sunday and calculates totals',
    () {
      final summary = calculateWeeklyProductivity([
        task(date: DateTime(2026, 11, 9), completed: true),
        task(date: DateTime(2026, 11, 10)),
        task(date: DateTime(2026, 11, 10, 15), completed: true),
        task(date: DateTime(2026, 11, 15), completed: true),
        task(date: DateTime(2026, 11, 16)),
      ], weekContaining: DateTime(2026, 11, 11));

      expect(summary.days.first.date, DateTime(2026, 11, 9));
      expect(summary.days.last.date, DateTime(2026, 11, 15));
      expect(summary.days[1].total, 2);
      expect(summary.days[1].completed, 1);
      expect(summary.total, 4);
      expect(summary.completed, 3);
      expect(summary.pending, 1);
      expect(summary.completion, 0.75);
    },
  );

  test('empty daily and weekly summaries have zero completion', () {
    final emptyDay = calculateDailyProductivity(
      const <TaskItem>[],
      date: DateTime(2026, 11, 10),
    );
    final emptyWeek = calculateWeeklyProductivity(
      const <TaskItem>[],
      weekContaining: DateTime(2026, 11, 10),
    );

    expect(emptyDay.total, 0);
    expect(emptyDay.completion, 0);
    expect(emptyWeek.total, 0);
    expect(emptyWeek.completion, 0);
  });
}
