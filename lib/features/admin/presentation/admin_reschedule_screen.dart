import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../data/admin_remote_data_source.dart';
import '../domain/entities/admin_vehicle.dart';
import 'staff_labels.dart';
import 'widgets/staff_pickers.dart';

/// Qué pedidos alcanza la reprogramación.
enum RescheduleScope { shipments, vehicle, city }

/// Pedido puntual a reprogramar (viene del detalle de un envío).
typedef RescheduleTarget = ({String shipmentId, String orderNumber});

/// Reprogramar pedidos: uno puntual, todos los de un camión o todos los de una
/// ciudad.
///
/// Siempre en dos pasos: primero la VISTA PREVIA ("vas a reprogramar 37
/// pedidos", cuáles y cuáles se saltean por estar cerrados) y recién después
/// la confirmación. El backend respeta las fechas bloqueadas del calendario.
class AdminRescheduleScreen extends ConsumerStatefulWidget {
  const AdminRescheduleScreen({super.key, this.target});

  /// Si viene, se reprograma SOLO ese pedido (sin elegir alcance).
  final RescheduleTarget? target;

  @override
  ConsumerState<AdminRescheduleScreen> createState() =>
      _AdminRescheduleScreenState();
}

class _AdminRescheduleScreenState extends ConsumerState<AdminRescheduleScreen> {
  final TextEditingController _city = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  late RescheduleScope _scope = widget.target == null
      ? RescheduleScope.vehicle
      : RescheduleScope.shipments;
  AdminVehicle? _vehicle;

  /// Acota camión/ciudad a los pedidos comprometidos para ESE día.
  DateTime? _routeDate;
  DateTime? _newDate;
  TimeOfDay _from = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 18, minute: 0);
  bool _notify = true;
  bool _busy = false;

  /// Vista previa vigente; se descarta al cambiar cualquier dato.
  RescheduleShipmentsResult? _preview;

  @override
  void dispose() {
    _city.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _changed(VoidCallback update) => setState(() {
    update();
    _preview = null;
  });

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  /// Arma el pedido, o `null` (con aviso) si falta algún dato.
  RescheduleShipmentsRequest? _request() {
    final newDate = _newDate;
    if (newDate == null) {
      showInfoSnack(context, 'Elegí la nueva fecha de entrega.');
      return null;
    }
    final Scope scope;
    switch (_scope) {
      case RescheduleScope.shipments:
        scope = Scope(shipmentIds: [widget.target!.shipmentId]);
      case RescheduleScope.vehicle:
        final vehicle = _vehicle;
        if (vehicle == null) {
          showInfoSnack(context, 'Elegí el camión.');
          return null;
        }
        scope = Scope(vehicleId: vehicle.id, routeDate: _routeDate);
      case RescheduleScope.city:
        final city = _city.text.trim();
        if (city.isEmpty) {
          showInfoSnack(context, 'Escribí la ciudad.');
          return null;
        }
        scope = Scope(city: city, routeDate: _routeDate);
    }
    final reason = _reason.text.trim();
    return RescheduleShipmentsRequest(
      scope: scope,
      newDate: newDate,
      windowStart: _hhmm(_from),
      windowEnd: _hhmm(_to),
      reason: reason.isEmpty ? null : reason,
      notifyCustomer: _notify,
    );
  }

  Future<void> _loadPreview() async {
    final request = _request();
    if (request == null) return;
    setState(() => _busy = true);
    try {
      final preview = await ref
          .read(adminRemoteDataSourceProvider)
          .previewReschedule(request);
      if (mounted) setState(() => _preview = preview);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final request = _request();
    if (request == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(adminRemoteDataSourceProvider)
          .reschedule(request);
      if (!mounted) return;
      final count = result.count ?? 0;
      final failed = result.failed?.length ?? 0;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            count == 1
                ? '1 pedido reprogramado'
                : '$count pedidos reprogramados',
          ),
          content: Text(
            failed == 0
                ? 'Quedaron para el ${staffDate(request.newDate)}.'
                : 'Quedaron para el ${staffDate(request.newDate)}. '
                      '$failed no se pudieron reprogramar: revisalos.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      if (mounted) await Navigator.of(context).maybePop();
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<DateTime?> _pickDate(DateTime? initial, {bool future = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: initial ?? today,
      firstDate: future ? today : today.subtract(const Duration(days: 60)),
      lastDate: today.add(const Duration(days: 180)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Reprogramar pedidos')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '1. Qué pedidos',
              child: target != null
                  ? Text(
                      'Pedido ${target.orderNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : _scopeFields(),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '2. Nueva fecha y horario',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            final date = await _pickDate(_newDate);
                            if (date != null) _changed(() => _newDate = date);
                          },
                    icon: const AnimatedAppIcon(AppIcon.myDay),
                    label: Text(
                      _newDate == null
                          ? 'Elegir nueva fecha'
                          : 'Nueva fecha: ${staffDate(_newDate!)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _timeButton('Desde', _from, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _timeButton('Hasta', _to, false)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reason,
                    enabled: !_busy,
                    maxLines: 2,
                    minLines: 1,
                    onChanged: (_) {
                      if (_preview != null) setState(() => _preview = null);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Motivo (opcional)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _notify,
                    onChanged: _busy
                        ? null
                        : (value) => _changed(() => _notify = value),
                    title: const Text('Avisar a los clientes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (preview == null)
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _loadPreview,
                  icon: AnimatedAppIcon(
                    AppIcon.search,
                    state: _busy ? AppIconState.loading : AppIconState.idle,
                    excludeFromSemantics: true,
                  ),
                  label: const Text('Ver qué se reprograma'),
                ),
              )
            else
              _PreviewCard(preview: preview, busy: _busy, onApply: _apply),
          ],
        ),
      ),
    );
  }

  Widget _timeButton(String label, TimeOfDay value, bool isFrom) =>
      OutlinedButton(
        onPressed: _busy
            ? null
            : () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: value,
                );
                if (picked == null) return;
                _changed(() => isFrom ? _from = picked : _to = picked);
              },
        child: Text('$label ${_hhmm(value)}'),
      );

  Widget _scopeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<RescheduleScope>(
          segments: const [
            ButtonSegment(
              value: RescheduleScope.vehicle,
              label: Text('Un camión'),
            ),
            ButtonSegment(
              value: RescheduleScope.city,
              label: Text('Una ciudad'),
            ),
          ],
          selected: {_scope},
          onSelectionChanged: _busy
              ? null
              : (selection) => _changed(() => _scope = selection.first),
        ),
        const SizedBox(height: 12),
        if (_scope == RescheduleScope.vehicle)
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final vehicle = await showVehiclePickerSheet(context);
                    if (vehicle != null) _changed(() => _vehicle = vehicle);
                  },
            icon: const AnimatedAppIcon(AppIcon.deliver),
            label: Text(
              _vehicle == null
                  ? 'Elegir camión'
                  : 'Camión ${_vehicle!.displayPlate}',
            ),
          )
        else
          TextField(
            controller: _city,
            enabled: !_busy,
            onChanged: (_) {
              if (_preview != null) setState(() => _preview = null);
            },
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              hintText: 'Santa Cruz, La Paz…',
            ),
          ),
        const SizedBox(height: 12),
        // Sin esto entran TODOS los pedidos abiertos del camión/ciudad.
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final date = await _pickDate(_routeDate, future: false);
                  if (date != null) _changed(() => _routeDate = date);
                },
          icon: const AnimatedAppIcon(AppIcon.myDay),
          label: Text(
            _routeDate == null
                ? 'Solo los de un día (opcional)'
                : 'Solo los del ${staffDate(_routeDate!)}',
          ),
        ),
        if (_routeDate != null)
          TextButton(
            onPressed: _busy ? null : () => _changed(() => _routeDate = null),
            child: const Text('Incluir todos los días'),
          ),
      ],
    );
  }
}

