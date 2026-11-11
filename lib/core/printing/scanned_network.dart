/// Red que se barre en una búsqueda de impresoras, para mostrar en la UI.
class ScannedNetwork {
  const ScannedNetwork({
    required this.label,
    this.added = false,
    this.fullLabel,
  });

  /// Rango barrido (`10.168.48.0/22`).
  final String label;

  /// `true` si la agregó el usuario ("Buscar también en otra red").
  final bool added;

  /// Red real cuando es más grande que lo barrido (`10.168.0.0/16`); `null`
  /// si se barre completa.
  final String? fullLabel;

  /// `true` si solo se barre una parte de la red del teléfono.
  bool get isPartial => fullLabel != null;

  @override
  bool operator ==(Object other) =>
      other is ScannedNetwork &&
      other.label == label &&
      other.added == added &&
      other.fullLabel == fullLabel;

  @override
  int get hashCode => Object.hash(label, added, fullLabel);

  @override
  String toString() => label;
}
