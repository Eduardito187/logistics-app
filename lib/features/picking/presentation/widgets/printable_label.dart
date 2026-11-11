import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/api/models/emitted_label.dart';

/// La etiqueta tal como sale en papel de una impresora de OFICINA: 4" × 6"
/// (400 × 600 lógicos a `kLabelLogicalDpi`), blanco y negro, sin foto (no se
/// puede esperar una imagen de red al dibujar fuera de pantalla) y con el QR
/// firmado real, el mismo que verifica el chofer.
///
/// MINIMALISTA a propósito (pedido del dueño: ahorrar papel): solo pedido,
/// producto, SKU, QR y el código. **Sin línea ni destino**: quien escanea el QR
/// ve todo el detalle (cliente, dirección) en la app si lo necesita.
class PrintableLabel extends StatelessWidget {
  const PrintableLabel({required this.label, this.productName, super.key});

  /// Tamaño lógico (4" × 6").
  static const Size logicalSize = Size(400, 600);

  final EmittedLabel label;
  final String? productName;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF000000);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: ink, width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pedido ${label.orderNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const Divider(color: ink, thickness: 2, height: 20),
              Text(
                productName ?? 'Producto',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(label.sku, style: const TextStyle(color: ink, fontSize: 16)),
              const Spacer(),
              Center(
                child: QrImageView(
                  data: label.qrContent,
                  version: QrVersions.auto,
                  size: 230,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: ink,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label.labelId,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ink, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
