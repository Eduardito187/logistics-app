package bo.com.dismac.logistics_app

import android.app.Activity
import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.InetAddress
import java.net.NetworkInterface

/**
 * Canal nativo de red para la búsqueda de impresoras WiFi. Contraparte Dart:
 * lib/core/printing/wifi_printer_scanner.dart.
 *
 * - "interfaces" → List<{name: String, ip: String, prefixLength: Int}>: una
 *   entrada por IPv4 de cada interfaz levantada y no loopback (con la máscara
 *   real, para no asumir /24). Ante cualquier error devuelve lista vacía.
 * - "discoverServices" {types: List<String>, timeoutMs: Int} →
 *   List<{name, type, host, port, txt: Map<String,String>}>: descubrimiento
 *   Bonjour/mDNS (DNS-SD) con NsdManager, deduplicado por host+port+type.
 *   Responde SIEMPRE dentro de timeoutMs + ~3 s (lista parcial o vacía).
 *
 * NsdManager toma por su cuenta el multicast lock: no hace falta el permiso
 * CHANGE_WIFI_MULTICAST_STATE.
 */
object NetworkChannel {
    private const val CHANNEL = "bo.com.dismac/network"

    fun register(engine: FlutterEngine, activity: Activity) {
        // Contexto de aplicación: el canal no debe retener la Activity.
        val context = activity.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "interfaces" -> interfaces(result)
                    "discoverServices" -> {
                        val types = (call.argument<List<Any?>>("types") ?: emptyList())
                            .mapNotNull { it as? String }
                            .filter { it.isNotBlank() }
                            .distinct()
                        val timeoutMs = (call.argument<Number>("timeoutMs")?.toLong() ?: 4000L)
                            .coerceIn(500L, 30_000L)
                        val nsd = context.getSystemService(Context.NSD_SERVICE) as? NsdManager
                        if (nsd == null || types.isEmpty()) {
                            result.success(emptyList<Map<String, Any>>())
                        } else {
                            ServiceDiscovery(nsd, types, timeoutMs, result).start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ---------------------------------------------------------------------
    // Interfaces
    // ---------------------------------------------------------------------

    /** Enumera fuera del hilo principal y responde en él. */
    private fun interfaces(result: MethodChannel.Result) {
        val main = Handler(Looper.getMainLooper())
        Thread {
            val list = try {
                readInterfaces()
            } catch (e: Throwable) {
                emptyList()
            }
            main.post { result.success(list) }
        }.apply {
            name = "NetworkChannel-interfaces"
            isDaemon = true
        }.start()
    }

    private fun readInterfaces(): List<Map<String, Any>> {
        val out = mutableListOf<Map<String, Any>>()
        val all = NetworkInterface.getNetworkInterfaces() ?: return out
        for (nif in all.toList()) {
            try {
                if (!nif.isUp || nif.isLoopback) continue
                for (address in nif.interfaceAddresses) {
                    val ip = address?.address as? Inet4Address ?: continue
                    if (ip.isLoopbackAddress) continue
                    val text = ip.hostAddress ?: continue
                    val prefix = address.networkPrefixLength.toInt()
                    out.add(
                        mapOf(
                            "name" to (nif.name ?: ""),
                            "ip" to text,
                            "prefixLength" to prefix.coerceIn(0, 32),
                        ),
                    )
                }
            } catch (e: Throwable) {
                // Una interfaz rara (p.ej. que desaparece mientras se lee) no
                // debe tumbar al resto.
            }
        }
        return out
    }

    // ---------------------------------------------------------------------
    // Descubrimiento DNS-SD
    // ---------------------------------------------------------------------

    /**
     * Una búsqueda: un DiscoveryListener por tipo durante [timeoutMs]; luego se
     * detienen y se resuelven en serie los servicios vistos (en API < 34
     * resolveService admite una sola resolución a la vez). Todo el estado se
     * toca solo en el hilo principal: los callbacks de NsdManager llegan en un
     * hilo interno y se re-postean al main.
     */
    private class ServiceDiscovery(
        private val nsd: NsdManager,
        private val types: List<String>,
        private val timeoutMs: Long,
        private val result: MethodChannel.Result,
    ) {
        private val main = Handler(Looper.getMainLooper())
        private val listeners = mutableListOf<NsdManager.DiscoveryListener>()

        // Servicios vistos (clave nombre+tipo) con el tipo pedido.
        private val found = LinkedHashMap<String, Pair<String, NsdServiceInfo>>()
        private val queue = ArrayDeque<Pair<String, NsdServiceInfo>>()
        private val resolved = LinkedHashMap<String, Map<String, Any>>()

        private var finished = false
        private var browsing = true

        // Identifica la resolución en curso: los callbacks de una resolución
        // que ya venció por timeout se ignoran.
        private var resolveToken = 0
        private var currentResolve: NsdManager.ResolveListener? = null

        fun start() {
            // Tope duro: pase lo que pase, se responde.
            main.postDelayed({ finish() }, timeoutMs + HARD_EXTRA_MS)
            main.postDelayed({ stopBrowsing() }, timeoutMs)
            for (type in types) {
                val listener = discoveryListener(type)
                try {
                    nsd.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, listener)
                    listeners.add(listener)
                } catch (e: Throwable) {
                    // Tipo inválido o NsdManager no disponible: se sigue con el resto.
                }
            }
        }

        private fun discoveryListener(type: String) = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String?) {}

            override fun onDiscoveryStopped(serviceType: String?) {}

            override fun onStartDiscoveryFailed(serviceType: String?, errorCode: Int) {}

            override fun onStopDiscoveryFailed(serviceType: String?, errorCode: Int) {}

            override fun onServiceFound(info: NsdServiceInfo?) {
                if (info == null) return
                main.post {
                    if (finished || !browsing) return@post
                    val name = info.serviceName ?: return@post
                    val key = "$name|$type"
                    if (!found.containsKey(key)) found[key] = type to info
                }
            }

            override fun onServiceLost(info: NsdServiceInfo?) {}
        }

        private fun stopBrowsing() {
            if (!browsing) return
            browsing = false
            stopListeners()
            if (finished) return
            queue.addAll(found.values)
            resolveNext()
        }

        private fun stopListeners() {
            for (listener in listeners) {
                try {
                    nsd.stopServiceDiscovery(listener)
                } catch (e: Throwable) {
                    // Listener que nunca arrancó o ya se detuvo.
                }
            }
            listeners.clear()
        }

        private fun resolveNext() {
            if (finished) return
            val next = queue.removeFirstOrNull()
            if (next == null) {
                finish()
                return
            }
            val (type, info) = next
            val token = ++resolveToken
            val listener = object : NsdManager.ResolveListener {
                override fun onServiceResolved(serviceInfo: NsdServiceInfo?) {
                    main.post {
                        if (token != resolveToken || finished) return@post
                        currentResolve = null
                        if (serviceInfo != null) addResolved(type, serviceInfo)
                        resolveNext()
                    }
                }

                override fun onResolveFailed(serviceInfo: NsdServiceInfo?, errorCode: Int) {
                    main.post {
                        if (token != resolveToken || finished) return@post
                        currentResolve = null
                        resolveNext()
                    }
                }
            }
            currentResolve = listener
            // Timeout por resolución: si NsdManager no contesta, se pasa al siguiente.
            main.postDelayed({
                if (token == resolveToken && !finished) {
                    cancelCurrentResolve()
                    resolveToken++
                    resolveNext()
                }
            }, RESOLVE_TIMEOUT_MS)
            try {
                @Suppress("DEPRECATION")
                nsd.resolveService(info, listener)
            } catch (e: Throwable) {
                // Se avanza en el siguiente ciclo (no recursivo en la pila).
                currentResolve = null
                resolveToken++
                main.post { resolveNext() }
            }
        }

        /** En API 34+ se puede cancelar una resolución colgada. */
        private fun cancelCurrentResolve() {
            val listener = currentResolve ?: return
            currentResolve = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                try {
                    nsd.stopServiceResolution(listener)
                } catch (e: Throwable) {
                    // Ya había terminado o no estaba registrada.
                }
            }
        }

