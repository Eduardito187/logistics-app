import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/vehicle_class.dart';

/// Etiqueta en español para el tipo de corredor.
String corridorTypeLabel(CorridorType type) => switch (type) {
  CorridorType.cdToCustomer => 'CD → Cliente',
  CorridorType.cdToCd => 'CD → CD',
  CorridorType.cdToStore => 'CD → Tienda',
  CorridorType.storeToStore => 'Tienda → Tienda',
  CorridorType.storeToCd => 'Tienda → CD',
  CorridorType.storePickup => 'Recojo en tienda',
  CorridorType.$unknown => 'Desconocido',
};

/// Palabras cortas del español que NO son siglas (para no gritar "LA PAZ").
const Set<String> _shortWords = {'la', 'el', 'de', 'del', 'los', 'las', 'y'};

/// Siglas vs. palabra: "scz", "cbb", "lpb" y "cd" no tienen vocales; "paz" sí.
final RegExp _vowel = RegExp('[aeiouáéíóú]');

/// Prefijos de nodo del backend con su nombre en español.
const Map<String, String> _nodePrefixes = {
  'cd': 'CD',
  'store': 'Tienda',
  'tienda': 'Tienda',
  'hub': 'Hub',
  'customer': 'Cliente',
};

/// Nombre presentable de un nodo del corredor a partir de su clave del backend.
/// `cd-santa-cruz` → "CD Santa Cruz"; `store-scz-centro` → "Tienda SCZ Centro".
/// Las siglas de 3 letras o menos quedan en mayúsculas (SCZ, LPB, CD).
String corridorNodeLabel(String slug) {
  final parts = slug
      .trim()
      .split(RegExp(r'[-_\s]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return slug.trim();

  final words = <String>[];
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i].toLowerCase();
    final prefix = i == 0 ? _nodePrefixes[part] : null;
    if (prefix != null) {
      words.add(prefix);
    } else if (_shortWords.contains(part)) {
      words.add(_capitalize(part));
    } else if (part.length <= 3 && !_vowel.hasMatch(part)) {
      words.add(part.toUpperCase());
    } else {
      words.add(_capitalize(part));
    }
  }
  return words.join(' ');
}

/// Nombre presentable del corredor completo: "CD Santa Cruz → Tienda SCZ Centro".
String corridorPairLabel(String from, String to) =>
    '${corridorNodeLabel(from)} → ${corridorNodeLabel(to)}';

String _capitalize(String word) =>
    word[0].toUpperCase() + word.substring(1).toLowerCase();

/// Etiqueta en español para la clase de vehículo.
String vehicleClassLabel(VehicleClass vClass) => switch (vClass) {
  VehicleClass.trailer => 'Tráiler',
  VehicleClass.truck => 'Camión',
  VehicleClass.thirdParty => 'Terceros',
  VehicleClass.$unknown => 'Desconocido',
};
