package bo.com.dismac.logistics_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Espejo de la ruta al RELOJ sin instalar ninguna app de reloj: una
 * notificación normal (id 4125, canal propio) que el reloj refleja y dibuja en
 * su estilo. Es aparte de la del foreground service de la ruta (id 4120), que es
 * "ongoing" y los relojes NO espejan.
 *
 * **NO-ongoing a propósito (nov 2026, pedido del dueño).** Antes era "ongoing"
 * (actividad en curso / chip). Problema: una ongoing NO se puede descartar y
 * "revivir" — el dueño la cerró en el reloj en la parada 1 y nunca volvió. Al
 * ser NO-ongoing, descartarla en el reloj se sincroniza al teléfono (el bridging
 * de Wear propaga el descarte) y la saca de las notificaciones activas; así, en
 * la SIGUIENTE actualización, [show] detecta que ya no está y la **vuelve a
 * publicar** (re-alertando una vez), de modo que reaparece en el reloj. Si sigue
 * visible, el update es silencioso (`setOnlyAlertOnce`).
 *
 * **Discreta en el teléfono.** Va en un canal de importancia LOW: en el teléfono
 * queda como una tarjeta silenciosa y colapsada (no compite con la isla/ruta,
 * que es la presencia principal), pero igual se espeja al reloj (el bridging no
 * depende de la importancia). No se puede hacer una notificación "solo reloj":
 * el reloj refleja lo del teléfono; lo más discreto posible es esto.
 *
 * **Anti-drenaje del reloj (nov 2026, crítico).** La notificación de ruta se
 * actualiza muy seguido (la distancia "A 2,3 km" tiquea ~cada 10 s). Antes
 * [show] re-publicaba 4125 en CADA tick → el reloj se despertaba/sincronizaba
 * cientos de veces por hora y se le iba la batería (86% en 2 h en pruebas). Ahora
 * [show] solo toca la notificación cuando cambia algo que el reloj realmente
 * muestra (parada, estado, cliente, avance); la **distancia NO va al reloj** (no
 * la necesita y es la que más tiquea). Un cambio REAL (avanzó la parada o el
 * estado, o había sido descartada) **re-alerta** para reaparecer; un cambio menor
 * (p. ej. solo la hora estimada) actualiza en silencio; si no cambió nada para el
 * reloj, no se toca la notificación.
 */
object WearMirror {
    // v2: el canal viejo "route_watch" quedó con importancia DEFAULT en los
    // equipos que ya corrieron una versión anterior (reinstalar conserva los
    // canales). Un id nuevo garantiza que rija la importancia LOW de abajo.
    private const val CHANNEL = "route_watch_v2"
    private const val OLD_CHANNEL = "route_watch"
    private const val ID = 4125
    private const val BRAND_RED = 0xFFE30613.toInt()
    private const val REQUEST_OPEN = 4126

    // Última firma publicada al reloj (lo que el reloj MUESTRA: título, cliente,
    // avance, estado) + avance/estado sueltos para decidir si re-alertar. La
    // distancia NO entra: es la que tiquea cada ~10 s y no se dibuja en el reloj.
    private var lastSignature: String? = null
    private var lastDone = -1
    private var lastStatus: String? = null

    /**
     * Postea/actualiza la notificación espejable de la ruta. Recibe el MISMO
     * mapa de estado que la isla (title="Parada N de M", body=cliente,
     * subText=hora, chip="N/M", stopCount, completed). Si fue descartada (en el
     * teléfono o en el reloj), la vuelve a publicar re-alertando; si sigue
     * visible, actualiza en silencio.
     */
    fun show(context: Context, args: Map<*, *>) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        if (!manager.areNotificationsEnabled()) return
        ensureChannel(manager)

        val title = (args["title"] as? String)?.takeIf { it.isNotEmpty() } ?: "Ruta en curso"
        val primary = (args["body"] as? String)?.takeIf { it.isNotEmpty() }
            ?: (args["customer"] as? String ?: "")
        val total = (args["stopCount"] as? Number)?.toInt() ?: 0
        val done = (args["completed"] as? Number)?.toInt()?.coerceIn(0, total) ?: 0
        val status = (args["status"] as? String) ?: ""
        // Lo que el reloj MUESTRA (sin distancia): si no cambió nada de esto y la
        // notificación sigue en la bandeja, NO se toca → el reloj no se despierta.
        val signature = "$title|$primary|$total|$done|$status"

        val stillVisible = isVisible(manager)
        if (signature == lastSignature && stillVisible) return

        // Cambio REAL para el reloj = avanzó la parada o cambió el estado, o había
        // sido descartada → re-alerta para REAPARECER (aunque la hayas cerrado).
        // Cambio menor (p. ej. solo la hora estimada en el título) → silencioso.
        val meaningful = done != lastDone || status != lastStatus || !stillVisible
        lastSignature = signature
        lastDone = done
        lastStatus = status

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
            .setStyle(NotificationCompat.BigTextStyle().bigText(primary))
            // NO-ongoing: descartable, para poder "revivirla" tras cerrarla.
            .setOngoing(false)
            // Espejable al reloj (no local-only).
            .setLocalOnly(false)
            // Silenciosa en cambios menores; re-alerta (reaparece) cuando avanza
            // la parada/estado o si había sido descartada.
            .setOnlyAlertOnce(!meaningful)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setColor(BRAND_RED)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(touch)
        // Barra de avance de la ruta (el reloj la dibuja junto al texto).
        if (total > 0) builder.setProgress(total, done, false)

        try {
            manager.notify(ID, builder.build())
        } catch (t: Throwable) {
            // Sin permiso de notificaciones: no es crítico.
        }
    }

    /** Quita la notificación del reloj (fin de ruta). */
    fun clear(context: Context) {
        lastSignature = null
        lastDone = -1
        lastStatus = null
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
            ?.cancel(ID)
    }

    /** ¿La notificación 4125 sigue en la bandeja (no fue descartada)? */
    private fun isVisible(manager: NotificationManager): Boolean =
        try {
            manager.activeNotifications.any { it.id == ID }
        } catch (t: Throwable) {
            // Sin acceso a las activas: se asume visible (update silencioso).
            true
        }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < 26) return
        // Limpia el canal viejo (importancia DEFAULT) para no dejar dos entradas
        // en los ajustes de notificaciones.
        try {
            manager.deleteNotificationChannel(OLD_CHANNEL)
        } catch (t: Throwable) {
            // No crítico.
        }
        if (manager.getNotificationChannel(CHANNEL) != null) return
        // LOW: discreta en el teléfono (sin heads-up ni sonido, colapsada bajo
        // la notificación de ruta), pero igual se espeja al reloj (el bridging
        // no depende de la importancia). Sin badge en el ícono de la app.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                "Ruta en el reloj",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Tu ruta en curso reflejada en el reloj"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            },
        )
    }
}
