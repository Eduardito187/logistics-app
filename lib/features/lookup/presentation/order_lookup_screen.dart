import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/labels/label_lookup.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/realtime/pusher_socket.dart';
import '../../../core/realtime/realtime_bus.dart';
import '../../../core/realtime/realtime_listener.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/field_icon.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/order_lookup_data_source.dart';
import '../domain/order_stage.dart';

/// Consultar un pedido: escanear la etiqueta de un producto o escribir el
/// código, y ver de quién es, qué lleva y **en qué estado está**.
///
/// Es de TODOS los roles y es solo informativa: no prepara, no carga ni
/// entrega nada. Sirve, por ejemplo, para que la tienda le diga a un cliente si
/// su pedido ya llegó o si todavía está en camino.
class OrderLookupScreen extends ConsumerStatefulWidget {
  const OrderLookupScreen({super.key, this.initialQuery});

  /// Búsqueda con la que abre (p. ej. lo que la tienda ya tenía escrito).
  final String? initialQuery;

  @override
  ConsumerState<OrderLookupScreen> createState() => _OrderLookupScreenState();
}

class _OrderLookupScreenState extends ConsumerState<OrderLookupScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.initialQuery ?? '',
  );
  final FocusNode _focus = FocusNode();

  /// Lo que dijo la última etiqueta escaneada (se muestra aunque el pedido no
  /// se pueda consultar).
  PickupLabelInfo? _label;
  List<OrderLookupItem>? _results;
  Object? _error;
  bool _loading = false;

  /// Sube con cada búsqueda: una respuesta vieja ya no se pinta.
  int _generation = 0;

  /// Última búsqueda hecha (para repetirla cuando el pedido cambia).
  String? _lastQuery;

  /// Un pedido de los que se ven cambió de estado: se repite la búsqueda sin
  /// spinner, y el resultado se actualiza en su lugar.
  Future<void> _onTracking(RealtimeEvent event) async {
    if (event.name != 'tracking.updated') return;
    final query = _lastQuery;
    final shown = _results;
    if (query == null || shown == null || _loading) return;
    final changed = event.data['shipment_id'];
    if (changed is String && !shown.any((order) => order.id == changed)) {
      return;
    }
    final generation = _generation;
    try {
      final results = await ref
          .read(orderLookupDataSourceProvider)
          .search(query);
      if (!mounted || generation != _generation) return;
      setState(() => _results = results);
    } on Object {
      // Se queda con lo que se ve.
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFor(initial));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _searchFor(String raw, {PickupLabelInfo? label}) async {
    final query = raw.trim();
    if (query.isEmpty) return;
    final generation = ++_generation;
    _lastQuery = query;
    setState(() {
      _loading = true;
      _error = null;
      _label = label;
    });
    try {
      final results = await ref
          .read(orderLookupDataSourceProvider)
          .search(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = null;
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _scan() async {
    final code = await scanCode(
      context,
      title: 'Escanear etiqueta',
      helper: 'Apunta a la etiqueta del producto.',
      formats: kLabelScanFormats,
    );
    if (code == null || !mounted) return;
    final info = await lookupPickupLabel(ref, code);
    if (!mounted) return;
    final problem = info.problem;
    if (problem != null) {
      showErrorSnack(context, switch (problem) {
        PickupLabelProblem.unreachable =>
          'No se pudo consultar la etiqueta. Intentá de nuevo.',
        PickupLabelProblem.unknown => 'Etiqueta no reconocida.',
      });
      return;
    }
    final order = info.orderNumber;
    if (order == null || order.isEmpty) {
      // La etiqueta se leyó pero no dice de qué pedido es.
      setState(() {
        _label = info;
        _results = const [];
        _error = null;
      });
      return;
    }
    _search.text = order;
    await _searchFor(order, label: info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultar pedido')),
      body: RealtimeListener(
        topic: RealtimeTopic.tracking,
        onEvent: _onTracking,
        child: ResponsiveBody(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        focusNode: _focus,
                        textInputAction: TextInputAction.search,
                        autocorrect: false,
                        onSubmitted: _searchFor,
                        decoration: InputDecoration(
                          prefixIconConstraints: FieldIcon.prefixConstraints,
                          prefixIcon: FieldIcon(
                            icon: AppIcon.search,
                            focusNode: _focus,
                          ),
                          labelText: 'Código del pedido',
                          hintText: 'Código, cliente o documento',
                          suffixIcon: IconButton(
                            tooltip: 'Buscar',
                            icon: const AnimatedAppIcon(
                              AppIcon.arrowForward,
                              size: 20,
                            ),
                            onPressed: () => _searchFor(_search.text),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox.square(
                      dimension: 56,
                      child: IconButton.filled(
                        tooltip: 'Escanear etiqueta',
                        onPressed: _loading ? null : _scan,
                        icon: const AnimatedAppIcon(AppIcon.scan),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const LoadingView();
    final error = _error;
    final label = _label;
    final results = _results;
    if (error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (label != null) _LabelCard(info: label),
          EmptyState(
            icon: AppIcon.cloudOff,
            title: 'No se pudo consultar',
            message: error is ApiException
                ? error.message
                : 'Ocurrió un error.',
          ),
        ],
      );
    }
    if (results == null) {
      return const EmptyState(
        icon: AppIcon.scan,
        title: 'Escaneá o buscá un pedido',
        message:
            'Escaneá la etiqueta de un producto o escribí el código del '
            'pedido para ver en qué estado está.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (label != null) ...[
          _LabelCard(info: label),
          const SizedBox(height: 12),
        ],
        if (results.isEmpty)
          const EmptyState(
            icon: AppIcon.search,
            title: 'Pedido no encontrado',
            message:
                'No hay un pedido con ese código entre los que podés '
                'consultar.',
          )
        else
          for (final order in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrderStatusCard(order: order),
            ),
      ],
    );
  }
}

/// Lo que dice la etiqueta escaneada: pedido y producto.
class _LabelCard extends StatelessWidget {
  const _LabelCard({required this.info});

  final PickupLabelInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Etiqueta escaneada',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.orderNumber != null) Text('Pedido ${info.orderNumber}'),
          if (info.productName != null)
            Text(
              info.productName!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          if (info.sku != null) Text('SKU ${info.sku}'),
          if (info.customerName != null) Text('Cliente: ${info.customerName}'),
        ],
      ),
    );
  }
}

/// Estado de un pedido: etapa (la que calcula el servidor), a cuántas paradas
/// está, sus hitos y qué lleva.
class OrderStatusCard extends StatelessWidget {
  const OrderStatusCard({super.key, required this.order});

  final OrderLookupItem order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final tracking = order.tracking;
    final stage = tracking.stage;
    final progress = order.progress;
    final plate = tracking.vehiclePlate ?? progress?.plate;
    final stops = stopsBeforeText(tracking.stopsBefore);
    final eta = tracking.etaAt?.toLocal();
    final store = tracking.currentNode?.name ?? order.destinationNode?.name;
    final trip = orderTripText(
      order.originDepartment,
      order.destinationDepartment,
    );
    String two(int n) => n.toString().padLeft(2, '0');
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedido ${order.externalId}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(order.customerName),
          const SizedBox(height: 10),
          StatusPill(
            orderStageLabel(stage),
            tone: _tone(stage),
            icon: _icon(stage),
          ),
          // Lo que la tienda le lee al cliente: a cuántas paradas está.
          if (stops != null) ...[
            const SizedBox(height: 8),
            Text(
              stops,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (eta != null)
            Text(
              'Llegada estimada: ${two(eta.day)}/${two(eta.month)} '
              '${two(eta.hour)}:${two(eta.minute)}',
            ),
          const SizedBox(height: 10),
          Text(deliveryModeText(order.deliveryMode), style: muted),
          if (trip != null) Text(trip, style: muted),
          if (store != null) Text(store, style: muted),
          Text(order.shortAddress ?? order.addressText, style: muted),
          if (plate != null && !orderStageClosed(stage)) Text('Camión $plate'),
          const SizedBox(height: 10),
          _Milestone('Preparado', progress?.preparedAt),
          _Milestone('Cargado al camión', progress?.loadedAt),
          if (order.deliveryMode == DeliveryMode.storePickup)
            _Milestone('Llegó a la tienda', progress?.readyForPickupAt),
          _Milestone('Entregado', progress?.deliveredAt),
          const SizedBox(height: 10),
          Text('Productos', style: muted),
          for (final line in order.lines)
            Text('${line.quantity} × ${line.productName} · ${line.sku}'),
          // El pedido se puede VER pero no operar desde este usuario (otra
          // ciudad, otra tienda, otra ruta).
          if (!order.canProcess) ...[
            const SizedBox(height: 10),
            const StatusPill('Solo consulta', icon: AppIcon.visibility),
          ],
        ],
      ),
    );
  }

  static PillTone _tone(OrderLookupStage stage) => switch (stage) {
    OrderLookupStage.delivered || OrderLookupStage.atStore => PillTone.success,
    OrderLookupStage.onTheWay || OrderLookupStage.prepared => PillTone.info,
    OrderLookupStage.failed => PillTone.danger,
    OrderLookupStage.planned || OrderLookupStage.received => PillTone.warning,
    OrderLookupStage.cancelled || OrderLookupStage.$unknown => PillTone.neutral,
  };

  static AppIcon _icon(OrderLookupStage stage) => switch (stage) {
    OrderLookupStage.delivered => AppIcon.success,
    OrderLookupStage.atStore => AppIcon.pickupStore,
    OrderLookupStage.onTheWay => AppIcon.deliver,
    OrderLookupStage.failed || OrderLookupStage.cancelled => AppIcon.cancel,
    _ => AppIcon.pending,
  };
}

/// Un hito del pedido con su fecha, o "pendiente" si todavía no pasó.
class _Milestone extends StatelessWidget {
  const _Milestone(this.label, this.at);

  final String label;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = at != null;
    final local = at?.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedAppIcon(
            done ? AppIcon.check : AppIcon.radioUnchecked,
            size: 18,
            color: done ? theme.colorScheme.primary : theme.colorScheme.outline,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              local == null
                  ? '$label: pendiente'
                  : '$label: ${two(local.day)}/${two(local.month)} '
                        '${two(local.hour)}:${two(local.minute)}',
              style: done
                  ? null
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
