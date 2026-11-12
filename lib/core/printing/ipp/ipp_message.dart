import 'dart:typed_data';

import 'ipp_attribute.dart';
import 'ipp_attribute_group.dart';

/// Pedido o respuesta IPP. [code] es la operación (pedido) o el status-code
/// (respuesta). [data] es el documento que sigue a los atributos.
class IppMessage {
  IppMessage({
    required this.code,
    required this.requestId,
    this.versionMajor = 1,
    this.versionMinor = 1,
    List<IppAttributeGroup>? groups,
    Uint8List? data,
  }) : groups = groups ?? <IppAttributeGroup>[],
       data = data ?? Uint8List(0);

  final int versionMajor;
  final int versionMinor;
  final int code;
  final int requestId;
  final List<IppAttributeGroup> groups;
  final Uint8List data;

  /// Primer grupo con [tag], o `null`.
  IppAttributeGroup? group(int tag) {
    for (final g in groups) {
      if (g.tag == tag) return g;
    }
    return null;
  }

  /// Atributo por nombre en cualquier grupo (el primero que aparezca).
  IppAttribute? attribute(String name) {
    for (final g in groups) {
      final a = g[name];
      if (a != null) return a;
    }
    return null;
  }
}
