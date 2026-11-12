/// Un atributo IPP con su tag de valor y uno o más valores.
///
/// Valores: `String` (tags de texto), `int` (integer/enum), `bool`,
/// `IppResolution`, `Uint8List` (octetos crudos) o `null` (sin valor). Una
/// colección decodificada queda como `Map` vacío (la app no las usa).
class IppAttribute {
  IppAttribute(this.name, this.tag, List<Object?> values)
    : values = List<Object?>.of(values);

  final String name;
  final int tag;
  final List<Object?> values;

  /// Primer valor como texto, o `null`.
  String? get string {
    for (final v in values) {
      if (v is String) return v;
    }
    return null;
  }

  /// Primer valor como entero, o `null`.
  int? get integer {
    for (final v in values) {
      if (v is int) return v;
    }
    return null;
  }

  /// Todos los valores de texto.
  List<String> get strings => values.whereType<String>().toList();

  @override
  String toString() => 'IppAttribute($name, 0x${tag.toRadixString(16)})';
}
