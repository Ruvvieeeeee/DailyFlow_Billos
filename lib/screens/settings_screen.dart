import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    this.notificationsEnabled = false,
    this.notificationPermissionGranted = false,
    this.pendingReminderCount = 0,
    this.onNotificationsChanged,
    this.onOpenNotificationSettings,
    this.onClearData,
    super.key,
  });

  final bool notificationsEnabled;
  final bool notificationPermissionGranted;
  final int pendingReminderCount;
  final Future<bool> Function(bool enabled)? onNotificationsChanged;
  final Future<void> Function()? onOpenNotificationSettings;
  final Future<void> Function()? onClearData;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themePreference = 'System';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        key: const PageStorageKey('settings-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Text(
            'Settings',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Make DailyFlow feel like yours.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Preferences',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SettingsIcon(icon: Icons.palette_outlined),
                title: const Text('Appearance'),
                subtitle: const Text('Theme preference preview'),
                trailing: DropdownButton<String>(
                  value: _themePreference,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'System', child: Text('System')),
                    DropdownMenuItem(value: 'Light', child: Text('Light')),
                    DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _themePreference = value);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const _SettingsIcon(
                  icon: Icons.notifications_none_rounded,
                ),
                title: const Text('Reminders'),
                subtitle: Text(
                  widget.notificationPermissionGranted
                      ? '${widget.pendingReminderCount} scheduled reminders'
                      : 'Notification permission is off',
                ),
                value: widget.notificationsEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: _changeNotificationPreference,
              ),
              if (!widget.notificationPermissionGranted)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onOpenNotificationSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Review notification permission'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Data',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SettingsIcon(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: const Text('Clear local task data'),
                subtitle: const Text('Remove all locally stored tasks'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showClearDataInfo,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SettingsIcon(icon: Icons.info_outline_rounded),
                title: const Text('About DailyFlow'),
                subtitle: const Text(AppConstants.appTagline),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SettingsIcon(icon: Icons.phone_android_rounded),
                title: const Text('App version'),
                trailing: Text(
                  AppConstants.appVersion,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'DailyFlow · Plan Your Day, Flow Your Way.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataInfo() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        title: const Text('Clear all task data?'),
        content: const Text(
          'This permanently removes all tasks and their scheduled reminders '
          'from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (clear != true || widget.onClearData == null) return;
    try {
      await widget.onClearData!();
      if (mounted) _showMessage('Local task data cleared.');
    } on Object catch (error) {
      if (mounted) _showMessage('Could not clear local task data: $error');
    }
  }

  Future<void> _changeNotificationPreference(bool enabled) async {
    final callback = widget.onNotificationsChanged;
    if (callback == null) return;
    try {
      final success = await callback(enabled);
      if (mounted && enabled && !success) {
        _showMessage(
          'Notifications are not allowed. Review your device permissions.',
        );
      }
    } on Object catch (error) {
      if (mounted) _showMessage('Could not update reminders: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 3),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.color = AppColors.primary});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
