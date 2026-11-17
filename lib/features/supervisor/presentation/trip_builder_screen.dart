import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/plan.dart';
import '../../../core/api/models/trip_candidate.dart';
import '../../../core/api/models/trip_candidate_list.dart';
import '../../../core/api/models/trip_sequence_suggestion.dart';
import '../../../core/api/models/trip_sequence_warning_code.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/repositories/supervisor_repository_impl.dart';
import '../domain/trip_already_planned.dart';
import 'controllers/supervisor_controllers.dart';
import 'controllers/trip_vehicle_picker.dart';
import 'supervisor_labels.dart';

/// Armar un viaje: "este camión sale y entrega estos pedidos".
///
/// Se elige el camión y el backend propone los pedidos MÁS CERCANOS a su base;
/// al sumar uno, propone los más cercanos a ese. Con dos o más paradas el
/// backend calcula el mejor orden (camino más corto, respetando la hora que
/// pidió cada cliente) y avisa si algo no llega a tiempo o no entra. La app
/// no decide cercanías ni órdenes: solo muestra lo que razona el servidor.
///
/// Al guardar queda un plan EN BORRADOR; se revisa y se publica en su detalle.
class TripBuilderScreen extends ConsumerStatefulWidget {
  const TripBuilderScreen({super.key});

  @override
  ConsumerState<TripBuilderScreen> createState() => _TripBuilderScreenState();
}

class _TripBuilderScreenState extends ConsumerState<TripBuilderScreen> {
  late DateTime _date = ref.read(plansDateProvider);
  TimeOfDay _departTime = const TimeOfDay(hour: 8, minute: 0);
  TripVehicle? _vehicle;

  /// Paradas del viaje, en orden.
  final List<TripCandidate> _trip = <TripCandidate>[];

  /// Pedidos cercanos al último elegido (o a la base), según el backend.
  TripCandidateList? _near;
  Object? _nearError;
  bool _loadingNear = false;

  /// Orden recomendado para las paradas actuales (`null` con menos de dos).
  TripSequenceSuggestion? _suggestion;

  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  bool _saving = false;

