import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/usecases/conduct_checklist.dart';
import 'controllers/driver_controllers.dart';
import 'driver_vehicle_gate.dart';

/// Ítems canónicos del checklist pre-salida. La clave es la que viaja al backend.
const Map<String, String> _checklistItems = {
  'tires': 'Llantas y presión',
  'brakes': 'Frenos',
  'lights': 'Luces y direccionales',
  'fluids': 'Niveles (aceite, agua)',
  'mirrors': 'Espejos',
  'seatbelt': 'Cinturón de seguridad',
  'extinguisher': 'Extintor',
  'documents': 'Documentos del vehículo',
};

/// Checklist pre-salida del camión. Es una escritura en línea (no va por la cola
/// offline): registra la inspección contra el backend. El chofer que firma es el
/// ASIGNADO al camión (el del crew, ya visible en la cabecera): no se pregunta.
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final Map<String, bool> _checks = {
    for (final key in _checklistItems.keys) key: false,
  };
  final TextEditingController _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DriverVehicleGate(
      title: 'Checklist pre-salida',
      builder: (context, vehicleId) {
        // Dentro del gate el crew ya está resuelto: el chofer que firma es el
        // asignado al camión (no se elige de una lista).
        final driver = ref.watch(myCrewProvider).value?.driver;
        if (driver == null) {
          return const EmptyState(
            icon: AppIcon.personOff,
            title: 'Sin chofer asignado',
            message: 'El camión no tiene un chofer asignado para firmar.',
          );
        }
        return _buildForm(context, vehicleId, driver);
      },
    );
  }

  Widget _buildForm(BuildContext context, String vehicleId, Driver driver) {
    final passedCount = _checks.values.where((v) => v).length;
    return ResponsiveBody(
      maxWidth: AppBreakpoints.maxFormWidth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Inspección ($passedCount/${_checklistItems.length})',
            child: Column(
              children: [
                for (final entry in _checklistItems.entries)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value),
                    value: _checks[entry.key] ?? false,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _checks[entry.key] = v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Observaciones',
            child: TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Notas opcionales de la inspección',
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : () => _submit(vehicleId, driver.id),
            icon: AnimatedAppIcon(
              AppIcon.save,
              state: _busy ? AppIconState.loading : AppIconState.idle,
            ),
            label: const Text('Registrar checklist'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String vehicleId, String driverId) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await ref
          .read(conductChecklistProvider)
          .call(
            vehicleId: vehicleId,
            driverId: driverId,
            items: Map<String, bool>.from(_checks),
            performedOn: DateTime.now(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      final allPassed = _checks.values.every((v) => v);
      final status = result?.status;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            allPassed
                ? 'Checklist registrado: apto para salir.'
                : 'Checklist registrado con observaciones'
                      '${status == null ? '' : ' ($status)'}.',
            // Sobre ámbar el texto claro no contrasta: tinta Noche (par de marca
            // ámbar+Noche). Sobre verde, texto claro.
            style: TextStyle(
              color: allPassed ? Colors.white : AppColors.accentInk,
            ),
          ),
          backgroundColor: allPassed ? AppColors.success : AppColors.warning,
        ),
      );
      navigator.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
