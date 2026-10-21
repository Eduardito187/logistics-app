import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/usecases/record_odometer.dart';
import 'controllers/fleet_ops_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/recent_readings.dart';

/// Registro de odómetro del vehículo del chofer. Lectura simple (km actual),
/// escritura con red. Lista las lecturas recientes.
class OdometerScreen extends ConsumerStatefulWidget {
  const OdometerScreen({super.key});

  @override
  ConsumerState<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends ConsumerState<OdometerScreen> {
  final TextEditingController _km = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _km.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DriverVehicleGate(
      title: 'Odómetro',
      builder: (context, vehicleId) {
        return ResponsiveBody(
          maxWidth: AppBreakpoints.maxFormWidth,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Nueva lectura',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _km,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kilómetros actuales',
                        suffixText: 'km',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _submit(vehicleId),
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.speed),
                      label: Text(_busy ? 'Registrando…' : 'Registrar lectura'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const RecentReadings(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(String vehicleId) async {
    final km = int.tryParse(_km.text.trim());
    if (km == null || km <= 0) {
      showErrorSnack(context, 'Ingresa los kilómetros actuales.');
      return;
    }
    final note = _note.text.trim();

    setState(() => _busy = true);
    try {
      // La llamada al backend vive en la capa de datos (caso de uso); la UI no
      // toca el API directamente.
      await ref
          .read(recordOdometerProvider)
          .call(
            vehicleId: vehicleId,
            km: km,
            source: RecordOdometerRequestSource.manual,
            readAt: DateTime.now(),
            note: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      ref.invalidate(vehicleOdometerReadingsProvider);
      _km.clear();
      _note.clear();
      showSuccessSnack(context, 'Lectura de odómetro registrada.');
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
