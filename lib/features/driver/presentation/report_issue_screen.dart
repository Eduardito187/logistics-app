import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/widgets/app_snack.dart';
import '../domain/usecases/report_delivery_issue.dart';

/// Etiqueta en español de cada tipo de inconveniente.
String deliveryIssueLabel(DeliveryIssueType type) => switch (type) {
  DeliveryIssueType.delay => 'Demora o tráfico',
  DeliveryIssueType.access => 'Acceso restringido (portería, condominio)',
  DeliveryIssueType.customerRequest =>
    'El cliente pidió esperar o cambiar algo',
  DeliveryIssueType.addressUnclear => 'Dirección confusa o difícil de ubicar',
  DeliveryIssueType.other => 'Otro',
  DeliveryIssueType.$unknown => 'Otro',
};

/// Reporte de un inconveniente que NO cierra la entrega: se informa al backend
/// (torre de control) y el chofer sigue con la entrega. Para no entregar, usar
/// "No se pudo entregar".
class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  DeliveryIssueType? _type;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _noteRequired => _type == DeliveryIssueType.other;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar un inconveniente')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'La entrega sigue en curso. Si no vas a poder entregar, usá '
              '"No se pudo entregar".',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            for (final type in DeliveryIssueType.$valuesDefined)
              RadioListTile<DeliveryIssueType>(
                contentPadding: EdgeInsets.zero,
                value: type,
                groupValue: _type,
                onChanged: _busy ? null : (v) => setState(() => _type = v),
                title: Text(deliveryIssueLabel(type)),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _noteRequired
                    ? 'Contanos qué pasa (obligatorio)'
                    : 'Detalle (opcional)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Enviar reporte'),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_busy &&
      _type != null &&
      (!_noteRequired || _note.text.trim().isNotEmpty);

  Future<void> _submit() async {
    final type = _type;
    if (type == null) return;
    if (_noteRequired && _note.text.trim().isEmpty) {
      showErrorSnack(context, 'Contanos qué pasa.');
      return;
    }
    setState(() => _busy = true);
    try {
      // El GPS no debe trabar el reporte: si no hay fix rápido, va sin ubicación.
      final fix = await ref
          .read(locationServiceProvider)
          .current(timeout: const Duration(seconds: 4));
      if (!mounted) return;
      final outcome = await ref
          .read(reportDeliveryIssueProvider)
          .call(
            shipmentId: widget.stop.shipmentId,
            type: type,
            note: _note.text,
            lat: fix?.lat,
            lng: fix?.lng,
            occurredAt: DateTime.now(),
            label: 'Inconveniente · parada ${widget.stop.sequence}',
          );
      if (!mounted) return;
      showSubmitOutcome(context, outcome);
      if (outcome != SubmitOutcome.failed) Navigator.of(context).pop();
    } finally {
      // Garantiza liberar el botón aunque algo falle (coherente con las demás
      // pantallas de envío); si no, el reporte quedaría trabado con el spinner.
      if (mounted) setState(() => _busy = false);
    }
  }
}
