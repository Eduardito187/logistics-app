import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/responsive_body.dart';
import '../../../../core/widgets/empty_state.dart';
import 'carrier_scan_record.dart';
import 'scan_outcome_pill.dart';

/// Formato de hora de las filas: se crea una sola vez (no en cada build).
final DateFormat _timeFormat = DateFormat.Hm();

/// Cuerpo común de las pantallas de escaneo del transportista (recoger y
/// entregar): lista perezosa de los bultos de la sesión y el botón grande de
/// escanear fijo al pie. En tablets el contenido se centra con ancho máximo.
class CarrierScanSessionView extends StatelessWidget {
  const CarrierScanSessionView({
    super.key,
    required this.records,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.rowIcon,
    required this.actionLabel,
    required this.busy,
    required this.onAction,
    this.actionStyle,
  });

  final List<CarrierScanRecord> records;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final IconData rowIcon;
  final String actionLabel;
  final bool busy;
  final VoidCallback onAction;
  final ButtonStyle? actionStyle;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody(
      child: Column(
        children: [
          Expanded(
            child: records.isEmpty
                // Scrollable para que con letra grande en teléfonos chicos el
                // estado vacío no se desborde.
                ? SingleChildScrollView(
                    child: EmptyState(
                      icon: emptyIcon,
                      title: emptyTitle,
                      message: emptyMessage,
                    ),
                  )
                // ListView.builder: solo construye las filas visibles (una
                // sesión puede tener cientos de bultos en un teléfono de 1 GB).
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: records.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CarrierScanTile(
                        record: records[index],
                        icon: rowIcon,
                      ),
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onAction,
                  style: actionStyle,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(actionLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de un bulto escaneado en la sesión: SKU, id del bulto, hora y la
/// pastilla del resultado del envío (lo encolado se ve como "Enviado").
///
/// La pastilla va DEBAJO del texto (no a la derecha como en un ListTile): en un
/// teléfono de 320 dp con letra 1.3x la pastilla a la derecha dejaba ~100 dp
/// para el SKU y el id del bulto, que se partían en muchas líneas.
class CarrierScanTile extends StatelessWidget {
  const CarrierScanTile({super.key, required this.record, required this.icon});

  final CarrierScanRecord record;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.unitId,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ScanOutcomePill(record.outcome),
                      Text(
                        _timeFormat.format(record.at),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
