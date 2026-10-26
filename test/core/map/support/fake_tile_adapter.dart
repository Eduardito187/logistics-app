import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adaptador HTTP falso para los tests de la caché de tiles: responde un PNG
/// mínimo (o falla) y cuenta pedidos y concurrencia.
class FakeTileAdapter implements HttpClientAdapter {
  FakeTileAdapter({this.delay = Duration.zero, this.fail = false});

  final Duration delay;

  /// `true` = simula que no hay señal (error de socket).
  bool fail;

  final List<Uri> requests = [];
  final List<Map<String, dynamic>> requestHeaders = [];
  int _inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    requestHeaders.add(Map.of(options.headers));
    _inFlight++;
    if (_inFlight > maxInFlight) {
      maxInFlight = _inFlight;
    }
    try {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (fail) {
        throw const SocketException('sin señal');
      }
      return ResponseBody.fromBytes(
        Uint8List.fromList(List<int>.filled(64, 7)),
        200,
        headers: {
          Headers.contentTypeHeader: ['image/png'],
        },
      );
    } finally {
      _inFlight--;
    }
  }

  @override
  void close({bool force = false}) {}
}
