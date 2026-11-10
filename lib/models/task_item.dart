import 'package:flutter/material.dart';

enum TaskCategory {
  personal('Personal', Icons.person_outline_rounded, Color(0xFF8B5CF6)),
  school('School', Icons.school_outlined, Color(0xFF3B82F6)),
  work('Work', Icons.work_outline_rounded, Color(0xFFF59E0B)),
  health('Health', Icons.favorite_border_rounded, Color(0xFF22C55E)),
  other('Other', Icons.category_outlined, Color(0xFF78716C));

  const TaskCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum TaskPriority {
  low('Low', Color(0xFF22C55E)),
  medium('Medium', Color(0xFFF59E0B)),
  high('High', Color(0xFFEF4444));

  const TaskPriority(this.label, this.color);

  final String label;
  final Color color;
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.scheduledAt,
    required this.priority,
    this.isCompleted = false,
    this.createdAt,
    this.reminderEnabled = false,
    this.reminderAt,
    this.notificationId,
  });

  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final DateTime scheduledAt;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime? createdAt;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final int? notificationId;

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    DateTime? scheduledAt,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    bool? reminderEnabled,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    int? notificationId,
    bool clearNotificationId = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderAt: clearReminderAt ? null : reminderAt ?? this.reminderAt,
      notificationId: clearNotificationId
          ? null
          : notificationId ?? this.notificationId,
    );
  }
}
