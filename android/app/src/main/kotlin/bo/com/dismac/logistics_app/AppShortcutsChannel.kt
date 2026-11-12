package bo.com.dismac.logistics_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * Accesos directos del ícono (mantener presionado el ícono en el launcher).
 * Contraparte Dart: lib/core/shortcuts/.
 *
 * Dart → nativo:
 * - "set" (lista de {id, title, shortTitle, route}) → Boolean
 * - "clear" → Boolean (al cerrar sesión)
 * - "consumeLaunchShortcut" → ruta con la que se abrió la app, o null (una vez)
 * Nativo → Dart:
 * - "launch" (ruta) cuando se toca un acceso (o el "Abrir" de la notificación
 *   de ruta en vivo) con la app ya abierta. Requiere que MainActivity llame a
 *   [onNewIntent] desde su `onNewIntent`.
 *
 * ShortcutManager existe desde API 25; en Android 7.0 (24) los accesos no se
 * publican (no-op), pero el extra de ruta igual se procesa.
 */
object AppShortcutsChannel {
    /** Extra del intent con la ruta go_router a abrir. */
    const val EXTRA_ROUTE = "shortcut_route"

    private const val CHANNEL = "bo.com.dismac/shortcuts"

    private var channel: MethodChannel? = null
    private var activityRef: WeakReference<Activity>? = null

    fun register(engine: FlutterEngine, activity: Activity) {
        activityRef = WeakReference(activity)
        val context = activity.applicationContext
        val methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "set" -> result.success(setShortcuts(context, call.arguments as? List<*>))
                    "clear" -> result.success(clear(context))
                    "consumeLaunchShortcut" ->
                        result.success(consume(activityRef?.get()?.intent))
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("shortcuts", e.message, null)
            }
        }
        channel = methodChannel
    }

    /**
     * Llamar desde MainActivity.onNewIntent: si el intent trae una ruta (acceso
     * directo o "Abrir" de la notificación), se la pasa a Dart.
     */
    fun onNewIntent(intent: Intent) {
        val route = consume(intent) ?: return
        channel?.invokeMethod("launch", route)
    }

    /** Lee y BORRA la ruta del intent (que no se repita al recrear la Activity). */
    private fun consume(intent: Intent?): String? {
        if (intent == null) return null
        // Abierta desde "Recientes": Android reentrega el intent original; no
        // se vuelve a navegar al acceso viejo.
        if ((intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) {
            intent.removeExtra(EXTRA_ROUTE)
            return null
        }
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: return null
        intent.removeExtra(EXTRA_ROUTE)
        return if (route.startsWith("/")) route else null
    }

    private fun setShortcuts(context: Context, items: List<*>?): Boolean {
        if (Build.VERSION.SDK_INT < 25) return false
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return false
        val max = manager.maxShortcutCountPerActivity
        val shortcuts = mutableListOf<ShortcutInfo>()
        items.orEmpty().forEachIndexed { index, raw ->
            val item = raw as? Map<*, *> ?: return@forEachIndexed
            val id = item["id"] as? String ?: return@forEachIndexed
            val route = item["route"] as? String ?: return@forEachIndexed
            val title = item["title"] as? String ?: return@forEachIndexed
            val shortTitle = item["shortTitle"] as? String ?: title
            if (shortcuts.size >= max) return@forEachIndexed
            val intent = Intent(context, MainActivity::class.java).apply {
                // ShortcutInfo exige una acción en el intent.
                action = Intent.ACTION_VIEW
                putExtra(EXTRA_ROUTE, route)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            shortcuts.add(
                ShortcutInfo.Builder(context, id)
                    .setShortLabel(shortTitle)
                    .setLongLabel(title)
                    .setIcon(Icon.createWithResource(context, R.mipmap.ic_launcher))
                    .setIntent(intent)
                    .setRank(index)
                    .build()
            )
        }
        return if (shortcuts.isEmpty()) {
            manager.removeAllDynamicShortcuts()
            true
        } else {
            manager.setDynamicShortcuts(shortcuts)
        }
    }

    private fun clear(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 25) return false
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return false
        manager.removeAllDynamicShortcuts()
        return true
    }
}
