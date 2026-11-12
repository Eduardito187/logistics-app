import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'ipv4.dart';

/// WS-Discovery (2005/04), lo que usa Windows para "agregar impresora": manda
/// un `Probe` SOAP por multicast UDP a 239.255.255.250:3702 y junta las IPs de
/// los `ProbeMatch` que responden (por unicast) en el tiempo de escucha.
///
/// Puro `dart:io`. Nunca falla: cualquier error devuelve lo juntado hasta ahí
/// (o vacío). Solo descubre equipos: después se prueba el 9100 sin enviarle
/// nada, igual que el barrido.
class WsDiscovery {
  const WsDiscovery();

  static const String multicastAddress = '239.255.255.250';
  static const int port = 3702;

  /// Hosts IPv4 que respondieron al Probe en [listen]. [broadcasts] son
  /// direcciones de broadcast extra (de cada red) a las que también se manda.
  Future<List<String>> discoverHosts(
    Duration listen, {
    List<String> broadcasts = const [],
  }) async {
    final hosts = <String>{};
    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? sub;
    Timer? timer;
    try {
      final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket = udp;
      udp.broadcastEnabled = true;
      final message = utf8.encode(buildProbe(newMessageId()));
      final done = Completer<void>();
      void finish() {
        if (!done.isCompleted) done.complete();
      }

      sub = udp.listen(
        (event) {
          if (event != RawSocketEvent.read) return;
          for (var d = udp.receive(); d != null; d = udp.receive()) {
            hosts.addAll(
              hostsFromResponse(
                utf8.decode(d.data, allowMalformed: true),
                d.address.address,
              ),
            );
          }
        },
        onError: (Object _) => finish(),
        onDone: finish,
      );
      for (final target in [multicastAddress, ...broadcasts]) {
        try {
          udp.send(message, InternetAddress(target), port);
        } on Object {
          // Una red sin ruta multicast/broadcast no corta las demás.
        }
      }
      timer = Timer(listen, finish);
      await done.future;
    } on Object {
      // Sin UDP (permiso, sin red): se omite WS-Discovery.
    } finally {
      timer?.cancel();
      await sub?.cancel();
      socket?.close();
    }
    return hosts.toList();
  }

  /// Mensaje `Probe` de WS-Discovery 2005/04 buscando `wsdp:Device`.
  static String buildProbe(String messageId) =>
      '<?xml version="1.0" encoding="utf-8"?>'
      '<soap:Envelope '
      'xmlns:soap="http://www.w3.org/2003/05/soap-envelope" '
      'xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" '
      'xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery" '
      'xmlns:wsdp="http://schemas.xmlsoap.org/ws/2006/02/devprof">'
      '<soap:Header>'
      '<wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>'
      '<wsa:Action>'
      'http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe'
      '</wsa:Action>'
      '<wsa:MessageID>urn:uuid:$messageId</wsa:MessageID>'
      '</soap:Header>'
      '<soap:Body>'
      '<wsd:Probe><wsd:Types>wsdp:Device</wsd:Types></wsd:Probe>'
      '</soap:Body>'
      '</soap:Envelope>';

  /// UUID v4 aleatorio (`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`).
  static String newMessageId([math.Random? random]) {
    final rnd = random ?? math.Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10).join()}';
  }

  static final RegExp _xAddrsPattern = RegExp(
    r'<(?:[\w-]+:)?XAddrs[^>]*>([\s\S]*?)</(?:[\w-]+:)?XAddrs>',
    caseSensitive: false,
  );

  /// IPs IPv4 de los `<wsd:XAddrs>` (URLs `http://IP:puerto/...` separadas
  /// por espacios) de una respuesta.
  static List<String> parseXAddrsHosts(String xml) {
    final out = <String>{};
    for (final match in _xAddrsPattern.allMatches(xml)) {
      for (final url in match.group(1)!.trim().split(RegExp(r'\s+'))) {
        final host = Uri.tryParse(url)?.host ?? '';
        if (Ipv4.parse(host) != null) out.add(host);
      }
    }
    return out.toList();
  }

  /// Hosts de una respuesta: solo `ProbeMatch`; las IPs de `XAddrs` o, si no
  /// trae ninguna IPv4, la IP de quien respondió.
  static List<String> hostsFromResponse(String xml, String sender) {
    if (!xml.contains('ProbeMatch')) return const [];
    final hosts = parseXAddrsHosts(xml);
    if (hosts.isNotEmpty) return hosts;
    return Ipv4.parse(sender) != null ? [sender] : const [];
  }
}
