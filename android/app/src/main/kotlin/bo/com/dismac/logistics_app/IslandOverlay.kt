package bo.com.dismac.logistics_app

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * "Isla de DisTrack": pastilla flotante arriba al centro (bajo la barra de
 * estado / recorte de cámara) con la ruta del chofer, para teléfonos SIN Live
 * Updates de Android 16 (o si el chofer la prefiere). Android 7+ (API 24).
 *
 * - Compacta: camión + "3/7 · 08:15" (fondo #141414, texto blanco, acento rojo).
 * - Tocar → se expande (animación corta de ancho/alto, una sola vez) a una
 *   tarjeta con "Parada 3 de 7 · Llega 08:15", cliente, distancia y botones
 *   Navegar / Abrir (mismos intents que la notificación).
 * - Tocar afuera o deslizar hacia arriba → vuelve a compacta. Arrastrable en X.
 *
 * La decide y la mueve Dart (RouteLiveUpdatesController): se muestra SOLO con
 * la app en segundo plano y ruta activa, se actualiza con las mismas fotos (y
 * el mismo throttling) que la notificación y se quita al volver la app, al
 * terminar la ruta o al cerrar sesión. Sin timers ni animaciones en loop: la
 * vista es estática. Al ocultarla se hace removeView y se sueltan las
 * referencias (no queda memoria tomada).
 *
 * Requiere "Mostrar sobre otras apps" (SYSTEM_ALERT_WINDOW, lo declara el
 * manifest). Sin permiso, show() no hace nada y queda solo la notificación.
 */
object IslandOverlay {
    private const val BG = 0xFF141414.toInt()
    private const val RED = 0xFFE30613.toInt()
    private const val AMBER = 0xFFFFB000.toInt()
    private const val WHITE = 0xFFFFFFFF.toInt()
    private const val MUTED = 0xFFD6D6D6.toInt()
    private const val BUTTON_DARK = 0xFF2A2A2A.toInt()
    private const val ANIM_MS = 180L

    private var windowManager: WindowManager? = null
    private var params: WindowManager.LayoutParams? = null
    private var root: LinearLayout? = null
    private var background: GradientDrawable? = null
    private var compactText: TextView? = null
    private var expandedSection: LinearLayout? = null
    private var titleText: TextView? = null
    private var customerText: TextView? = null
    private var distanceText: TextView? = null
    private var navigateButton: TextView? = null
    private var animator: ValueAnimator? = null
    private var expanded = false

    // Destino de "Navegar".
    private var lat: Double? = null
    private var lng: Double? = null
    private var customer = ""

    /** La isla propia existe en todo Android soportado por la app (API 24+). */
    fun isSupported(): Boolean = true

    fun canDraw(context: Context): Boolean = Settings.canDrawOverlays(context)

    /** Ajuste "Mostrar sobre otras apps" de DisTrack (fallback: ficha de la app). */
    fun openSettings(context: Context): Boolean {
        val pkg = Uri.parse("package:${context.packageName}")
        val intents = listOf(
            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkg),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg),
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

    /** Muestra (o actualiza) la isla con la foto de la ruta. */
    fun show(context: Context, args: Map<*, *>): Boolean {
        val app = context.applicationContext
        if (!canDraw(app)) return false
        return try {
            if (root == null) create(app)
            bind(args)
            true
        } catch (e: Exception) {
            // El sistema rechazó la ventana (permiso revocado al vuelo, etc.).
            hide()
            false
        }
    }

    /** Quita la isla y suelta la vista. */
    fun hide() {
        animator?.cancel()
        animator = null
        val view = root
        if (view != null) {
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                // Ya no estaba adjunta.
            }
        }
        windowManager = null
        params = null
        root = null
        background = null
        compactText = null
        expandedSection = null
        titleText = null
        customerText = null
        distanceText = null
        navigateButton = null
        expanded = false
    }

    // ---------------------------------------------------------------- vista

    @SuppressLint("ClickableViewAccessibility")
    private fun create(context: Context) {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val bg = GradientDrawable().apply {
            setColor(BG)
            cornerRadius = dp(context, 999f)
        }
        val compactRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(context, 32f).roundToInt()
        }
        val icon = ImageView(context).apply {
            setImageResource(R.drawable.ic_stat_route)
            setColorFilter(RED)
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        val iconSize = dp(context, 18f).roundToInt()
        compactRow.addView(icon, LinearLayout.LayoutParams(iconSize, iconSize))
        val compact = text(context, 14f, WHITE, bold = true)
        compactRow.addView(
            compact,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { marginStart = dp(context, 6f).roundToInt() },
        )

        val title = text(context, 15f, WHITE, bold = true)
        val customerView = text(context, 14f, MUTED, bold = false)
        val distance = text(context, 13f, AMBER, bold = true)
        val navigate = button(context, "Navegar", RED) { openNavigation(context) }
        val open = button(context, "Abrir", BUTTON_DARK) { openApp(context) }
        val buttons = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(context, 10f).roundToInt(), 0, 0)
        }
        val buttonHeight = dp(context, 44f).roundToInt()
        buttons.addView(
            navigate,
            LinearLayout.LayoutParams(0, buttonHeight, 1f).apply {
                marginEnd = dp(context, 8f).roundToInt()
            },
        )
        buttons.addView(open, LinearLayout.LayoutParams(0, buttonHeight, 1f))
        val section = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            setPadding(0, dp(context, 8f).roundToInt(), 0, 0)
            addView(title)
            addView(customerView)
            addView(distance)
            addView(buttons)
        }

        val view = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = bg
            val h = dp(context, 14f).roundToInt()
            val v = dp(context, 4f).roundToInt()
            setPadding(h, v, h, v)
            elevation = dp(context, 6f)
            addView(compactRow)
            addView(
                section,
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ),
            )
        }

        val lp = WindowManager.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = 0
            y = topInset(context, wm) + dp(context, 4f).roundToInt()
        }

        view.setOnTouchListener(DragListener(context))
        wm.addView(view, lp)

        windowManager = wm
        params = lp
        root = view
        background = bg
        compactText = compact
        expandedSection = section
        titleText = title
        customerText = customerView
        distanceText = distance
        navigateButton = navigate
        expanded = false
    }

    private fun bind(args: Map<*, *>) {
        val stopIndex = (args["stopIndex"] as? Number)?.toInt() ?: 0
        val stopCount = (args["stopCount"] as? Number)?.toInt() ?: 0
        val status = args["status"] as? String
        val eta = args["etaText"] as? String
        val chip = args["chip"] as? String
        val counter = "$stopIndex/$stopCount"
        val second = when {
            status == "on_the_way" && !eta.isNullOrEmpty() -> eta
            !chip.isNullOrEmpty() && chip != counter -> chip
            else -> null
        }
        val compact = if (second == null) counter else "$counter · $second"
        compactText?.text = compact
        root?.contentDescription = args["title"] as? String ?: compact

        titleText?.text = args["title"] as? String ?: ""
        customer = args["customer"] as? String ?: ""
        customerText?.apply {
            text = customer
            visibility = if (customer.isEmpty()) View.GONE else View.VISIBLE
        }
        val distance = args["subText"] as? String
        distanceText?.apply {
            text = distance ?: ""
            visibility = if (distance.isNullOrEmpty()) View.GONE else View.VISIBLE
        }
        lat = (args["lat"] as? Number)?.toDouble()
        lng = (args["lng"] as? Number)?.toDouble()
        navigateButton?.visibility =
            if (lat != null && lng != null) View.VISIBLE else View.GONE
    }

    // ------------------------------------------------------ expandir / plegar

    private fun expand(context: Context) {
        val view = root ?: return
        val section = expandedSection ?: return
        if (expanded) return
        expanded = true
        val fromW = view.width
        val fromH = view.height
        section.visibility = View.VISIBLE
        background?.cornerRadius = dp(context, 20f)
        val screen = context.resources.displayMetrics.widthPixels
        val targetW = min(screen - dp(context, 32f).roundToInt(), dp(context, 420f).roundToInt())
        view.measure(
            View.MeasureSpec.makeMeasureSpec(targetW, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        )
        val targetH = view.measuredHeight
        params?.x = 0
        animateSize(fromW, fromH, targetW, targetH) {
            params?.height = ViewGroup.LayoutParams.WRAP_CONTENT
        }
    }

    private fun collapse(context: Context) {
        val view = root ?: return
        val section = expandedSection ?: return
        if (!expanded) return
        expanded = false
        val fromW = view.width
        val fromH = view.height
        section.visibility = View.GONE
        background?.cornerRadius = dp(context, 999f)
        view.measure(
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        )
        animateSize(fromW, fromH, view.measuredWidth, view.measuredHeight) {
            params?.width = ViewGroup.LayoutParams.WRAP_CONTENT
            params?.height = ViewGroup.LayoutParams.WRAP_CONTENT
        }
    }

    /** Una animación corta de ancho/alto (nada en loop). */
    private fun animateSize(fromW: Int, fromH: Int, toW: Int, toH: Int, onEnd: () -> Unit) {
        animator?.cancel()
        val anim = ValueAnimator.ofFloat(0f, 1f).setDuration(ANIM_MS)
        anim.addUpdateListener {
            val t = it.animatedValue as Float
            val lp = params ?: return@addUpdateListener
            lp.width = (fromW + (toW - fromW) * t).roundToInt()
            lp.height = (fromH + (toH - fromH) * t).roundToInt()
            relayout()
        }
        anim.addListener(object : android.animation.AnimatorListenerAdapter() {
            private var canceled = false

            override fun onAnimationCancel(animation: android.animation.Animator) {
                canceled = true
            }

            override fun onAnimationEnd(animation: android.animation.Animator) {
                if (animator === anim) animator = null
                if (canceled) return
                onEnd()
                relayout()
            }
        })
        animator = anim
        anim.start()
    }

    private fun relayout() {
        val view = root ?: return
        val lp = params ?: return
        try {
            windowManager?.updateViewLayout(view, lp)
        } catch (e: Exception) {
            // La vista ya no está adjunta.
        }
    }

    // --------------------------------------------------------------- toques

    /** Arrastre en X, toque para expandir, deslizar arriba / tocar afuera para plegar. */
    private class DragListener(private val context: Context) : View.OnTouchListener {
        private val slop = ViewConfiguration.get(context).scaledTouchSlop
        private var downX = 0f
        private var downY = 0f
        private var startX = 0
        private var dragging = false

        @SuppressLint("ClickableViewAccessibility")
        override fun onTouch(v: View, event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_OUTSIDE -> {
                    collapse(context)
                    return false
                }
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = params?.x ?: 0
                    dragging = false
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (!dragging && abs(dx) > slop && abs(dx) > abs(dy)) dragging = true
                    if (dragging) {
                        val lp = params ?: return true
                        val screen = context.resources.displayMetrics.widthPixels
                        val limit = max(0, (screen - v.width) / 2)
                        lp.x = (startX + dx.roundToInt()).coerceIn(-limit, limit)
                        relayout()
                    }
                    return true
                }
                MotionEvent.ACTION_UP -> {
                    val dy = event.rawY - downY
                    when {
                        dragging -> Unit
                        dy < -dp(context, 24f) -> collapse(context)
                        abs(dy) <= slop && !expanded -> expand(context)
                    }
                    dragging = false
                    return true
                }
                MotionEvent.ACTION_CANCEL -> {
                    dragging = false
                    return true
                }
            }
            return false
        }
    }

    private fun openNavigation(context: Context) {
        val la = lat ?: return
        val ln = lng ?: return
        start(context, LiveUpdatesChannel.navigateRawIntent(la, ln, customer))
        collapse(context)
    }

    private fun openApp(context: Context) {
        start(context, LiveUpdatesChannel.openAppRawIntent(context))
        collapse(context)
    }

    private fun start(context: Context, intent: Intent) {
        try {
            // Desde la ventana flotante (no es una Activity): tarea nueva. Con
            // el permiso de superposición el sistema permite abrir desde 2.º plano.
            context.startActivity(Intent(intent).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: ActivityNotFoundException) {
            // Sin app de mapas: no se hace nada.
        }
    }

    // -------------------------------------------------------------- helpers

    @Suppress("DEPRECATION")
    private fun overlayType(): Int =
        if (Build.VERSION.SDK_INT >= 26) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

    /**
     * Margen superior: barra de estado + recorte de cámara. API 30+: insets
     * reales de la ventana; antes, el alto de la barra de estado (en 28–29 el
     * recorte queda dentro de la barra de estado).
     */
    @SuppressLint("DiscouragedApi", "InternalInsetResource")
    private fun topInset(context: Context, wm: WindowManager): Int {
        if (Build.VERSION.SDK_INT >= 30) {
            try {
                return wm.currentWindowMetrics.windowInsets
                    .getInsets(WindowInsets.Type.statusBars() or WindowInsets.Type.displayCutout())
                    .top
            } catch (e: Exception) {
                // Sigue con el alto de la barra de estado.
            }
        }
        val id = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (id > 0) {
            context.resources.getDimensionPixelSize(id)
        } else {
            dp(context, 24f).roundToInt()
        }
    }

    private fun text(context: Context, sizeSp: Float, color: Int, bold: Boolean): TextView =
        TextView(context).apply {
            setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
            setTextColor(color)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            if (bold) setTypeface(typeface, Typeface.BOLD)
        }

    private fun button(context: Context, label: String, color: Int, onTap: () -> Unit): TextView =
        text(context, 14f, WHITE, bold = true).apply {
            text = label
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(color)
                cornerRadius = dp(context, 12f)
            }
            isClickable = true
            setOnClickListener { onTap() }
        }

    private fun dp(context: Context, value: Float): Float =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value,
            context.resources.displayMetrics,
        )
}
