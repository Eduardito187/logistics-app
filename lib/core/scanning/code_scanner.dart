import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Abre un escáner y devuelve el código leído, o `null` si se canceló.
typedef CodeScanner =
    Future<String?> Function(
      BuildContext context, {
      required String title,
      String? helper,
      required List<BarcodeFormat> formats,
    });

/// Escáner que usa toda la app vía `scanCode`. En producción abre la cámara
/// (`ScannerScreen`); en widget tests se reemplaza con
/// `codeScannerProvider.overrideWithValue(...)` para devolver un código fijo y
/// ejercitar los flujos escaneo → submit (POD, entrega fallida, recepción...).
///
/// `null` (por defecto) = cámara real; así este archivo no depende de la UI.
final codeScannerProvider = Provider<CodeScanner?>((ref) => null);
