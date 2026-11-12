import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import 'printer_option_card.dart';

/// Paso 1 del asistente, "¿Cómo se conecta?": tres tarjetas grandes, una
/// decisión. Tocar una pasa al paso siguiente.
class PrinterTransportStep extends StatelessWidget {
  const PrinterTransportStep({required this.onPick, super.key});

  final ValueChanged<PrinterTransport> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrinterOptionCard(
          icon: AppIcon.bluetooth,
          title: 'Bluetooth',
          subtitle: 'Zebra portátil',
          onTap: () => onPick(PrinterTransport.bluetooth),
        ),
        PrinterOptionCard(
          icon: AppIcon.wifi,
          title: 'WiFi',
          subtitle: 'Impresora de red',
          onTap: () => onPick(PrinterTransport.wifi),
        ),
        PrinterOptionCard(
          icon: AppIcon.usb,
          title: 'Cable USB',
          subtitle: 'Conectada al teléfono',
          onTap: () => onPick(PrinterTransport.usb),
        ),
      ],
    );
  }
}
