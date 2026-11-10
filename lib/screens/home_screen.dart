import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/task_item.dart';
import '../services/task_store.dart';
import '../utils/app_colors.dart';
import '../utils/date_helpers.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.statistics,
    required this.onTaskToggle,
    required this.onTaskTap,
    required this.onViewAll,
    super.key,
  });

  final TaskStatistics statistics;
  final ValueChanged<TaskItem> onTaskToggle;
  final ValueChanged<TaskItem> onTaskTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTasks = statistics.todayTasks;
    final progress = statistics.dailyCompletion;
    final hour = today.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppConstants.appName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  '$greeting!',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatDate(today),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your daily overview',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _OverviewTile(
                      label: 'Total',
                      value: '${statistics.total}',
                      icon: Icons.checklist_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _OverviewTile(
                      label: 'Done',
                      value: '${statistics.completed}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _OverviewTile(
                      label: 'To do',
                      value: '${statistics.pending}',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily progress',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  todayTasks.isEmpty
                                      ? 'Add a task to get started'
                                      : '${statistics.todayCompleted} of ${todayTasks.length} tasks completed',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.background,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Today's tasks",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (todayTasks.isEmpty)
                  const Text('No tasks scheduled for today.')
                else
                  for (final task in todayTasks.take(3))
                    TaskCard(
                      task: task,
                      onToggle: (_) => onTaskToggle(task),
                      onTap: () => onTaskTap(task),
                    ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 94,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 19, color: color),
            Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