  /// Descarta respuestas viejas si el viaje cambió mientras llegaban.
  int _generation = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  DateTime get _departAt => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _departTime.hour,
    _departTime.minute,
  );

  List<String> get _ids => [for (final stop in _trip) stop.shipmentId];

  /// Vuelve a pedirle al backend los cercanos y el orden recomendado.
  Future<void> _reload() async {
    final vehicle = _vehicle;
    if (vehicle == null) return;
    final generation = ++_generation;
    setState(() {
      _loadingNear = true;
      _nearError = null;
    });
    final repo = ref.read(supervisorRepositoryProvider);
    final ids = _ids;
    try {
      final near = await repo.listTripCandidates(
        date: _date,
        vehicleId: vehicle.id,
        departAt: _departAt,
        selected: ids,
        query: _search.text.trim(),
      );
      if (!mounted || generation != _generation) return;
      setState(() => _near = near);
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _nearError = error);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingNear = false);
      }
    }
    TripSequenceSuggestion? suggestion;
    if (ids.length >= 2) {
      try {
        suggestion = await repo.suggestTripSequence(
          date: _date,
          vehicleId: vehicle.id,
          departAt: _departAt,
          shipmentIds: ids,
        );
      } on Object {
        // Sin sugerencia: el viaje se puede armar igual, en el orden elegido.
        suggestion = null;
      }
    }
    if (!mounted || generation != _generation) return;
    setState(() => _suggestion = suggestion);
  }

  Future<void> _pickVehicle() async {
    final picked = await ref.read(tripVehiclePickerProvider)(context);
    if (picked == null || !mounted) return;
    setState(() {
      _vehicle = picked;
      // Otro camión, otra base: se empieza el viaje de nuevo.
      _trip.clear();
      _near = null;
      _suggestion = null;
    });
    await _reload();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Día del viaje',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _trip.clear();
      _suggestion = null;
    });
    await _reload();
  }

  Future<void> _pickDepartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departTime,
      helpText: 'Hora de salida',
    );
    if (picked == null || !mounted) return;
    setState(() => _departTime = picked);
    await _reload();
  }

  void _add(TripCandidate candidate) {
    setState(() => _trip.add(candidate));
    unawaited(_reload());
  }

  void _removeAt(int index) {
    setState(() => _trip.removeAt(index));
    unawaited(_reload());
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _trip.length) return;
    setState(() => _trip.insert(target, _trip.removeAt(index)));
    unawaited(_reload());
  }

  /// Deja las paradas en el orden que recomienda el backend.
  void _useSuggestedOrder() {
    final suggestion = _suggestion;
    if (suggestion == null) return;
    final byId = {for (final stop in _trip) stop.shipmentId: stop};
    final ordered = [
      for (final id in suggestion.orderedShipmentIds) ?byId.remove(id),
      ...byId.values,
    ];
    setState(() {
      _trip
        ..clear()
        ..addAll(ordered);
    });
    unawaited(_reload());
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  Future<void> _save() async {
    final vehicle = _vehicle;
    if (vehicle == null || _trip.isEmpty) return;
    // Los pedidos que armó el usuario, para verificar que el plan guardado sea
    // EL SUYO (no uno ajeno que el backend pudiera devolver).
    final requested = _ids.toSet();
    setState(() => _saving = true);
    try {
      final plan = await ref
          .read(supervisorRepositoryProvider)
          .createTrip(
            date: _date,
            vehicleId: vehicle.id,
            departAt: _departAt,
            shipmentIds: _ids,
          );
      if (!mounted) return;
      // Guarda de integridad: el plan creado DEBE contener los pedidos que armé.
      // Si el backend devolvió OTRO plan (p. ej. uno ya existente de ese camión
      // ese día, con pedidos que nunca elegí), NO decir "guardado" ni mandar en
      // silencio a un plan ajeno: se avisa y se CONSERVA el viaje armado para no
      // perder el trabajo. (Si la respuesta no trae paradas todavía —se calculan
      // async— no se puede verificar: se confía y se abre.)
      final saved = plan.stops.map((s) => s.shipmentId).toSet();
      if (plan.stops.isNotEmpty && !saved.containsAll(requested)) {
        showErrorSnack(
          context,
          'El viaje no se guardó con los pedidos que armaste: ese camión ya '
          'tiene un viaje ese día. Elegí otro camión o abrí el viaje existente.',
          actionLabel: 'Ver viaje',
          onAction: () => _openPlan(plan.id, plan: plan),
          bottomClearance: kBottomActionClearance,
        );
        return; // conserva el builder con las paradas armadas
      }
      _openPlan(plan.id, plan: plan);
      showSuccessSnack(context, 'Viaje guardado. Revisalo y publicalo.');
    } on TripAlreadyPlanned catch (existing) {
      if (!mounted) return;
      // NO destruir el viaje armado ni abrir un plan ajeno en silencio: se avisa
      // claro y se conserva el armado; con el botón se abre el viaje existente.
      showErrorSnack(
        context,
        'Ese camión ya tiene un viaje ese día. Elegí otro camión o abrí el '
        'viaje existente para sumarle los pedidos.',
        actionLabel: 'Ver viaje',
        onAction: () => _openPlan(existing.planId),
        bottomClearance: kBottomActionClearance,
      );
    } on Object catch (error) {
      if (mounted) {
        showErrorSnack(
          context,
          error,
          bottomClearance: kBottomActionClearance,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openPlan(String planId, {Plan? plan}) {
    ref.invalidate(plansProvider);
    context.pushReplacement('/supervisor/plans/$planId', extra: plan);
  }

  String _orderName(String shipmentId) {
    for (var i = 0; i < _trip.length; i++) {
      if (_trip[i].shipmentId == shipmentId) {
        return stopTitle(_trip[i].orderReference, i + 1);
      }
    }
    return 'Un pedido';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = _vehicle;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Armar un viaje')),
      // FIJO al pie: no hay que deslizar toda la lista para guardar.
      bottomNavigationBar: vehicle == null
          ? null
          : Material(
              elevation: 8,
              color: theme.colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _saving || _trip.isEmpty ? null : _save,
                      icon: AnimatedAppIcon(
                        AppIcon.save,
                        state: _saving
                            ? AppIconState.loading
                            : AppIconState.idle,
                        excludeFromSemantics: true,
                      ),
                      label: Text(
                        _trip.isEmpty
                            ? 'Guardar viaje'
                            : _trip.length == 1
                            ? 'Guardar viaje · 1 parada'
                            : 'Guardar viaje · ${_trip.length} paradas',
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxContentWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '1. Camión y salida',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickVehicle,
                    icon: const AnimatedAppIcon(
                      AppIcon.deliver,
                      excludeFromSemantics: true,
                    ),
                    label: Text(
                      vehicle == null
                          ? 'Elegir camión'
                          : 'Camión ${vehicle.plate} · Cambiar',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _pickDate,
                          child: Text('Día ${formatDay(_date)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _pickDepartTime,
                          child: Text('Sale ${_departTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (vehicle == null) ...[
              const SizedBox(height: 24),
              Text(
                'Elegí el camión y te mostramos los pedidos más cercanos a '
                'su base para ir armando el viaje.',
                style: muted,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 16),
              _tripCard(theme, muted),
              const SizedBox(height: 16),
              _nearCard(theme, muted),
            ],
          ],
        ),
      ),
    );
  }

  /// Paradas elegidas, el orden que recomienda el backend y sus avisos.
  Widget _tripCard(ThemeData theme, TextStyle? muted) {
    final suggestion = _suggestion;
    final capacity = _near?.meta.capacity;
    final usedKg = capacity?.usedKg;
    final maxKg = capacity?.maxKg;
    return SectionCard(
      title: _trip.isEmpty
          ? '2. Tu viaje'
          : '2. Tu viaje · ${_trip.length} '
                '${_trip.length == 1 ? 'parada' : 'paradas'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_trip.isEmpty)
            Text('Sumá pedidos de la lista de abajo.', style: muted),
          if (usedKg != null && maxKg != null && _trip.isNotEmpty)
            Text(
              'Carga: ${usedKg.round()} de ${maxKg.round()} kg',
              style: muted,
            ),
          for (var i = 0; i < _trip.length; i++)
            _TripStopRow(
              key: ValueKey(_trip[i].shipmentId),
              position: i + 1,
              stop: _trip[i],
              onUp: i == 0 ? null : () => _move(i, -1),
              onDown: i == _trip.length - 1 ? null : () => _move(i, 1),
              onRemove: () => _removeAt(i),
            ),
          if (suggestion != null) ...[
            const SizedBox(height: 8),
            Text(
              'Recorrido ${formatKm(suggestion.distanceKm)} · '
              '${formatDuration(suggestion.durationMinutes)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final warning in suggestion.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_orderName(warning.shipmentId)}: '
                  '${tripWarningText(warning.code)}',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (suggestion.changed) ...[
              const SizedBox(height: 8),
              Text('Hay un orden mejor para este viaje.', style: muted),
              const SizedBox(height: 4),
              FilledButton.tonalIcon(
                onPressed: _saving ? null : _useSuggestedOrder,
                icon: const AnimatedAppIcon(
                  AppIcon.route,
                  excludeFromSemantics: true,
                ),
                label: const Text('Usar el orden sugerido'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Pedidos que el backend propone sumar, del más cercano al más lejano.
  Widget _nearCard(ThemeData theme, TextStyle? muted) {
    final near = _near;
    final anchor = near?.meta.anchor?.name;
    final items = near?.data ?? const <TripCandidate>[];
    return SectionCard(
      title: anchor == null
          ? '3. Pedidos cercanos'
          : '3. Pedidos cercanos a $anchor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Buscar pedido o cliente',
            ),
          ),
          const SizedBox(height: 8),
          if (_nearError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('No se pudieron cargar los pedidos.', style: muted),
                TextButton(onPressed: _reload, child: const Text('Reintentar')),
              ],
            )
          else if (near == null && _loadingNear)
            Text('Buscando los pedidos más cercanos…', style: muted)
          else if (items.isEmpty)
            Text('No quedan pedidos para sumar ese día.', style: muted),
          for (final candidate in items)
            _CandidateRow(
              key: ValueKey(candidate.shipmentId),
              candidate: candidate,
              onAdd: _saving ? null : () => _add(candidate),
            ),
        ],
      ),
    );
  }
}

/// Texto de un aviso del orden sugerido.
String tripWarningText(TripSequenceWarningCode code) => switch (code) {
  TripSequenceWarningCode.windowMissed =>
    'no se llega a la hora que pidió el cliente',
  TripSequenceWarningCode.overCapacity => 'supera la capacidad del camión',
  TripSequenceWarningCode.outOfDepartment => 'es de otra ciudad',
  TripSequenceWarningCode.missingLocation => 'no tiene ubicación en el mapa',
  TripSequenceWarningCode.$unknown => 'revisá este pedido',
};

/// Una parada del viaje en armado, con sus acciones.
class _TripStopRow extends StatelessWidget {
  const _TripStopRow({
    super.key,
    required this.position,
    required this.stop,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int position;
  final TripCandidate stop;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final who = stopWho(stop.customerName, stop.shortAddress);
    final window = stop.timeWindow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              child: Text(
                '$position',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stopTitle(stop.orderReference, position),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (who != null) Text(who),
                  if (window != null)
                    Text(
                      timeWindowText(window.from, window.to),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.end,
          children: [
            TextButton(onPressed: onUp, child: const Text('Subir')),
            TextButton(onPressed: onDown, child: const Text('Bajar')),
            TextButton(onPressed: onRemove, child: const Text('Quitar')),
          ],
        ),
        const Divider(height: 8),
      ],
    );
  }
}

/// Un pedido que se puede sumar: a qué distancia está, si el backend lo
/// recomienda y, si no entra, por qué.
class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    super.key,
    required this.candidate,
    required this.onAdd,
  });

  final TripCandidate candidate;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final who = stopWho(candidate.customerName, candidate.shortAddress);
    final window = candidate.timeWindow;
    final distance = candidate.distanceKmFromAnchor;
    final reason = candidate.suggested
        ? candidate.suggestedReason
        : (candidate.fits ? null : candidate.fitsReason);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Nunca el UUID: si no hay código legible, solo "Pedido" (el
                  // cliente/dirección van debajo).
                  switch (readableOrderReference(candidate.orderReference)) {
                    final ref? => 'Pedido $ref',
                    _ => 'Pedido',
                  },
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (who != null) Text(who),
                if (window != null)
                  Text(
                    timeWindowText(window.from, window.to),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (distance != null)
                      Text('A ${formatKm(distance)}', style: muted),
                    if (candidate.suggested)
                      const StatusPill('Sugerido', tone: PillTone.success),
                    if (!candidate.fits)
                      const StatusPill('No entra', tone: PillTone.danger),
                  ],
                ),
                if (reason != null && reason.isNotEmpty)
                  Text(reason, style: muted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            // El tema pide ancho completo: acá va al lado del texto.
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: candidate.fits ? onAdd : null,
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
