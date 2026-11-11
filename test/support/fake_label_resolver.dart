import 'package:logistics_app/core/labels/label_resolver.dart';

/// Resolver de etiquetas falso para tests (Code128 → `label_id`): devuelve las
/// resoluciones sembradas, o `resolved:false` para un label desconocido. Con
/// [offline] en `true` simula que no hay señal (lanza; `resolveLabelId` lo
/// traduce a `null` → la etiqueta se rechaza por no validable). Con [echo] en
/// `true` un label no sembrado se reconoce usando el propio `label_id` como
/// `unit_id` (para flujos donde el código escaneado representa directamente al
/// bulto, como antes del contrato real).
///
/// Uso: `labelResolverProvider.overrideWithValue(fake)`.
class FakeLabelResolver implements LabelResolver {
  FakeLabelResolver({
    Map<String, LabelResolution>? resolutions,
    this.offline = false,
    this.echo = false,
  }) : _resolutions = resolutions ?? const {};

  final Map<String, LabelResolution> _resolutions;
  final bool offline;
  final bool echo;

  /// Los `label_id` consultados, en orden.
  final List<String> requested = [];

  @override
  Future<LabelResolution> resolve(String labelId) async {
    requested.add(labelId);
    if (offline) {
      throw StateError('FakeLabelResolver: sin señal');
    }
    final seeded = _resolutions[labelId];
    if (seeded != null) return seeded;
    if (echo) {
      return LabelResolution(labelId: labelId, resolved: true, unitId: labelId);
    }
    return LabelResolution(labelId: labelId, resolved: false);
  }
}
