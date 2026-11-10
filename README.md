# DailyFlow – Daily Productivity and Task Management App

**Plan Your Day, Flow Your Way.**

## 1. Project Overview

DailyFlow is a simple and user-friendly daily productivity and task management mobile application developed using Flutter and Dart.

The application is designed to help users organize their daily activities, manage tasks, set priorities, monitor deadlines, and track their daily accomplishments.

DailyFlow provides a convenient way to manage everyday responsibilities through a clean, modern, and organized mobile interface.

The application focuses on simplicity, productivity, and ease of use.

## 2. Problem Statement

Many people struggle to organize their daily activities and remember important responsibilities. Without a proper task management system, users may forget deadlines, overlook important activities, and have difficulty managing their time.

DailyFlow aims to solve this problem by providing a simple mobile application where users can organize, manage, and monitor their daily tasks in one place.

## 3. Project Objectives

The main objectives of DailyFlow are:

- To help users organize their daily activities.
- To provide an easy way to create and manage tasks.
- To allow users to set priorities and deadlines.
- To monitor completed and pending activities.
- To improve daily productivity and time management.
- To provide a simple and convenient user experience.

## 4. Target Users

DailyFlow is intended for:

- Students managing school activities and assignments.
- Employees organizing work responsibilities.
- Individuals managing personal activities.
- Anyone who wants to organize their daily schedule.

## 5. Technology Stack

The application will use the following technologies:

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Main programming language |
| SQLite | Local database storage |
| SharedPreferences | Simple local settings storage |
| Material Design | User interface guidelines |
| GitHub Copilot | Development assistance |

**Platform:** Android

**Development Environment:** Visual Studio Code

**Database:** Local device storage. No online database or account registration is required.

## 6. Core Features and Functional Requirements

### 6.1 Dashboard

The dashboard serves as the main screen of the application.

It should display:

- Greeting message.
- Current date.
- Total number of tasks.
- Number of completed tasks.
- Number of pending tasks.
- Daily progress indicator.
- List of today's tasks.
- Quick access to create a new task.

### 6.2 Task Management

Users should be able to create and manage their daily activities.

Each task should contain:

- Task title.
- Task description.
- Category.
- Date.
- Time or deadline.
- Priority level.
- Completion status.

Available operations:

- Add a new task.
- View task details.
- Edit an existing task.
- Delete a task.
- Mark a task as completed.
- Mark a completed task as pending.

### 6.3 Task Categories

Users can organize their tasks into different categories.

Default categories:

- Personal
- School
- Work
- Health
- Other

Each category should have a recognizable visual indicator.

### 6.4 Priority Management

Users can assign priority levels to their tasks.

Available priorities:

- Low
- Medium
- High

Use clear visual indicators to distinguish each priority level.

### 6.5 Calendar and Scheduling

Provide a calendar interface that allows users to:

- View scheduled tasks.
- Select a specific date.
- See tasks assigned to the selected date.
- View upcoming activities.

### 6.6 Task Progress Tracking

Provide a progress section that displays:

- Total tasks.
- Completed tasks.
- Pending tasks.
- Daily completion percentage.

Calculate the progress automatically based on the user's tasks.

### 6.7 Search and Filtering

Allow users to search and organize their tasks.

Filtering options:

- All Tasks
- Today
- Upcoming
- Completed
- Pending
- High Priority

### 6.8 Reminders and Notifications

Allow users to configure reminders for scheduled tasks.

Requirements:

- Set a reminder date and time.
- Receive a local notification when a reminder is due.
- Allow users to enable or disable reminders.
- Handle notification permissions properly.

### 6.9 Settings

Provide a settings screen containing:

- Application information.
- Theme preferences.
- Notification settings.
- Clear local task data option with confirmation.
- Application version.

## 7. User Interface and Design Guidelines

DailyFlow should have a modern, clean, minimalist, and friendly design.

### Design Direction

The application should feel:

- Simple.
- Organized.
- Modern.
- Comfortable to use.
- Visually consistent.
- Beginner-friendly.

### Color Palette

Use a warm and productivity-focused color palette.

Suggested colors:

