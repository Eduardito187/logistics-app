package bo.com.dismac.logistics_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.PowerManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Canal nativo de energía: nivel de batería, si está cargando y si el ahorro
 * de energía del sistema está activo. Contraparte Dart:
 * lib/core/power/power_channel.dart.
 *
 * - "status" → {level: Int 0-100 (-1 si no se pudo leer), charging: Boolean,
 *   powerSave: Boolean}
 *
 * Es una consulta puntual (sin receivers registrados ni wakelocks): Dart la
 * repite al volver a primer plano y, durante la ruta, cada pocos minutos.
 */
object PowerChannel {
    private const val CHANNEL = "bo.com.dismac/power"

    fun register(engine: FlutterEngine, activity: Activity) {
        // Contexto de aplicación: el canal no debe retener la Activity.
        val context = activity.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "status") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    result.success(status(context))
                } catch (e: Exception) {
                    result.error("power_unavailable", e.message, null)
                }
            }
    }

    private fun status(context: Context): Map<String, Any> {
        val battery = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        var level = battery?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
        // Algunos fabricantes devuelven 0 / Integer.MIN_VALUE en la propiedad:
        // se cae al broadcast "sticky" de batería (no registra ningún receiver).
        if (level <= 0 || level > 100) {
            level = stickyLevel(context)
        }
        val charging = battery?.isCharging ?: stickyCharging(context)
        return mapOf(
            "level" to level,
            "charging" to charging,
            "powerSave" to (power?.isPowerSaveMode ?: false),
        )
    }

    private fun stickyIntent(context: Context): Intent? =
        context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))

    private fun stickyLevel(context: Context): Int {
        val intent = stickyIntent(context) ?: return -1
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        if (level < 0 || scale <= 0) return -1
        return (level * 100) / scale
    }

    private fun stickyCharging(context: Context): Boolean {
        val status = stickyIntent(context)?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
    }
}
