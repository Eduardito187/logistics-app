import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/wifi_printer_hit.dart';
import '../../../../core/widgets/status_pill.dart';
import 'printer_option_card.dart';

/// Impresora encontrada en la red, como tarjeta grande: nombre, `ip:puerto` y
/// marca: "Zebra" (lista para etiquetas), "No es Zebra" (advertencia: el ZPL
/// saldría como texto) o "Modelo desconocido" si no se pudo identificar.
class WifiPrinterHitTile extends StatelessWidget {
  const WifiPrinterHitTile({
    required this.hit,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final WifiPrinterHit hit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PrinterOptionCard(
      icon: AppIcon.printing,
      title: hit.displayName,
      subtitle: hit.name == null
          ? '${hit.address} · Modelo desconocido'
          : hit.address,
      selected: selected,
      onTap: onTap,
      trailing: hit.isZebra
          ? const StatusPill('Zebra', tone: PillTone.success)
          : hit.isKnownNonZebra
          ? const StatusPill('No es Zebra', tone: PillTone.warning)
          : null,
    );
  }
}
