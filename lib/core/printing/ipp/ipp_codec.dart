import 'dart:convert';
import 'dart:typed_data';

import 'ipp_attribute.dart';
import 'ipp_attribute_group.dart';
import 'ipp_byte_reader.dart';
import 'ipp_message.dart';
import 'ipp_resolution.dart';
import 'ipp_tags.dart';

/// Codificación binaria `application/ipp` (RFC 8010), escrita a mano.
abstract final class IppCodec {
  /// Serializa [message] (cabecera, grupos, fin de atributos y documento).
  static Uint8List encode(IppMessage message) {
    final out = BytesBuilder(copy: false)
      ..addByte(message.versionMajor & 0xFF)
      ..addByte(message.versionMinor & 0xFF)
      ..add(_u16(message.code))
      ..add(_u32(message.requestId));
    for (final group in message.groups) {
      out.addByte(group.tag);
      for (final attr in group.attributes) {
        final values = attr.values.isEmpty
            ? const <Object?>[null]
            : attr.values;
        for (var i = 0; i < values.length; i++) {
          final name = i == 0 ? utf8.encode(attr.name) : const <int>[];
          final value = _encodeValue(attr.tag, values[i]);
          out
            ..addByte(attr.tag)
            ..add(_u16(name.length))
            ..add(name)
            ..add(_u16(value.length))
            ..add(value);
        }
      }
    }
    out
      ..addByte(IppTag.endOfAttributes)
      ..add(message.data);
    return out.takeBytes();
  }

  /// Interpreta una respuesta/pedido IPP. Lanza [FormatException] si los
  /// bytes no son IPP válido (truncado, sin grupo, sin fin de atributos).
  static IppMessage decode(Uint8List bytes) {
    if (bytes.length < 9) {
      throw const FormatException('Respuesta IPP demasiado corta');
    }
    final r = IppByteReader(bytes);
    final major = r.u8();
    final minor = r.u8();
    final code = r.u16();
    final requestId = r.u32();
    final groups = <IppAttributeGroup>[];
    IppAttributeGroup? current;
    IppAttribute? last;
    while (true) {
      if (r.done) throw const FormatException('IPP sin fin de atributos');
      var tag = r.u8();
      if (tag == IppTag.endOfAttributes) break;
      if (IppTag.isDelimiter(tag)) {
        current = IppAttributeGroup(tag);
        groups.add(current);
        last = null;
        continue;
      }
      if (tag == IppTag.extension) tag = r.u32();
      final name = utf8.decode(r.bytes(r.u16()), allowMalformed: true);
      final raw = r.bytes(r.u16());
      Object? value;
      if (tag == IppTag.begCollection) {
        _skipCollection(r);
        value = const <String, Object?>{};
      } else {
        value = _decodeValue(tag, raw);
      }
      if (current == null) {
        throw const FormatException('Atributo IPP fuera de un grupo');
      }
      if (name.isEmpty) {
        if (last == null) {
          throw const FormatException('Valor adicional IPP sin atributo');
        }
        last.values.add(value);
      } else {
        last = IppAttribute(name, tag, [value]);
        current.attributes.add(last);
      }
    }
    return IppMessage(
      versionMajor: major,
      versionMinor: minor,
      code: code,
      requestId: requestId,
      groups: groups,
      data: r.rest(),
    );
  }

  /// Saltea los miembros de una colección (anidadas incluidas).
  static void _skipCollection(IppByteReader r) {
    var depth = 1;
    while (depth > 0) {
      var tag = r.u8();
      if (tag == IppTag.extension) tag = r.u32();
      r.bytes(r.u16());
      r.bytes(r.u16());
      if (tag == IppTag.begCollection) depth++;
      if (tag == IppTag.endCollection) depth--;
    }
  }

  static List<int> _encodeValue(int tag, Object? value) {
    if (value == null) return const <int>[];
    if (value is Uint8List) return value;
    switch (tag) {
      case IppTag.integer:
      case IppTag.enumeration:
        return _u32((value as int) & 0xFFFFFFFF);
      case IppTag.boolean:
        return [(value as bool) ? 1 : 0];
      case IppTag.resolution:
        final res = value as IppResolution;
        return [..._u32(res.x), ..._u32(res.y), res.units & 0xFF];
      case IppTag.unsupported:
      case IppTag.unknown:
      case IppTag.noValue:
        return const <int>[];
    }
    return utf8.encode(value.toString());
  }

  static Object? _decodeValue(int tag, Uint8List raw) {
    switch (tag) {
      case IppTag.integer:
      case IppTag.enumeration:
        if (raw.length != 4) return raw;
        return ByteData.sublistView(raw).getInt32(0);
      case IppTag.boolean:
        return raw.isNotEmpty && raw[0] != 0;
      case IppTag.resolution:
        if (raw.length != 9) return raw;
        final d = ByteData.sublistView(raw);
        return IppResolution(d.getInt32(0), d.getInt32(4), units: raw[8]);
      case IppTag.unsupported:
      case IppTag.unknown:
      case IppTag.noValue:
        return null;
    }
    if (IppTag.isString(tag)) return utf8.decode(raw, allowMalformed: true);
    return raw;
  }

  static List<int> _u16(int v) => [(v >> 8) & 0xFF, v & 0xFF];

  static List<int> _u32(int v) => [
    (v >> 24) & 0xFF,
    (v >> 16) & 0xFF,
    (v >> 8) & 0xFF,
    v & 0xFF,
  ];
}
