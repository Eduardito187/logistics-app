package bo.com.dismac.logistics_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

/**
 * Espejo de la ruta al reloj SIN app de reloj: una notificación NORMAL
 * (no-ongoing) que Samsung/Wear OS reflejan automáticamente, como las de
 * WhatsApp. Es aparte de la notificación de foreground service de la ruta —esa
 * es "ongoing" y los relojes NO la espejan— y de la isla del teléfono (overlay).
 *
 * Se postea SIEMPRE durante la ruta (solo la dispara `LiveUpdatesChannel`, que
 * ya corre únicamente para el chofer con ruta activa): el relay al reloj lo hace
 * el sistema (Galaxy Wearable / Wear OS), que NO depende de que la app vea el
 * reloj como "nodo" de la Data Layer de Google. Se quita al terminar ([clear]).
 */
object WearMirror {
    private const val CHANNEL = "route_watch"
    private const val ID = 4125

    /**
     * Postea/actualiza la notificación espejable de la ruta. Se postea SIEMPRE
     * durante la ruta: el espejado al reloj lo hace el relay del sistema (Galaxy
     * Wearable / Wear OS), que NO depende de que la app vea el reloj como "nodo"
     * de la Data Layer de Google. Gatearlo por `connectedNodes` dejaba sin
     * espejar al Samsung (que puede no figurar como nodo GMS). Es silenciosa y
     * se quita al terminar la ruta ([clear]); en el teléfono es una notificación
     * más durante el viaje (junto a la isla), el precio de no instalar app de reloj.
     */
    fun show(context: Context, args: Map<*, *>) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        if (!manager.areNotificationsEnabled()) return
        ensureChannel(manager, context)

        val title = args["title"] as? String ?: "Ruta en curso"
        val body = (args["body"] as? String)?.takeIf { it.isNotEmpty() }
            ?: (args["customer"] as? String ?: "")

        val builder = newBuilder(context)
            .setSmallIcon(R.drawable.ic_stat_route)
            .setContentTitle(title)
            .setContentText(body)
            // BigTextStyle: estándar universal, el reloj (cualquier marca) muestra
            // el texto completo y lo renderiza en su propio estilo circular/cuadrado.
            .setStyle(Notification.BigTextStyle().bigText(body).setBigContentTitle(title))
            // CLAVE para el espejado: NO ongoing (si no, el reloj la filtra como
            // hace con la del foreground service) y NO local-only (permite que
            // viaje al reloj). setOnlyAlertOnce: los updates no vuelven a sonar.
            .setOngoing(false)
            .setLocalOnly(false)
            .setOnlyAlertOnce(true)
            .setColor(0xFFE30613.toInt())
            .setContentIntent(
                android.app.PendingIntent.getActivity(
                    context,
                    4126,
                    LiveUpdatesChannel.openAppRawIntent(context),
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                        android.app.PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        try {
            manager.notify(ID, builder.build())
        } catch (t: Throwable) {
            // Sin permiso de notificaciones: no es crítico.
        }
    }

    /** Quita la notificación del reloj (fin de ruta). */
    fun clear(context: Context) {
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
            ?.cancel(ID)
    }

    private fun ensureChannel(manager: NotificationManager, context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        if (manager.getNotificationChannel(CHANNEL) != null) return
        // IMPORTANCE_DEFAULT con sonido por defecto: los relojes (Galaxy
        // Wearable / Wear OS) espejan las notificaciones que ALERTAN; una
        // totalmente silenciosa puede quedar filtrada y no llegar al reloj (como
        // WhatsApp, que suena). Con `setOnlyAlertOnce(true)` en el builder solo
        // alerta la PRIMERA vez de cada ruta; los updates de la misma parada no
        // vuelven a sonar. Sin badge en el ícono de la app.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                "Ruta en el reloj",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Próxima parada reflejada en tu reloj"
                setShowBadge(false)
            },
        )
    }

    @Suppress("DEPRECATION")
    private fun newBuilder(context: Context): Notification.Builder =
        if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, CHANNEL)
        } else {
            Notification.Builder(context).setPriority(Notification.PRIORITY_DEFAULT)
        }
}
