import 'dart:io';
import 'dart:typed_data';

/// Manda bytes crudos a `host:port` (JetDirect 9100). Seam para tests.
typedef RawTcpSender =
    Future<void> Function(String host, int port, Uint8List bytes);

/// Envío real: conecta, escribe, vacía y cierra. No hay confirmación posible:
/// el 9100 acepta los bytes aunque la impresora después los descarte.
Future<void> sendRawTcp(String host, int port, Uint8List bytes) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 8),
    );
    socket.add(bytes);
    await socket.flush();
  } finally {
    await socket?.close();
  }
}
