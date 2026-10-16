import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/labels/label_format_exception.dart';
import '../../../../core/labels/label_scanner.dart';
import '../../../../core/labels/label_verifier.dart';
import '../../../../core/scanning/scanner_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack.dart';
import 'signed_label_result.dart';

/// Escanea una etiqueta QR y verifica su firma Ed25519 sin red. Devuelve la
/// etiqueta solo si es válida; en cualquier otro caso informa al usuario y
/// devuelve `null`.
Future<SignedLabelResult?> scanAndVerifyLabel(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String? helper,
}) async {
  final qr = await scanCode(
    context,
    title: title,
    helper: helper,
    formats: const [BarcodeFormat.qrCode],
  );
  if (qr == null || !context.mounted) return null;

  final scanner = ref.read(labelScannerProvider);
  try {
    final result = await scanner.scanAndReport(qr);
    if (!result.isValid) {
      if (context.mounted) {
        _showScanMessage(
          context,
          result.verification == VerificationResult.unknownKey
              ? 'Etiqueta de una clave desconocida: no se puede verificar.'
              : 'Firma inválida: etiqueta editada o falsa.',
          AppColors.danger,
        );
      }
      return null;
    }
    return SignedLabelResult(
      unitId: result.label.payload.id,
      shipmentId: result.label.payload.orderNumber,
      sku: result.label.payload.sku,
    );
  } on LabelFormatException catch (e) {
    if (context.mounted) {
      _showScanMessage(context, e.reason, AppColors.warning);
    }
    return null;
  }
}

/// Aviso del resultado de la verificación. Corto y flotando ENCIMA del botón
/// de escanear del pie ([kBottomActionClearance]) para que un segundo toque
/// rápido siempre llegue al botón. Reemplaza el aviso anterior (no se apilan).
void _showScanMessage(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      buildAppSnackBar(
        message,
        color,
        duration: kShortSnackDuration,
        bottomClearance: kBottomActionClearance,
      ),
    );
}
