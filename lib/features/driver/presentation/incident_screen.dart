import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/widgets/section_card.dart';
import 'driver_common.dart';
import 'driver_vehicle_gate.dart';

/// Reporte de incidente del vehículo (avería o accidente). MINOR retrasa la ETA
/// de las paradas pendientes; MAJOR saca el vehículo de servicio y reprograma.
class IncidentScreen extends ConsumerStatefulWidget {
  const IncidentScreen({super.key});

  @override
  ConsumerState<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends ConsumerState<IncidentScreen> {
  Type _type = Type.breakdown;
  Severity _severity = Severity.minor;
  final TextEditingController _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DriverVehicleGate(
      title: 'Reportar incidente',
      builder: (context, vehicleId) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Tipo de incidente',
              child: RadioGroup<Type>(
                groupValue: _type,
                onChanged: (v) {
                  if (_busy || v == null) return;
                  setState(() => _type = v);
                },
                child: Column(
                  children: [
                    for (final type in Type.$valuesDefined)
                      RadioListTile<Type>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_typeLabel(type)),
                        value: type,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Gravedad',
              child: RadioGroup<Severity>(
                groupValue: _severity,
                onChanged: (v) {
                  if (_busy || v == null) return;
                  setState(() => _severity = v);
                },
                child: Column(
                  children: [
                    for (final severity in Severity.$valuesDefined)
                      RadioListTile<Severity>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_severityLabel(severity)),
                        subtitle: Text(_severityHint(severity)),
                        value: severity,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Descripción',
              child: TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Qué pasó (opcional)',
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: _busy ? null : () => _report(vehicleId),
              icon: const Icon(Icons.report),
              label: const Text('Reportar incidente'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _report(String vehicleId) async {
    setState(() => _busy = true);
    try {
      final fix = await currentFix(ref);
      if (!mounted) return;
      final now = DateTime.now();
      final note = _note.text.trim();
      final payload = <String, Object?>{
        ...AppVehiclesVehicleIdIncidentsRequestBody(
          severity: _severity,
          type: _type,
          note: note.isEmpty ? null : note,
          lat: fix?.lat,
          lng: fix?.lng,
          occurredAt: now,
        ).toJson(),
        '@vehicleId': vehicleId,
      };
      final outcome = await ref
          .read(offlineQueueProvider)
          .submit(
            kind: 'reportVehicleIncident',
            payload: payload,
            label: 'Incidente · ${_typeLabel(_type)}',
            occurredAt: now,
          );
      if (!mounted) return;
      showSubmitOutcome(context, outcome);
      if (outcome != SubmitOutcome.failed) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

String _typeLabel(Type type) => switch (type) {
  Type.breakdown => 'Avería',
  Type.accident => 'Accidente',
  _ => 'Incidente',
};

String _severityLabel(Severity severity) => switch (severity) {
  Severity.minor => 'Menor',
  Severity.major => 'Grave',
  _ => 'Gravedad',
};

String _severityHint(Severity severity) => switch (severity) {
  Severity.minor => 'La ruta sigue con ETAs retrasadas.',
  Severity.major =>
    'Vehículo fuera de servicio; se reprograma al día siguiente.',
  _ => '',
};
