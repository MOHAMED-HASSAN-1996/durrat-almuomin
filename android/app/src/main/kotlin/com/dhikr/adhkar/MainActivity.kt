package com.dhikr.adhkar

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Vibrator
import android.os.VibratorManager
import android.os.VibrationEffect
import android.provider.Settings
import android.app.NotificationManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.dhikr.adhkar/permissions"
    private var permissionChannel: MethodChannel? = null
    private var isVibrating = false

    private fun getVibrator(): Vibrator? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun startStrongVibration() {
        try {
            val vibrator = getVibrator() ?: return
            if (!vibrator.hasVibrator()) return
            isVibrating = true
            // Strong alarm vibration: 0ms wait, 1200ms strong pulse, 400ms silence, 1200ms pulse, 400ms silence
            val pattern = longArrayOf(0, 1200, 400, 1200, 400)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // 255 is maximum motor amplitude
                val amplitudes = intArrayOf(0, 255, 0, 255, 0)
                val effect = VibrationEffect.createWaveform(pattern, amplitudes, 0) // repeat continuously
                vibrator.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopStrongVibration() {
        try {
            isVibrating = false
            val vibrator = getVibrator() ?: return
            vibrator.cancel()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * نبضة اهتزاز قوية لنقرة العدّ (السبحة الإلكترونية وأذكار الصباح والمساء
     * وبعد الصلاة والرقية الشرعية).
     *
     * نستخدم الطبقة الأصلية (مو HapticFeedback من فلاتر) لأن قوة الاهتزاز
     * هناك ثابتة من النظام وما تنفع تزوّدها — هنا نتحكم بالمدة والسعة.
     *
     * ملاحظة مهمة: الإحساس بـ«الثقل» في النقرة يأتي من *مدة* النبضة وعددها،
     * مو من سعتها لوحدها. النبضة الواحدة القصيرة (45ms) كانت ضعيفة ومحدودة
     * الإحساس مهما كانت سعتها، فصارت نبضتين متتاليتين بأقصى سعة — نفس الشدة
     * لكن الإحساس صار واضح. ونبضة الإتمام ثلاث نبضات أطول عشان يعرف
     * المستخدم إن الذكر خلص من غير ما يشيل إصبعه عن الشاشة.
     *
     * @param intensity 1 = نقرة عدّ عادية (نبضتان) — 2 = إتمام العدّ (ثلاث نبضات).
     */
    private fun tapVibration(intensity: Int = 1) {
        try {
            // ما نتدخّل إذا اهتزاز الأذان شغّال — منقدر نلغيه أو نعيده بالغلط.
            if (isVibrating) return
            val vibrator = getVibrator() ?: return
            if (!vibrator.hasVibrator()) return

            val timings: LongArray
            val amplitudes: IntArray
            if (intensity >= 2) {
                // إتمام الذكر: ثلاث نبضات متدرّجة الطول عشان تُحسّ «بتمام».
                timings = longArrayOf(0, 90, 60, 90, 60, 120)
                amplitudes = intArrayOf(0, 255, 0, 255, 0, 255)
            } else {
                // نقرة العدّ: نبضتان متتاليتان بأقصى سعة.
                timings = longArrayOf(0, 70, 50, 70)
                amplitudes = intArrayOf(0, 255, 0, 255)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // 255 أقصى سعة للمحرك؛ -1 يعني اهتزاز مرة واحدة بدون تكرار.
                val effect = VibrationEffect.createWaveform(timings, amplitudes, -1)
                vibrator.vibrate(effect)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                @Suppress("DEPRECATION")
                vibrator.vibrate(timings, -1)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        permissionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        permissionChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isIgnoring = powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                        result.success(isIgnoring)
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                            if (powerManager?.isIgnoringBatteryOptimizations(packageName) == false) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("BATTERY_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "openBatteryOptimizationSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_SETTINGS_ERROR", e.message, null)
                    }
                }
                "canScheduleExactAlarms" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager
                        val canExact = alarmManager?.canScheduleExactAlarms() ?: false
                        result.success(canExact)
                    } else {
                        result.success(true)
                    }
                }
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ALARM_ERROR", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent().apply {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            } else {
                                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                data = Uri.parse("package:$packageName")
                            }
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIF_ERROR", e.message, null)
                    }
                }
                "canUseFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                        result.success(manager?.canUseFullScreenIntent() ?: false)
                    } else {
                        result.success(true)
                    }
                }
                "canDrawOverlays" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("OVERLAY_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "startAdhanVibration" -> {
                    startStrongVibration()
                    result.success(true)
                }
                "tapVibration" -> {
                    tapVibration(call.argument<Int>("intensity") ?: 1)
                    result.success(true)
                }
                "stopAdhanVibration" -> {
                    stopStrongVibration()
                    result.success(true)
                }
                "closeAdhanScreen" -> {
                    stopStrongVibration()
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            setShowWhenLocked(false)
                            setTurnScreenOn(false)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            finishAndRemoveTask()
                        } else {
                            finish()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CLOSE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // إيقاف الأذان عند ضغط زر تعلية/خفض الصوت — نُبلغ Flutter ليوقف الصوت
    // مع السماح للنظام بتغيير مستوى الصوت طبيعياً.
    override fun onKeyDown(keyCode: Int, event: android.view.KeyEvent?): Boolean {
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP ||
            keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            stopStrongVibration()
            try {
                permissionChannel?.invokeMethod("volumeButtonPressed", null)
            } catch (_: Exception) {}
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        stopStrongVibration()
        super.onDestroy()
    }
}
