import Flutter
import Foundation

/// Canal nativo de red para la búsqueda de impresoras WiFi. Contraparte Dart:
/// lib/core/printing/wifi_printer_scanner.dart.
///
/// - "interfaces" → [{name: String, ip: String, prefixLength: Int}]: una
///   entrada por IPv4 de cada interfaz levantada y no loopback (con la máscara
///   real, para no asumir /24). Ante cualquier error devuelve lista vacía.
/// - "discoverServices" {types: [String], timeoutMs: Int} →
///   [{name, type, host, port, txt: [String: String]}]: descubrimiento
///   Bonjour/mDNS con NetServiceBrowser, deduplicado por host+port+type.
///   Responde SIEMPRE dentro de timeoutMs + ~3 s (lista parcial o vacía).
///
/// Requiere NSBonjourServices y NSLocalNetworkUsageDescription en Info.plist
/// (iOS 14+); sin ellos el sistema rechaza la búsqueda y se devuelve vacío.
enum NetworkChannel {
  private static let channelName = "bo.com.dismac/network"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "interfaces":
        result(interfaces())
      case "discoverServices":
        let args = call.arguments as? [String: Any] ?? [:]
        var types: [String] = []
        for type in (args["types"] as? [Any] ?? []) {
          if let text = type as? String, !text.isEmpty, !types.contains(text) {
            types.append(text)
          }
        }
        let rawTimeout = (args["timeoutMs"] as? NSNumber)?.intValue ?? 4000
        let timeoutMs = min(max(rawTimeout, 500), 30_000)
        if types.isEmpty {
          result([[String: Any]]())
          return
        }
        BonjourDiscovery(types: types, timeoutMs: timeoutMs, result: result).start()
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Interfaces

  private static func interfaces() -> [[String: Any]] {
    var out: [[String: Any]] = []
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return out }
    defer { freeifaddrs(ifaddr) }

    var cursor: UnsafeMutablePointer<ifaddrs>? = first
    while let current = cursor {
      defer { cursor = current.pointee.ifa_next }
      let entry = current.pointee
      let flags = Int32(bitPattern: entry.ifa_flags)
      guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else { continue }
      guard let addr = entry.ifa_addr, addr.pointee.sa_family == sa_family_t(AF_INET) else {
        continue
      }
      guard let mask = entry.ifa_netmask else { continue }

      var ipAddr = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
        $0.pointee.sin_addr
      }
      let maskBits = mask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
        $0.pointee.sin_addr.s_addr
      }
      guard let ip = ipv4String(&ipAddr) else { continue }
      // La máscara es contigua: contar bits en 1 da el prefijo sin importar
      // el orden de bytes.
      let prefix = min(max(maskBits.nonzeroBitCount, 0), 32)
      out.append([
        "name": String(cString: entry.ifa_name),
        "ip": ip,
        "prefixLength": prefix,
      ])
    }
    return out
  }

  fileprivate static func ipv4String(_ addr: inout in_addr) -> String? {
    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
    guard inet_ntop(AF_INET, &addr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else {
      return nil
    }
    return String(cString: buffer)
  }
}

// MARK: - Descubrimiento Bonjour

