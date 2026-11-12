import 'label_raster.dart';

/// Dibuja la etiqueta (o la página de prueba) cuando la impresora la necesita
/// como imagen (impresoras de oficina). Solo se llama si hace falta.
typedef LabelRenderer = Future<LabelRaster> Function();
