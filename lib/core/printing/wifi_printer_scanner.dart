import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'extra_networks_notifier.dart';
import 'ipv4.dart';
import 'ipv4_subnet.dart';
import 'local_network.dart';
import 'mdns_service.dart';
import 'network_info_channel.dart';
import 'network_printer_identity.dart';
import 'printer_config_data.dart';
import 'printer_reachability.dart';
import 'scanned_network.dart';
import 'wifi_hit_source.dart';
import 'wifi_printer_hit.dart';
import 'wifi_scan_progress.dart';
import 'ws_discovery.dart';

export 'network_info_channel.dart' show InterfaceLister;

/// `true` si [host]:[port] acepta una conexión TCP. Seam para tests.
typedef PortProbe =
    Future<bool> Function(String host, int port, Duration timeout);

/// Nombre/modelo de la impresora en [host] por su web, o `null`. Seam.
typedef PrinterIdentifier =
    Future<NetworkPrinterIdentity?> Function(String host, Duration timeout);

/// Diagnóstico de conexión TCP ("Probar conexión"). Seam para tests.
typedef ConnectionDiagnoser =
    Future<PrinterReachability> Function(
      String host,
      int port,
      Duration timeout,
    );

/// Búsqueda mDNS/Bonjour de servicios [types]. Seam (canal nativo).
typedef ServiceDiscoverer =
    Future<List<MdnsService>> Function(List<String> types, Duration timeout);

/// Hosts que responden a WS-Discovery en [listen]. Seam para tests.
typedef WsdDiscoverer =
    Future<List<String>> Function(Duration listen, List<String> broadcasts);

/// Redes extra elegidas por el usuario. Seam para tests.
typedef ExtraNetworksReader = Future<List<Ipv4Subnet>> Function();

/// Mensaje cuando el teléfono no está en ninguna red WiFi/LAN.
const String kNoLocalNetworkMessage =
    'Conectá el teléfono al WiFi del local para buscar impresoras.';

/// Búsqueda automática de impresoras de red, como hace Windows al "agregar
/// impresora", por cuatro caminos en paralelo:
/// - barrido TCP del puerto ZPL crudo (9100) en la red del teléfono (con su
///   máscara real; una red grande se barre en el bloque /22 del teléfono);
/// - barrido de las redes agregadas por el usuario (p. ej. la de cable);
/// - mDNS/Bonjour (`_pdl-datastream`, `_printer`, `_ipp`) por canal nativo;
/// - WS-Discovery (multicast UDP 3702), puro `dart:io`.
///
/// A cada equipo que acepta el 9100 le lee el nombre/modelo desde su web (o
/// del servicio mDNS). Nunca envía datos al 9100 al buscar (abrir y cerrar el
/// socket no imprime nada). Solo corre a pedido (botón), nunca en segundo
/// plano; cancelar la suscripción la detiene.
class WifiPrinterScanner {
  WifiPrinterScanner({
    InterfaceLister? listInterfaces,
    PortProbe? probe,
    PrinterIdentifier? identify,
    ConnectionDiagnoser? diagnoser,
    ServiceDiscoverer? discoverServices,
    WsdDiscoverer? wsDiscover,
    ExtraNetworksReader? extraNetworks,
    this.concurrency = 96,
    this.probeTimeout = const Duration(milliseconds: 700),
    this.identifyTimeout = const Duration(seconds: 2),
    this.mdnsTimeout = const Duration(seconds: 4),
    this.wsdListen = const Duration(seconds: 3),
  }) : _listInterfaces = listInterfaces ?? NetworkInfoChannel.systemInterfaces,
       _probe = probe ?? tcpProbe,
       _identify = identify ?? identifyOverHttp,
       _diagnoser = diagnoser ?? tcpDiagnose,
       _discoverServices = discoverServices,
       _wsDiscover = wsDiscover,
       _extraNetworks = extraNetworks;

  final InterfaceLister _listInterfaces;
  final PortProbe _probe;
  final PrinterIdentifier _identify;
  final ConnectionDiagnoser _diagnoser;

  /// `null` = sin mDNS (p. ej. tests); el provider cablea el canal nativo.
  final ServiceDiscoverer? _discoverServices;

  /// `null` = sin WS-Discovery; el provider cablea [WsDiscovery].
  final WsdDiscoverer? _wsDiscover;

  /// `null` = sin redes extra; el provider cablea [extraNetworksProvider].
  final ExtraNetworksReader? _extraNetworks;

  /// Conexiones simultáneas del barrido (1022 direcciones en ~8 s).
  final int concurrency;
  final Duration probeTimeout;
  final Duration identifyTimeout;

  /// Tiempo de búsqueda mDNS (lo corta el lado nativo).
  final Duration mdnsTimeout;

  /// Tiempo de escucha de respuestas WS-Discovery.
  final Duration wsdListen;