/// Una búsqueda: un NetServiceBrowser por tipo en el run loop principal; cada
/// servicio encontrado se resuelve con timeout de 1,5 s. Al vencer timeoutMs se
/// detienen los browsers y, si quedan resoluciones en curso, se les da un
/// margen corto antes de responder. Todo corre en el hilo principal.
///
/// Las instancias vivas se guardan en `active` para mantener referencias
/// fuertes (NetServiceBrowser/NetService no retienen a su delegate).
private final class BonjourDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
  private static var active: [ObjectIdentifier: BonjourDiscovery] = [:]

  private static let resolveTimeout: TimeInterval = 1.5
  private static let resolveGraceMs = 1_600
  private static let hardExtraMs = 2_500

  private let types: [String]
  private let timeoutMs: Int
  private var result: FlutterResult?

  private var browsers: [NetServiceBrowser] = []
  private var browserTypes: [ObjectIdentifier: String] = [:]
  private var services: [NetService] = []
  private var serviceTypes: [ObjectIdentifier: String] = [:]
  private var seenServices: Set<String> = []
  private var pending: Set<ObjectIdentifier> = []
  private var resolved: [String: [String: Any]] = [:]
  private var order: [String] = []

  private var browsing = true
  private var finished = false

  init(types: [String], timeoutMs: Int, result: @escaping FlutterResult) {
    self.types = types
    self.timeoutMs = timeoutMs
    self.result = result
    super.init()
  }

  func start() {
    BonjourDiscovery.active[ObjectIdentifier(self)] = self

    // Tope duro: pase lo que pase, se responde.
    DispatchQueue.main.asyncAfter(
      deadline: .now() + .milliseconds(timeoutMs + BonjourDiscovery.hardExtraMs)
    ) { [weak self] in
      self?.finish()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) { [weak self] in
      self?.stopBrowsing()
    }

    for type in types {
      let browser = NetServiceBrowser()
      browser.delegate = self
      browsers.append(browser)
      browserTypes[ObjectIdentifier(browser)] = type
      // NetServiceBrowser espera el tipo terminado en punto ("_ipp._tcp.").
      let query = type.hasSuffix(".") ? type : type + "."
      browser.searchForServices(ofType: query, inDomain: "local.")
    }
  }

  private func stopBrowsing() {
    guard browsing, !finished else { return }
    browsing = false
    for browser in browsers {
      browser.stop()
    }
    if pending.isEmpty {
      finish()
    } else {
      // Margen para las resoluciones en curso (cada una tiene su timeout).
      DispatchQueue.main.asyncAfter(
        deadline: .now() + .milliseconds(BonjourDiscovery.resolveGraceMs)
      ) { [weak self] in
        self?.finish()
      }
    }
  }

  /// Responde UNA sola vez y libera browsers, servicios y la referencia fuerte.
  private func finish() {
    guard !finished else { return }
    finished = true
    browsing = false
    for browser in browsers {
      browser.delegate = nil
      browser.stop()
    }
    for service in services {
      service.delegate = nil
      service.stop()
    }
    browsers.removeAll()
    services.removeAll()
    pending.removeAll()

    let list = order.compactMap { resolved[$0] }
    result?(list)
    result = nil
    BonjourDiscovery.active.removeValue(forKey: ObjectIdentifier(self))
  }

  // MARK: NetServiceBrowserDelegate

  func netServiceBrowser(
    _ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool
  ) {
    guard browsing, !finished else { return }
    guard let type = browserTypes[ObjectIdentifier(browser)] else { return }
    let key = service.name + "|" + type
    guard !seenServices.contains(key) else { return }
    seenServices.insert(key)

    services.append(service)
    serviceTypes[ObjectIdentifier(service)] = type
    pending.insert(ObjectIdentifier(service))
    service.delegate = self
    service.resolve(withTimeout: BonjourDiscovery.resolveTimeout)
  }

  func netServiceBrowser(
    _ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]
  ) {
    // Tipo inválido o sin permiso de red local: se sigue con el resto.
  }

  // MARK: NetServiceDelegate

  func netServiceDidResolveAddress(_ sender: NetService) {
    guard !finished else { return }
    let id = ObjectIdentifier(sender)
    if let type = serviceTypes[id] {
      addResolved(sender, type: type)
    }
    pending.remove(id)
    sender.stop()
    finishIfIdle()
  }

  func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    guard !finished else { return }
    pending.remove(ObjectIdentifier(sender))
    finishIfIdle()
  }

  /// Si ya no se busca y no quedan resoluciones, se responde sin esperar el margen.
  private func finishIfIdle() {
    if !browsing && pending.isEmpty {
      finish()
    }
  }

  private func addResolved(_ service: NetService, type: String) {
    guard let host = ipv4(of: service) else { return }
    let port = service.port
    guard port > 0 else { return }
    let key = "\(host)|\(port)|\(type)"
    guard resolved[key] == nil else { return }
    resolved[key] = [
      "name": service.name,
      "type": type,
      "host": host,
      "port": port,
      "txt": txt(of: service),
    ]
    order.append(key)
  }

  /// Primera IPv4 de las direcciones resueltas; se prefiere una que no sea
  /// link-local (169.254.x.x).
  private func ipv4(of service: NetService) -> String? {
    var fallback: String?
    for data in service.addresses ?? [] {
      guard data.count >= MemoryLayout<sockaddr_in>.size else { continue }
      var sin = sockaddr_in()
      (data as NSData).getBytes(&sin, length: MemoryLayout<sockaddr_in>.size)
      guard sin.sin_family == sa_family_t(AF_INET) else { continue }
      var addr = sin.sin_addr
      guard let text = NetworkChannel.ipv4String(&addr) else { continue }
      if text.hasPrefix("169.254.") {
        if fallback == nil { fallback = text }
        continue
      }
      return text
    }
    return fallback
  }

  private func txt(of service: NetService) -> [String: String] {
    var out: [String: String] = [:]
    guard let data = service.txtRecordData() else { return out }
    for (key, value) in NetService.dictionary(fromTXTRecord: data) where !key.isEmpty {
      out[key] = String(data: value, encoding: .utf8) ?? ""
    }
    return out
  }
}
