import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/app_colors.dart';
import '../utils/date_helpers.dart';
import '../utils/productivity_calculations.dart';
import '../widgets/progress_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({required this.tasks, super.key});

  final List<TaskItem> tasks;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late DateTime _selectedDate = DateTime.now();
  late DateTime _weekContaining = DateTime.now();

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
        _weekContaining = date;
      });
    }
  }

  void _changeWeek(int amount) {
    setState(() {
      _weekContaining = _weekContaining.add(Duration(days: amount * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final daily = calculateDailyProductivity(widget.tasks, date: _selectedDate);
    final weekly = calculateWeeklyProductivity(
      widget.tasks,
      weekContaining: _weekContaining,
    );
    final textTheme = Theme.of(context).textTheme;
    final weeklyStart = weekly.days.first.date;
    final weeklyEnd = weekly.days.last.date;
    final today = DateTime.now();
    final currentWeek = calculateWeeklyProductivity(
      widget.tasks,
      weekContaining: today,
    );
    final showingCurrentWeek = isSameDay(
      weeklyStart,
      currentWeek.days.first.date,
    );

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('progress-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Your progress',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Small steps add up to big things.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  key: const ValueKey('progress-date-button'),
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    isSameDay(_selectedDate, DateTime.now())
                        ? 'Today · ${formatDate(_selectedDate)}'
                        : formatDate(_selectedDate),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 112,
                  child: Row(
                    children: [
                      Expanded(
                        child: ProgressCard(
                          label: 'Total tasks',
                          value: '${daily.total}',
                          icon: Icons.checklist_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProgressCard(
                          label: 'Completed',
                          value: '${daily.completed}',
                          icon: Icons.task_alt_rounded,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  child: Row(
                    children: [
                      Expanded(
                        child: ProgressCard(
                          label: 'Pending',
                          value: '${daily.pending}',
                          icon: Icons.pending_actions_rounded,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ProgressCard(
                          label: 'Completion',
                          value: '${(daily.completion * 100).round()}%',
                          icon: Icons.insights_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily summary',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        daily.total == 0
                            ? 'No tasks planned for this date.'
                            : '${daily.completed} completed · '
                                  '${daily.pending} still to go',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: daily.completion,
                          minHeight: 9,
                          backgroundColor: AppColors.background,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '${(daily.completion * 100).round()}% complete',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('previous-week-button'),
                      tooltip: 'Previous week',
                      onPressed: () => _changeWeek(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        showingCurrentWeek ? 'This week' : 'Week overview',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('next-week-button'),
                      tooltip: 'Next week',
                      onPressed: () => _changeWeek(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    '${formatDate(weeklyStart)} – ${formatDate(weeklyEnd)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                _WeeklyProgress(weekly: weekly),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly total: ${weekly.total} tasks',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${weekly.completed} completed · ${weekly.pending} pending · '
                        '${(weekly.completion * 100).round()}% complete',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress({required this.weekly});

  final WeeklyProductivity weekly;

  @override
  Widget build(BuildContext context) {
    final maxTasks = weekly.days.fold<int>(
      0,
      (maximum, day) => day.total > maximum ? day.total : maximum,
    );
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 142,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final day in weekly.days)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${day.completed}/${day.total}',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 80,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maxTasks == 0
                              ? 0
                              : day.total / maxTasks,
                          widthFactor: 0.62,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Column(
                              children: [
                                if (day.pending > 0)
                                  Expanded(
                                    flex: day.pending,
                                    child: Container(
                                      width: double.infinity,
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                if (day.completed > 0)
                                  Expanded(
                                    flex: day.completed,
                                    child: Container(
                                      width: double.infinity,
                                      color: AppColors.success,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      const [
                        'M',
                        'T',
                        'W',
                        'T',
                        'F',
                        'S',
                        'S',
                      ][day.date.weekday - 1],
                      style: textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
