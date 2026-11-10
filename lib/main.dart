import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'screens/app_shell.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DailyFlowApp());
}

class DailyFlowApp extends StatelessWidget {
  const DailyFlowApp({
    this.databaseService,
    this.notificationClient,
    super.key,
  });

  final DatabaseService? databaseService;
  final LocalNotificationClient? notificationClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(
        databaseService: databaseService,
        notificationClient: notificationClient,
      ),
    );
  }
}