  /// `true` si además del barrido busca por Bonjour y/o WS-Discovery.
  bool get usesServiceDiscovery =>
      _discoverServices != null || _wsDiscover != null;

  /// Redes locales del teléfono (WiFi primero). Vacía = sin WiFi/LAN.
  Future<List<LocalNetwork>> localNetworks() async {
    try {
      return LocalNetwork.fromInterfaces(await _listInterfaces());
    } on Object {
      return const [];
    }
  }

  /// `true` si hay algo escuchando en [host]:[port].
  Future<bool> probe(String host, {int port = kDefaultWifiPort}) =>
      _probe(host, port, const Duration(seconds: 3));

  /// "Probar conexión" con diagnóstico: responde, rechaza el puerto, no hay
  /// ruta o no contesta. Solo abre y cierra el socket (no imprime nada).
  Future<PrinterReachability> diagnose(
    String host, {
    int port = kDefaultWifiPort,
  }) async {
    if (host.trim().isEmpty || port < 1 || port > 65535) {
      return PrinterReachability.invalid;
    }
    try {
      return await _diagnoser(host.trim(), port, const Duration(seconds: 3));
    } on Object catch (e) {
      return reachabilityFromError(e);
    }
  }

  /// Barre la red local buscando impresoras en [port]. Emite el avance (con lo
  /// encontrado hasta el momento) y cierra con `done: true`. Cancelar la
  /// suscripción detiene el barrido. Sin red local emite un
  /// [WifiScanProgress.failed].
  Stream<WifiScanProgress> scan({int port = kDefaultWifiPort}) {
    var cancelled = false;
    late final StreamController<WifiScanProgress> controller;
    controller = StreamController<WifiScanProgress>(
      onListen: () => unawaited(
        _run(controller, port, () => cancelled || controller.isClosed),
      ),
      onCancel: () => cancelled = true,
    );
    return controller.stream;
  }

  /// Busca la impresora llamada [name] (re-localización tras un cambio de IP
  /// por DHCP). Devuelve la ÚNICA coincidencia o `null` (ninguna o varias).
  Future<WifiPrinterHit?> findByName(
    String name, {
    int port = kDefaultWifiPort,
  }) async {
    try {
      final last = await scan(port: port).last;
      final matches = last.found.where((h) => h.name == name).toList();
      return matches.length == 1 ? matches.single : null;
    } on Object {
      return null;
    }
  }

  Future<List<Ipv4Subnet>> _safeExtraNetworks() async {
    final reader = _extraNetworks;
    if (reader == null) return const [];
    try {
      return await reader();
    } on Object {
      return const [];
    }
  }

  Future<void> _run(
    StreamController<WifiScanProgress> out,
    int port,
    bool Function() stopped,
  ) async {
    try {
      final networks = await localNetworks();
      if (networks.isEmpty) {
        if (!stopped()) {
          out.add(const WifiScanProgress.failed(kNoLocalNetworkMessage));
        }
        return;
      }
      final extras = await _safeExtraNetworks();
      final ownIps = <int>{for (final n in networks) ?Ipv4.parse(n.ownIp)};

      // Redes a barrer: las del teléfono y luego las agregadas (sin repetir).
      final swept = <Ipv4Subnet>{};
      final labels = <ScannedNetwork>[];
      // Host → origen; el mapa (LinkedHashMap) conserva orden y deduplica.
      final targets = <int, WifiHitSource>{};
      for (final n in networks) {
        if (!swept.add(n.scanSubnet)) continue;
        labels.add(
          ScannedNetwork(
            label: n.label,
            fullLabel: n.isScanLimited ? n.subnet.label : null,
          ),
        );
        for (final ip in n.scanSubnet.hosts) {
          if (!ownIps.contains(ip)) {
            targets.putIfAbsent(ip, () => WifiHitSource.sweep);
          }
        }
      }
      for (final subnet in extras) {
        if (!swept.add(subnet)) continue;
        labels.add(ScannedNetwork(label: subnet.label, added: true));
        for (final ip in subnet.hosts) {
          if (!ownIps.contains(ip)) {
            targets.putIfAbsent(ip, () => WifiHitSource.addedNetwork);
          }
        }
      }
      final hosts = targets.keys.toList(growable: false);
      final hits = <String, WifiPrinterHit>{};
      var scanned = 0;
      var next = 0;
      var discovering = usesServiceDiscovery;

      void emit({bool done = false}) {
        if (stopped()) return;
        final sorted = [...hits.values]..sort(WifiPrinterHit.compare);
        out.add(
          WifiScanProgress(
            scanned: scanned,
            total: hosts.length,
            found: List.unmodifiable(sorted),
            networks: List.unmodifiable(labels),
            done: done,
            discoveringServices: discovering && !done,
          ),
        );
      }

      void addHit(WifiPrinterHit hit) {
        final previous = hits[hit.address];
        hits[hit.address] = previous == null ? hit : previous.merge(hit);
      }

      // Avance ~cada 1 %: barra fluida sin reconstruir mil veces.
      final emitEvery = math.max(8, hosts.length ~/ 100);

      Future<void> worker() async {
        while (!stopped() && next < hosts.length) {
          final ip = hosts[next++];
          final host = Ipv4.format(ip);
          final open = await _probe(host, port, probeTimeout);
          scanned++;
          if (open) {
            final id = await _safeIdentify(host);
            addHit(
              WifiPrinterHit(
                host: host,
                port: port,
                name: id?.name,
                isZebra: id?.isZebra ?? false,
                source: targets[ip] ?? WifiHitSource.sweep,
              ),
            );
            emit();
          } else if (scanned % emitEvery == 0) {
            emit();
          }
        }
      }

      Future<void> sweep() async {
        await Future.wait([
          for (var i = 0; i < math.min(concurrency, hosts.length); i++)
            worker(),
        ]);
        // Barra al 100 % aunque Bonjour/WSD sigan buscando.
        emit();
      }

      Future<void> services() async {
        if (!discovering) return;
        final broadcasts = [
          for (final n in networks) Ipv4.format(n.subnet.broadcast),
        ];
        await Future.wait([
          _viaMdns(port, stopped, addHit, emit),
          _viaWsd(port, broadcasts, ownIps, hits, stopped, addHit, emit),
        ]);
        discovering = false;
        emit();
      }

      emit();
      await Future.wait([sweep(), services()], eagerError: true);
      emit(done: true);
    } on Object {
      if (!stopped()) {
        out.add(
          const WifiScanProgress.failed(
            'No se pudo buscar impresoras. Probá de nuevo o ingresá la IP.',
          ),
        );
      }
    } finally {
      if (!out.isClosed) await out.close();
    }
  }

