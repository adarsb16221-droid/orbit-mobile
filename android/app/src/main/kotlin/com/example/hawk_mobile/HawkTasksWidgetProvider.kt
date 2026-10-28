package com.example.hawk_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HawkTasksWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hawk_tasks_widget).apply {
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                val title = widgetData.getString("widget_title", "🦅 HAWK Dashboard") ?: "🦅 HAWK Dashboard"
                val updatedTime = widgetData.getString("widget_updated_time", "Today") ?: "Today"
                val tasksText = widgetData.getString("tasks_summary", "No pending tasks. You're all caught up!") ?: "No pending tasks."
                val remindersText = widgetData.getString("reminders_summary", "No reminders scheduled for today.") ?: "No reminders scheduled."
                val taskCount = widgetData.getInt("tasks_count", 0)
                val reminderCount = widgetData.getInt("reminders_count", 0)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_updated_time, updatedTime)
                setTextViewText(R.id.widget_tasks_text, tasksText)
                setTextViewText(R.id.widget_reminders_text, remindersText)
                setTextViewText(R.id.widget_tasks_count_badge, taskCount.toString())
                setTextViewText(R.id.widget_reminders_count_badge, reminderCount.toString())
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
