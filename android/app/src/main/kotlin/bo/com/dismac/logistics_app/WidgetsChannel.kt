package bo.com.dismac.logistics_app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import bo.com.dismac.logistics_app.widgets.WidgetKind
import bo.com.dismac.logistics_app.widgets.WidgetRenderer
import bo.com.dismac.logistics_app.widgets.WidgetStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Widgets de la pantalla de inicio (Android). Contraparte Dart:
 * lib/core/home_widgets/. Los providers, layouts y el renderer viven en el
 * paquete `widgets`.
 *
 * Dart → nativo (canal "bo.com.dismac/widgets"):
 * - "isSupported" → {pinSupported: Boolean} (API 26+ y launcher que acepte pin)
 * - "update" {kind, payload: Map} → guarda el payload (JSON) en
 *   SharedPreferences "distrack_widgets" bajo `kind` y refresca todas las
 *   instancias de ese widget. Devuelve null. Kind desconocido: se ignora.
 * - "clearAll" → {"state":"signedOut"} para cada kind y refresca todo (logout).
 * - "setEnabledKinds" {kinds: List<String>} → habilita los providers listados
 *   y deshabilita el resto (los deshabilitados desaparecen del selector de
 *   widgets). Idempotente: solo toca los que cambian. Devuelve null.
 * - "requestPin" {kind} → Boolean (pide al launcher fijar el widget; API 26+).
 *
 * Kinds: next_delivery, route_day, picking_pending, store_receptions,
 * supervisor_summary, quick_scan (ver WidgetKind). Batería: los widgets no se
 * refrescan solos (updatePeriodMillis = 0); solo cambian cuando Dart llama
 * "update".
 */
object WidgetsChannel {
    private const val CHANNEL = "bo.com.dismac/widgets"

    fun register(engine: FlutterEngine, activity: Activity) {
        val context = activity.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    val args = call.arguments as? Map<*, *>
                    when (call.method) {
                        "isSupported" ->
                            result.success(mapOf("pinSupported" to isPinSupported(context)))
                        "update" -> {
                            update(context, args)
                            result.success(null)
                        }
                        "clearAll" -> {
                            clearAll(context)
                            result.success(null)
                        }
                        "setEnabledKinds" -> {
                            setEnabledKinds(context, args?.get("kinds") as? List<*>)
                            result.success(null)
                        }
                        "requestPin" ->
                            result.success(requestPin(context, args?.get("kind") as? String))
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("widgets", e.message, null)
                }
            }
    }

    private fun isPinSupported(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 26) return false
        val manager = AppWidgetManager.getInstance(context) ?: return false
        return manager.isRequestPinAppWidgetSupported
    }

    private fun update(context: Context, args: Map<*, *>?) {
        val kind = WidgetKind.fromKey(args?.get("kind") as? String) ?: return
        val payload = args?.get("payload") as? Map<*, *>
        val json = if (payload != null) WidgetStore.toJson(payload) else WidgetStore.signedOut()
        WidgetStore.save(context, kind, json)
        WidgetRenderer.refresh(context, kind)
    }

    private fun clearAll(context: Context) {
        for (kind in WidgetKind.entries) {
            WidgetStore.save(context, kind, WidgetStore.signedOut())
        }
        WidgetRenderer.refreshAll(context)
    }

    /**
     * Muestra en el selector solo los widgets del rol. Se compara con el
     * estado actual para no disparar PACKAGE_CHANGED (y que el launcher
     * recargue) cuando nada cambia. COMPONENT_ENABLED_STATE_DEFAULT = lo del
     * manifest (habilitado).
     *
     * Ojo: deshabilitar un provider también quita del launcher las instancias
     * ya colocadas de ese widget (p. ej. al cambiar de rol en el mismo
     * teléfono).
     */
    private fun setEnabledKinds(context: Context, kinds: List<*>?) {
        val wanted = kinds.orEmpty().filterIsInstance<String>().toSet()
        val pm = context.packageManager
        for (kind in WidgetKind.entries) {
            val component = ComponentName(context, kind.providerClass)
            val enable = kind.key in wanted
            val current = pm.getComponentEnabledSetting(component)
            val enabledNow = current == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                current == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
            if (enable == enabledNow) continue
            pm.setComponentEnabledSetting(
                component,
                if (enable) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                },
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun requestPin(context: Context, key: String?): Boolean {
        if (Build.VERSION.SDK_INT < 26) return false
        val kind = WidgetKind.fromKey(key) ?: return false
        val manager = AppWidgetManager.getInstance(context) ?: return false
        if (!manager.isRequestPinAppWidgetSupported) return false
        val component = ComponentName(context, kind.providerClass)
        // Un provider deshabilitado (otro rol) no se puede fijar.
        val state = context.packageManager.getComponentEnabledSetting(component)
        if (state != PackageManager.COMPONENT_ENABLED_STATE_ENABLED &&
            state != PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
        ) {
            return false
        }
        return manager.requestPinAppWidget(component, null, null)
    }
}
