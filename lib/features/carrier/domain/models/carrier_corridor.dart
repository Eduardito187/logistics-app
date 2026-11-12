import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/settlement.dart';

/// Un corredor real del transportista: el par origen→destino (claves del
/// backend, p. ej. `cd-santa-cruz`) junto con su tipo.
///
/// El backend todavía no expone un catálogo de corredores, así que la única
/// fuente confiable son las liquidaciones del propio transportista
/// (`corridor_from` / `corridor_to` / `corridor_type`). Elegir uno de estos
/// corredores garantiza que la consulta de tarifa no termine en 404.
class CarrierCorridor {
  const CarrierCorridor({
    required this.from,
    required this.to,
    required this.type,
  });

  /// Pares únicos origen→destino (con su tipo) presentes en [settlements],
  /// ordenados de forma estable para que la lista no baile entre consultas.
  /// Descarta tipos desconocidos y claves vacías: no se puede consultar con
  /// ellos.
  static List<CarrierCorridor> uniqueFrom(List<Settlement> settlements) {
    final unique = <String, CarrierCorridor>{};
    for (final settlement in settlements) {
      final from = settlement.corridorFrom.trim();
      final to = settlement.corridorTo.trim();
      if (from.isEmpty || to.isEmpty) continue;
      if (settlement.corridorType == CorridorType.$unknown) continue;
      final corridor = CarrierCorridor(
        from: from,
        to: to,
        type: settlement.corridorType,
      );
      unique.putIfAbsent(corridor.key, () => corridor);
    }
    final list = unique.values.toList()..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  final String from;
  final String to;
  final CorridorType type;

  /// Clave de identidad (también usada para ordenar y deduplicar).
  String get key => '$from|$to|${type.name}';

  @override
  bool operator ==(Object other) =>
      other is CarrierCorridor &&
      other.from == from &&
      other.to == to &&
      other.type == type;

  @override
  int get hashCode => Object.hash(from, to, type);

  @override
  String toString() => 'CarrierCorridor($key)';
}
