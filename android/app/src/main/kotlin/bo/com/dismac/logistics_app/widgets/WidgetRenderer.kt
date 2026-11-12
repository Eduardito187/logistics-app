package bo.com.dismac.logistics_app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import bo.com.dismac.logistics_app.AppShortcutsChannel
import bo.com.dismac.logistics_app.MainActivity
import bo.com.dismac.logistics_app.R
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Arma los RemoteViews de cada widget a partir del JSON guardado en
 * WidgetStore. Común a todos los kinds; sin red ni timers: solo lee
 * SharedPreferences y pinta.
 *
 * Estados (payload "state"): ok → contenido; signedOut → "Iniciá sesión en
 * DisTrack"; notAllowed → "No disponible para tu rol"; empty → texto amable
 * del kind. Cualquier otro valor se trata como signedOut.
 *
 * Taps: intent explícito a MainActivity con el extra
 * AppShortcutsChannel.EXTRA_ROUTE y los mismos flags que los accesos directos
 * (SINGLE_TOP | CLEAR_TOP); Dart lo recibe por "consumeLaunchShortcut" (app
 * cerrada) o por "launch" (app abierta, vía onNewIntent). El launcher agrega
 * FLAG_ACTIVITY_NEW_TASK al lanzar el PendingIntent.
 */
internal object WidgetRenderer {
    // requestCode = kind.requestBase + slot (único por kind + acción).
    private const val SLOT_OPEN = 0
    private const val SLOT_NAVIGATE = 1
    private const val SLOT_SCAN = 2

    // Por debajo de esta altura (dp) se ocultan el pie y la dirección.
    private const val COMPACT_HEIGHT_DP = 120
    private const val PROGRESS_MAX = 1000

    private val VALUE_IDS = intArrayOf(
        R.id.widget_stat1_value,
        R.id.widget_stat2_value,
        R.id.widget_stat3_value,
    )

    /** Un número de los widgets de resumen; [danger] lo pinta rojo si es > 0. */
    private class Stat(val key: String, val danger: Boolean = false)

