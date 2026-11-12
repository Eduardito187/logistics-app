package bo.com.dismac.logistics_app.widgets

import android.appwidget.AppWidgetProvider
import bo.com.dismac.logistics_app.R

/**
 * Tipos de widget de la pantalla de inicio. [key] es el "kind" del contrato
 * con Dart (canal bo.com.dismac/widgets) y la clave en SharedPreferences.
 *
 * [requestBase]: base de los requestCode de los PendingIntent de cada kind
 * (+0 abrir, +1 navegar, +2 escanear). Rango 7400–7459, lejos de los de
 * LiveUpdatesChannel (4121/4122): dos PendingIntent a MainActivity con el
 * mismo requestCode se pisarían los extras (FLAG_UPDATE_CURRENT).
 */
enum class WidgetKind(
    val key: String,
    val requestBase: Int,
    val layoutRes: Int,
    val emptyTextRes: Int,
) {
    NEXT_DELIVERY(
        "next_delivery", 7400, R.layout.widget_next_delivery, R.string.widget_empty_next_delivery,
    ),
    ROUTE_DAY("route_day", 7410, R.layout.widget_route_day, R.string.widget_empty_route_day),
    PICKING_PENDING(
        "picking_pending", 7420, R.layout.widget_picking_pending,
        R.string.widget_empty_picking_pending,
    ),
    STORE_RECEPTIONS(
        "store_receptions", 7430, R.layout.widget_store_receptions,
        R.string.widget_empty_store_receptions,
    ),
    SUPERVISOR_SUMMARY(
        "supervisor_summary", 7440, R.layout.widget_supervisor_summary,
        R.string.widget_empty_supervisor_summary,
    ),
    // quick_scan no tiene estado "vacío": siempre es el botón.
    QUICK_SCAN("quick_scan", 7450, R.layout.widget_quick_scan, R.string.widget_action_scan);

    /** Clase del AppWidgetProvider (receiver del manifest) de este kind. */
    val providerClass: Class<out AppWidgetProvider>
        get() = when (this) {
            NEXT_DELIVERY -> NextDeliveryWidget::class.java
            ROUTE_DAY -> RouteDayWidget::class.java
            PICKING_PENDING -> PickingPendingWidget::class.java
            STORE_RECEPTIONS -> StoreReceptionsWidget::class.java
            SUPERVISOR_SUMMARY -> SupervisorSummaryWidget::class.java
            QUICK_SCAN -> QuickScanWidget::class.java
        }

    companion object {
        fun fromKey(key: String?): WidgetKind? = entries.firstOrNull { it.key == key }
    }
}
