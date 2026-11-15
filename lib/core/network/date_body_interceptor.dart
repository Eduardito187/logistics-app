import 'package:dio/dio.dart';

/// Recorta a `Y-m-d` (fecha de calendario) los campos de fecha del CUERPO que el
/// backend valida con `date_format:Y-m-d`.
///
/// El cliente generado serializa los `DateTime` como fecha-hora ISO
/// (`toIso8601String`, p. ej. `2026-11-12T15:30:00.000`). Varios endpoints del
/// backend validan esos campos como `date_format:Y-m-d` → 422 ("the field must
/// match the format Y-m-d"). `DateQueryInterceptor` ya lo resuelve para los
/// QUERY params; esto hace lo mismo para el CUERPO.
///
/// Solo toca una lista CURADA de claves que en el backend son fecha-de-calendario
/// (todas sin hora). NUNCA toca los `*_at`/`*At` (son fecha-hora reales:
/// `occurred_at`, `read_at`, `returned_at`, `depart_at`, `captured_at`,
/// `expires_at`…), ni claves ambiguas. Recortar un valor que ya es `Y-m-d` es
/// idempotente (no cambia nada), así que es seguro aunque el data source ya lo
/// mande bien (p. ej. el checklist, que usa Dio directo).
class DateBodyInterceptor extends Interceptor {
  const DateBodyInterceptor();

  /// Claves del cuerpo que el backend valida `date_format:Y-m-d` (verificado
  /// contra el spec desplegado). Solo fechas de calendario, nunca `*_at`.
  static const Set<String> dateOnlyKeys = {
    'plan_date',
    'route_date',
    'performed_on',
    'period_from',
    'period_to',
    'effective_from',
    'assembled_for',
    'appointment_date',
    'slot_date',
    'reference_date',
    'expires_on',
    'license_expiry',
    'from_date',
    'delivery_date_from',
    'delivery_date_to',
  };

  static final RegExp _ymdHead = RegExp(r'^(\d{4}-\d{2}-\d{2})');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data;
    if (data is Map) {
      for (final key in dateOnlyKeys) {
        final value = data[key];
        if (value is String) {
          final match = _ymdHead.firstMatch(value);
          // Recorta "2026-11-12T15:30:…" → "2026-11-12"; si ya es Y-m-d, igual.
          if (match != null && match.group(1)!.length != value.length) {
            data[key] = match.group(1);
          }
        }
      }
    }
    handler.next(options);
  }
}
