import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/labels/label_format_exception.dart';
import '../../../core/labels/label_scanner.dart';
import '../../../core/labels/signed_label.dart';
import '../../../core/location/location_service.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';

/// Escanea una etiqueta de unidad y verifica su firma Ed25519 sin red.
/// Devuelve el id del bulto (`unit_id`), o `null` si se canceló o la etiqueta
/// no es válida. Avisa en pantalla cuando la firma no verifica.
///
/// [bottomClearance]: en pantallas con botón fijo al pie pasar
/// `kBottomActionClearance` para que el aviso no tape el botón.
Future<String?> scanVerifiedUnit(
  BuildContext context,
  WidgetRef ref, {
  String helper = 'Apunta al QR del bulto',
  double? bottomClearance,
}) async {
  final qr = await scanCode(
    context,
    title: 'Escanear bulto',
    helper: helper,
    formats: const [BarcodeFormat.qrCode],
  );
  if (qr == null || !context.mounted) return null;

  final unitId = await verifyUnitLabel(ref, qr);
  if (unitId == null && context.mounted) {
    // Avisa que la etiqueta no sirve (sin bulto).
    showInfoSnack(
      context,
      'Etiqueta no válida',
      bottomClearance: bottomClearance,
    );
  }
  return unitId;
}

/// Verifica OFFLINE la etiqueta [qr] de un bulto (firma Ed25519, sin esperar
/// red) y devuelve su `unit_id`, o `null` si no es una etiqueta válida. No
/// muestra nada: lo usan el escaneo de un solo código ([scanVerifiedUnit]) y el
/// continuo de carga/descarga (que avisa sobre la cámara).
Future<String?> verifyUnitLabel(WidgetRef ref, String qr) async {
  final scanner = ref.read(labelScannerProvider);
  try {
    final result = await scanner.scanAndReport(qr);
    return result.isValid ? result.label.payload.id : null;
  } on LabelFormatException {
    // Con claves configuradas, un formato inválido es una etiqueta no válida.
    if (scanner.canVerify) return null;
    // Sin claves (app sin configurar): se lee el id sin poder verificar firma.
    try {
      return SignedLabel.fromQrContent(qr).payload.id;
    } on LabelFormatException {
      return null;
    }
  }
}

/// Toma el fix GPS actual (o `null` si no hay señal/permiso a tiempo). Un
/// escaneo nunca se traba esperando al GPS (offline-first). Nunca lanza: un
/// fallo del GPS es "sin posición", así se puede pedir en paralelo a otra cosa
/// (abrir la cámara, encolar la foto) sin futuros con errores sueltos.
Future<GpsFix?> currentFix(WidgetRef ref) async {
  try {
    return await ref.read(locationServiceProvider).current();
  } on Object {
    return null;
  }
}

/// Formatea centavos a un monto legible (p. ej. "BOB 1234.50").
String formatMoneyCents(int cents, String currency) {
  final amount = (cents / 100).toStringAsFixed(2);
  return '$currency $amount';
}

/// Fecha corta `yyyy-MM-dd`.
String formatDate(DateTime d) {
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}

/// Hora corta `HH:mm`.
String formatTime(DateTime d) {
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
