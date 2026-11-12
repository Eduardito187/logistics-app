package bo.com.dismac.logistics_app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (no FlutterActivity): el BiometricPrompt de androidx
// necesita una FragmentActivity para mostrar el diálogo de huella/rostro.
class MainActivity : FlutterFragmentActivity() {
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
        // Huella / rostro (lib/core/auth/biometric).
        BiometricChannel.register(flutterEngine, this)
        // Live Updates: notificación de ruta en la barra de estado / Now Bar
        // (lib/core/live_updates).
        LiveUpdatesChannel.register(flutterEngine, this)
        // Accesos directos al mantener presionado el ícono (lib/core/shortcuts).
        AppShortcutsChannel.register(flutterEngine, this)
        // Estado de batería / ahorro de energía (lib/core/power).
        PowerChannel.register(flutterEngine, this)
        // Máscara real de la red + Bonjour/mDNS para buscar impresoras
        // (lib/core/printing).
        NetworkChannel.register(flutterEngine, this)
        // Widgets de la pantalla de inicio (lib/core/home_widgets).
        WidgetsChannel.register(flutterEngine, this)
    }

    // App ya abierta y se toca un acceso directo / la acción "Abrir" de la
    // notificación de ruta: llega un intent nuevo con la ruta a abrir.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        AppShortcutsChannel.onNewIntent(intent)
    }
}