  /// mDNS/Bonjour: cada servicio anunciado cuyo puerto de impresión acepta
  /// conexión es un hallazgo con el nombre del servicio (vale aunque esté en
  /// otra subred: hay redes con gateway mDNS entre VLANs). Errores: se omite.
  Future<void> _viaMdns(
    int port,
    bool Function() stopped,
    void Function(WifiPrinterHit) addHit,
    void Function() emit,
  ) async {
    final discover = _discoverServices;
    if (discover == null) return;
    List<MdnsService> services;
    try {
      services = await discover(
        NetworkInfoChannel.printerServiceTypes,
        mdnsTimeout,
      );
    } on Object {
      return;
    }
    final byAddress = <String, MdnsService>{};
    for (final s in services) {
      // Solo IPv4: `ip:puerto` es el formato guardado de la impresora.
      if (s.host.contains(':')) continue;
      byAddress.putIfAbsent('${s.host}:${s.portToProbe(port)}', () => s);
    }
    Future<void> check(MdnsService s) async {
      if (stopped()) return;
      final target = s.portToProbe(port);
      if (!await _safeProbe(s.host, target)) return;
      addHit(
        WifiPrinterHit(
          host: s.host,
          port: target,
          name: _cleanName(s.name),
          isZebra: s.looksLikeZebra,
          source: WifiHitSource.mdns,
        ),
      );
      emit();
    }

    await Future.wait([for (final s in byAddress.values) check(s)]);
  }

  /// WS-Discovery: equipos que responden al Probe; si aceptan el 9100 se
  /// identifican por su web como en el barrido. Errores: se omite.
  Future<void> _viaWsd(
    int port,
    List<String> broadcasts,
    Set<int> ownIps,
    Map<String, WifiPrinterHit> hits,
    bool Function() stopped,
    void Function(WifiPrinterHit) addHit,
    void Function() emit,
  ) async {
    final discover = _wsDiscover;
    if (discover == null) return;
    List<String> found;
    try {
      found = await discover(wsdListen, broadcasts);
    } on Object {
      return;
    }
    final hosts = <String>{};
    for (final h in found) {
      final ip = Ipv4.parse(h);
      if (ip != null && !ownIps.contains(ip)) hosts.add(Ipv4.format(ip));
    }
    Future<void> check(String host) async {
      if (stopped() || hits.containsKey('$host:$port')) return;
      if (!await _safeProbe(host, port)) return;
      final id = await _safeIdentify(host);
      addHit(
        WifiPrinterHit(
          host: host,
          port: port,
          name: id?.name,
          isZebra: id?.isZebra ?? false,
          source: WifiHitSource.wsd,
        ),
      );
      emit();
    }

    await Future.wait([for (final host in hosts) check(host)]);
  }

  Future<bool> _safeProbe(String host, int port) async {
    try {
      return await _probe(host, port, probeTimeout);
    } on Object {
      return false;
    }
  }

