/// Tipo de escaneo del transportista externo: recoger la carga o entregarla.
///
/// Reúne lo que la pantalla y la cola offline tienen que compartir para que la
/// tanda se pueda RECONSTRUIR al reabrir la pantalla: el `kind` con el que se
/// encola cada registro y el prefijo de su etiqueta legible.
enum CarrierScanKind {
  pickup(queueKind: 'recordLoadScan', labelPrefix: 'Recojo transportista'),
  deliver(
    queueKind: 'recordProofOfDelivery',
    labelPrefix: 'Entrega transportista',
  );

  const CarrierScanKind({required this.queueKind, required this.labelPrefix});

  /// `kind` de la fila en la cola offline (lo resuelve el dispatcher de core).
  final String queueKind;

  /// Prefijo de la etiqueta legible de la fila (`"<prefijo> · SKU"`).
  ///
  /// Es PROPIO del transportista a propósito: la cola es del DISPOSITIVO y el
  /// mismo `queueKind` lo usan el chofer (`recordLoadScan` al cargar) y la
  /// tienda (`recordProofOfDelivery` en mostrador), así que el prefijo es lo
  /// único que distingue nuestras filas de las suyas al reconstruir la tanda.
  final String labelPrefix;

  /// Separador entre el prefijo y el SKU en la etiqueta de la fila.
  static const String separator = ' · ';

  /// Etiqueta legible de la fila para [sku].
  String labelFor(String sku) => '$labelPrefix$separator$sku';

  /// SKU de una etiqueta de esta clase, o `null` si la fila no es de este
  /// escaneo del transportista (otro rol, otro flujo o etiqueta vacía).
  String? skuOf(String? label) {
    final prefix = '$labelPrefix$separator';
    if (label == null || !label.startsWith(prefix)) return null;
    return label.substring(prefix.length);
  }
}
