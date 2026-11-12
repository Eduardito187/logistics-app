import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../office/label_raster.dart';

/// Unidades lógicas por pulgada al dibujar una etiqueta fuera de pantalla:
/// una etiqueta de 4" de ancho mide 400 de ancho lógico.
const double kLabelLogicalDpi = 100;

/// Dibuja [widget] FUERA de pantalla (árbol propio, no se ve nada) a
/// [logicalSize] y lo rasteriza a [dpi] para la impresora de oficina.
///
/// Usa su propio `PipelineOwner`/`BuildOwner` atado a [view] sin componer
/// nunca un frame: la vista real no cambia. El widget debe pintarse de una
/// vez (sin imágenes de red ni animaciones): ver `PrintableLabel`.
Future<LabelRaster> renderWidgetToRaster(
  Widget widget, {
  required Size logicalSize,
  required ui.FlutterView view,
  double dpi = 300,
}) async {
  final pixelRatio = dpi / kLabelLogicalDpi;
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(logicalSize),
      physicalConstraints: BoxConstraints.tight(logicalSize * pixelRatio),
      devicePixelRatio: pixelRatio,
    ),
    child: RenderPositionedBox(child: boundary),
  );
  final pipelineOwner = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final focusManager = FocusManager();
  final buildOwner = BuildOwner(focusManager: focusManager);
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: MediaQuery(
      data: MediaQueryData(size: logicalSize, devicePixelRatio: pixelRatio),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF000000), fontSize: 14),
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: SizedBox.fromSize(size: logicalSize, child: widget),
          ),
        ),
      ),
    ),
  ).attachToRenderTree(buildOwner);
  try {
    buildOwner
      ..buildScope(root)
      ..finalizeTree();
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      return await rasterFromImage(image, dpi: dpi);
    } finally {
      image.dispose();
    }
  } finally {
    // Desmonta el árbol temporal (libera estados y listeners). Best-effort:
    // si falla, el árbol queda sin referencias y lo junta el GC.
    try {
      buildOwner
        ..buildScope(
          root,
          () => root.update(
            RenderObjectToWidgetAdapter<RenderBox>(container: boundary),
          ),
        )
        ..finalizeTree();
    } on Object {
      // Nada que hacer.
    }
    focusManager.dispose();
  }
}

/// Pasa un `ui.Image` a [LabelRaster] en gris (sobre blanco).
Future<LabelRaster> rasterFromImage(
  ui.Image image, {
  required double dpi,
}) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    throw StateError('No se pudo leer la imagen de la etiqueta.');
  }
  return LabelRaster.fromRgba(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    width: image.width,
    height: image.height,
    dpi: dpi,
  );
}
