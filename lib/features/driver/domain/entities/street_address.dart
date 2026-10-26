/// Dirección corta para el chofer: solo lo que ubica la casa (calle, número,
/// anillo, barrio, referencia), sin ciudad, municipio, departamento ni país,
/// que ya conoce y le comen espacio en pantalla.
///
/// La dirección llega como texto libre separado por comas
/// (`Av. Roca y Coronado 3er anillo externo, Barrio Las Palmas, Santa Cruz de
/// la Sierra`); se descartan los tramos que son solo una ciudad/municipio/
/// departamento conocido (con o sin "Municipio de", "Provincia", "Depto.").
/// Si todos los tramos son ciudad, se devuelve el texto original.
String streetAddress(String address) {
  final parts = address
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
  final kept = parts.where((p) => !_isPlace(p)).toList(growable: false);
  if (kept.isEmpty) return address.trim();
  return kept.join(', ');
}

bool _isPlace(String part) {
  var key = _normalize(part);
  for (final prefix in _prefixes) {
    if (key.startsWith(prefix)) {
      key = key.substring(prefix.length).trim();
      break;
    }
  }
  return _places.contains(key);
}

String _normalize(String s) {
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  final lower = s.toLowerCase().replaceAll('.', '').trim();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString().replaceAll(_spaces, ' ');
}

final RegExp _spaces = RegExp(r'\s+');

const _prefixes = [
  'municipio de ',
  'municipio ',
  'ciudad de ',
  'provincia ',
  'departamento de ',
  'departamento ',
  'depto de ',
  'depto ',
  'dpto ',
];

/// Ciudades, municipios del área metropolitana, departamentos y país.
const _places = <String>{
  'bolivia',
  // Departamentos.
  'santa cruz', 'la paz', 'cochabamba', 'chuquisaca', 'oruro', 'potosi',
  'tarija', 'beni', 'pando',
  // Capitales y ciudades.
  'santa cruz de la sierra', 'scz', 'lpz', 'cbba', 'el alto', 'sucre',
  'trinidad', 'cobija', 'montero', 'yacuiba', 'riberalta',
  // Área metropolitana de Santa Cruz.
  'warnes', 'la guardia', 'cotoca', 'porongo', 'el torno', 'andres ibanez',
  // Área metropolitana de Cochabamba.
  'quillacollo', 'sacaba', 'tiquipaya', 'colcapirhua', 'vinto', 'sipe sipe',
  'cercado',
  // Área metropolitana de La Paz.
  'viacha', 'achocalla', 'mecapaca', 'palca', 'murillo',
};
