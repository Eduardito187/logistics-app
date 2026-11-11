import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/usecases/conduct_checklist.dart';
import '../domain/usecases/record_odometer.dart';
import 'controllers/driver_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'inspection_history_screen.dart';

/// Ítems canónicos de la inspección diaria del camión (diésel). La clave es la
/// que viaja al backend. Se priorizan los chequeos diarios de un diésel que
/// pidió el dueño: agua/refrigerante, frenos y funcionamiento del motor, más
/// aceite, fugas, llantas, luces, combustible y seguridad.
const Map<String, String> _checklistItems = {
  'engine': 'Motor: ruidos y funcionamiento',
  'oil': 'Aceite de motor',
  'coolant': 'Agua / refrigerante',
  'brakes': 'Frenos',
  'tires': 'Llantas y presión',
  'lights': 'Luces y direccionales',
  'leaks': 'Fugas (aceite, combustible, agua)',
  'fuel': 'Nivel de combustible',
  'extinguisher': 'Extintor',
  'documents': 'Documentos del vehículo',
};

/// Ítems CRÍTICOS de seguridad: si fallan, el camión NO está apto para salir
/// (no es una observación menor). Para un diésel, frenos y motor son los que no
/// se negocian.
const Set<String> _criticalItems = {'brakes', 'engine'};

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
  // Odómetro de salida: se captura acá (el momento de "salir del almacén") y se
  // registra con `source: departure`. El odómetro ya no se pide suelto.
  final TextEditingController _km = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    _km.dispose();
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
                    subtitle: _criticalItems.contains(entry.key)
                        ? const Text(
                            'Crítico para salir',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
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
            title: 'Odómetro de salida',
            child: TextField(
              controller: _km,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                labelText: 'Kilómetros al salir',
                helperText: 'Se registra como lectura de salida de ruta.',
                suffixText: 'km',
              ),
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InspectionHistoryScreen(),
                    ),
                  ),
            icon: const AnimatedAppIcon(AppIcon.orders),
            label: const Text('Ver historial de inspecciones'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String vehicleId, String driverId) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final km = int.tryParse(_km.text.trim());
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
      // Odómetro de salida: secundario respecto a la inspección. Se registra si
      // se cargó un valor; un fallo (p. ej. menor al último) NO frena el
      // checklist, solo se avisa suave.
      if (km != null && km > 0) {
        try {
          await ref
              .read(recordOdometerProvider)
              .call(
                vehicleId: vehicleId,
                km: km,
                source: RecordOdometerRequestSource.departure,
                readAt: DateTime.now(),
                note: 'Salida de ruta',
              );
        } on ApiException {
          if (mounted) {
            showInfoSnack(
              context,
              'El odómetro de salida no se pudo registrar.',
            );
          }
        }
      }
      final allPassed = _checks.values.every((v) => v);
      final status = result?.status;
      // Ítems críticos fallados (frenos/motor): el camión NO está apto. Se
      // avisa en ROJO y bien claro; igual queda registrado para el historial.
      final failedCritical = [
        for (final key in _criticalItems)
          if (_checks[key] == false) _checklistItems[key]!,
      ];
      final String message;
      final Color bg;
      final Color fg;
      if (allPassed) {
        message = 'Checklist registrado: apto para salir.';
        bg = AppColors.success;
        fg = Colors.white;
      } else if (failedCritical.isNotEmpty) {
        message =
            'NO apto para salir. Revisá: ${failedCritical.join(', ')}. '
            'No salgas sin resolverlo.';
        bg = AppColors.danger;
        fg = Colors.white;
      } else {
        message =
            'Checklist registrado con observaciones'
            '${status == null ? '' : ' ($status)'}.';
        // Sobre ámbar el texto claro no contrasta: tinta Noche (par de marca
        // ámbar+Noche).
        bg = AppColors.warning;
        fg = AppColors.accentInk;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: fg)),
          backgroundColor: bg,
          // El aviso crítico se queda más tiempo (es importante leerlo).
          duration: failedCritical.isNotEmpty
              ? const Duration(seconds: 6)
              : const Duration(seconds: 4),
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
