import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mdns_service.dart';
import 'network_interface_info.dart';

/// Lista las interfaces IPv4 del teléfono. Seam para tests.
typedef InterfaceLister = Future<List<NetworkInterfaceInfo>> Function();

/// Canal nativo `bo.com.dismac/network`:
/// - `interfaces` → `[{name, ip, prefixLength}]` (IPv4, activas, sin
///   loopback): da la máscara REAL de la red, que `dart:io` no expone.
/// - `discoverServices` `{types, timeoutMs}` → `[{name, type, host, port,
///   txt}]`: búsqueda mDNS/Bonjour (NsdManager / NetServiceBrowser).
///
/// Nunca falla: sin canal (tests, versión vieja del lado nativo) las
/// interfaces salen de `dart:io` asumiendo /24 y mDNS devuelve vacío.
class NetworkInfoChannel {
  const NetworkInfoChannel({
    MethodChannel channel = defaultChannel,
    InterfaceLister fallback = systemInterfaces,
  }) : _channel = channel,
       _fallback = fallback;

  static const MethodChannel defaultChannel = MethodChannel(
    'bo.com.dismac/network',
  );

  /// Tipos de servicio mDNS de impresoras (como Windows).
  static const List<String> printerServiceTypes = [
    '_pdl-datastream._tcp',
    '_printer._tcp',
    '_ipp._tcp',
  ];

  final MethodChannel _channel;
  final InterfaceLister _fallback;

  /// Interfaces con su máscara real; sin canal (o vacío) → `dart:io` + /24.
  Future<List<NetworkInterfaceInfo>> interfaces() async {
    try {
      final raw = await _channel.invokeListMethod<Object?>('interfaces');
      final parsed = parseInterfaces(raw);
      if (parsed.isNotEmpty) return parsed;
    } on MissingPluginException {
      // Lado nativo sin el canal: se cae a dart:io.
    } on PlatformException {
      // Error nativo: se cae a dart:io.
    }
    return _fallback();
  }

  /// Servicios mDNS de [types] encontrados en [timeout]. Vacío si no hay
  /// canal o falla (la búsqueda sigue con el barrido).
  Future<List<MdnsService>> discoverServices(
    List<String> types,
    Duration timeout,
  ) async {
    try {
      final raw = await _channel.invokeListMethod<Object?>(
        'discoverServices',
        {'types': types, 'timeoutMs': timeout.inMilliseconds},
      );
      return [
        for (final item in raw ?? const <Object?>[])
          ?MdnsService.fromMap(item),
      ];
    } on Object {
      return const [];
    }
  }

  /// Mapas del canal → interfaces; descarta entradas mal formadas.
  static List<NetworkInterfaceInfo> parseInterfaces(List<Object?>? raw) {
    if (raw == null) return const [];
    final out = <NetworkInterfaceInfo>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final name = item['name'];
      final ip = item['ip'];
      final prefix = item['prefixLength'];
      if (name is! String || ip is! String) continue;
      out.add(
        NetworkInterfaceInfo(
          name: name,
          ip: ip,
          prefixLength: prefix is int && prefix >= 0 && prefix <= 32
              ? prefix
              : 24,
        ),
      );
    }
    return out;
  }

  /// Interfaces según `dart:io` (sin máscara: se asume /24).
  static Future<List<NetworkInterfaceInfo>> systemInterfaces() async {
    final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return [
      for (final iface in list)
        for (final addr in iface.addresses)
          NetworkInterfaceInfo(name: iface.name, ip: addr.address),
    ];
  }
}

final networkInfoChannelProvider = Provider<NetworkInfoChannel>(
  (ref) => const NetworkInfoChannel(),
);
