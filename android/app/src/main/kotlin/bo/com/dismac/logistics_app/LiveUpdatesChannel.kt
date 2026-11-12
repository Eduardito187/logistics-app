package bo.com.dismac.logistics_app

import android.annotation.TargetApi
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Ruta del chofer "en vivo" en la barra de estado. Contraparte Dart:
 * lib/core/live_updates/ (LiveUpdatesService + RouteLiveUpdatesController).
 *
 * - "isSupported" → {android: {promoted: Boolean, sdk: Int}, ios: {liveActivities: false}}
 * - "promotionStatus" → {sdk, canPostPromoted, promotable, promotedNow, channelImportance, reasons:[…]}
 * - "openPromotionSettings" → Boolean (ajustes "Live updates" de la app; fallback: notificaciones)
 * - "start" / "update" (mapa de RouteLiveStatus.toMap) → Boolean
 * - "end" (mapa opcional con el estado final) → Boolean
 * - "setPromotionEnabled" {enabled} → Boolean (apagado con la isla de DisTrack: una sola isla)
 * - "overlayStatus" / "openOverlaySettings" / "overlayShow" / "overlayHide": isla de
 *   DisTrack (pastilla flotante propia, Android 7+), ver IslandOverlay.
 *
 * UNA sola notificación (id 4120 = `routeLiveNotificationId` en Dart): el
 * foreground service del rastreo (flutter_foreground_task) arranca con ese
 * mismo `serviceId`. Al publicar acá con el id del servicio, Android le
 * re-aplica FLAG_FOREGROUND_SERVICE y usa el canal de ESTA publicación
 * ("route_live"), así no queda una segunda notificación "silenciada" en el
 * canal del plugin. Mientras el servicio corre, `cancel` no tiene efecto (el
 * sistema no deja quitar la notificación de un FGS): por eso "end" la deja
 * con texto neutro y se va sola cuando el rastreo baja el servicio.
 *
 * Canal propio "route_live" (importancia DEFAULT, sin sonido ni vibración,
 * setOnlyAlertOnce: los updates no suenan).
 *
 * Android 16 (API 36): Notification.ProgressStyle con un segmento por parada,
 * puntos en las paradas atendidas y el camión como "tracker"; texto corto en
 * el chip de la barra de estado (setShortCriticalText) y pedido de promoción
 * (Live Update: chip / Now Bar / Live Alerts / cápsula según el fabricante).
 * Requisitos de promoción que se cumplen acá: ongoing, contentTitle, estilo
 * estándar o Progress, sin customContentView, NO colorizada, canal no MIN y
 * el extra "android.requestPromotedOngoing". Android 8–15: barra de progreso
 * clásica. Android 7 (24–25): mismo diseño con el constructor sin canal.
 *
 * Xiaomi/Redmi/POCO (HyperOS): además, best-effort, el extra
 * "miui.focus.param" (notificación de foco / Super Island). Otros sistemas lo
 * ignoran.
 *
 * Acciones: "Navegar" (geo: → Google Maps / Waze) y "Abrir" (la app en la
 * entrega en curso; usa el extra de AppShortcutsChannel para que Dart navegue).
 *
 * Además registra ScreenChannel (brillo al mostrar un QR) para no tocar
 * MainActivity.
 */
object LiveUpdatesChannel {
    private const val CHANNEL = "bo.com.dismac/live_updates"
    private const val NOTIFICATION_CHANNEL_ID = "route_live"

    // = routeLiveNotificationId (lib/core/live_updates/route_live_notification.dart)
    // = serviceId del foreground service del rastreo. NO cambiar uno sin el otro.
    private const val NOTIFICATION_ID = 4120
    private const val DELIVERY_ROUTE = "/driver/delivery"

    // Texto neutro con el servicio corriendo y sin ruta (= routeLiveFallback* en Dart).
    private const val FALLBACK_TITLE = "DisTrack"
    private const val FALLBACK_TEXT = "En servicio"

    // EXTRA_REQUEST_PROMOTED_ONGOING no está en el android.jar público de
    // compileSdk 36: se usa el literal (Notification.EXTRA_REQUEST_PROMOTED_ONGOING).
    private const val EXTRA_REQUEST_PROMOTED = "android.requestPromotedOngoing"

    // HyperOS: parámetros de la notificación de foco (JSON "param_v2").
    private const val EXTRA_MIUI_FOCUS = "miui.focus.param"

