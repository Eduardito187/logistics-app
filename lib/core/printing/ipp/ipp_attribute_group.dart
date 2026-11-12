import 'ipp_attribute.dart';

/// Grupo de atributos (operation, job, printer, unsupported…).
class IppAttributeGroup {
  IppAttributeGroup(this.tag, [List<IppAttribute>? attributes])
    : attributes = attributes ?? <IppAttribute>[];

  final int tag;
  final List<IppAttribute> attributes;

  /// Atributo por nombre, o `null`.
  IppAttribute? operator [](String name) {
    for (final a in attributes) {
      if (a.name == name) return a;
    }
    return null;
  }
}