    /** Refresca todas las instancias colocadas de [kind] (no-op si no hay). */
    fun refresh(context: Context, kind: WidgetKind) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val ids = manager.getAppWidgetIds(ComponentName(context, kind.providerClass))
        if (ids == null || ids.isEmpty()) return
        render(context, manager, ids, kind)
    }

    fun refreshAll(context: Context) {
        WidgetKind.entries.forEach { refresh(context, it) }
    }

    /** Pinta [ids] con el último dato guardado (también desde onUpdate). */
    fun render(context: Context, manager: AppWidgetManager, ids: IntArray, kind: WidgetKind) {
        val data = WidgetStore.load(context, kind)
        for (id in ids) {
            val options = try {
                manager.getAppWidgetOptions(id)
            } catch (e: RuntimeException) {
                null
            }
            manager.updateAppWidget(id, build(context, kind, data, options))
        }
    }

    private fun build(
        context: Context,
        kind: WidgetKind,
        data: JSONObject,
        options: Bundle?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, kind.layoutRes)
        val state = normalizeState(data.optString("state", WidgetStore.STATE_SIGNED_OUT))
        val compact = isCompact(context, options)
        // Tocar la tarjeta abre la app (en la ruta del payload, si viene).
        views.setOnClickPendingIntent(
            android.R.id.background,
            openApp(context, kind, SLOT_OPEN, routeOf(data, "route")),
        )
        when (kind) {
            WidgetKind.NEXT_DELIVERY ->
                renderNextDelivery(context, views, kind, data, state, compact)
            WidgetKind.QUICK_SCAN -> renderQuickScan(context, views, kind, data, state)
            else -> renderStats(context, views, kind, data, state, compact)
        }
        return views
    }

    // ---------------------------------------------------------------- kinds

    private fun renderNextDelivery(
        context: Context,
        views: RemoteViews,
        kind: WidgetKind,
        data: JSONObject,
        state: String,
        compact: Boolean,
    ) {
        val ok = applyState(context, views, kind, state)
        applyFooter(context, views, data, state, compact)

        val stopIndex = data.optInt("stopIndex", 0)
        val stopCount = data.optInt("stopCount", 0)
        if (ok && stopCount > 0) {
            views.setTextViewText(
                R.id.widget_badge,
                context.getString(R.string.widget_stop_of, stopIndex, stopCount),
            )
            views.setViewVisibility(R.id.widget_badge, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_badge, View.GONE)
        }
        if (!ok) return

        val customer = str(data, "customer").orEmpty()
        views.setTextViewText(R.id.widget_customer, customer)

        val address = str(data, "address")
        if (address == null || compact) {
            views.setViewVisibility(R.id.widget_address, View.GONE)
        } else {
            views.setTextViewText(R.id.widget_address, address)
            views.setViewVisibility(R.id.widget_address, View.VISIBLE)
        }

        val eta = str(data, "etaText")
        if (eta == null) {
            // Se deja el espacio (INVISIBLE) para que "Navegar" quede a la derecha.
            views.setViewVisibility(R.id.widget_eta, View.INVISIBLE)
        } else {
            views.setTextViewText(R.id.widget_eta, context.getString(R.string.widget_eta, eta))
            views.setViewVisibility(R.id.widget_eta, View.VISIBLE)
        }

        val rawProgress = data.optDouble("progress", 0.0)
        val progress = if (rawProgress.isNaN() || rawProgress.isInfinite()) {
            0.0
        } else {
            rawProgress.coerceIn(0.0, 1.0)
        }
        views.setProgressBar(
            R.id.widget_progress,
            PROGRESS_MAX,
            (progress * PROGRESS_MAX).roundToInt(),
            false,
        )

        val lat = coordinate(data, "lat", 90.0)
        val lng = coordinate(data, "lng", 180.0)
        if (lat != null && lng != null) {
            views.setOnClickPendingIntent(
                R.id.widget_navigate,
                navigateIntent(context, kind, lat, lng, customer),
            )
            views.setViewVisibility(R.id.widget_navigate, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_navigate, View.GONE)
        }
    }

    private fun renderStats(
        context: Context,
        views: RemoteViews,
        kind: WidgetKind,
        data: JSONObject,
        state: String,
        compact: Boolean,
    ) {
        val ok = applyState(context, views, kind, state)
        applyFooter(context, views, data, state, compact)

        // Insignia: solo "Total N" en la ruta del día.
        val total = if (kind == WidgetKind.ROUTE_DAY) intOrNull(data, "total") else null
        if (ok && total != null) {
            views.setTextViewText(
                R.id.widget_badge,
                context.getString(R.string.widget_total, total),
            )
            views.setViewVisibility(R.id.widget_badge, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_badge, View.GONE)
        }
        if (!ok) return

        // Las etiquetas y cuántas columnas se ven son fijas en cada layout.
        val accent = context.getColor(R.color.widget_accent)
        statsFor(kind).forEachIndexed { index, stat ->
            if (index >= VALUE_IDS.size) return@forEachIndexed
            val value = intOrNull(data, stat.key)
            val viewId = VALUE_IDS[index]
            views.setTextViewText(
                viewId,
                value?.toString() ?: context.getString(R.string.widget_no_value),
            )
            // Rojo de marca (igual en claro y oscuro) solo si hay algo que mirar;
            // si no, queda el color del layout (que sigue el modo oscuro).
            if (stat.danger && value != null && value > 0) views.setTextColor(viewId, accent)
        }

        if (kind == WidgetKind.PICKING_PENDING) {
            val scanRoute = routeOf(data, "scanRoute")
            if (scanRoute != null) {
                views.setOnClickPendingIntent(
                    R.id.widget_action,
                    openApp(context, kind, SLOT_SCAN, scanRoute),
                )
                views.setViewVisibility(R.id.widget_action, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_action, View.GONE)
            }
        }
    }

    private fun renderQuickScan(
        context: Context,
        views: RemoteViews,
        kind: WidgetKind,
        data: JSONObject,
        state: String,
    ) {
        val ok = state == WidgetStore.STATE_OK
        val label = if (ok) {
            str(data, "label") ?: context.getString(R.string.widget_action_scan)
        } else {
            context.getString(R.string.widget_action_sign_in)
        }
        // Solo ícono: el texto queda para lectores de pantalla. Sin sesión el
        // ícono se atenúa (ImageView.setImageAlpha es remotable).
        views.setContentDescription(R.id.widget_action, label)
        views.setInt(R.id.widget_action, "setImageAlpha", if (ok) 255 else 115)
        // Sin sesión: abre la app sin ruta (Dart muestra el login).
        val target = openApp(context, kind, SLOT_SCAN, if (ok) routeOf(data, "route") else null)
        views.setOnClickPendingIntent(R.id.widget_action, target)
        views.setOnClickPendingIntent(android.R.id.background, target)
    }

    private fun statsFor(kind: WidgetKind): List<Stat> = when (kind) {
        WidgetKind.ROUTE_DAY -> listOf(Stat("delivered"), Stat("pending"), Stat("failed", true))
        WidgetKind.PICKING_PENDING -> listOf(Stat("pending"), Stat("inProgress"))
        WidgetKind.STORE_RECEPTIONS -> listOf(Stat("incoming"), Stat("pickups"))
        WidgetKind.SUPERVISOR_SUMMARY ->
            listOf(Stat("delivered"), Stat("incidents", true), Stat("trucksOnRoute"))
        else -> emptyList()
    }

    // -------------------------------------------------------------- comunes

    private fun normalizeState(raw: String): String = when (raw) {
        WidgetStore.STATE_OK,
        WidgetStore.STATE_EMPTY,
        WidgetStore.STATE_NOT_ALLOWED -> raw
        else -> WidgetStore.STATE_SIGNED_OUT
    }

    /** Muestra el contenido (true) o el mensaje del estado (false). */
    private fun applyState(
        context: Context,
        views: RemoteViews,
        kind: WidgetKind,
        state: String,
    ): Boolean {
        val messageRes = when (state) {
            WidgetStore.STATE_OK -> null
            WidgetStore.STATE_EMPTY -> kind.emptyTextRes
            WidgetStore.STATE_NOT_ALLOWED -> R.string.widget_state_not_allowed
            else -> R.string.widget_state_signed_out
        }
        if (messageRes == null) {
            views.setViewVisibility(R.id.widget_content, View.VISIBLE)
            views.setViewVisibility(R.id.widget_message, View.GONE)
            return true
        }
        views.setViewVisibility(R.id.widget_content, View.GONE)
        views.setTextViewText(R.id.widget_message, context.getString(messageRes))
        views.setViewVisibility(R.id.widget_message, View.VISIBLE)
        return false
    }

    /** Pie "Actualizado 14:20" (hora local del teléfono). */
    private fun applyFooter(
        context: Context,
        views: RemoteViews,
        data: JSONObject,
        state: String,
        compact: Boolean,
    ) {
        val updatedAt = data.optLong("updatedAt", 0L)
        val show = !compact && updatedAt > 0L &&
            (state == WidgetStore.STATE_OK || state == WidgetStore.STATE_EMPTY)
        if (show) {
            val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(updatedAt))
            views.setTextViewText(
                R.id.widget_footer,
                context.getString(R.string.widget_updated_at, time),
            )
            views.setViewVisibility(R.id.widget_footer, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_footer, View.GONE)
        }
    }

    /**
     * Alto real del widget: en vertical es OPTION_APPWIDGET_MAX_HEIGHT y en
     * horizontal OPTION_APPWIDGET_MIN_HEIGHT (convención de AppWidgetManager).
     */
    private fun isCompact(context: Context, options: Bundle?): Boolean {
        if (options == null) return false
        val landscape =
            context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val key = if (landscape) {
            AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
        } else {
            AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
        }
        val height = options.getInt(key, 0)
        return height in 1 until COMPACT_HEIGHT_DP
    }

    private fun str(data: JSONObject, key: String): String? {
        if (!data.has(key) || data.isNull(key)) return null
        return data.optString(key).takeIf { it.isNotBlank() }
    }

    private fun intOrNull(data: JSONObject, key: String): Int? {
        if (!data.has(key) || data.isNull(key)) return null
        val value = data.optDouble(key)
        return if (value.isNaN() || value.isInfinite()) null else value.roundToInt()
    }

    private fun coordinate(data: JSONObject, key: String, limit: Double): Double? {
        if (!data.has(key) || data.isNull(key)) return null
        val value = data.optDouble(key)
        if (value.isNaN() || value.isInfinite() || value < -limit || value > limit) return null
        return value
    }

    /** Rutas go_router: solo las que empiezan con "/" (igual que AppShortcutsChannel). */
    private fun routeOf(data: JSONObject, key: String): String? =
        str(data, key)?.takeIf { it.startsWith("/") }

    private fun openApp(
        context: Context,
        kind: WidgetKind,
        slot: Int,
        route: String?,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            // Mismo intent que los accesos directos (AppShortcutsChannel). Sin
            // data URI a propósito: el deep linking de Flutter la tomaría como
            // ruta inicial.
            action = Intent.ACTION_VIEW
            if (route != null) putExtra(AppShortcutsChannel.EXTRA_ROUTE, route)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        // FLAG_UPDATE_CURRENT reemplaza los extras (y los quita si ahora no
        // hay ruta); requestCode único por kind + acción.
        return PendingIntent.getActivity(
            context,
            kind.requestBase + slot,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** geo:lat,lng?q=lat,lng(Cliente): Google Maps / Waze abren listos para navegar. */
    private fun navigateIntent(
        context: Context,
        kind: WidgetKind,
        lat: Double,
        lng: Double,
        label: String,
    ): PendingIntent {
        val coords = String.format(Locale.US, "%.6f,%.6f", lat, lng)
        val query = coords + if (label.isNotBlank()) "(${Uri.encode(label)})" else ""
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("geo:$coords?q=$query"))
        return PendingIntent.getActivity(
            context,
            kind.requestBase + SLOT_NAVIGATE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
