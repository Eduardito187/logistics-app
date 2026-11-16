import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/planned_stop.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../lookup/domain/usecases/find_order.dart';
import '../../domain/usecases/assign_shipment_to_plan.dart';
import '../../domain/usecases/delete_plan.dart';
import '../../domain/usecases/publish_plan.dart';
import '../../domain/usecases/remove_shipment_from_plan.dart';
import '../supervisor_labels.dart';
import '../../domain/usecases/reorder_plan_stops.dart';
import '../controllers/planning_controllers.dart';
import '../controllers/supervisor_controllers.dart';
import 'stop_tile.dart';

/// Edición de un plan todavía SIN publicar (planificador / administrador):
/// ordenar las paradas, agregar un pedido al camión y publicarlo.
///
/// Reemplaza a la lista de paradas de solo lectura del detalle.
class PlanEditor extends ConsumerStatefulWidget {
  const PlanEditor({super.key, required this.plan});

  final Plan plan;

  @override
  ConsumerState<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<PlanEditor> {
  late List<PlannedStop> _stops = _sorted(widget.plan);
  bool _dirty = false;
  bool _busy = false;

  static List<PlannedStop> _sorted(Plan plan) =>
      [...plan.stops]..sort((a, b) => a.sequence.compareTo(b.sequence));

  @override
  void didUpdateWidget(PlanEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Llegó el plan fresco del servidor: si no hay cambios sin guardar, manda.
    if (!_dirty && oldWidget.plan != widget.plan) {
      _stops = _sorted(widget.plan);
    }
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _stops.length) return;
    setState(() {
      final stop = _stops.removeAt(index);
      _stops.insert(target, stop);
      _dirty = true;
    });
  }

  void _refresh() {
    ref.invalidate(planDetailProvider(widget.plan.id));
    ref.invalidate(planEtaProvider(widget.plan.id));
    ref.invalidate(plansProvider);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _dirty = false;
      _refresh();
      showSuccessSnack(context, done);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveOrder() => _run(
    () => ref.read(reorderPlanStopsProvider)(widget.plan.id, [
      for (final stop in _stops) stop.shipmentId,
    ]),
    'Orden guardado.',
  );

  Future<void> _remove(PlannedStop stop, int position) async {
    final name = stopTitle(stop.orderReference, position);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Quitar $name del viaje?'),
        content: const Text(
          'El pedido queda sin camión para asignarlo después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref.read(removeShipmentFromPlanProvider)(
        widget.plan.id,
        stop.shipmentId,
      ),
      'Parada quitada.',
    );
  }

  Future<void> _addOrder() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _OrderCodeDialog(),
    );
    if (code == null || code.isEmpty || !mounted) return;
    var found = true;
    await _run(() async {
      final order = await ref.read(findOrderProvider)(code);
      if (order == null) {
        found = false;
        return;
      }
      await ref.read(assignShipmentToPlanProvider)(widget.plan.id, order.id);
    }, 'Pedido agregado al camión.');
    if (!found && mounted) showInfoSnack(context, 'Pedido no encontrado.');
  }

  Future<void> _publish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Publicar el plan?'),
        content: const Text(
          'El preparador y el chofer van a ver este plan. Después de '
          'publicarlo ya no se edita desde acá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref.read(publishPlanProvider)(widget.plan.id),
      'Plan publicado.',
    );
  }

  /// Borra el plan (solo sin publicar): sus pedidos quedan sin camión. Al
  /// terminar se cierra el detalle, que ya no existe.
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar el plan?'),
        content: const Text(
          'El viaje se borra y sus pedidos quedan sin camión para '
          'asignarlos a otro viaje.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(deletePlanProvider)(widget.plan.id);
      if (!mounted) return;
      ref.invalidate(plansProvider);
      showSuccessSnack(context, 'Plan eliminado.');
      await Navigator.of(context).maybePop();
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Guardar orden" y "Publicar plan" van FIJOS al pie del detalle (no al
  /// final de la lista): se le avisa a la pantalla qué mostrar.
  void _publishActions() {
    final notifier = ref.read(
      planEditorActionsProvider(widget.plan.id).notifier,
    );
    final PlanEditorActions actions = (
      busy: _busy,
      dirty: _dirty,
      // Con el orden sin guardar primero se guarda: así se publica lo que
      // se ve en pantalla.
      canPublish: !_dirty && _stops.isNotEmpty,
      save: _saveOrder,
      publish: _publish,
    );
    // Fuera del build: cambia el estado de otro provider.
    Future<void>.microtask(() {
      if (mounted) notifier.set(actions);
    });
  }

  @override
  Widget build(BuildContext context) {
    _publishActions();
    final etas = ref.watch(planStopEtasProvider(widget.plan.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_stops.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('El plan todavía no tiene paradas.'),
          ),
        for (var i = 0; i < _stops.length; i++)
          StopTile(
            key: ValueKey(_stops[i].shipmentId),
            position: i + 1,
            stop: _stops[i],
            eta: etas[_stops[i].shipmentId] ?? _stops[i].etaAt,
            isFirst: i == 0,
            isLast: i == _stops.length - 1,
            footer: Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy || i == 0 ? null : () => _move(i, -1),
                  child: const Text('Subir'),
                ),
                TextButton(
                  onPressed: _busy || i == _stops.length - 1
                      ? null
                      : () => _move(i, 1),
                  child: const Text('Bajar'),
                ),
                TextButton(
                  // Con el orden sin guardar no se quita: primero guardar.
                  onPressed: _busy || _dirty
                      ? null
                      : () => _remove(_stops[i], i + 1),
                  child: const Text('Quitar'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _addOrder,
          icon: const AnimatedAppIcon(AppIcon.add, excludeFromSemantics: true),
          label: const Text('Agregar pedido'),
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _busy ? null : _delete,
          child: const Text('Eliminar plan'),
        ),
      ],
    );
  }
}

/// Pide el código del pedido a agregar.
class _OrderCodeDialog extends StatefulWidget {
  const _OrderCodeDialog();

  @override
  State<_OrderCodeDialog> createState() => _OrderCodeDialogState();
}

class _OrderCodeDialogState extends State<_OrderCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar pedido'),
      content: TextField(
        controller: _code,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Código del pedido'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_code.text.trim()),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
