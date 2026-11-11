import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import 'controllers/inspection_history_controller.dart';
import 'driver_vehicle_gate.dart';

// Formato creado una vez (no en cada build).
final DateFormat _dateFormat = DateFormat('EEEE d MMM y, HH:mm', 'es');

/// Historial de inspecciones diarias (checklist pre-salida) del camión asignado
/// al chofer (solo lectura). La inspección pre-salida ES la inspección diaria.
class InspectionHistoryScreen extends ConsumerWidget {
  const InspectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DriverVehicleGate(
      title: 'Inspecciones del camión',
      builder: (context, vehicleId) {
        final history = ref.watch(inspectionHistoryProvider(vehicleId));
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(inspectionHistoryProvider(vehicleId)),
          child: ResponsiveBody(
            child: AsyncValueView<List<PreTripChecklist>>(
              value: history,
              onRetry: () =>
                  ref.invalidate(inspectionHistoryProvider(vehicleId)),
              data: (items) {
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: AppIcon.checklist,
                        title: 'Sin inspecciones',
                        message:
                            'Las inspecciones del camión que registres '
                            'aparecerán aquí.',
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _inspectionCard(context, items[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta de una inspección: fecha, resultado (apto / con observaciones),
/// ítems pendientes y notas.
Widget _inspectionCard(BuildContext context, PreTripChecklist checklist) {
  final theme = Theme.of(context);
  final passed = checklist.passed ?? false;
  final performed = checklist.performedOn;
  final pending = checklist.pending ?? const <String>[];
  final notes = checklist.notes;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  performed == null
                      ? 'Fecha desconocida'
                      : _dateFormat.format(performed.toLocal()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                passed ? 'Apto' : 'Con observaciones',
                tone: passed ? PillTone.success : PillTone.warning,
                icon: passed ? AppIcon.verified : AppIcon.incident,
              ),
            ],
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Pendientes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final item in pending)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $item'),
              ),
          ],
          if (notes != null && notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notas',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(notes),
          ],
        ],
      ),
    ),
  );
}
