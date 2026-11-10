import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const destinations = [
    (label: 'Home', icon: Icons.home_outlined, selected: Icons.home_rounded),
    (
      label: 'Tasks',
      icon: Icons.checklist_rounded,
      selected: Icons.checklist_rounded,
    ),
    (
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      selected: Icons.calendar_month_rounded,
    ),
    (
      label: 'Progress',
      icon: Icons.insights_outlined,
      selected: Icons.insights_rounded,
    ),
    (
      label: 'Settings',
      icon: Icons.settings_outlined,
      selected: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.secondary.withValues(alpha: 0.35),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 68,
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selected),
            label: destination.label,
          ),
      ],
    );
  }
}
