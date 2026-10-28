import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hawk_mobile/main.dart';
import 'package:hawk_mobile/providers/auth_provider.dart';
import 'package:hawk_mobile/providers/task_provider.dart';
import 'package:hawk_mobile/providers/journal_provider.dart';
import 'package:hawk_mobile/providers/schedule_provider.dart';
import 'package:hawk_mobile/providers/link_provider.dart';
import 'package:hawk_mobile/providers/chat_provider.dart';
import 'package:hawk_mobile/providers/theme_provider.dart';
import 'package:hawk_mobile/widgets/tasks_reminders_overview_widget.dart';
import 'package:hawk_mobile/widgets/home_screen_widget_sheet.dart';
import 'package:hawk_mobile/widgets/hawk_header.dart';
import 'package:hawk_mobile/screens/home_screen.dart';
import 'package:hawk_mobile/screens/chat_screen.dart';
import 'package:hawk_mobile/screens/journal_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HawkApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => ScheduleProvider()),
          ChangeNotifierProvider(create: (_) => LinkProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const HawkApp(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TasksRemindersOverviewWidget renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TasksRemindersOverviewWidget(),
          ),
        ),
      ),
    );

    expect(find.text("Today's Overview"), findsOneWidget);
    expect(find.text('Tasks To Do'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Phone Widget'), findsOneWidget);
  });

  testWidgets('HomeScreenWidgetSheet renders widget preview and Add Widget button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeScreenWidgetSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home Screen Widget'), findsOneWidget);
    expect(find.text('WIDGET PREVIEW'), findsOneWidget);
    expect(find.text('Add Widget to Home Screen'), findsOneWidget);
    expect(find.text('Sync Widget Data Now'), findsOneWidget);
  });

  testWidgets('HomeScreen dashboard renders exact website UI components', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => ScheduleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify Header and Dashboard title
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Done Tasks'), findsOneWidget);

    // Verify Phone Home Screen Widget card
    expect(find.text('Phone Home Screen Widget'), findsOneWidget);

    // Verify sections matching my-app/app/(dashboard)/page.js
    expect(find.text('Daily Habits'), findsOneWidget);
    expect(find.text('Focus Tasks'), findsOneWidget);

    // Scroll down to check further items in the dashboard
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Long Term Goals'), findsOneWidget);
    expect(find.text('DEEP FOCUS'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('ChatScreen renders matching website chat page with FaceAvatar and speech bubble', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('AI Chat & Focus'), findsOneWidget);
    expect(find.text('Focus Mode'), findsOneWidget);
    expect(find.text('HAWK'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('JournalScreen renders matching website journal page with notebook lines and controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: JournalScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Journal & Plan'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('HawkHeader renders title, subtitle, and toggles global theme', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    expect(themeProvider.isDarkMode, isTrue);

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: HawkHeader(
              title: 'Global Header',
              subtitle: 'Works on All Screens',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Global Header'), findsOneWidget);
    expect(find.text('Works on All Screens'), findsOneWidget);
    expect(find.byIcon(Icons.light_mode), findsOneWidget);

    // Tap theme toggle button
    await tester.tap(find.byIcon(Icons.light_mode));
    await tester.pumpAndSettle();

    expect(themeProvider.isDarkMode, isFalse);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  });
}