  Future<NetworkPrinterIdentity?> _safeIdentify(String host) async {
    try {
      return await _identify(host, identifyTimeout);
    } on Object {
      return null;
    }
  }

  /// Nombre de servicio mDNS para la UI (sin espacios de más, ≤ 60).
  static String _cleanName(String name) {
    final text = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length > 60 ? '${text.substring(0, 60)}…' : text;
  }

  /// Prueba TCP: conectar y cerrar. No envía bytes (no imprime nada).
  static Future<bool> tcpProbe(String host, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } on Object {
      return false;
    }
  }

  /// Conectar y cerrar, clasificando el error (sin enviar bytes).
  static Future<PrinterReachability> tcpDiagnose(
    String host,
    int port,
    Duration timeout,
  ) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return PrinterReachability.reachable;
    } on Object catch (e) {
      return reachabilityFromError(e);
    }
  }

  /// errno de "conexión rechazada" (Linux/Android, Windows, iOS/macOS).
  static const Set<int> _refusedCodes = {111, 10061, 61};

  /// errno de "sin ruta al host/red" (Linux/Android, Windows, iOS/macOS).
  static const Set<int> _noRouteCodes = {113, 101, 10065, 10051, 65, 51};

  /// Clasifica el error de `Socket.connect`: rechazado (hay equipo pero el
  /// puerto está cerrado), sin ruta, o timeout (sin `osError` = venció el
  /// tiempo de espera de Dart).
  static PrinterReachability reachabilityFromError(Object error) {
    if (error is ArgumentError) return PrinterReachability.invalid;
    if (error is! SocketException) return PrinterReachability.timeout;
    if (error.message.toLowerCase().contains('host lookup')) {
      return PrinterReachability.invalid;
    }
    final code = error.osError?.errorCode;
    if (code == null) return PrinterReachability.timeout;
    if (_refusedCodes.contains(code)) return PrinterReachability.refused;
    if (_noRouteCodes.contains(code)) return PrinterReachability.noRoute;
    return PrinterReachability.timeout;
  }

  /// Lee la página web de la impresora (HTTP en el 80; si redirige a HTTPS,
  /// el 443 aceptando su certificado autofirmado: solo se lee el título, no se
  /// envía nada sensible). Socket crudo a propósito: no depende de la política
  /// de tráfico en claro de la app (que es para el backend, no la LAN).
  static Future<NetworkPrinterIdentity?> identifyOverHttp(
    String host,
    Duration timeout,
  ) async {
    final plain = await _httpGet(host, timeout, secure: false);
    if (plain == null) {
      return _parse(await _httpGet(host, timeout, secure: true));
    }
    final found = _parse(plain);
    if (found != null && found.name != 'Zebra') return found;
    final redirectsToHttps = RegExp(
      r'^location:\s*https://',
      caseSensitive: false,
      multiLine: true,
    ).hasMatch(plain);
    if (!redirectsToHttps) return found;
    return _parse(await _httpGet(host, timeout, secure: true)) ?? found;
  }

  static NetworkPrinterIdentity? _parse(String? raw) =>
      raw == null ? null : NetworkPrinterIdentity.fromHttpResponse(raw);

  /// Tope de lectura de la página (alcanza para cabeceras + `<title>`).
  static const int _maxResponseBytes = 32 * 1024;

  static Future<String?> _httpGet(
    String host,
    Duration timeout, {
    required bool secure,
  }) async {
    Socket? socket;
    try {
      socket = secure
          ? await SecureSocket.connect(
              host,
              443,
              timeout: timeout,
              onBadCertificate: (_) => true,
            )
          : await Socket.connect(host, 80, timeout: timeout);
      socket.write(
        'GET / HTTP/1.0\r\nHost: $host\r\nUser-Agent: DisTrack\r\n'
        'Connection: close\r\n\r\n',
      );
      await socket.flush();
      final bytes = <int>[];
      await for (final chunk in socket.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length >= _maxResponseBytes) break;
      }
      return utf8.decode(bytes, allowMalformed: true);
    } on Object {
      return null;
    } finally {
      socket?.destroy();
    }
  }
}

/// Escáner real: interfaces y mDNS por el canal nativo (con caída a
/// `dart:io`), WS-Discovery por UDP y las redes extra del usuario.
final wifiPrinterScannerProvider = Provider<WifiPrinterScanner>((ref) {
  final channel = ref.watch(networkInfoChannelProvider);
  return WifiPrinterScanner(
    listInterfaces: channel.interfaces,
    discoverServices: channel.discoverServices,
    wsDiscover: (listen, broadcasts) =>
        const WsDiscovery().discoverHosts(listen, broadcasts: broadcasts),
    extraNetworks: () => ref.read(extraNetworksProvider.notifier).current(),
  );
});
