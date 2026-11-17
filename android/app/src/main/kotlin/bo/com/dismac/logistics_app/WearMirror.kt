package bo.com.dismac.logistics_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status

/**
 * Espejo de la ruta al reloj SIN app de reloj, como ACTIVIDAD EN CURSO.
 *
 * Es una notificación aparte (id 4125, canal propio) de la del foreground
 * service de la ruta (esa es "ongoing" de FGS y los relojes NO la espejan) y de
 * la isla del teléfono (overlay). Novedad (nov 2026): se marca con la
 * **Ongoing Activity API** (`androidx.wear:wear-ongoing`), que hace que Wear OS
 * la muestre como un **chip en la cara del reloj** mientras dura la ruta, sin
 * instalar NADA en el reloj. Es PERSISTENTE (`ongoing`) y se ACTUALIZA sola en
 * cada parada (parada N de M, cliente, hora de llegada); `setOnlyAlertOnce`:
 * alerta la primera vez (así el reloj la engancha como las de WhatsApp) y los
 * updates no vuelven a sonar.
 *
 * Límite honesto: sigue siendo una NOTIFICACIÓN (no un tile/widget con diseño
 * propio, que exigiría app de reloj). Cuánto se destaca depende de la marca:
 * Wear OS (Samsung) la muestra como chip; otros relojes la listan como
 * notificación persistente. Es el precio de no instalar app de reloj, y en el
 * teléfono es una notificación más durante el viaje (junto a la isla).
 */
object WearMirror {
    private const val CHANNEL = "route_watch"
    private const val ID = 4125
    private const val BRAND_RED = 0xFFE30613.toInt()
    private const val REQUEST_OPEN = 4126

    /**
     * Postea/actualiza la actividad en curso espejable de la ruta. Recibe el
     * MISMO mapa de estado que la isla (title="Parada N de M", body=cliente,
     * subText=hora, chip="N/M", stopCount, completed). El espejado al reloj lo
     * hace el relay del sistema (Galaxy Wearable / Wear OS), que NO depende de
     * ver el reloj como "nodo" de la Data Layer de Google.
     */
    fun show(context: Context, args: Map<*, *>) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        if (!manager.areNotificationsEnabled()) return
        ensureChannel(manager)

        val title = (args["title"] as? String)?.takeIf { it.isNotEmpty() } ?: "Ruta en curso"
        val primary = (args["body"] as? String)?.takeIf { it.isNotEmpty() }
            ?: (args["customer"] as? String ?: "")
        val extra = (args["subText"] as? String)?.takeIf { it.isNotEmpty() }
        val chip = (args["chip"] as? String)?.takeIf { it.isNotEmpty() }
        val total = (args["stopCount"] as? Number)?.toInt() ?: 0
        val done = (args["completed"] as? Number)?.toInt()?.coerceIn(0, total) ?: 0
        val longText = listOf(primary, extra).filter { !it.isNullOrEmpty() }.joinToString("\n")

        val touch = PendingIntent.getActivity(
            context,
            REQUEST_OPEN,
            LiveUpdatesChannel.openAppRawIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_route)
            .setContentTitle(title)
            .setContentText(primary)
            .setStyle(NotificationCompat.BigTextStyle().bigText(longText))
            // Actividad en curso: persistente y espejable (NO local-only).
            .setOngoing(true)
            .setLocalOnly(false)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setColor(BRAND_RED)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(touch)
        // Barra de avance de la ruta (el reloj la dibuja junto al texto).
        if (total > 0) builder.setProgress(total, done, false)

        // Ongoing Activity: Wear OS la surface como CHIP en la cara del reloj.
        // El estado corto (chip "N/M" o el título) es lo que se ve de un vistazo.
        try {
            OngoingActivity.Builder(context, ID, builder)
                .setStaticIcon(R.drawable.ic_stat_route)
                .setTouchIntent(touch)
                .setStatus(
                    Status.Builder().addTemplate(chip ?: title).build(),
                )
                .build()
                .apply(context)
        } catch (t: Throwable) {
            // Si la API de Wear no estuviera disponible, queda la notificación
            // persistente normal (igual se espeja al reloj).
        }

        try {
            manager.notify(ID, builder.build())
        } catch (t: Throwable) {
            // Sin permiso de notificaciones: no es crítico.
        }
    }

    /** Quita la actividad del reloj (fin de ruta). */
    fun clear(context: Context) {
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
            ?.cancel(ID)
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < 26) return
        if (manager.getNotificationChannel(CHANNEL) != null) return
        // IMPORTANCE_DEFAULT: los relojes espejan las notificaciones que ALERTAN
        // al menos una vez; con `setOnlyAlertOnce(true)` solo suena la primera de
        // cada ruta. Sin badge en el ícono de la app.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                "Ruta en el reloj",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Tu ruta en curso reflejada en el reloj"
                setShowBadge(false)
            },
        )
    }
}
