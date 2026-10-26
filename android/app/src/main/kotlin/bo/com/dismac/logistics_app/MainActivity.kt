package bo.com.dismac.logistics_app

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Memoria del teléfono para que Dart ajuste cachés (lib/core/performance).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bo.com.dismac/device_memory")
            .setMethodCallHandler { call, result ->
                if (call.method != "info") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val info = ActivityManager.MemoryInfo()
                am.getMemoryInfo(info)
                result.success(
                    mapOf(
                        "totalMb" to (info.totalMem / (1024 * 1024)).toInt(),
                        "lowRam" to am.isLowRamDevice,
                        // Tope de heap Java por app (indicador de gama del equipo).
                        "memoryClassMb" to am.memoryClass,
                    )
                )
            }
    }
}
