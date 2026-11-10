import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/app_colors.dart';
import '../utils/date_helpers.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.tasks,
    required this.onTaskToggle,
    required this.onTaskTap,
    super.key,
  });

  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onTaskToggle;
  final ValueChanged<TaskItem> onTaskTap;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _displayedMonth = DateTime(today.year, today.month);
  }

  void _changeMonth(int amount) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + amount,
      );
      if (_selectedDate.month != _displayedMonth.month ||
          _selectedDate.year != _displayedMonth.year) {
        _selectedDate = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday =
        DateTime(_displayedMonth.year, _displayedMonth.month).weekday - 1;
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final cellCount = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;
    final selectedTasks =
        widget.tasks
            .where((task) => isSameDay(task.scheduledAt, _selectedDate))
            .toList()
          ..sort(
            (first, second) => first.scheduledAt.compareTo(second.scheduledAt),
          );
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('calendar-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Calendar',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'See what’s coming up.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Previous month',
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Expanded(
                            child: Text(
                              formatMonth(_displayedMonth),
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next month',
                            onPressed: () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final today = DateTime.now();
                            setState(() {
                              _selectedDate = DateTime(
                                today.year,
                                today.month,
                                today.day,
                              );
                              _displayedMonth = DateTime(
                                today.year,
                                today.month,
                              );
                            });
                          },
                          child: const Text('Today'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final weekday in const [
                            'M',
                            'T',
                            'W',
                            'T',
                            'F',
                            'S',
                            'S',
                          ])
                            Expanded(
                              child: Center(
                                child: Text(
                                  weekday,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var week = 0; week < cellCount ~/ 7; week++)
                        Row(
                          children: [
                            for (var weekday = 0; weekday < 7; weekday++)
                              Expanded(
                                child: _DayCell(
                                  day: week * 7 + weekday - firstWeekday + 1,
                                  daysInMonth: daysInMonth,
                                  displayedMonth: _displayedMonth,
                                  selectedDate: _selectedDate,
                                  tasks: widget.tasks,
                                  onSelected: (date) {
                                    if (date != null) {
                                      setState(() => _selectedDate = date);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  formatDate(_selectedDate),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedTasks.isEmpty)
                  const EmptyStateWidget(
                    title: 'Nothing planned',
                    message: 'There are no tasks scheduled for this date.',
                    icon: Icons.event_available_rounded,
                  )
                else
                  for (final task in selectedTasks)
                    TaskCard(
                      task: task,
                      onToggle: (_) => widget.onTaskToggle(task),
                      onTap: () => widget.onTaskTap(task),
                    ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.daysInMonth,
    required this.displayedMonth,
    required this.selectedDate,
    required this.tasks,
    required this.onSelected,
  });

  final int day;
  final int daysInMonth;
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<TaskItem> tasks;
  final ValueChanged<DateTime?> onSelected;

  @override
  Widget build(BuildContext context) {
    final inMonth = day > 0 && day <= daysInMonth;
    if (!inMonth) return const SizedBox(height: 44);

    final date = DateTime(displayedMonth.year, displayedMonth.month, day);
    final isSelected = isSameDay(date, selectedDate);
    final isToday = isSameDay(date, DateTime.now());
    final hasTasks = tasks.any((task) => isSameDay(task.scheduledAt, date));

    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: () => onSelected(date),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: hasTasks
                  ? '$day, ${tasks.where((task) => isSameDay(task.scheduledAt, date)).length} tasks'
                  : '$day, no tasks',
              button: true,
              selected: isSelected,
              excludeSemantics: true,
              child: Container(
                key: ValueKey(
                  'calendar-day-${date.year}-${date.month}-${date.day}',
                ),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary)
                      : null,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.surface
                        : AppColors.primaryText,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasTasks ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