        private fun addResolved(type: String, info: NsdServiceInfo) {
            val host = ipv4Of(info) ?: return
            val port = info.port
            if (port <= 0) return
            val key = "$host|$port|$type"
            if (resolved.containsKey(key)) return
            resolved[key] = mapOf(
                "name" to (info.serviceName ?: ""),
                "type" to type,
                "host" to host,
                "port" to port,
                "txt" to txtOf(info),
            )
        }

        private fun ipv4Of(info: NsdServiceInfo): String? {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                try {
                    val v4 = info.hostAddresses.firstOrNull { it is Inet4Address }
                    v4?.hostAddress?.let { return it }
                } catch (e: Throwable) {
                    // Se cae al host clásico.
                }
            }
            @Suppress("DEPRECATION")
            val host: InetAddress? = info.host
            return (host as? Inet4Address)?.hostAddress
        }

        private fun txtOf(info: NsdServiceInfo): Map<String, String> {
            val out = LinkedHashMap<String, String>()
            try {
                val attributes: Map<String?, ByteArray?> = info.attributes ?: return out
                for ((key, value) in attributes) {
                    if (key.isNullOrEmpty()) continue
                    out[key] = if (value == null) "" else String(value, Charsets.UTF_8)
                }
            } catch (e: Throwable) {
                // TXT malformado: se devuelve lo que se haya podido leer.
            }
            return out
        }

        /** Responde UNA sola vez, en el hilo principal, y libera todo. */
        private fun finish() {
            if (finished) return
            finished = true
            if (browsing) {
                browsing = false
                stopListeners()
            }
            cancelCurrentResolve()
            queue.clear()
            main.removeCallbacksAndMessages(null)
            try {
                result.success(resolved.values.toList())
            } catch (e: Throwable) {
                // El engine pudo haberse destruido mientras tanto.
            }
        }

        companion object {
            private const val RESOLVE_TIMEOUT_MS = 1500L
            private const val HARD_EXTRA_MS = 2500L
        }
    }
}