    // Topes de ProgressStyle (el sistema descarta lo que exceda).
    private const val MAX_SEGMENTS = 15
    private const val MAX_POINTS = 15
    private const val SEGMENT_LENGTH = 100

    // Marca DisTrack.
    private const val BRAND_RED = 0xFFE30613.toInt()
    private const val BRAND_AMBER = 0xFFFFB000.toInt()
    private const val BRAND_GREY = 0xFF9E9E9E.toInt()

    private const val REQUEST_OPEN = 4121
    private const val REQUEST_NAVIGATE = 4122

    // Foto de muestra para diagnosticar la promoción antes de la primera ruta.
    private val SAMPLE_ARGS: Map<String, Any> = mapOf(
        "title" to "Parada 1 de 3",
        "body" to "Cliente",
        "stopCount" to 3,
        "completed" to 1,
        "chip" to "1/3",
    )

    private var channelCreated = false

    /** Último estado publicado (diagnóstico de promoción); null tras "end". */
    private var lastArgs: Map<*, *>? = null

    /**
     * Pedir la promoción de Android 16 (chip / Now Bar). Dart la apaga cuando
     * la isla elegida es la de DisTrack, para no mostrar dos islas.
     */
    private var promoteEnabled = true

    /** Hora fija de la notificación mientras dura la ruta (orden estable). */
    private var postedAt = 0L

