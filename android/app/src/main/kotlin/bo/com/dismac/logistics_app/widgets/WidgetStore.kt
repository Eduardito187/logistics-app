package bo.com.dismac.logistics_app.widgets

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * Datos de los widgets: un JSON por kind en SharedPreferences
 * "distrack_widgets". Lo escribe WidgetsChannel (cuando la app manda datos) y
 * lo lee WidgetRenderer (al refrescar y en onUpdate del sistema). Sin datos o
 * con JSON roto → estado "signedOut".
 */
internal object WidgetStore {
    const val PREFS_NAME = "distrack_widgets"

    const val STATE_OK = "ok"
    const val STATE_SIGNED_OUT = "signedOut"
    const val STATE_NOT_ALLOWED = "notAllowed"
    const val STATE_EMPTY = "empty"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun save(context: Context, kind: WidgetKind, payload: JSONObject) {
        // apply(): la caché en memoria se actualiza al instante, así el
        // refresco que sigue ya lee el dato nuevo; el disco se escribe aparte.
        prefs(context).edit().putString(kind.key, payload.toString()).apply()
    }

    fun load(context: Context, kind: WidgetKind): JSONObject {
        val raw = prefs(context).getString(kind.key, null) ?: return signedOut()
        return try {
            JSONObject(raw)
        } catch (e: JSONException) {
            signedOut()
        }
    }

    fun signedOut(): JSONObject = JSONObject().put("state", STATE_SIGNED_OUT)

    /**
     * Mapa del MethodChannel → JSONObject. A mano (no JSONObject(Map)) para
     * descartar claves no-String y dobles NaN/infinito, que harían lanzar a
     * JSONObject.
     */
    fun toJson(map: Map<*, *>): JSONObject {
        val json = JSONObject()
        for ((rawKey, value) in map) {
            val key = rawKey as? String ?: continue
            val converted = convert(value) ?: continue
            json.put(key, converted)
        }
        return json
    }

    private fun convert(value: Any?): Any? = when (value) {
        null -> null
        is Double -> if (value.isNaN() || value.isInfinite()) null else value
        is Float -> if (value.isNaN() || value.isInfinite()) null else value.toDouble()
        is Number, is Boolean, is String -> value
        is Map<*, *> -> toJson(value)
        is List<*> -> JSONArray().also { array -> value.forEach { item -> convert(item)?.let { array.put(it) } } }
        else -> value.toString()
    }
}
