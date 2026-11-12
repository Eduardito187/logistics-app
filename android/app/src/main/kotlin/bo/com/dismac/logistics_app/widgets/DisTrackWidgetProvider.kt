package bo.com.dismac.logistics_app.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle

/**
 * Base de los widgets DisTrack. El sistema llama a onUpdate al colocar el
 * widget, al reiniciar el teléfono o al actualizar la app (updatePeriodMillis
 * es 0: no hay refresco periódico). Solo se lee el último dato guardado; sin
 * datos se muestra "Iniciá sesión en DisTrack". Nada de red ni timers.
 */
abstract class DisTrackWidgetProvider(private val kind: WidgetKind) : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        WidgetRenderer.render(context, appWidgetManager, appWidgetIds, kind)
    }

    // Al redimensionar: se re-pinta para ocultar/mostrar pie y dirección.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        WidgetRenderer.render(context, appWidgetManager, intArrayOf(appWidgetId), kind)
    }
}
