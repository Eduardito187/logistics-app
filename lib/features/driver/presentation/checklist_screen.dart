import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/async_value_view.dart';
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
/// offline): registra la inspección contra el backend.
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
  String? _driverId;
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
        final drivers = ref.watch(driversProvider);
        return AsyncValueView<List<Driver>>(
          value: drivers,
          onRetry: () => ref.invalidate(driversProvider),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.person_off,
                title: 'Sin choferes',
                message: 'No hay choferes activos para firmar el checklist.',
              );
            }
            return _buildForm(context, vehicleId, list);
          },
        );
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    String vehicleId,
    List<Driver> drivers,
  ) {
    final passedCount = _checks.values.where((v) => v).length;
    return ResponsiveBody(
      maxWidth: AppBreakpoints.maxFormWidth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Chofer',
            child: DropdownButtonFormField<String>(
              value: _driverId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Selecciona el chofer',
              ),
              items: [
                for (final driver in drivers)
                  DropdownMenuItem<String>(
                    value: driver.id,
                    child: Text(driver.name ?? driver.id),
                  ),
              ],
              onChanged: _busy ? null : (v) => setState(() => _driverId = v),
            ),
          ),
          const SizedBox(height: 16),
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
            onPressed: _driverId != null && !_busy
                ? () => _submit(vehicleId)
                : null,
            icon: const Icon(Icons.save),
            label: const Text('Registrar checklist'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String vehicleId) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await ref
          .read(conductChecklistProvider)
          .call(
            vehicleId: vehicleId,
            driverId: _driverId!,
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
          ),
          backgroundColor: allPassed
              ? Colors.green.shade700
              : Colors.orange.shade800,
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
