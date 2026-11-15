import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/delivery_mode.dart';
import '../../../core/api/models/shipment.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/field_icon.dart';
import 'controllers/store_shipments_notifier.dart';
import 'controllers/store_shipments_state.dart';
import '../../../core/labels/label_lookup.dart';
import 'widgets/load_more_footer.dart';
import 'widgets/load_more_on_scroll.dart';
import 'widgets/pickup_card.dart';
import 'widgets/pickup_label_sheet.dart';

/// Recojo en tienda: pedidos que el CLIENTE pasa a retirar. El personal busca
/// el pedido por su código (o el nombre/documento del cliente) o escanea la
/// etiqueta de un producto para saber de qué pedido es y a quién se entrega; la
/// entrega se registra en la siguiente pantalla.
class CounterPickupScreen extends ConsumerStatefulWidget {
  const CounterPickupScreen({super.key});

  @override
  ConsumerState<CounterPickupScreen> createState() =>
      _CounterPickupScreenState();
}

class _CounterPickupScreenState extends ConsumerState<CounterPickupScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Texto buscado, ya normalizado (sin espacios, en minúsculas).
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsAsync = ref.watch(storeShipmentsPagedProvider);
    // Lista con datos: tarjetas perezosas (grilla en tablets). Cargando, vacío
    // o error ocupan el resto de la pantalla pero siguen siendo "scrolleables"
    // para que el gesto de refrescar funcione también ahí.
    final paged = shipmentsAsync.hasError ? null : shipmentsAsync.value;
    final all = _customerPickups(paged?.shipments);
    // La búsqueda filtra lo ya cargado (sin otra llamada al backend).
    final shipments = all == null || _query.isEmpty
        ? all
        : all.where(_matches).toList(growable: false);
    final searching = _query.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Recojo en tienda')),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      autocorrect: false,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        prefixIconConstraints: FieldIcon.prefixConstraints,
                        prefixIcon: FieldIcon(
                          icon: AppIcon.search,
                          focusNode: _searchFocus,
                        ),
                        labelText: 'Código del pedido',
                        hintText: 'Código, cliente o documento',
                        suffixIcon: searching
                            ? IconButton(
                                tooltip: 'Borrar búsqueda',
                                icon: const AnimatedAppIcon(
                                  AppIcon.close,
                                  size: 20,
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Escanear la etiqueta de un producto: dice de qué pedido es
                  // y a qué cliente se entrega.
                  SizedBox.square(
                    dimension: 56,
                    child: IconButton.filled(
                      tooltip: 'Escanear etiqueta',
                      onPressed: _scanLabel,
                      icon: const AnimatedAppIcon(AppIcon.scan),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                // Refrescar vuelve a la página 1 (lo que espera el gesto).
                onRefresh: () async =>
                    ref.invalidate(storeShipmentsPagedProvider),
                child: LoadMoreOnScroll(
                  onLoadMore: _loadMore,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (shipments != null && shipments.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverMainAxisGroup(
                            slivers: [
                              SliverAdaptiveCardRows(
                                itemCount: shipments.length,
                                itemBuilder: (context, i) =>
                                    PickupCard(shipment: shipments[i]),
                              ),
                              // Scroll infinito: al acercarse al final se pide
                              // la página siguiente y el pie muestra el
                              // progreso.
                              if (paged!.hasMore)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: _footer(paged),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else if (searching && all != null && all.isNotEmpty)
                        // Hay recojos, pero ninguno coincide con lo buscado.
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: AppIcon.search,
                            title: 'Pedido no encontrado',
                            message:
                                'Todavía no está en la tienda para retirar. '
                                'Consultá en qué estado está para decírselo '
                                'al cliente.',
                            // El pedido puede estar en camino: la consulta
                            // dice su estado aunque no sea un recojo listo.
                            action: FilledButton.icon(
                              onPressed: () => context.push(
                                '/lookup',
                                extra: _search.text.trim(),
                              ),
                              icon: const AnimatedAppIcon(AppIcon.search),
                              label: const Text('Consultar estado del pedido'),
                            ),
                          ),
                        )
                      else
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AsyncValueView<StoreShipmentsState>(
                            value: shipmentsAsync,
                            onRetry: () =>
                                ref.invalidate(storeShipmentsPagedProvider),
                            data: (state) => EmptyState(
                              icon: AppIcon.pickupStore,
                              title: 'Sin recojos',
                              message: 'No hay pedidos para recojo en tienda.',
                              // Puede haber recojos en páginas aún no traídas
                              // (las cargadas eran solo traslados).
                              action: state.hasMore ? _footer(state) : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(StoreShipmentsState paged) => LoadMoreFooter(
    loading: paged.loadingMore,
    failed: paged.moreFailed,
    onLoadMore: _loadMore,
    label: 'Cargar más recojos',
    loadingLabel: 'Cargando más recojos…',
    failedLabel: 'No se pudieron cargar más recojos.',
  );

  Future<void> _loadMore() =>
      ref.read(storeShipmentsPagedProvider.notifier).loadMore();

  /// Solo los pedidos que un CLIENTE retira (`delivery_mode: store_pickup`): los
  /// traslados de almacén a tienda (`transfer`) son de Recepción, no de acá. La
  /// lista se comparte con Recepción (una sola consulta), por eso se separa en
  /// el teléfono. Con un backend que aún no manda `delivery_mode` no se filtra
  /// (se ve todo, como antes).
  static List<Shipment>? _customerPickups(List<Shipment>? shipments) {
    if (shipments == null) return null;
    if (!shipments.any((s) => s.deliveryMode != null)) return shipments;
    return [
      for (final shipment in shipments)
        if (shipment.deliveryMode == DeliveryMode.storePickup) shipment,
    ];
  }

  /// Coincide por código de pedido, nombre o documento del cliente.
  bool _matches(Shipment shipment) =>
      _normalize(shipment.externalId).contains(_query) ||
      _normalize(shipment.customerName).contains(_query) ||
      _normalize(shipment.customerDocumentId ?? '').contains(_query);

  static String _normalize(String text) => text.trim().toLowerCase();

  void _onSearchChanged(String text) {
    final query = _normalize(text);
    if (query != _query) setState(() => _query = query);
  }

  void _clearSearch() {
    _search.clear();
    _onSearchChanged('');
  }

  /// Escanea la etiqueta de un producto y muestra de qué pedido es y los datos
  /// del cliente a entregar (si es un recojo de esta tienda).
  Future<void> _scanLabel() async {
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
    final shipment = _shipmentOf(info);
    // La búsqueda queda en ese pedido: al cerrar la hoja se ve solo ese.
    final order = shipment?.externalId ?? info.orderNumber;
    if (order != null) {
      _search.text = order;
      _onSearchChanged(order);
    }
    final deliver = await showPickupLabelSheet(
      context,
      info: info,
      shipment: shipment,
    );
    if (deliver != true || shipment == null || !mounted) return;
    await context.push('/store/pickup/pod', extra: shipment);
  }

  /// Recojo cargado al que pertenece la etiqueta (por envío o nº de pedido).
  Shipment? _shipmentOf(PickupLabelInfo info) {
    final all = _customerPickups(
      ref.read(storeShipmentsPagedProvider).value?.shipments,
    );
    if (all == null) return null;
    for (final shipment in all) {
      if (shipment.id == info.shipmentId ||
          (info.orderNumber != null &&
              shipment.externalId == info.orderNumber)) {
        return shipment;
      }
    }
    return null;
  }
}
