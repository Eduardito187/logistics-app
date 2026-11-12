import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

/// Resolución de una etiqueta por su `label_id` contra el backend
/// (`GET /app/labels/{labelId}/resolve`). Es el camino ONLINE para las etiquetas
/// impresas en simbología **Code128 (Zebra)**, cuyo valor escaneado ES el
/// `label_id` y que —a diferencia del QR firmado— NO se pueden verificar offline
/// (no llevan firma Ed25519). El QR sigue 100% offline y no pasa por acá.
///
/// El backend responde SIEMPRE 200 (incluso si no encuentra la etiqueta): hay
/// que mirar [resolved], no el código HTTP. Campos `revoked`/`order_number` son
/// aditivos (si el backend aún no los manda, se leen como `false`/`null`).
class LabelResolution {
  const LabelResolution({
    required this.labelId,
    required this.resolved,
    this.unitId,
    this.shipmentId,
    this.sku,
    this.productName,
    this.lineNumber,
    this.unitIndex,
    this.unitTotal,
    this.pieceIndex,
    this.pieceTotal,
    this.revoked = false,
    this.orderNumber,
  });

  factory LabelResolution.fromJson(Map<String, dynamic> json) {
    int? asInt(Object? v) => v is num ? v.toInt() : null;
    String? asString(Object? v) => v is String ? v : null;
    Map<String, dynamic>? asMap(Object? v) =>
        v is Map<String, dynamic> ? v : null;
    // `unit`/`piece` llegan ANIDADOS (`{index,total}`, u objeto `null`): es la
    // forma canónica del backend (`LabelUnitView::toArray()`). Se mantiene un
    // fallback a la forma plana (`unit_index`…) por las dudas, aunque la API no
    // la manda.
    final unit = asMap(json['unit']);
    final piece = asMap(json['piece']);
    return LabelResolution(
      labelId: asString(json['label_id']) ?? '',
      resolved: json['resolved'] == true,
      unitId: asString(json['unit_id']),
      shipmentId: asString(json['shipment_id']),
      sku: asString(json['sku']),
      productName: asString(json['product_name']),
      lineNumber: asInt(json['line_number']),
      unitIndex: asInt(unit?['index']) ?? asInt(json['unit_index']),
      unitTotal: asInt(unit?['total']) ?? asInt(json['unit_total']),
      pieceIndex: asInt(piece?['index']) ?? asInt(json['piece_index']),
      pieceTotal: asInt(piece?['total']) ?? asInt(json['piece_total']),
      revoked: json['revoked'] == true,
      orderNumber: asString(json['order_number']),
    );
  }

  final String labelId;

  /// `true` si el backend reconoció la etiqueta y pudo mapearla a un producto.
  /// `false` = etiqueta inexistente o no resoluble (se rechaza en terreno).
  final bool resolved;

  final String? unitId;
  final String? shipmentId;
  final String? sku;
  final String? productName;
  final int? lineNumber;
  final int? unitIndex;
  final int? unitTotal;
  final int? pieceIndex;
  final int? pieceTotal;

  /// Etiquetas GLOBALES y PERMANENTES (decisión del dueño, nov 2026): una
  /// etiqueta NUNCA se anula. El backend ya no manda `revoked`; se deja el campo
  /// por compatibilidad pero SIEMPRE es `false` y NO afecta la validez.
  final bool revoked;

  /// Pedido de la etiqueta (para contexto / "no es de este pedido"). Aditivo.
  final String? orderNumber;

  /// Aceptable en terreno: el backend reconoció la etiqueta (resuelve) y tiene
  /// producto. Nada se rechaza por "anulada" (las etiquetas son permanentes).
  bool get accepted => resolved && unitId != null;
}

class LabelResolver {
  LabelResolver(this._dio);

  final Dio _dio;

  /// Resuelve un `label_id` contra el backend. Lanza [DioException] si no hay
  /// red o el servidor falla (lo maneja [resolveLabelId], que lo trata como
  /// "no validable sin señal").
  Future<LabelResolution> resolve(String labelId) async {
    final res = await _dio.get<Object?>(
      '/app/labels/${Uri.encodeComponent(labelId)}/resolve',
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      return LabelResolution(labelId: labelId, resolved: false);
    }
    return LabelResolution.fromJson(data);
  }
}

/// Resolución de etiquetas por `label_id` (Code128). Dio crudo: el endpoint vive
/// en el working tree del backend y todavía no está en el cliente generado.
final labelResolverProvider = Provider<LabelResolver>(
  (ref) => LabelResolver(ref.watch(dioProvider)),
);

/// Resuelve un `label_id` (Code128, sin firma) contra el backend. Devuelve la
/// resolución, o `null` si no hubo red / falló la llamada (un Code128 sin señal
/// NO es validable: se rechaza en terreno con aviso). Nunca lanza.
Future<LabelResolution?> resolveLabelId(WidgetRef ref, String labelId) async {
  try {
    return await ref.read(labelResolverProvider).resolve(labelId);
  } on Object {
    return null;
  }
}
