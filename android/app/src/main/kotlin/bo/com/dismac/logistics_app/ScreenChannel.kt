package bo.com.dismac.logistics_app

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * Brillo de la ventana de la app (no el del sistema: sin permisos y al salir
 * de la app el teléfono vuelve solo a su brillo). Contraparte Dart:
 * lib/core/device/screen_brightness_service.dart.
 *
 * - "boostBrightness" → brillo al máximo (mostrar un QR para que otro lo lea)
 * - "restoreBrightness" → vuelve al brillo del usuario
 *
 * Lo registra LiveUpdatesChannel.register (no hace falta tocar MainActivity).
 */
object ScreenChannel {
    private const val CHANNEL = "bo.com.dismac/screen"

    fun register(engine: FlutterEngine, activity: Activity) {
        val activityRef = WeakReference(activity)
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val brightness = when (call.method) {
                    "boostBrightness" -> WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_FULL
                    "restoreBrightness" -> WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                val window = activityRef.get()?.window
                if (window == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                try {
                    // El handler corre en el hilo principal (UI): se puede
                    // tocar la ventana directo.
                    val params = window.attributes
                    params.screenBrightness = brightness
                    window.attributes = params
                    result.success(true)
                } catch (e: Exception) {
                    result.error("screen", e.message, null)
                }
            }
    }
}
