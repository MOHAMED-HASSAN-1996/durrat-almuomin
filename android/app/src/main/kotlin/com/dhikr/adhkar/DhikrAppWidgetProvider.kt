package com.dhikr.adhkar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DhikrAppWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, DhikrAppWidgetProvider::class.java)
            )
            if (ids != null && ids.isNotEmpty()) {
                val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
                onUpdate(context, appWidgetManager, ids, widgetData)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            try {
                updateSingleWidget(context, appWidgetManager, widgetId, widgetData)
            } catch (e: Exception) {
                e.printStackTrace()
                // If update fails, show minimal safe widget so it doesn't appear broken
                try {
                    val safeViews = RemoteViews(context.packageName, R.layout.dhikr_home_widget)
                    appWidgetManager.updateAppWidget(widgetId, safeViews)
                } catch (e2: Exception) {
                    e2.printStackTrace()
                }
            }
        }
    }

    private fun updateSingleWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.dhikr_home_widget)

        // ─── Next Prayer ───────────────────────────────────────────────────────
        val nextPrayerTitle = widgetData.getString("next_prayer_title", "الصلاة القادمة")
            ?: "الصلاة القادمة"
        val nextPrayerTime = widgetData.getString("next_prayer_time", "--:--")
            ?: "--:--"

        views.setTextViewText(R.id.widget_next_prayer_title, nextPrayerTitle)
        views.setTextViewText(R.id.widget_next_prayer_time, nextPrayerTime)

        // ─── 5 Prayer Times ────────────────────────────────────────────────────
        views.setTextViewText(R.id.widget_fajr_time,
            widgetData.getString("prayer_fajr", "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_dhuhr_time,
            widgetData.getString("prayer_dhuhr", "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_asr_time,
            widgetData.getString("prayer_asr", "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_maghrib_time,
            widgetData.getString("prayer_maghrib", "--:--") ?: "--:--")
        views.setTextViewText(R.id.widget_isha_time,
            widgetData.getString("prayer_isha", "--:--") ?: "--:--")

        // ─── Highlight the next prayer ─────────────────────────────────────────
        val defaultColor = Color.WHITE
        val highlightColor = Color.parseColor("#FCD34D") // Gold
        views.setTextColor(R.id.widget_fajr_time, defaultColor)
        views.setTextColor(R.id.widget_dhuhr_time, defaultColor)
        views.setTextColor(R.id.widget_asr_time, defaultColor)
        views.setTextColor(R.id.widget_maghrib_time, defaultColor)
        views.setTextColor(R.id.widget_isha_time, defaultColor)

        when (widgetData.getString("next_prayer_key", "")) {
            "fajr"    -> views.setTextColor(R.id.widget_fajr_time,    highlightColor)
            "dhuhr"   -> views.setTextColor(R.id.widget_dhuhr_time,   highlightColor)
            "asr"     -> views.setTextColor(R.id.widget_asr_time,     highlightColor)
            "maghrib" -> views.setTextColor(R.id.widget_maghrib_time, highlightColor)
            "isha"    -> views.setTextColor(R.id.widget_isha_time,    highlightColor)
        }

        // ─── Dhikr Section ─────────────────────────────────────────────────────
        val dhikrLabel = widgetData.getString("dhikr_label", "اذكار اليوم")
            ?: "اذكار اليوم"
        val dhikrText = widgetData.getString("dhikr_text",
            "سبحان الله وبحمده، سبحان الله العظيم")
            ?: "سبحان الله وبحمده، سبحان الله العظيم"

        // Strip emojis from label to avoid crash on older Android
        val safeLabel = dhikrLabel.replace(Regex("[^\\u0000-\\uFFFF]"), "").trim()
        views.setTextViewText(R.id.widget_dhikr_label,
            safeLabel.ifEmpty { "اذكار اليوم" })
        views.setTextViewText(R.id.widget_dhikr_text, dhikrText)

        // ─── Tap → Open App ────────────────────────────────────────────────────
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, flags)
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        // ─── Apply to widget ───────────────────────────────────────────────────
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
