/// Códigos de estado IPP (RFC 8011 §5.4.15) y su texto para el operario.
abstract final class IppStatus {
  static const int successfulOk = 0x0000;
  static const int clientErrorBadRequest = 0x0400;
  static const int clientErrorForbidden = 0x0401;
  static const int clientErrorNotAuthenticated = 0x0402;
  static const int clientErrorNotAuthorized = 0x0403;
  static const int clientErrorNotPossible = 0x0404;
  static const int clientErrorTimeout = 0x0405;
  static const int clientErrorNotFound = 0x0406;
  static const int clientErrorGone = 0x0407;
  static const int clientErrorRequestEntityTooLarge = 0x0408;
  static const int clientErrorDocumentFormatNotSupported = 0x040A;
  static const int clientErrorAttributesOrValuesNotSupported = 0x040B;
  static const int serverErrorInternalError = 0x0500;
  static const int serverErrorOperationNotSupported = 0x0501;
  static const int serverErrorServiceUnavailable = 0x0502;
  static const int serverErrorVersionNotSupported = 0x0503;
  static const int serverErrorDeviceError = 0x0504;
  static const int serverErrorTemporaryError = 0x0505;
  static const int serverErrorNotAcceptingJobs = 0x0506;
  static const int serverErrorBusy = 0x0507;
  static const int serverErrorJobCanceled = 0x0508;

  /// successful-ok y variantes (0x0000–0x00FF).
  static bool isSuccess(int code) => code >= 0x0000 && code <= 0x00FF;

  /// Falta autenticarse o el usuario no tiene permiso.
  static bool isAuthProblem(int code) =>
      code == clientErrorNotAuthenticated || code == clientErrorNotAuthorized;

  /// Texto en español para el operario.
  static String message(int code) {
    if (isSuccess(code)) return 'La impresora aceptó el pedido.';
    return switch (code) {
      clientErrorBadRequest => 'La impresora rechazó el pedido (inválido).',
      clientErrorForbidden =>
        'La impresora no permite imprimir desde este teléfono o usuario.',
      clientErrorNotAuthenticated =>
        'La impresora pide autenticarse: ingresá tu usuario de dominio y la '
            'contraseña en Ajustes › Impresora › Acceso a la impresora.',
      clientErrorNotAuthorized =>
        'Tu usuario no está autorizado para imprimir en esta impresora.',
      clientErrorNotPossible => 'La impresora no puede hacer este trabajo.',
      clientErrorTimeout =>
        'La impresora tardó demasiado en recibir el '
            'documento.',
      clientErrorNotFound => 'No se encontró la impresora en esa ruta IPP.',
      clientErrorGone => 'La impresora ya no existe en esa dirección.',
      clientErrorRequestEntityTooLarge =>
        'El documento es demasiado grande para la impresora.',
      clientErrorDocumentFormatNotSupported =>
        'La impresora no acepta el formato del documento.',
      clientErrorAttributesOrValuesNotSupported =>
        'La impresora no admite alguna opción del trabajo.',
      serverErrorInternalError => 'Error interno de la impresora.',
      serverErrorOperationNotSupported =>
        'La impresora no admite esta operación IPP.',
      serverErrorServiceUnavailable =>
        'La impresora no está disponible (servicio IPP apagado).',
      serverErrorVersionNotSupported =>
        'La impresora no admite esta versión de IPP.',
      serverErrorDeviceError =>
        'Error del equipo: revisá papel, tóner, atascos o tapas abiertas.',
      serverErrorTemporaryError =>
        'Error temporal de la impresora; probá de nuevo.',
      serverErrorNotAcceptingJobs =>
        'La impresora no está aceptando trabajos (pausada o detenida).',
      serverErrorBusy =>
        'La impresora está ocupada; probá de nuevo en un momento.',
      serverErrorJobCanceled => 'La impresora canceló el trabajo.',
      _ =>
        'La impresora rechazó el trabajo (código IPP '
            '0x${code.toRadixString(16).padLeft(4, '0')}).',
    };
  }
}
