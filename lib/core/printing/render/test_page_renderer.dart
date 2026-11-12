import 'dart:ui' as ui;

import '../office/label_raster.dart';
import 'offscreen_widget_renderer.dart';

/// Página de prueba para impresoras de oficina, dibujada con
/// `PictureRecorder` (sin widgets): "Prueba DisTrack", fecha y hora, y el
/// nombre del teléfono. Tamaño 4" × 3" (centrada en la hoja).
Future<LabelRaster> renderTestPage({
  required String deviceName,
  DateTime? now,
  double dpi = 200,
}) async {
  final width = (4 * dpi).round();
  final height = (3 * dpi).round();
  final unit = dpi / 100; // 1 unidad = 1/100"
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    )
    ..drawRect(
      ui.Rect.fromLTWH(
        6 * unit,
        6 * unit,
        width - 12 * unit,
        height - 12 * unit,
      ),
      ui.Paint()
        ..color = const ui.Color(0xFF000000)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3 * unit,
    );

  final when = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final date =
      '${two(when.day)}/${two(when.month)}/${when.year} '
      '${two(when.hour)}:${two(when.minute)}';

  var y = 30 * unit;
  void line(String text, double size, {bool bold = false}) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: ui.TextAlign.center,
              maxLines: 2,
              ellipsis: '…',
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: const ui.Color(0xFF000000),
              fontSize: size * unit,
              fontWeight: bold ? ui.FontWeight.w800 : ui.FontWeight.w500,
            ),
          )
          ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width - 40 * unit));
    canvas.drawParagraph(paragraph, ui.Offset(20 * unit, y));
    y += paragraph.height + 12 * unit;
  }

  line('Prueba DisTrack', 34, bold: true);
  line(date, 18);
  line(deviceName, 18);
  line('Si ves esta hoja, la impresora quedó lista.', 14);

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  try {
    return await rasterFromImage(image, dpi: dpi);
  } finally {
    image.dispose();
  }
}
