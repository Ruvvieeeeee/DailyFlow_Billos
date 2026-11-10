import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../services/task_store.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    required this.tasks,
    required this.onTaskToggle,
    required this.onTaskTap,
    super.key,
  });

  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onTaskToggle;
  final ValueChanged<TaskItem> onTaskTap;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  TaskCategory? _category;
  TaskPriority? _priority;
  TaskStatusFilter _status = TaskStatusFilter.all;
  TaskSortOrder _sortOrder = TaskSortOrder.earliestScheduled;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TaskItem> get _filteredTasks {
    return filterAndSortTasks(
      widget.tasks,
      query: _query,
      status: _status,
      category: _category,
      priority: _priority,
      sortOrder: _sortOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('tasks-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'My tasks',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your tasks are saved on this device.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search tasks',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  'Categories',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryFilterChip(
                        label: 'All Categories',
                        selected: _category == null,
                        onSelected: () => setState(() => _category = null),
                      ),
                      for (final category in TaskCategory.values)
                        _CategoryFilterChip(
                          label: category.label,
                          selected: _category == category,
                          onSelected: () =>
                              setState(() => _category = category),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Show',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  children: [
                    for (final filter in TaskStatusFilter.values)
                      ChoiceChip(
                        label: Text(_statusLabel(filter)),
                        selected: _status == filter,
                        onSelected: (_) => setState(() => _status = filter),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Priority',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  children: [
                    _PriorityFilterChip(
                      label: 'All priorities',
                      selected: _priority == null,
                      onSelected: () => setState(() => _priority = null),
                    ),
                    for (final priority in TaskPriority.values)
                      _PriorityFilterChip(
                        label: priority.label,
                        selected: _priority == priority,
                        onSelected: () => setState(() => _priority = priority),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Sort by',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 205,
                      child: DropdownButtonFormField<TaskSortOrder>(
                        key: const ValueKey('task-sort-order'),
                        initialValue: _sortOrder,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          for (final order in TaskSortOrder.values)
                            DropdownMenuItem(
                              value: order,
                              child: Text(
                                _sortLabel(order),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortOrder = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_filteredTasks.length} ${_filteredTasks.length == 1 ? 'task' : 'tasks'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                if (_filteredTasks.isEmpty)
                  const EmptyStateWidget(
                    title: 'No tasks found',
                    message: 'Try a different search or filter.',
                    icon: Icons.search_off_rounded,
                  )
                else
                  for (final task in _filteredTasks)
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

  String _statusLabel(TaskStatusFilter status) => switch (status) {
    TaskStatusFilter.all => 'All Tasks',
    TaskStatusFilter.today => 'Today',
    TaskStatusFilter.upcoming => 'Upcoming',
    TaskStatusFilter.pending => 'Pending',
    TaskStatusFilter.completed => 'Completed',
  };

  String _sortLabel(TaskSortOrder order) => switch (order) {
    TaskSortOrder.newestFirst => 'Newest first',
    TaskSortOrder.oldestFirst => 'Oldest first',
    TaskSortOrder.highPriorityFirst => 'Priority: High to Low',
    TaskSortOrder.lowPriorityFirst => 'Priority: Low to High',
    TaskSortOrder.earliestScheduled => 'Earliest scheduled',
  };
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        selectedColor: AppColors.secondary.withValues(alpha: 0.4),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
        ),
      ),
    );
  }
}

class _PriorityFilterChip extends StatelessWidget {
  const _PriorityFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.secondary.withValues(alpha: 0.4),
    );
  }
}
