import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/odometer_check.dart';
import '../domain/usecases/record_odometer.dart';
import 'controllers/fleet_ops_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/recent_readings.dart';

/// Registro de odómetro del vehículo del chofer. Lectura simple (km actual),
/// escritura con red. Lista las lecturas recientes.
///
/// El odómetro solo se pide en dos momentos de la ruta (decisión del dueño): al
/// SALIR (va en el checklist pre-salida, `source: departure`) y al LLEGAR al
/// centro de distribución. Esta pantalla sirve para la lectura de LLEGADA: se
/// abre al finalizar la ruta con [source]/[title]/[intro]/[initialNote]
/// preseteados. Los valores por defecto mantienen el comportamiento genérico
/// para los tests existentes.
class OdometerScreen extends ConsumerStatefulWidget {
  const OdometerScreen({
    super.key,
    this.source = RecordOdometerRequestSource.manual,
    this.title = 'Odómetro',
    this.intro,
    this.initialNote,
  });

  /// Origen de la lectura que viaja al backend (p. ej. `departure`/`manual`).
  final RecordOdometerRequestSource source;

  /// Título de la barra superior.
  final String title;

  /// Texto guía opcional sobre el campo (p. ej. "al llegar al CD").
  final String? intro;

  /// Nota precargada (p. ej. "Llegada al CD").
  final String? initialNote;

  @override
  ConsumerState<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends ConsumerState<OdometerScreen> {
  final TextEditingController _km = TextEditingController();
  late final TextEditingController _note = TextEditingController(
    text: widget.initialNote ?? '',
  );
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
      title: widget.title,
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
                    if (widget.intro != null) ...[
                      Text(
                        widget.intro!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
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
                      icon: AnimatedAppIcon(
                        AppIcon.speed,
                        state: _busy ? AppIconState.loading : AppIconState.idle,
                      ),
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
    // El odómetro solo avanza: se avisa en el acto si retrocede (mismo guard
    // del backend, adelantado para no pagar el viaje de red ni confundir).
    final lastKm = odometerBelowLast(
      km,
      ref.read(vehicleOdometerReadingsProvider).value ?? const [],
    );
    if (lastKm != null) {
      showErrorSnack(
        context,
        'No puede ser menor al último registro ($lastKm km).',
      );
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
            source: widget.source,
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
