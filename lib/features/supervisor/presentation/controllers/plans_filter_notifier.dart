import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/plan_status.dart';

/// Filtro de la lista de planes/viajes del día: estado elegido (`null` = todos)
/// y texto de búsqueda (placa o chofer). Es un `record`, así que compara por
/// valor y dos filtros iguales no disparan reconstrucciones.
typedef PlansFilter = ({PlanStatus? status, String query});

/// Estado del filtro de planes que elige el usuario en la pantalla.
///
/// Sin autoDispose a propósito: conserva el filtro elegido al ir y volver del
/// detalle de un plan durante la sesión, como la fecha y el filtro de alertas.
class PlansFilterNotifier extends Notifier<PlansFilter> {
  @override
  PlansFilter build() => (status: null, query: '');

  /// Estado del plan por el que se filtra; `null` = todos.
  void setStatus(PlanStatus? status) =>
      state = (status: status, query: state.query);

  /// Texto de búsqueda (placa o chofer); vacío = no filtra por texto.
  void setQuery(String query) => state = (status: state.status, query: query);

  /// Vuelve a "todos" y sin texto (botón "Limpiar filtro").
  void clear() => state = (status: null, query: '');
}

final plansFilterProvider = NotifierProvider<PlansFilterNotifier, PlansFilter>(
  PlansFilterNotifier.new,
);

/// Aplica el filtro (estado + texto) a los planes del día. El estado filtra por
/// `Plan.status`; el texto busca en placa y chofer sin distinguir mayúsculas ni
/// tildes. Ambos se combinan con Y (AND). Devuelve una lista nueva; si el filtro
/// está vacío devuelve los mismos planes en el mismo orden.
List<Plan> filterPlans(List<Plan> plans, PlansFilter filter) {
  final needle = normalizePlanQuery(filter.query);
  return [
    for (final plan in plans)
      if (_matchesStatus(plan, filter.status) && _matchesQuery(plan, needle))
        plan,
  ];
}

bool _matchesStatus(Plan plan, PlanStatus? status) =>
    status == null || plan.status == status;

bool _matchesQuery(Plan plan, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  final haystack = [
    if (plan.plate != null) plan.plate!,
    if (plan.driverName != null) plan.driverName!,
  ].map(normalizePlanQuery).join(' ');
  return haystack.contains(normalizedQuery);
}

/// Normaliza un texto para buscar: lo pasa a minúsculas, le quita espacios al
/// borde y le saca las tildes/diéresis (y la ñ) para que "muñoz" encuentre a
/// "Muñoz" y "garcia" a "García".
String normalizePlanQuery(String value) {
  var result = value.trim().toLowerCase();
  const diacritics = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  diacritics.forEach((accented, plain) {
    result = result.replaceAll(accented, plain);
  });
  return result;
}
