package com.dhikr.adhkar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews

class PrayerWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS = "prayer_widget_data"

        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
            if (ids.isNotEmpty()) {
                val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }
    }

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        val data = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        for (id in ids) {
            updateWidget(context, mgr, id, data)
        }
    }

    private fun updateWidget(context: Context, mgr: AppWidgetManager, id: Int, data: SharedPreferences) {
        val v = RemoteViews(context.packageName, R.layout.widget_prayer)

        val fajr    = data.getString("prayer_fajr",    "--:--") ?: "--:--"
        val dhuhr   = data.getString("prayer_dhuhr",   "--:--") ?: "--:--"
        val asr     = data.getString("prayer_asr",     "--:--") ?: "--:--"
        val maghrib = data.getString("prayer_maghrib", "--:--") ?: "--:--"
        val isha    = data.getString("prayer_isha",    "--:--") ?: "--:--"

        v.setTextViewText(R.id.widget_time_fajr,    fajr)
        v.setTextViewText(R.id.widget_time_dhuhr,   dhuhr)
        v.setTextViewText(R.id.widget_time_asr,     asr)
        v.setTextViewText(R.id.widget_time_maghrib, maghrib)
        v.setTextViewText(R.id.widget_time_isha,    isha)

        val nextKey  = data.getString("next_prayer_key", "") ?: ""
        val nextTime = data.getString("next_prayer_time", "--:--") ?: "--:--"

        val names = mapOf(
            "fajr"    to "الفجر",
            "dhuhr"   to "الظهر",
            "asr"     to "العصر",
            "maghrib" to "المغرب",
            "isha"    to "العشاء"
        )
        v.setTextViewText(R.id.widget_next_name, names[nextKey] ?: "الفجر")
        v.setTextViewText(R.id.widget_next_time, nextTime)

        val idle = Color.parseColor("#E0FDF4")
        val gold = Color.parseColor("#C5A059")
        val mute = Color.parseColor("#6EE7B790")

        val timeIds = mapOf(
            "fajr"    to R.id.widget_time_fajr,
            "dhuhr"   to R.id.widget_time_dhuhr,
            "asr"     to R.id.widget_time_asr,
            "maghrib" to R.id.widget_time_maghrib,
            "isha"    to R.id.widget_time_isha
        )
        val labelIds = mapOf(
            "fajr"    to R.id.widget_lbl_fajr,
            "dhuhr"   to R.id.widget_lbl_dhuhr,
            "asr"     to R.id.widget_lbl_asr,
            "maghrib" to R.id.widget_lbl_maghrib,
            "isha"    to R.id.widget_lbl_isha
        )

        for ((key, timeId) in timeIds) {
            val labelId = labelIds[key] ?: continue
            if (key == nextKey) {
                v.setTextColor(timeId, gold)
                v.setTextColor(labelId, gold)
            } else {
                v.setTextColor(timeId, idle)
                v.setTextColor(labelId, mute)
            }
        }

        val launch = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        v.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(context, 0, launch, flags))

        mgr.updateAppWidget(id, v)
    }
}
