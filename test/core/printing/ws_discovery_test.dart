import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ws_discovery.dart';

// WS-Discovery: mensaje Probe y parseo de ProbeMatch. Sin red: solo funciones
// puras (el envío/escucha UDP se reemplaza en el escáner por un seam).

/// ProbeMatch real (recortado) de una multifunción de oficina por WSD.
const _probeMatch = '''
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
  xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
  xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery"
  xmlns:wsdp="http://schemas.xmlsoap.org/ws/2006/02/devprof"
  xmlns:wprt="http://schemas.microsoft.com/windows/2006/08/wdp/print">
<soap:Header>
  <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To>
  <wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches</wsa:Action>
  <wsa:MessageID>urn:uuid:7c1f2a6e-0b6d-4d1e-9f7a-2b0e3c4d5e6f</wsa:MessageID>
  <wsa:RelatesTo>urn:uuid:1b4e28ba-2fa1-41d2-883f-0016d3cca427</wsa:RelatesTo>
  <wsd:AppSequence InstanceId="1700000000" MessageNumber="12"/>
</soap:Header>
<soap:Body>
  <wsd:ProbeMatches>
    <wsd:ProbeMatch>
      <wsa:EndpointReference>
        <wsa:Address>urn:uuid:4509a320-00a0-008f-00b6-002673a1b2c3</wsa:Address>
      </wsa:EndpointReference>
      <wsd:Types>wsdp:Device wprt:PrintDeviceType</wsd:Types>
      <wsd:XAddrs>http://192.168.2.154:53000/4509a320-00a0-008f-00b6-002673a1b2c3/ http://[fe80::226:73ff:fea1:b2c3]:53000/4509a320/</wsd:XAddrs>
      <wsd:MetadataVersion>1</wsd:MetadataVersion>
    </wsd:ProbeMatch>
  </wsd:ProbeMatches>
</soap:Body>
</soap:Envelope>
''';

void main() {
  group('buildProbe', () {
    test('Probe WS-Discovery 2005/04 con To, Action, MessageID y Types', () {
      final xml = WsDiscovery.buildProbe('abc-123');

      expect(
        xml,
        contains(
          '<wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>',
        ),
      );
      expect(
        xml,
        contains('http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe<'),
      );
      expect(xml, contains('<wsa:MessageID>urn:uuid:abc-123</wsa:MessageID>'));
      expect(xml, contains('<wsd:Types>wsdp:Device</wsd:Types>'));
      expect(xml, contains('http://www.w3.org/2003/05/soap-envelope'));
      // El propio Probe NO debe parecer una respuesta (eco por multicast).
      expect(WsDiscovery.hostsFromResponse(xml, '10.0.0.9'), isEmpty);
    });

    test('MessageID: UUID v4 aleatorio', () {
      final id = WsDiscovery.newMessageId(math.Random(7));

      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
        reason: id,
      );
      expect(WsDiscovery.newMessageId(), isNot(WsDiscovery.newMessageId()));
    });
  });

  group('ProbeMatch', () {
    test('extrae la IPv4 de XAddrs (ignora IPv6)', () {
      expect(WsDiscovery.parseXAddrsHosts(_probeMatch), ['192.168.2.154']);
      expect(WsDiscovery.hostsFromResponse(_probeMatch, '192.168.2.154'), [
        '192.168.2.154',
      ]);
    });

    test('XAddrs con varias IPv4 y sin prefijo de namespace', () {
      const xml =
          '<ProbeMatch><XAddrs>http://10.0.0.5/a https://10.0.0.6:443/b '
          'http://printer.local/c</XAddrs></ProbeMatch>';

      expect(WsDiscovery.parseXAddrsHosts(xml), ['10.0.0.5', '10.0.0.6']);
    });

    test('ProbeMatch sin XAddrs IPv4 -> la IP de quien respondió', () {
      const xml =
          '<wsd:ProbeMatches><wsd:ProbeMatch><wsd:XAddrs>'
          'http://[fe80::1]/x</wsd:XAddrs></wsd:ProbeMatch></wsd:ProbeMatches>';

      expect(WsDiscovery.hostsFromResponse(xml, '192.168.2.40'), [
        '192.168.2.40',
      ]);
      expect(WsDiscovery.hostsFromResponse(xml, 'fe80::1'), isEmpty);
    });

    test('lo que no es ProbeMatch se ignora', () {
      expect(WsDiscovery.hostsFromResponse('<Hello/>', '10.0.0.1'), isEmpty);
      expect(WsDiscovery.hostsFromResponse('basura', '10.0.0.1'), isEmpty);
    });
  });
}
