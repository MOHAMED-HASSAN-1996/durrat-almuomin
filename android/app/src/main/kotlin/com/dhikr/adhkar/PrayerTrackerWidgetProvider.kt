package com.dhikr.adhkar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerTrackerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun setPrayerStatus(
        views: RemoteViews,
        viewId: Int,
        done: Boolean,
        time: String,
        isNext: Boolean,
    ) {
        if (done) {
            views.setTextViewText(viewId, "✔")
            views.setTextColor(viewId, Color.parseColor("#10B981"))
            return
        }
        views.setTextViewText(viewId, time)
        views.setTextColor(
            viewId,
            if (isNext) Color.parseColor("#FFFFFF") else Color.parseColor("#9CA3AF"),
        )
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_prayer_tracker)

        val fajr = widgetData.getString("prayer_fajr", "--:--") ?: "--:--"
        val dhuhr = widgetData.getString("prayer_dhuhr", "--:--") ?: "--:--"
        val asr = widgetData.getString("prayer_asr", "--:--") ?: "--:--"
        val maghrib = widgetData.getString("prayer_maghrib", "--:--") ?: "--:--"
        val isha = widgetData.getString("prayer_isha", "--:--") ?: "--:--"

        val fajrDone = widgetData.getBoolean("task_fajr_done", false)
        val dhuhrDone = widgetData.getBoolean("task_dhuhr_done", false)
        val asrDone = widgetData.getBoolean("task_asr_done", false)
        val maghribDone = widgetData.getBoolean("task_maghrib_done", false)
        val ishaDone = widgetData.getBoolean("task_isha_done", false)

        val savedStreak = widgetData.getInt("streak_count", 1)
        val streak = if (savedStreak >= 1) savedStreak else 1
        val streakSuffix = if (3 > streak || streak >= 11) " يوم" else " أيام"
        views.setTextViewText(R.id.widget_tracker_streak, "🔥 $streak$streakSuffix")

        val nextPrayerKey = widgetData.getString("next_prayer_key", "fajr") ?: "fajr"
        val nextPrayerTimestamp = widgetData.getLong("next_prayer_timestamp", 0L)

        val doneCount =
            (if (fajrDone) 1 else 0) +
                (if (dhuhrDone) 1 else 0) +
                (if (asrDone) 1 else 0) +
                (if (maghribDone) 1 else 0) +
                (if (ishaDone) 1 else 0)

        setPrayerStatus(views, R.id.widget_tracker_status_fajr, fajrDone, fajr, nextPrayerKey == "fajr")
        setPrayerStatus(views, R.id.widget_tracker_status_dhuhr, dhuhrDone, dhuhr, nextPrayerKey == "dhuhr")
        setPrayerStatus(views, R.id.widget_tracker_status_asr, asrDone, asr, nextPrayerKey == "asr")
        setPrayerStatus(views, R.id.widget_tracker_status_maghrib, maghribDone, maghrib, nextPrayerKey == "maghrib")
        setPrayerStatus(views, R.id.widget_tracker_status_isha, ishaDone, isha, nextPrayerKey == "isha")

        views.setProgressBar(R.id.widget_tracker_progress, 5, doneCount, false)

        val prayerNames = mapOf(
            "fajr" to "الفجر",
            "dhuhr" to "الظهر",
            "asr" to "العصر",
            "maghrib" to "المغرب",
            "isha" to "العشاء",
        )
        val nextName = prayerNames[nextPrayerKey] ?: "الصلاة"

        val remainingMillis = nextPrayerTimestamp - System.currentTimeMillis()
        var countdown = "الآن"
        if (nextPrayerTimestamp > 0L && remainingMillis > 0L) {
            val totalMinutes = remainingMillis / 60_000L
            val hours = totalMinutes / 60L
            val minutes = totalMinutes % 60L
            countdown = when {
                hours > 0L && minutes > 0L -> "$hours س و $minutes د"
                hours > 0L -> "$hours ساعة"
                minutes > 0L -> "$minutes دقيقة"
                else -> "الآن"
            }
        }

        val summary = if (doneCount == 5) {
            "بارك الله فيك! أتممت جميع صلوات اليوم 🌟"
        } else {
            "أديت $doneCount من 5 صلوات • متبقي على $nextName $countdown"
        }
        views.setTextViewText(R.id.widget_tracker_summary, summary)

        views.setOnClickPendingIntent(
            R.id.widget_tracker_root,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("dhikr://open/prayer_times"),
            ),
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}