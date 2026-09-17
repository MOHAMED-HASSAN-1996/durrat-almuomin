package com.dhikr.adhkar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.Locale

class PrayerWidgetProvider : HomeWidgetProvider() {

    private class PrayerItem(val key: String, val arabicName: String, val time: String)

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

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_prayer)

        val calendar = Calendar.getInstance()
        var hour = calendar.get(Calendar.HOUR_OF_DAY) % 12
        if (hour == 0) hour = 12
        val minuteText = String.format(Locale.US, "%02d", calendar.get(Calendar.MINUTE))
        val period = if (calendar.get(Calendar.AM_PM) == Calendar.AM) "ص" else "م"
        val currentTime = "$hour:$minuteText $period"

        var fallbackDay = "الأَحَــــد"
        when (calendar.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> fallbackDay = "الإِثْنَــــيْن"
            Calendar.TUESDAY -> fallbackDay = "الثُّـلَاثَــــاء"
            Calendar.WEDNESDAY -> fallbackDay = "الأَرْبِعَــــاء"
            Calendar.THURSDAY -> fallbackDay = "الخَمِيــــس"
            Calendar.FRIDAY -> fallbackDay = "الجُـمُعَــــة"
            Calendar.SATURDAY -> fallbackDay = "السَّــــبْت"
        }

        val dayCalligraphy =
            widgetData.getString("widget_day_calligraphy", fallbackDay) ?: fallbackDay
        val hijriDate =
            widgetData.getString("widget_hijri_date", "١ ربيع الآخر ١٤٤٨ هـ")
                ?: "١ ربيع الآخر ١٤٤٨ هـ"
        val gregorianDate =
            widgetData.getString("widget_gregorian_date", "١٤ سبتمبر ٢٠٢٦ م")
                ?: "١٤ سبتمبر ٢٠٢٦ م"

        val fajr = widgetData.getString("prayer_fajr", "5:10") ?: "5:10"
        val sunrise = widgetData.getString("prayer_sunrise", "6:38") ?: "6:38"
        val dhuhr = widgetData.getString("prayer_dhuhr", "12:51") ?: "12:51"
        val asr = widgetData.getString("prayer_asr", "4:23") ?: "4:23"
        val maghrib = widgetData.getString("prayer_maghrib", "7:04") ?: "7:04"
        val isha = widgetData.getString("prayer_isha", "8:23") ?: "8:23"

        val nextPrayerKey = (widgetData.getString("next_prayer_key", "fajr") ?: "fajr")
            .lowercase(Locale.ROOT)

        val bitmap = renderFullWidgetBitmap(
            context = context,
            dayCalligraphy = dayCalligraphy,
            currentTime = currentTime,
            hijriDate = hijriDate,
            gregorianDate = gregorianDate,
            fajr = fajr,
            sunrise = sunrise,
            dhuhr = dhuhr,
            asr = asr,
            maghrib = maghrib,
            isha = isha,
            nextPrayerKey = nextPrayerKey,
        )

        if (bitmap != null) {
            views.setImageViewBitmap(R.id.widget_canvas_image, bitmap)
        }

        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("dhikr://open/prayer_times"),
            ),
        )

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun loadFont(context: Context, resId: Int, fallback: Typeface): Typeface {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return try {
                context.resources.getFont(resId)
            } catch (t: Throwable) {
                fallback
            }
        }
        return fallback
    }

    private fun renderFullWidgetBitmap(
        context: Context,
        dayCalligraphy: String,
        currentTime: String,
        hijriDate: String,
        gregorianDate: String,
        fajr: String,
        sunrise: String,
        dhuhr: String,
        asr: String,
        maghrib: String,
        isha: String,
        nextPrayerKey: String,
    ): Bitmap? {
        return try {
            val thuluth = loadFont(context, R.font.thuluth, Typeface.DEFAULT_BOLD)
            val somarsansBold =
                loadFont(context, R.font.somarsans_bold, Typeface.DEFAULT_BOLD)
            val somarsansMedium =
                loadFont(context, R.font.somarsans_medium, Typeface.DEFAULT)

            val bitmap = Bitmap.createBitmap(1080, 480, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            val dayLabel = resolveDayCalligraphy(dayCalligraphy)

            // Day calligraphy → top-left
            val dayPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = thuluth
                color = Color.WHITE
                textAlign = Paint.Align.LEFT
                setShadowLayer(14.0f, 0.0f, 4.0f, Color.parseColor("#E6000000"))
            }
            var daySize = 78.0f
            dayPaint.textSize = daySize
            var dayMeasure = dayPaint.measureText(dayLabel)
            val maxDayWidth = 1080f * 0.42f
            while (dayMeasure > maxDayWidth && daySize > 52.0f) {
                daySize -= 2.0f
                dayPaint.textSize = daySize
                dayMeasure = dayPaint.measureText(dayLabel)
            }
            canvas.drawText(dayLabel, 48.0f, 182.0f, dayPaint)

            // Current time → top-right
            val rightX = 1080f - 48.0f
            val timePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = somarsansBold
                textSize = 130.0f
                color = Color.WHITE
                textAlign = Paint.Align.RIGHT
                setShadowLayer(14.0f, 0.0f, 4.0f, Color.parseColor("#E6000000"))
            }
            canvas.drawText(currentTime, rightX, 126.0f, timePaint)

            // Date line → gregorian (after comma) . hijri
            val gregPart = if (gregorianDate.contains("،")) {
                val idx = gregorianDate.indexOf("،")
                gregorianDate.substring(idx + 1).trim()
            } else {
                gregorianDate.trim()
            }
            val dateLine = gregPart + "  .  " + hijriDate.trim()
            val datePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = somarsansMedium
                textSize = 32.0f
                color = Color.parseColor("#E2E8F0")
                textAlign = Paint.Align.RIGHT
                setShadowLayer(10.0f, 0.0f, 3.0f, Color.parseColor("#E6000000"))
            }
            canvas.drawText(dateLine, rightX, 198.0f, datePaint)

            // Divider
            val dividerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#4DFFFFFF")
                strokeWidth = 1.5f
            }
            canvas.drawLine(48.0f, 235.0f, rightX, 235.0f, dividerPaint)

            // Prayer columns (right → left)
            val prayers = listOf(
                PrayerItem("fajr", "الفجر", fajr),
                PrayerItem("sunrise", "الشروق", sunrise),
                PrayerItem("dhuhr", "الظهر", dhuhr),
                PrayerItem("asr", "العصر", asr),
                PrayerItem("maghrib", "المغرب", maghrib),
                PrayerItem("isha", "العشاء", isha),
            )
            val slot = (1080f - 96.0f) / 6.0f
            val regularColor = Color.parseColor("#F1F5F9")

            val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                color = Color.parseColor("#33FFFFFF")
            }
            val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 2.0f
                color = Color.parseColor("#80FFFFFF")
            }

            prayers.forEachIndexed { index, item ->
                val isNext = item.key == nextPrayerKey
                val centerX = rightX - (index + 0.5f) * slot

                if (isNext) {
                    val half = 0.44f * slot
                    val rect = RectF(centerX - half, 255.0f, centerX + half, 445.0f)
                    canvas.drawRoundRect(rect, 20.0f, 20.0f, fillPaint)
                    canvas.drawRoundRect(rect, 20.0f, 20.0f, strokePaint)
                }

                val namePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    typeface = somarsansMedium
                    textSize = 36.0f
                    color = if (isNext) Color.WHITE else regularColor
                    textAlign = Paint.Align.CENTER
                    setShadowLayer(10.0f, 0.0f, 3.0f, Color.parseColor("#E6000000"))
                }
                canvas.drawText(item.arabicName, centerX, 320.0f, namePaint)

                val timePaintItem = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    typeface = somarsansBold
                    textSize = 42.0f
                    color = Color.WHITE
                    textAlign = Paint.Align.CENTER
                    setShadowLayer(10.0f, 0.0f, 3.0f, Color.parseColor("#E6000000"))
                }
                canvas.drawText(item.time, centerX, 410.0f, timePaintItem)
            }

            bitmap
        } catch (t: Throwable) {
            null
        }
    }

    /**
     * Resolves the day label into its calligraphy form.
     * A saved day key without kashida (e.g. "الأحد") maps to the matching ornate label,
     * exactly like the original (9/16) implementation.
     */
    private fun resolveDayCalligraphy(key: String): String {
        fun clean(sub: String): Boolean = key.contains(sub) && !key.contains("ـ")
        return when {
            clean("سبت") -> "السَّــبْت"
            clean("أحد") || clean("احد") -> "الأَحَــد"
            clean("اثنين") || clean("إثنين") -> "الإِثْنَــيْن"
            clean("ثلاثاء") -> "الثُّـلَاثَــاء"
            clean("اربعاء") || clean("أربعاء") -> "الأَرْبِعَــاء"
            clean("خميس") -> "الخَمِيــس"
            clean("جمعة") -> "الجُـمُعَــة"
            else -> "الأَرْبِعَــاء"
        }
    }
}