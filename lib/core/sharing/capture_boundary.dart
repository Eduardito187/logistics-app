import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Captura un boundary a PNG. Seam para tests: en pruebas se inyecta un doble
/// que devuelve bytes fijos y no rasteriza de verdad.
typedef BoundaryCapturer =
    Future<Uint8List?> Function(GlobalKey key, {double pixelRatio});

/// Capturador real (rasteriza el RepaintBoundary). Se sustituye en tests con
/// [boundaryCapturerProvider].
final boundaryCapturerProvider = Provider<BoundaryCapturer>(
  (ref) => captureBoundaryPng,
);

/// Captura a PNG el widget envuelto en un [RepaintBoundary] identificado por
/// [key]. Devuelve `null` si el boundary todavía no está montado/pintado.
///
/// Se usa para "fotografiar" la etiqueta dibujada en pantalla y compartirla por
/// el menú nativo (no hay imagen renderizada del backend; la app dibuja fiel la
/// etiqueta desde el QR firmado). [pixelRatio] fija la nitidez del PNG: 3x da un
/// archivo nítido para WhatsApp sin pesar de más.
Future<Uint8List?> captureBoundaryPng(
  GlobalKey key, {
  double pixelRatio = 3.0,
}) async {
  final object = key.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;
  final image = await object.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