/// Vista previa: cuántos pedidos se reprograman, cuáles y cuáles se saltean.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.preview,
    required this.busy,
    required this.onApply,
  });

  final RescheduleShipmentsResult preview;
  final bool busy;
  final VoidCallback onApply;

  /// Filas que se listan; el resto se resume ("y 30 más").
  static const int _maxRows = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shipments = preview.shipments ?? const <Shipments2>[];
    final count = preview.count ?? shipments.length;
    final skipped = preview.skippedCount ?? preview.skipped?.length ?? 0;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SectionCard(
      title: '3. Confirmar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            count == 0
                ? 'No hay pedidos para reprogramar con esos datos.'
                : count == 1
                ? 'Vas a reprogramar 1 pedido.'
                : 'Vas a reprogramar $count pedidos.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (skipped > 0)
            Text(
              skipped == 1
                  ? '1 se saltea porque ya está cerrado.'
                  : '$skipped se saltean porque ya están cerrados.',
              style: muted,
            ),
          const SizedBox(height: 8),
          for (final s in shipments.take(_maxRows))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                [
                  'Pedido ${s.externalId ?? '—'}',
                  if (s.customerName != null) s.customerName!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (shipments.length > _maxRows)
            Text('y ${shipments.length - _maxRows} más', style: muted),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: busy || count == 0 ? null : onApply,
              icon: AnimatedAppIcon(
                AppIcon.success,
                state: busy ? AppIconState.loading : AppIconState.idle,
                excludeFromSemantics: true,
              ),
              label: Text(
                count == 1
                    ? 'Reprogramar 1 pedido'
                    : 'Reprogramar $count pedidos',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
