import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/admin_remote_data_source.dart';
import '../../domain/entities/admin_vehicle.dart';
import '../../../../core/widgets/paged_search_list.dart';

/// Tiendas y centros activos. Casi no cambian: se piden una vez por pantalla.
final adminNodesProvider = FutureProvider.autoDispose<List<Node>>(
  (ref) => ref.watch(adminRemoteDataSourceProvider).listNodes(),
);

/// Resultado del selector de tienda: [nodeId] `null` = "Sin tienda".
typedef NodeChoice = ({String? nodeId, String? name});

/// Elegir la tienda/centro de una persona. Devuelve `null` si se cancela.
Future<NodeChoice?> showNodePickerSheet(
  BuildContext context, {
  String? currentNodeId,
}) => showModalBottomSheet<NodeChoice>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _NodePickerSheet(currentNodeId: currentNodeId),
);

class _NodePickerSheet extends ConsumerWidget {
  const _NodePickerSheet({this.currentNodeId});

  final String? currentNodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(adminNodesProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: AsyncValueView<List<Node>>(
          value: nodes,
          onRetry: () => ref.invalidate(adminNodesProvider),
          data: (list) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Asignar a una tienda',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const AnimatedAppIcon(AppIcon.close),
                title: const Text('Sin tienda'),
                selected: currentNodeId == null,
                onTap: () =>
                    Navigator.of(context).pop((nodeId: null, name: null)),
              ),
              for (final node in list)
                ListTile(
                  leading: const AnimatedAppIcon(AppIcon.pickupStore),
                  title: Text(node.name),
                  subtitle: Text(node.code),
                  selected: node.id == currentNodeId,
                  onTap: () => Navigator.of(
                    context,
                  ).pop((nodeId: node.id, name: node.name)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Elegir un camión (busca por placa en el servidor). Devuelve `null` si se
/// cancela.
Future<AdminVehicle?> showVehiclePickerSheet(BuildContext context) =>
    showModalBottomSheet<AdminVehicle>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _VehiclePickerSheet(),
    );

class _VehiclePickerSheet extends ConsumerWidget {
  const _VehiclePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        // El teclado del buscador no tapa la lista.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: PagedSearchList<AdminVehicle>(
            searchLabel: 'Buscar camión por placa',
            emptyTitle: 'Sin camiones',
            emptyIcon: AppIcon.deliver,
            fetch: (query, page) => ref
                .read(adminRemoteDataSourceProvider)
                .listVehicles(query: query, page: page),
            itemBuilder: (context, vehicle) => Card(
              child: ListTile(
                leading: const AnimatedAppIcon(AppIcon.deliver),
                title: Text(
                  vehicle.displayPlate,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(vehicle.status.label),
                onTap: () => Navigator.of(context).pop(vehicle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