    fun register(engine: FlutterEngine, activity: Activity) {
        // Contexto de aplicación: el canal no retiene la Activity.
        val context = activity.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isSupported" -> result.success(
                            mapOf(
                                "android" to mapOf(
                                    "promoted" to canPromote(context),
                                    "sdk" to Build.VERSION.SDK_INT,
                                ),
                                "ios" to mapOf("liveActivities" to false),
                            )
                        )
                        "promotionStatus" -> result.success(promotionStatus(context))
                        "openPromotionSettings" -> result.success(openPromotionSettings(context))
                        "start", "update" -> {
                            val args = call.arguments as? Map<*, *>
                            if (args == null) {
                                result.error("bad_args", "Falta el estado de la ruta", null)
                            } else {
                                result.success(show(context, args))
                            }
                        }
                        "end" -> result.success(end(context, call.arguments as? Map<*, *>))
                        "setPromotionEnabled" -> {
                            promoteEnabled = (call.argument<Boolean>("enabled")) ?: true
                            result.success(true)
                        }
                        "overlayStatus" -> result.success(
                            mapOf(
                                "supported" to IslandOverlay.isSupported(),
                                "granted" to IslandOverlay.canDraw(context),
                            )
                        )
                        "openOverlaySettings" -> result.success(
                            IslandOverlay.openSettings(context)
                        )
                        "overlayShow" -> {
                            val args = call.arguments as? Map<*, *>
                            if (args == null) {
                                result.error("bad_args", "Falta el estado de la ruta", null)
                            } else {
                                result.success(IslandOverlay.show(context, args))
                            }
                        }
                        "overlayHide" -> {
                            IslandOverlay.hide()
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("live_updates", e.message, null)
                }
            }
        ScreenChannel.register(engine, activity)
    }

    private fun manager(context: Context): NotificationManager? =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager

    private fun canPromote(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        return try {
            manager(context)?.canPostPromotedNotifications() ?: false
        } catch (t: Throwable) {
            // ROM sin la API (no debería pasar en 36): sin promoción.
            false
        }
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (channelCreated || Build.VERSION.SDK_INT < 26) return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Ruta en curso",
            // DEFAULT (no MIN ni LOW): Live Updates no promueve canales MIN.
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Parada actual, hora de llegada y avance de la ruta"
            setSound(null, null)
            enableVibration(false)
            enableLights(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        manager.createNotificationChannel(channel)
        channelCreated = true
    }

    private fun show(context: Context, args: Map<*, *>): Boolean {
        val manager = manager(context) ?: return false
        if (!manager.areNotificationsEnabled()) return false
        ensureChannel(manager)
        if (lastArgs == null || postedAt == 0L) postedAt = System.currentTimeMillis()
        val notification = buildNotification(context, args)
        lastArgs = args
        manager.notify(NOTIFICATION_ID, notification)
        return true
    }

    /**
     * Fin de la ruta en vivo. Sin foreground service: se quita. Con el servicio
     * del rastreo corriendo (la notificación es la suya y `cancel` no la quita):
     * queda con el estado final ("Ruta completada") o el texto neutro, sin
     * promoción, hasta que el rastreo baje el servicio.
     */
    private fun end(context: Context, last: Map<*, *>?): Boolean {
        val manager = manager(context) ?: return false
        lastArgs = null
        postedAt = 0L
        if (isForegroundServiceNotification(manager)) {
            ensureChannel(manager)
            manager.notify(NOTIFICATION_ID, neutralNotification(context, last))
        } else {
            manager.cancel(NOTIFICATION_ID)
        }
        return true
    }

    /** ¿La notificación 4120 visible es la del foreground service? */
    private fun isForegroundServiceNotification(manager: NotificationManager): Boolean =
        try {
            manager.activeNotifications.any {
                it.id == NOTIFICATION_ID &&
                    (it.notification.flags and Notification.FLAG_FOREGROUND_SERVICE) != 0
            }
        } catch (e: Exception) {
            false
        }

    private fun neutralNotification(context: Context, last: Map<*, *>?): Notification {
        val finished = last?.get("status") == "finished"
        val title = if (finished) last?.get("title") as? String ?: FALLBACK_TITLE else FALLBACK_TITLE
        val text = if (finished) last?.get("body") as? String ?: FALLBACK_TEXT else FALLBACK_TEXT
        val builder = newBuilder(context)
            .setSmallIcon(R.drawable.ic_stat_route)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setUsesChronometer(false)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setColor(BRAND_RED)
            .setContentIntent(openAppIntent(context))
        applyCommon(builder)
        return builder.build()
    }

    /** Arma la notificación de ruta (también se usa para diagnosticar la promoción). */
    private fun buildNotification(context: Context, args: Map<*, *>): Notification {
        val title = args["title"] as? String ?: "Ruta en curso"
        val body = args["body"] as? String ?: ""
        val subText = args["subText"] as? String
        val chip = args["chip"] as? String
        val publicTitle = args["publicTitle"] as? String ?: title
        val stopCount = (args["stopCount"] as? Number)?.toInt() ?: 0
        val completed = (args["completed"] as? Number)?.toInt() ?: 0
        val lat = (args["lat"] as? Number)?.toDouble()
        val lng = (args["lng"] as? Number)?.toDouble()
        val customer = args["customer"] as? String ?: ""
        val `when` = if (postedAt > 0L) postedAt else System.currentTimeMillis()

        val openIntent = openAppIntent(context)
        val builder = newBuilder(context)
            .setSmallIcon(R.drawable.ic_stat_route)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            // Hora fija del inicio (orden estable) y oculta: la ETA va en el
            // título y en el chip (setShortCriticalText), no un cronómetro.
            .setWhen(`when`)
            .setShowWhen(false)
            .setUsesChronometer(false)
            .setCategory(Notification.CATEGORY_NAVIGATION)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            // Color de acento (ícono/acciones). NO setColorized(true): una
            // notificación colorizada no se promueve.
            .setColor(BRAND_RED)
            .setContentIntent(openIntent)
            // Pantalla bloqueada: sin el nombre del cliente.
            .setPublicVersion(
                newBuilder(context)
                    .setSmallIcon(R.drawable.ic_stat_route)
                    .setContentTitle(publicTitle)
                    .setColor(BRAND_RED)
                    .setShowWhen(false)
                    .build()
            )
        applyCommon(builder)
        if (!subText.isNullOrEmpty()) builder.setSubText(subText)

        if (lat != null && lng != null) {
            builder.addAction(
                Notification.Action.Builder(
                    // Link al mapa → ícono de mapa (no el camión, que es el estado).
                    Icon.createWithResource(context, R.drawable.ic_action_map),
                    "Navegar",
                    navigateIntent(context, lat, lng, customer),
                ).build()
            )
        }
        builder.addAction(
            Notification.Action.Builder(
                // Abre la app → ícono "abrir en la app".
                Icon.createWithResource(context, R.drawable.ic_action_open),
                "Abrir",
                openIntent,
            ).build()
        )

        val total = stopCount.coerceAtLeast(0)
        val done = completed.coerceIn(0, total)
        if (Build.VERSION.SDK_INT >= 36) {
            applyLiveUpdate(context, builder, total, done, chip)
        } else if (total > 0) {
            builder.setProgress(total, done, false)
        }
        if (isXiaomi()) applyXiaomiFocus(builder, title, body, chip, total, done)
        return builder.build()
    }

    /** Ajustes comunes por versión: sin colorizar y visible al instante como FGS. */
    private fun applyCommon(builder: Notification.Builder) {
        if (Build.VERSION.SDK_INT >= 26) builder.setColorized(false)
        if (Build.VERSION.SDK_INT >= 31) {
            // Si es la notificación del foreground service, que no se demore 10 s.
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }
    }

    /** Android 16: ProgressStyle por paradas + chip + pedido de promoción. */
    @TargetApi(36)
    private fun applyLiveUpdate(
        context: Context,
        builder: Notification.Builder,
        total: Int,
        done: Int,
        chip: String?,
    ) {
        if (Build.VERSION.SDK_INT < 36) return
        if (total > 0) {
            val style = Notification.ProgressStyle()
                .setStyledByProgress(true)
                .setProgressTrackerIcon(
                    Icon.createWithResource(context, R.drawable.ic_stat_route)
                )
            if (total <= MAX_SEGMENTS) {
                // Un tramo por parada (como la barra de la app).
                for (i in 0 until total) {
                    style.addProgressSegment(
                        Notification.ProgressStyle.Segment(SEGMENT_LENGTH).setColor(BRAND_RED)
                    )
                }
            } else {
                style.addProgressSegment(
                    Notification.ProgressStyle.Segment(SEGMENT_LENGTH * total).setColor(BRAND_RED)
                )
            }
            // Un punto al final de cada parada ya atendida.
            val points = done.coerceAtMost(MAX_POINTS)
            for (i in 1..points) {
                val position = i * SEGMENT_LENGTH
                style.addProgressPoint(
                    Notification.ProgressStyle.Point(position)
                        .setColor(if (i == done) BRAND_AMBER else BRAND_GREY)
                )
            }
            style.setProgress(done * SEGMENT_LENGTH)
            builder.setStyle(style)
        }
        // Con la isla de DisTrack elegida: sin chip ni promoción (una sola isla).
        if (!promoteEnabled) return
        // Texto del chip de la barra de estado (≤ ~7 caracteres: "08:15", "3/8").
        if (!chip.isNullOrEmpty()) builder.setShortCriticalText(chip)
        builder.extras.putBoolean(EXTRA_REQUEST_PROMOTED, true)
    }

    private fun isXiaomi(): Boolean {
        val maker = "${Build.MANUFACTURER} ${Build.BRAND}".lowercase()
        return maker.contains("xiaomi") || maker.contains("redmi") || maker.contains("poco")
    }

    /**
     * HyperOS (Xiaomi/Redmi/POCO), best-effort y sin dependencias: notificación
     * de foco ("miui.focus.param", JSON "param_v2" del protocolo público). El
     * sistema decide si la muestra en la Super Island (puede exigir que la app
     * esté habilitada por Xiaomi); si no, queda la notificación estándar. En
     * HyperOS 3 (Android 16) el camino estándar de Live Updates también aplica.
     */
    private fun applyXiaomiFocus(
        builder: Notification.Builder,
        title: String,
        body: String,
        chip: String?,
        total: Int,
        done: Int,
    ) {
        try {
            val paramV2 = JSONObject()
                .put("protocol", 1)
                .put("ticker", chip?.takeIf { it.isNotEmpty() } ?: title)
                .put("updatable", true)
                .put("enableFloat", false)
                .put(
                    "baseInfo",
                    JSONObject()
                        .put("type", 1)
                        .put("title", title)
                        .put("content", body),
                )
            if (total > 0) {
                paramV2.put(
                    "progressInfo",
                    JSONObject().put("progress", done * 100 / total),
                )
            }
            builder.extras.putString(
                EXTRA_MIUI_FOCUS,
                JSONObject().put("param_v2", paramV2).toString(),
            )
        } catch (e: Exception) {
            // Solo un extra: la notificación estándar sigue igual.
        }
    }

    /**
     * Diagnóstico de la promoción (Live Updates, Android 16):
     * {sdk, canPostPromoted, promotable, promotedNow, channelImportance, reasons}.
     * Razones: sdk, notificationsDisabled, channelBlocked, channelImportanceMin,
     * promotionDenied, colorized, notOngoing, noTitle, notPromotable.
     */
    private fun promotionStatus(context: Context): Map<String, Any?> {
        val sdk = Build.VERSION.SDK_INT
        val reasons = mutableListOf<String>()
        var canPostPromoted = false
        var promotable = false
        var promotedNow = false
        var importance: Int? = null
        val manager = manager(context)
        if (sdk < 36) reasons.add("sdk")
        if (manager == null || !manager.areNotificationsEnabled()) {
            reasons.add("notificationsDisabled")
        }
        if (manager != null && sdk >= 26) {
            ensureChannel(manager)
            importance = manager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)?.importance
            when (importance) {
                NotificationManager.IMPORTANCE_NONE -> reasons.add("channelBlocked")
                NotificationManager.IMPORTANCE_MIN -> reasons.add("channelImportanceMin")
            }
        }
        if (manager != null && sdk >= 36) {
            canPostPromoted = canPromote(context)
            if (!canPostPromoted) reasons.add("promotionDenied")
            val notification = buildNotification(context, lastArgs ?: SAMPLE_ARGS)
            promotable = hasPromotableCharacteristics(notification)
            if (notification.extras.getBoolean(Notification.EXTRA_COLORIZED)) {
                reasons.add("colorized")
            }
            if ((notification.flags and Notification.FLAG_ONGOING_EVENT) == 0) {
                reasons.add("notOngoing")
            }
            if (notification.extras.getCharSequence(Notification.EXTRA_TITLE).isNullOrEmpty()) {
                reasons.add("noTitle")
            }
            if (!promotable) reasons.add("notPromotable")
            promotedNow = isPromotedNow(manager)
        }
        return mapOf(
            "sdk" to sdk,
            "canPostPromoted" to canPostPromoted,
            "promotable" to promotable,
            "promotedNow" to promotedNow,
            "channelImportance" to importance,
            "reasons" to reasons,
        )
    }

    @TargetApi(36)
    private fun hasPromotableCharacteristics(notification: Notification): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        return try {
            notification.hasPromotableCharacteristics()
        } catch (t: Throwable) {
            false
        }
    }

    /** ¿La notificación visible ya quedó promovida (FLAG_PROMOTED_ONGOING)? */
    @TargetApi(36)
    private fun isPromotedNow(manager: NotificationManager): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        return try {
            manager.activeNotifications.any {
                it.id == NOTIFICATION_ID &&
                    (it.notification.flags and Notification.FLAG_PROMOTED_ONGOING) != 0
            }
        } catch (t: Throwable) {
            false
        }
    }

    /**
     * Ajustes del sistema para activar "Live updates" de la app (Android 16);
     * si el teléfono no tiene esa pantalla, los de notificaciones de la app y,
     * en última instancia, la ficha de la app.
     */
    private fun openPromotionSettings(context: Context): Boolean {
        val pkg = context.packageName
        val intents = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= 36) {
            intents.add(
                Intent(Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
            )
        }
        if (Build.VERSION.SDK_INT >= 26) {
            intents.add(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
            )
        }
        intents.add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg"))
        )
        for (intent in intents) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (e: ActivityNotFoundException) {
                // Siguiente alternativa.
            } catch (e: SecurityException) {
                // Siguiente alternativa.
            }
        }
        return false
    }

    @Suppress("DEPRECATION")
    private fun newBuilder(context: Context): Notification.Builder =
        if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, NOTIFICATION_CHANNEL_ID)
        } else {
            // Android 7: sin canales; prioridad normal y sin sonido.
            Notification.Builder(context)
                .setPriority(Notification.PRIORITY_DEFAULT)
                .setSound(null)
                .setVibrate(null)
        }

    /** Intent que abre la app en "Entrega en curso" (también lo usa la isla propia). */
    internal fun openAppRawIntent(context: Context): Intent =
        Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra(AppShortcutsChannel.EXTRA_ROUTE, DELIVERY_ROUTE)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

    /** geo:lat,lng?q=lat,lng(Cliente) (también lo usa la isla propia). */
    internal fun navigateRawIntent(lat: Double, lng: Double, label: String): Intent {
        val query = "$lat,$lng" + if (label.isNotEmpty()) "(${Uri.encode(label)})" else ""
        return Intent(Intent.ACTION_VIEW, Uri.parse("geo:$lat,$lng?q=$query")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    /** Abre la app en "Entrega en curso" (Dart lo recibe por el canal de accesos). */
    private fun openAppIntent(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            REQUEST_OPEN,
            openAppRawIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** geo:lat,lng?q=lat,lng(Cliente): Google Maps y Waze lo abren navegando. */
    private fun navigateIntent(
        context: Context,
        lat: Double,
        lng: Double,
        label: String,
    ): PendingIntent =
        PendingIntent.getActivity(
            context,
            REQUEST_NAVIGATE,
            navigateRawIntent(lat, lng, label),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
