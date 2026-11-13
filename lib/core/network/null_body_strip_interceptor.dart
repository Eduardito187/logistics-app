import 'package:dio/dio.dart';

/// Quita las claves de NIVEL SUPERIOR con valor `null` del cuerpo JSON de cada
/// request.
///
/// El cliente generado (json_serializable) incluye SIEMPRE los campos opcionales
/// en el cuerpo, incluso cuando valen `null` (p. ej. `device_id`, `user_id`,
/// `photo_path`, `photo_url`, `idempotency_key`). Varias validaciones del backend
/// usan `['sometimes','string']` SIN `nullable`: una clave presente-con-`null`
/// NO la saltea `sometimes`, y la regla `string` sobre `null` falla con **422**
/// (el POD caía con "No se pudo registrar" por `device_id`/`user_id` en null, aun
/// mandando bien el resto).
///
/// Omitir la clave (campo AUSENTE) es el comportamiento correcto de un campo
/// opcional sin valor: así `sometimes` sí lo saltea y `nullable`/`required_with`
/// se evalúan como corresponde. Los valores presentes no se tocan; `idempotency_key`
/// viaja igual por el header `Idempotency-Key`.
///
/// Solo toca el PRIMER nivel de un `Map` (los anidados quedan igual, por si algún
/// endpoint distingue "campo anidado en null" de "ausente") y no aplica a cuerpos
/// que no sean `Map` (FormData de subida de fotos, strings) ni a GET (sin cuerpo).
class NullBodyStripInterceptor extends Interceptor {
  const NullBodyStripInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data;
    if (data is Map) {
      options.data = <dynamic, dynamic>{
        for (final entry in data.entries)
          if (entry.value != null) entry.key: entry.value,
      };
    }
    handler.next(options);
  }
}