| Element | Color |
|---|---|
| Primary | Orange (#F59E0B) |
| Secondary | Yellow (#FACC15) |
| Background | Warm White (#FFFBF2) |
| Surface | White (#FFFFFF) |
| Primary Text | Dark Gray (#292524) |
| Secondary Text | Gray (#78716C) |
| Success | Green (#22C55E) |
| Error | Red (#EF4444) |

Use these colors consistently throughout the application.

### UI Components

Use:

- Rounded cards.
- Clean typography.
- Simple icons.
- Comfortable spacing.
- Clear buttons.
- Readable task lists.
- Subtle shadows.
- Consistent margins and padding.
- Smooth and simple transitions.

Avoid:

- Excessive gradients.
- Too many colors.
- Unnecessary animations.
- Cluttered layouts.
- Complicated navigation.
- Oversized interface elements.

## 8. Application Navigation

Use a bottom navigation bar for the main application screens.

Main navigation:

1. Home – Dashboard and today's tasks.
2. Tasks – Complete task management.
3. Calendar – Scheduled activities.
4. Progress – Productivity statistics.
5. Settings – Application preferences.

Navigation should be simple, consistent, and easy to understand.

## 9. Data Storage and Database Structure

DailyFlow should use SQLite to store user tasks locally.

No online database, cloud synchronization, or user account system is required.

### Task Table

Suggested fields:

| Field | Data Type | Description |
|---|---|---|
| id | INTEGER | Unique task ID |
| title | TEXT | Task title |
| description | TEXT | Task details |
| category | TEXT | Task category |
| date | TEXT | Scheduled date |
| time | TEXT | Scheduled time |
| priority | TEXT | Priority level |
| isCompleted | INTEGER | Completion status |
| reminderDateTime | TEXT | Optional reminder |

### Data Requirements

- Save tasks locally.
- Load saved tasks when the application starts.
- Update existing task records.
- Delete selected tasks.
- Preserve data after closing the application.
- Automatically calculate progress using saved task records.

## 10. Recommended Project Structure

Organize the project using a clean and beginner-friendly folder structure.

```text
lib/
│
├── main.dart
│
├── models/
│   └── task_model.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── tasks_screen.dart
│   ├── calendar_screen.dart
│   ├── progress_screen.dart
│   ├── settings_screen.dart
│   └── add_task_screen.dart
│
├── widgets/
│   ├── task_card.dart
│   ├── progress_card.dart
│   ├── category_chip.dart
│   └── bottom_navigation.dart
│
├── services/
│   ├── database_service.dart
│   └── notification_service.dart
│
├── theme/
│   └── app_theme.dart
│
├── utils/
│   ├── app_colors.dart
│   └── date_helpers.dart
│
└── constants/
    └── app_constants.dart
```

The structure may be adjusted when necessary, but keep it organized and avoid unnecessary complexity.

## 11. Application Development Phases

Development must be completed in separate phases.

### Phase 1 – Project Foundation

- Inspect the README.md.
- Initialize the Flutter project.
- Configure dependencies.
- Establish the folder structure.
- Configure MaterialApp.
- Set up the application theme.
- Create the initial application screen.
- Verify that the application runs successfully.

### Phase 2 – UI/UX Implementation

- Create the dashboard.
- Create the bottom navigation.
- Create the task management interface.
- Create the calendar interface.
- Create the progress screen.
- Create the settings screen.
- Maintain consistent styling.

### Phase 3 – Task Management Functionality

- Add tasks.
- View task details.
- Edit tasks.
- Delete tasks.
- Mark tasks as completed.
- Implement categories and priorities.
- Implement search and filtering.

### Phase 4 – Local Database Integration

- Configure SQLite.
- Create the task database.
- Implement CRUD operations.
- Connect the database to the UI.
- Ensure saved tasks remain available after restarting the application.

### Phase 5 – Advanced Features

- Implement calendar scheduling.
- Implement local notifications.
- Implement task reminders.
- Implement daily progress calculations.
- Complete settings functionality.

### Phase 6 – Testing and Finalization

- Test all application features.
- Fix bugs and errors.
- Improve UI consistency.
- Check data persistence.
- Run Flutter analysis and tests.
- Build the final Android APK.

## 12. Development Rules for GitHub Copilot

GitHub Copilot must follow these rules throughout development:

1. Always read this README.md before implementing a feature.
2. Treat this document as the primary project reference.
3. Use Flutter and Dart.
4. Follow the defined color palette and design guidelines.
5. Keep the application beginner-friendly and maintainable.
6. Use reusable widgets when appropriate.
7. Avoid unnecessary dependencies.
8. Do not introduce an online database or authentication system.
9. Do not remove existing working features.
10. Do not redesign existing screens without permission.
11. Do not modify unrelated files.
12. Implement features according to their assigned development phases.
13. Test changes before reporting completion.
14. Fix errors before moving to the next phase.
15. Update this README only when a project requirement or implementation detail genuinely changes.

## 13. Testing Commands

Use these commands during development:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

All commands should be checked for errors after major development phases.

## 14. Expected Final Output

The completed DailyFlow application should provide:

- A functional productivity dashboard.
- Complete task management.
- Task categories and priorities.
- Calendar and scheduling.
- Local notifications and reminders.
- Daily productivity tracking.
- Search and filtering.
- Local SQLite database.
- Consistent and responsive user interface.
- Reliable local data storage.

## 15. Final Project Vision

DailyFlow aims to make everyday task management easier and more convenient.

It should help users plan their activities, stay organized, complete responsibilities, and monitor their daily progress through a simple and reliable mobile application.

**DailyFlow – Plan Your Day, Flow Your Way.**

## 16. Current Implementation and Setup

This section records the implementation currently present in this repository.
The feature and design requirements above remain the project reference.

### Implemented Features

- Five-tab dashboard, tasks, calendar, progress, and settings navigation.
- Task creation, details, editing, deletion, completion, search, combined
  status/category/priority filters, and sorting.
- Monthly calendar with date selection and indicators for scheduled tasks.
- Daily and Monday-to-Sunday productivity calculations from saved tasks.
- SQLite persistence on the device, including schema migration from database
  version 1 to version 2.
- Optional local task reminders, notification permission and preference
  controls, reminder rescheduling, and task navigation from notification taps.
- Confirmed local task-data clearing.
- An original orange-and-yellow calendar/checklist launcher icon with an
  adaptive Android icon and Android 13 monochrome asset.
- A warm-white native Android launch splash and an animated branded Flutter
  splash shown while local tasks and reminders initialize.

The theme preference control is a visual preference preview; it does not yet
change the application theme. There is no account, cloud sync, or online
database.

### Technology and Architecture

- Flutter and Dart; Android is the supported application platform.
- `sqflite` provides SQLite storage; `shared_preferences` stores the reminder
  preference.
- `flutter_local_notifications`, `flutter_timezone`, and `timezone` handle
  local notifications and scheduled local times.
- `TaskStore` is the app's `ChangeNotifier` state manager and works with
  `DatabaseService` as the persistent task source.
- Productivity calculations are pure helpers in `lib/utils/`.
- The Android application ID is `com.dailyflow.billos`.

Relevant source layout:

```text
lib/
  constants/       Application constants
  data/            Sample tasks used only in tests/previews
  models/          Task and category/priority types
  screens/         App shell and seven application screens
  services/        SQLite, task state, and notification services
  theme/           Material theme
  utils/           Colors, date helpers, and productivity calculations
  widgets/         Shared cards, chips, navigation, and empty states
test/
  helpers/          Fake notification client
  *_test.dart       Database, task, productivity, and widget tests
android/
  app/              Android manifest, activity, and Gradle configuration
assets/
  branding/         DailyFlow launcher, splash, and monochrome logo artwork
```

### Local Database

The database file is `dailyflow.db`, created in the platform's application
database directory. It is not recreated at launch. Schema version 2 includes
the `tasks` table with an auto-incrementing integer ID, title, description,
category, scheduled date and time, priority, completion state, optional
reminder time, reminder-enabled state, notification ID, and creation time.
Completion and reminder-enabled values are stored as SQLite integers (0/1).
Version 2 adds reminder-enabled and notification-ID columns to the earlier
schema without removing existing task records.

Automated database tests use temporary SQLite files and do not access the
installed application's database.

### Notifications and Limitations

Reminders are opt-in and require Android notification permission. Android
scheduled alarms are inexact to avoid requesting exact-alarm access; delivery
may therefore be delayed. The app attempts to restore scheduled reminders
when it starts and when it resumes. On the API 37 emulator with notification
permission granted, a scheduled reminder was delivered and tapping it opened the
matching task details. Physical-device reminder delivery and notification-tap
behavior remain unverified.

### Development and Verification

Install Flutter with Android support, then run these commands from the project
root:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

Run the app on a connected Android device or emulator with:

```bash
flutter run
```

Debug and release APKs are generated under
`build/app/outputs/flutter-apk/`. The current Android release build type uses
the debug signing configuration for local build verification only. A
publishable APK requires a user-managed release keystore and signing
configuration; do not commit signing credentials.

### App Branding

The Android launcher icon is generated from `assets/branding/` using
`flutter_launcher_icons`; the native Android splash is generated with
`flutter_native_splash`. After changing the logo artwork or branding
configuration, run:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The Flutter splash uses the existing theme colors and app name/tagline, and
automatically gives way to the existing dashboard after task initialization.
If task loading fails, the existing retryable error screen is shown instead.

### Known Limitations

- Theme choices are not persisted or applied.
- Reminder delivery uses inexact Android alarms and is not guaranteed at an
  exact minute.
- Notification behavior can vary with device permissions and manufacturer
  battery restrictions.
- There is no cloud backup; uninstalling the app or clearing its storage can
  remove local tasks.