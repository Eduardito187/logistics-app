import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/plan_status.dart';
import '../../../../core/icons/icons.dart';
import '../controllers/plans_filter_notifier.dart';
import '../supervisor_labels.dart';

/// Fila de filtros de la lista de planes/viajes: un SELECT de estado y una caja
/// de búsqueda por placa o chofer. Lee y escribe [plansFilterProvider]; el
/// filtrado en sí lo hace la pantalla sobre los planes ya cargados.
///
/// Es `Stateful` por la caja de texto: necesita su propio
/// [TextEditingController] y, si el filtro se limpia desde afuera (botón
/// "Limpiar filtro" del estado vacío), refleja ese cambio en la caja.
class PlansFilterBar extends ConsumerStatefulWidget {
  const PlansFilterBar({super.key});

  @override
  ConsumerState<PlansFilterBar> createState() => _PlansFilterBarState();
}

class _PlansFilterBarState extends ConsumerState<PlansFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(plansFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si el texto cambia desde afuera (p. ej. "Limpiar filtro"), reflejarlo en
    // la caja sin pelear con lo que el usuario está escribiendo.
    ref.listen(plansFilterProvider.select((f) => f.query), (_, query) {
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });
    final status = ref.watch(plansFilterProvider.select((f) => f.status));
    final notifier = ref.read(plansFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SELECT de estado. En Flutter 3.32 el dropdown usa `value:`.
          Expanded(
            child: DropdownButtonFormField<PlanStatus?>(
              key: const Key('plans-status-filter'),
              value: status,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Estado',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<PlanStatus?>(
                  value: null,
                  child: Text('Todos'),
                ),
                for (final value in PlanStatus.$valuesDefined)
                  DropdownMenuItem<PlanStatus?>(
                    value: value,
                    // Misma etiqueta que la pastilla de la tarjeta
                    // (`planStatusLabel`): el filtro y la tarjeta no pueden
                    // nombrar el mismo estado distinto en la misma pantalla.
                    child: Text(planStatusLabel(value)),
                  ),
              ],
              onChanged: notifier.setStatus,
            ),
          ),
          const SizedBox(width: 12),
          // Buscador por placa o chofer.
          Expanded(
            child: TextField(
              key: const Key('plans-search-field'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: notifier.setQuery,
              decoration: InputDecoration(
                labelText: 'Buscar',
                hintText: 'Placa o chofer',
                isDense: true,
                prefixIcon: const AnimatedAppIcon(
                  AppIcon.search,
                  size: 20,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
