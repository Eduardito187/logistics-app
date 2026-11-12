import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipv4.dart';
import 'package:logistics_app/core/printing/ipv4_subnet.dart';
import 'package:logistics_app/core/printing/printer_reachability.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_test_message.dart';

// Texto de "Probar conexión": diagnóstico por resultado y nota de "otra red"
// cuando la IP no está en ninguna red del teléfono (caso Ricoh en la red de
// cable 192.168.2.x con el teléfono en el WiFi 10.168.50.x).

Ipv4Subnet _net(String ip, int prefix) =>
    Ipv4Subnet.containing(Ipv4.parse(ip)!, prefix);

String _msg(
  PrinterReachability r, {
  String host = '192.168.2.154',
  int port = 9100,
  List<Ipv4Subnet> nets = const [],
}) => wifiTestMessage(
  host: host,
  port: port,
  reachability: r,
  phoneNetworks: nets,
);

void main() {
  test('reachable', () {
    expect(
      _msg(PrinterReachability.reachable),
      'La impresora responde en 192.168.2.154:9100.',
    );
  });

  test('refused menciona el puerto', () {
    expect(
      _msg(PrinterReachability.refused, port: 6101),
      'Hay un equipo en esa IP pero no acepta impresión en el puerto 6101. '
      'Revisá el puerto (Zebra: 9100).',
    );
  });

  test('timeout y noRoute: mismo texto de red sin acceso', () {
    const expected =
        'No hay conexión desde el WiFi de este teléfono hasta 192.168.2.154. '
        'Puede estar en otra red (por ejemplo la de cable) sin acceso desde el '
        'WiFi: pedí a sistemas que habiliten el acceso o conectá el teléfono a '
        'la red de la impresora.';
    expect(_msg(PrinterReachability.timeout), expected);
    expect(_msg(PrinterReachability.noRoute), expected);
  });

  test('invalid', () {
    expect(
      _msg(PrinterReachability.invalid),
      'No se pudo probar: revisá la IP y el puerto.',
    );
  });

  test('IP fuera de las redes del teléfono: nota con sus redes', () {
    final msg = _msg(
      PrinterReachability.timeout,
      nets: [_net('10.168.50.17', 23), _net('172.30.220.5', 22)],
    );

    expect(
      msg,
      startsWith(
        'Esa IP es de otra red distinta a la del teléfono '
        '(10.168.50.0/23, 172.30.220.0/22). No hay conexión',
      ),
    );
  });

  test('IP dentro de una red del teléfono: sin nota', () {
    final msg = _msg(
      PrinterReachability.refused,
      host: '10.168.51.9',
      nets: [_net('10.168.50.17', 23)],
    );

    expect(msg, startsWith('Hay un equipo'));
  });

  test('sin redes conocidas o host por nombre: sin nota', () {
    expect(_msg(PrinterReachability.timeout), startsWith('No hay conexión'));
    expect(
      _msg(
        PrinterReachability.timeout,
        host: 'zebra-anden',
        nets: [_net('10.168.50.17', 23)],
      ),
      startsWith('No hay conexión'),
    );
  });
}
