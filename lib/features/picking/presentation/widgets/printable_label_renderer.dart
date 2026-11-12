import 'dart:ui' as ui;

import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/printing/label_printer.dart';
import '../../../../core/printing/render/offscreen_widget_renderer.dart';
import 'printable_label.dart';

/// [LabelRenderer] de una etiqueta emitida para impresoras de oficina: dibuja
/// [PrintableLabel] fuera de pantalla a 300 dpi. Solo se ejecuta si la
/// impresora activa lo necesita (las Zebra reciben el ZPL).
LabelRenderer printableLabelRenderer(
  EmittedLabel label, {
  required ui.FlutterView view,
  double dpi = 300,
}) {
  return () => renderWidgetToRaster(
    // Sin destino en el papel (ahorro): el QR lo lleva y la app lo muestra.
    PrintableLabel(label: label, productName: label.productName),
    logicalSize: PrintableLabel.logicalSize,
    view: view,
    dpi: dpi,
  );
}
