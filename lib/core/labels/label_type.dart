/// Tipos de QR del ecosistema. Por ahora solo PKG tiene payload implementado.
enum LabelType {
  package('PKG'),
  manifest('MAN'),
  node('NOD'),
  vehicle('VEH'),
  delivery('DLV');

  const LabelType(this.code);

  final String code;

  static LabelType? fromCode(String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}
