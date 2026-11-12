/// Qué se sabe del trabajo después de mandarlo. El texto ([message]) es
/// veraz: solo dice "aceptó" cuando la impresora lo confirmó.
enum PrintOutcomeKind {
  /// IPP: la impresora aceptó el trabajo y sigue procesándolo (no terminó
  /// dentro del seguimiento).
  accepted,

  /// IPP: la impresora informó el trabajo como TERMINADO (job-state 9).
  printed,

  /// IPP: la impresora lo RETUVO (job-state 4): sale recién cuando el usuario
  /// lo libera en el panel (impresión segura / retenida).
  held,

  /// Zebra por 9100: respondió el estado y no tiene errores.
  ready,

  /// 9100 sin respuesta de estado: se mandó pero nadie lo confirma.
  sentUnconfirmed,

  /// Bluetooth/USB: los bytes se escribieron (sin canal de confirmación).
  sent,
}

/// Resultado de una impresión que no falló.
class PrintOutcome {
  const PrintOutcome._(this.kind, {this.jobId, this.note});

  /// IPP aceptó el trabajo. [note] = aviso del estado de la impresora (p. ej.
  /// "La impresora está sin papel.") que no impidió aceptarlo.
  const PrintOutcome.accepted({int? jobId, String? note})
    : this._(PrintOutcomeKind.accepted, jobId: jobId, note: note);

  /// IPP: la impresora confirmó que terminó de imprimir el trabajo.
  const PrintOutcome.printed({int? jobId, String? note})
    : this._(PrintOutcomeKind.printed, jobId: jobId, note: note);

  /// IPP: el trabajo quedó retenido esperando que lo liberen en el panel.
  const PrintOutcome.held({int? jobId, String? note})
    : this._(PrintOutcomeKind.held, jobId: jobId, note: note);

  const PrintOutcome.ready() : this._(PrintOutcomeKind.ready);

  const PrintOutcome.sentUnconfirmed()
    : this._(PrintOutcomeKind.sentUnconfirmed);

  const PrintOutcome.sent() : this._(PrintOutcomeKind.sent);

  final PrintOutcomeKind kind;

  /// `job-id` informado por la impresora (IPP).
  final int? jobId;

  /// Aviso adicional (estado de la impresora), si lo hay.
  final String? note;

  /// La impresora confirmó haber recibido el trabajo.
  bool get confirmed =>
      kind == PrintOutcomeKind.accepted ||
      kind == PrintOutcomeKind.printed ||
      kind == PrintOutcomeKind.held ||
      kind == PrintOutcomeKind.ready;

  /// Texto para el operario (español).
  String get message {
    final base = switch (kind) {
      // Sin estado final: NO se insinúa éxito ("procesando" sonaba a que iba
      // bien y la Ricoh lo había cancelado). Se dice lo único seguro.
      PrintOutcomeKind.accepted =>
        jobId == null
            ? 'La impresora recibió el trabajo pero no confirmó si lo '
                  'imprimió. Revisá que haya salido.'
            : 'La impresora recibió el trabajo (#$jobId) pero no confirmó si '
                  'lo imprimió. Revisá que haya salido.',
      PrintOutcomeKind.printed =>
        jobId == null
            ? 'Impreso: la impresora confirmó el trabajo.'
            : 'Impreso: la impresora confirmó el trabajo (#$jobId).',
      PrintOutcomeKind.held =>
        'La impresora retuvo el trabajo${jobId == null ? '' : ' (#$jobId)'}: '
            'liberalo desde el panel de la impresora con tu usuario.',
      PrintOutcomeKind.ready =>
        'La impresora recibió la etiqueta y está lista.',
      PrintOutcomeKind.sentUnconfirmed =>
        'Enviado. Esta impresora no confirma la impresión; revisá que haya '
            'salido.',
      PrintOutcomeKind.sent => 'Etiqueta enviada a la impresora.',
    };
    final extra = note;
    return extra == null ? base : '$base $extra';
  }

  @override
  bool operator ==(Object other) =>
      other is PrintOutcome &&
      other.kind == kind &&
      other.jobId == jobId &&
      other.note == note;

  @override
  int get hashCode => Object.hash(kind, jobId, note);

  @override
  String toString() => 'PrintOutcome($kind, job: $jobId)';
}
