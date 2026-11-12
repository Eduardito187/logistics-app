import '../../../../core/printing/ipv4.dart';
import '../../../../core/printing/ipv4_subnet.dart';
import '../../../../core/printing/printer_reachability.dart';

/// Texto del resultado de "Probar conexión" para el operario. Si [host] es una
/// IP fuera de todas las [phoneNetworks], antepone que es de otra red: la
/// causa típica de que no conecte (impresora en la red de cable y teléfono en
/// el WiFi, sin ruta entre ambas).
String wifiTestMessage({
  required String host,
  required int port,
  required PrinterReachability reachability,
  List<Ipv4Subnet> phoneNetworks = const [],
}) {
  final result = switch (reachability) {
    PrinterReachability.reachable => 'La impresora responde en $host:$port.',
    PrinterReachability.refused =>
      'Hay un equipo en esa IP pero no acepta impresión en el puerto $port. '
          'Revisá el puerto (Zebra: 9100).',
    PrinterReachability.timeout || PrinterReachability.noRoute =>
      'No hay conexión desde el WiFi de este teléfono hasta $host. Puede estar '
          'en otra red (por ejemplo la de cable) sin acceso desde el WiFi: '
          'pedí a sistemas que habiliten el acceso o conectá el teléfono a la '
          'red de la impresora.',
    PrinterReachability.invalid =>
      'No se pudo probar: revisá la IP y el puerto.',
  };
  final ip = Ipv4.parse(host);
  final otherNetwork =
      ip != null &&
      phoneNetworks.isNotEmpty &&
      !phoneNetworks.any((n) => n.contains(ip));
  if (!otherNetwork) return result;
  final labels = phoneNetworks.map((n) => n.label).join(', ');
  return 'Esa IP es de otra red distinta a la del teléfono ($labels). $result';
}
