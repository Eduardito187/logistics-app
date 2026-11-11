/// Dónde atiende IPP una impresora: host, puerto, ruta y si es HTTPS.
class IppEndpoint {
  const IppEndpoint({
    required this.host,
    required this.port,
    required this.path,
    this.tls = false,
  });

  final String host;
  final int port;
  final String path;
  final bool tls;

  /// URL HTTP(S) a la que se hace el POST.
  Uri get httpUri =>
      Uri(scheme: tls ? 'https' : 'http', host: host, port: port, path: path);

  /// `printer-uri` que va dentro del pedido (`ipp://` o `ipps://`).
  String get printerUri => '${tls ? 'ipps' : 'ipp'}://$host:$port$path';

  /// Clave del puerto (para no insistir con rutas si el puerto no responde).
  String get portKey => '${tls ? 's' : ''}$port';

  @override
  bool operator ==(Object other) =>
      other is IppEndpoint &&
      other.host == host &&
      other.port == port &&
      other.path == path &&
      other.tls == tls;

  @override
  int get hashCode => Object.hash(host, port, path, tls);

  @override
  String toString() => printerUri;
}
