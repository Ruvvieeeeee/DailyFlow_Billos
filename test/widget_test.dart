import 'dart:io';

import 'package:dailyflow_billos/data/sample_tasks.dart';
import 'package:dailyflow_billos/main.dart';
import 'package:dailyflow_billos/services/database_service.dart';
import 'package:dailyflow_billos/utils/date_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/fake_notification_client.dart';

void main() {
  late Directory directory;
  late DatabaseService databaseService;
  late FakeNotificationClient notificationClient;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    notificationClient = FakeNotificationClient();
    directory = await Directory.systemTemp.createTemp('dailyflow_widget_test_');
    databaseService = DatabaseService(
      factory: databaseFactoryFfi,
      pathOverride: path.join(directory.path, 'dailyflow_test.db'),
    );
    for (final task in createSampleTasks(DateTime.now())) {
      await databaseService.insertTask(task);
    }
  });

  tearDown(() async {
    await databaseService.close();
    await directory.delete(recursive: true);
  });

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      DailyFlowApp(
        databaseService: databaseService,
        notificationClient: notificationClient,
      ),
    );
    await tester.runAsync(databaseService.getTasks);
    await pumpFrames(tester);
  }

  testWidgets('shows the database-backed DailyFlow dashboard', (tester) async {
    await pumpApp(tester);

    expect(find.text('DailyFlow'), findsOneWidget);
    expect(find.text('Your daily overview'), findsOneWidget);
    expect(find.text("Today's tasks"), findsOneWidget);
    expect(find.byTooltip('Add task'), findsOneWidget);
  });

  testWidgets('shows branding while the application initializes', (
    tester,
  ) async {
    await tester.pumpWidget(
      DailyFlowApp(
        databaseService: databaseService,
        notificationClient: notificationClient,
      ),
    );

    expect(find.byKey(const ValueKey('dailyflow-splash')), findsOneWidget);
    expect(find.text('DailyFlow'), findsOneWidget);
    expect(find.text('Plan Your Day, Flow Your Way.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.runAsync(databaseService.getTasks);
    await pumpFrames(tester);

    expect(find.byKey(const ValueKey('dailyflow-splash')), findsNothing);
    expect(find.text('Your daily overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty states when the database has no tasks', (
    tester,
  ) async {
    await tester.runAsync(databaseService.deleteAllTasks);
    await pumpApp(tester);

    expect(find.text('No tasks scheduled for today.'), findsOneWidget);
    await tester.tap(find.text('Tasks').last);
    await pumpFrames(tester);
    expect(find.text('No tasks found'), findsOneWidget);
    expect(find.text('0 tasks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation opens all five database-backed screens', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Tasks').last);
    await pumpFrames(tester);
    expect(find.text('My tasks'), findsOneWidget);
    expect(find.text('Search tasks'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Calendar').last);
    await pumpFrames(tester);
    expect(find.text('See what’s coming up.'), findsOneWidget);
    expect(find.byTooltip('Previous month'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Progress').last);
    await pumpFrames(tester);
    expect(find.text('Your progress'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('previous-week-button')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('This week'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Settings').last);
    await pumpFrames(tester);
    expect(find.text('About DailyFlow'), findsOneWidget);
    expect(find.text('Clear local task data'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Home').last);
    await pumpFrames(tester);
    expect(find.text('Your daily overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('task form validates a required title', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Add task'));
    await pumpFrames(tester);
    expect(find.text('New task'), findsOneWidget);

    final saveButton = find.byKey(const ValueKey('save-task-button'));
    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(saveButton);
    await pumpFrames(tester);
    expect(find.text('Please enter a task title.'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-reminder-toggle')), findsOneWidget);
  });

  testWidgets('calendar navigates months and returns to today', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Calendar').last);
    await pumpFrames(tester);

    final today = DateTime.now();
    final currentMonth = formatMonth(DateTime(today.year, today.month));
    final nextMonth = formatMonth(DateTime(today.year, today.month + 1));
    expect(find.text(currentMonth), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await pumpFrames(tester);
    expect(find.text(nextMonth), findsOneWidget);

    await tester.tap(find.text('Today'));
    await pumpFrames(tester);
    expect(find.text(currentMonth), findsOneWidget);
    expect(find.byTooltip('Previous month'), findsOneWidget);
  });

  testWidgets('calendar marks task dates and shows the selected date tasks', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(find.text('Calendar').last);
    await pumpFrames(tester);

    final today = DateTime.now();
    expect(
      find.byKey(
        ValueKey('calendar-day-${today.year}-${today.month}-${today.day}'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('${today.day}, 4 tasks'), findsOneWidget);
    await tester.tap(
      find.byKey(
        ValueKey('calendar-day-${today.year}-${today.month}-${today.day}'),
      ),
    );
    await pumpFrames(tester);
    await tester.scrollUntilVisible(
      find.text('Complete programming assignment'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Complete programming assignment'), findsOneWidget);
    expect(find.text('Morning exercise'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reminder control requests permission and shows its fields', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Add task'));
    await pumpFrames(tester);

    final reminderToggle = find.byKey(const ValueKey('task-reminder-toggle'));
    await tester.scrollUntilVisible(
      reminderToggle,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(reminderToggle);
    await pumpFrames(tester);
    expect(notificationClient.permissionRequests, 1);
    expect(find.text('Reminder date and time'), findsOneWidget);
    expect(find.text('Choose a reminder time in the future.'), findsNothing);
  });
}
