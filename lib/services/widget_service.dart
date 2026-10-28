import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/schedule.dart';

class WidgetService {
  static const String appGroupId = 'group.com.example.hawk_mobile';
  static const String androidWidgetName = 'HawkTasksWidgetProvider';
  static const String iOSWidgetName = 'HawkTasksWidget';

  static Future<void> init() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
    } catch (e) {
      debugPrint('WidgetService init error: $e');
    }
  }

  /// Formats and updates the Home Screen widget with current tasks and reminders/schedules
  static Future<bool> updateWidgetData({
    List<Task>? tasks,
    List<Schedule>? schedules,
  }) async {
    try {
      if (kIsWeb) return false;
      if (!Platform.isAndroid && !Platform.isIOS) return false;

      final timeFormatted = DateFormat('h:mm a').format(DateTime.now());
      await HomeWidget.saveWidgetData<String>('widget_title', '🦅 HAWK Dashboard');
      await HomeWidget.saveWidgetData<String>('widget_updated_time', 'Updated $timeFormatted');

      if (tasks != null) {
        // Filter pending tasks
        final pendingTasks = tasks.where((t) => !t.completed).toList();
        // Sort tasks: high priority first
        pendingTasks.sort((a, b) {
          final pMap = {'high': 0, 'urgent': 0, 'medium': 1, 'low': 2};
          final pA = pMap[a.priority.toLowerCase()] ?? 1;
          final pB = pMap[b.priority.toLowerCase()] ?? 1;
          return pA.compareTo(pB);
        });

        // Prepare tasks summary string (first 4 tasks)
        String tasksSummary;
        if (pendingTasks.isEmpty) {
          tasksSummary = "No pending tasks. You're all caught up!";
        } else {
          final displayTasks = pendingTasks.take(4).map((t) {
            final prefix = t.isGoal ? '🎯 ' : (t.isRegular ? '🔄 ' : '• ');
            return '$prefix${t.text}';
          }).toList();

          final remaining = pendingTasks.length - displayTasks.length;
          if (remaining > 0) {
            displayTasks.add('... and $remaining more');
          }
          tasksSummary = displayTasks.join('\n');
        }

        await HomeWidget.saveWidgetData<String>('tasks_summary', tasksSummary);
        await HomeWidget.saveWidgetData<int>('tasks_count', pendingTasks.length);
      }

      if (schedules != null) {
        // Prepare reminders/schedules summary string (first 3 schedules)
        String remindersSummary;
        if (schedules.isEmpty) {
          remindersSummary = 'No reminders scheduled for today.';
        } else {
          final displaySchedules = schedules.take(3).map((s) {
            final time = s.startTime.isNotEmpty ? '${s.startTime} ' : '';
            return '⏰ $time${s.title}';
          }).toList();

          final remaining = schedules.length - displaySchedules.length;
          if (remaining > 0) {
            displaySchedules.add('... and $remaining more');
          }
          remindersSummary = displaySchedules.join('\n');
        }

        await HomeWidget.saveWidgetData<String>('reminders_summary', remindersSummary);
        await HomeWidget.saveWidgetData<int>('reminders_count', schedules.length);
      }

      // Trigger native widget update
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );

      return true;
    } catch (e) {
      debugPrint('Error updating home widget: $e');
      return false;
    }
  }

  /// Request the system to pin the widget to the device home screen
  static Future<bool> requestPinWidget() async {
    try {
      if (kIsWeb) return false;
      if (!Platform.isAndroid) return false;

      final isSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isSupported == true) {
        await HomeWidget.requestPinWidget(
          name: androidWidgetName,
          androidName: androidWidgetName,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting pin widget: $e');
      return false;
    }
  }

  static Future<bool> isPinningSupported() async {
    try {
      if (kIsWeb || !Platform.isAndroid) return false;
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }
}
