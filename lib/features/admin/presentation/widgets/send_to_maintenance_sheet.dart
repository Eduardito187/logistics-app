import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../data/admin_remote_data_source.dart';
import '../../domain/entities/admin_vehicle.dart';
import '../../domain/entities/maintenance_result.dart';
import 'staff_pickers.dart';

/// Abre el formulario para mandar [vehicle] a mantenimiento. Devuelve el
/// resultado si se envió, o `null` si se canceló.
Future<MaintenanceResult?> showSendToMaintenanceSheet(
  BuildContext context,
  AdminVehicle vehicle,
) => showModalBottomSheet<MaintenanceResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => SendToMaintenanceSheet(vehicle: vehicle),
);

/// Manda un camión a mantenimiento ahora: tipo, taller y nota. El backend abre
/// la orden y deja el camión en mantenimiento en una sola llamada.
class SendToMaintenanceSheet extends ConsumerStatefulWidget {
  const SendToMaintenanceSheet({super.key, required this.vehicle});

  final AdminVehicle vehicle;

  @override
  ConsumerState<SendToMaintenanceSheet> createState() =>
      _SendToMaintenanceSheetState();
}

class _SendToMaintenanceSheetState
    extends ConsumerState<SendToMaintenanceSheet> {
  final TextEditingController _workshop = TextEditingController();
  final TextEditingController _note = TextEditingController();
  MaintenanceType _type = MaintenanceType.corrective;

  /// Camión que toma las paradas pendientes de la ruta de este (opcional).
  AdminVehicle? _takeover;
  bool _busy = false;

  @override
  void dispose() {
    _workshop.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(adminRemoteDataSourceProvider)
          .sendToMaintenance(
            widget.vehicle.id,
            type: _type,
            workshop: _workshop.text.trim(),
            note: _note.text.trim(),
            reassignToVehicleId: _takeover?.id,
          );
      if (mounted) Navigator.of(context).pop(result);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        // El teclado no tapa los campos ni el botón.
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mandar a mantenimiento',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text('Camión ${widget.vehicle.displayPlate}'),
            const SizedBox(height: 12),
            for (final type in MaintenanceType.values)
              RadioListTile<MaintenanceType>(
                contentPadding: EdgeInsets.zero,
                value: type,
                groupValue: _type,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _type = value ?? _type),
                title: Text(type.label),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _workshop,
              enabled: !_busy,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Taller (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Motivo o nota (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            // Si el camión tiene paradas pendientes hoy, otro camión puede
            // tomarlas; si no se elige, quedan liberadas para asignarlas después.
            Text(
              'Si tiene pedidos pendientes hoy',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final picked = await showVehiclePickerSheet(context);
                      if (picked == null || !context.mounted) return;
                      if (picked.id == widget.vehicle.id) {
                        showInfoSnack(context, 'Elegí OTRO camión.');
                        return;
                      }
                      setState(() => _takeover = picked);
                    },
              icon: const AnimatedAppIcon(
                AppIcon.swap,
                excludeFromSemantics: true,
              ),
              label: Text(
                _takeover == null
                    ? 'Pasarlos a otro camión (opcional)'
                    : 'Los toma el camión ${_takeover!.displayPlate}',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: AnimatedAppIcon(
                  AppIcon.settings,
                  state: _busy ? AppIconState.loading : AppIconState.idle,
                  excludeFromSemantics: true,
                ),
                label: const Text('Mandar a mantenimiento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
