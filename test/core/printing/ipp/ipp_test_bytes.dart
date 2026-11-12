import 'dart:convert';
import 'dart:typed_data';

import 'package:logistics_app/core/printing/ipp/ipp_tags.dart';

// Constructores de bytes IPP para los tests (largos calculados acá; el test
// de codificación usa bytes literales).

List<int> u16(int v) => [(v >> 8) & 0xFF, v & 0xFF];

List<int> int32(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

/// Un registro atributo: tag, nombre y valor.
List<int> rec(int tag, String name, List<int> value) => [
  tag,
  ...u16(utf8.encode(name).length),
  ...utf8.encode(name),
  ...u16(value.length),
  ...value,
];

List<int> printerGroup(List<List<int>> records) => [
  IppTag.printerAttributes,
  for (final r in records) ...r,
];

List<int> operationGroup() => [
  IppTag.operationAttributes,
  ...rec(IppTag.charset, 'attributes-charset', ascii.encode('utf-8')),
  ...rec(IppTag.naturalLanguage, 'attributes-natural-language', [0x65, 0x73]),
];

/// Respuesta IPP 1.1 con [status] y los grupos dados (además del de
/// operación).
Uint8List ippResponse(
  int status,
  List<List<int>> groups, {
  int requestId = 1,
  List<int> data = const [],
}) => Uint8List.fromList([
  1,
  1,
  ...u16(status),
  ...int32(requestId),
  ...operationGroup(),
  for (final g in groups) ...g,
  IppTag.endOfAttributes,
  ...data,
]);

/// Get-Printer-Attributes de la Ricoh IM 550 REAL del dueño (consultada el
/// 11-nov-2026): autenticación de usuarios activa pero por IPP solo admite el
/// nombre (`requesting-user-name`), sin Basic/Digest.
Uint8List ricohUserNameOnlyResponse() => ippResponse(0, [
  printerGroup([
    rec(
      IppTag.textWithoutLanguage,
      'printer-make-and-model',
      ascii.encode('RICOH IM 550 PS3'),
    ),
    rec(IppTag.enumeration, 'printer-state', int32(3)),
    rec(IppTag.keyword, 'printer-state-reasons', ascii.encode('none-report')),
    rec(
      IppTag.mimeMediaType,
      'document-format-supported',
      ascii.encode('application/pdf'),
    ),
    rec(IppTag.mimeMediaType, '', ascii.encode('application/octet-stream')),
    rec(
      IppTag.keyword,
      'uri-authentication-supported',
      ascii.encode('requesting-user-name'),
    ),
  ]),
]);

/// Respuesta de Get-Printer-Attributes de una Ricoh con IPP Basic.
Uint8List ricohAttributesResponse() => ippResponse(0, [
  printerGroup([
    rec(
      IppTag.textWithoutLanguage,
      'printer-make-and-model',
      ascii.encode('RICOH IM 550'),
    ),
    rec(IppTag.enumeration, 'printer-state', int32(3)),
    rec(IppTag.keyword, 'printer-state-reasons', ascii.encode('none')),
    rec(
      IppTag.mimeMediaType,
      'document-format-supported',
      ascii.encode('application/pdf'),
    ),
    rec(IppTag.mimeMediaType, '', ascii.encode('image/pwg-raster')),
    rec(IppTag.mimeMediaType, '', ascii.encode('application/octet-stream')),
    rec(IppTag.keyword, 'uri-authentication-supported', ascii.encode('basic')),
    rec(IppTag.boolean, 'printer-is-accepting-jobs', [1]),
    rec(IppTag.resolution, 'pwg-raster-document-resolution-supported', [
      ...int32(300),
      ...int32(300),
      3,
    ]),
    // Colección anidada (media-col-default) que el decodificador saltea.
    rec(IppTag.begCollection, 'media-col-default', const []),
    rec(IppTag.memberAttrName, '', ascii.encode('media-size')),
    rec(IppTag.begCollection, '', const []),
    rec(IppTag.memberAttrName, '', ascii.encode('x-dimension')),
    rec(IppTag.integer, '', int32(21000)),
    rec(IppTag.endCollection, '', const []),
    rec(IppTag.endCollection, '', const []),
    rec(IppTag.integer, 'queued-job-count', int32(2)),
  ]),
]);
