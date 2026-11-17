import 'package:flutter/foundation.dart';

/// Un motivo de "no se pudo entregar", configurable por el administrador.
///
/// El admin crea los motivos, elige cuáles se muestran al chofer ([active]) y,
/// por cada uno, si al elegirlo hay que pedir **foto** ([requiresPhoto]) y/o un
/// **texto/observación** ([requiresNote]). El [code] es el identificador estable
/// que viaja al backend (`reason`); NUNCA se muestra en pantalla (preferencia
/// del dueño: ningún código técnico a la vista) — en la UI solo se ve [label].
///
/// Hasta que el backend tenga el catálogo, la app arranca con
/// [kDefaultFailureReasons] (los 5 motivos de siempre), así el flujo del chofer
/// funciona offline y antes del deploy.
@immutable
class FailureReasonOption {
  const FailureReasonOption({
    required this.code,
    required this.label,
    this.active = true,
    this.requiresPhoto = false,
    this.requiresNote = false,
    this.noteLabel,
    this.sortOrder = 0,
  });

  factory FailureReasonOption.fromJson(Map<String, Object?> json) {
    final note = json['note_label'];
    final order = json['sort_order'];
    return FailureReasonOption(
      code: (json['code'] as String?)?.trim() ?? '',
      label: (json['label'] as String?)?.trim() ?? '',
      // Si el backend no manda `active`, se asume visible (compatibilidad).
      active: json['active'] is bool ? json['active']! as bool : true,
      requiresPhoto:
          json['requires_photo'] is bool ? json['requires_photo']! as bool : false,
      requiresNote:
          json['requires_note'] is bool ? json['requires_note']! as bool : false,
      noteLabel: note is String && note.trim().isNotEmpty ? note.trim() : null,
      sortOrder: order is num ? order.toInt() : 0,
    );
  }

  /// Identificador estable que viaja al backend como `reason`. No se muestra.
  final String code;

  /// Texto que ve el chofer (en español).
  final String label;

  /// Si está visible/habilitado para el chofer. Desactivado = no aparece en la
  /// lista de motivos (se conserva para el historial y para reactivarlo).
  final bool active;

  /// Al elegir este motivo, la foto es obligatoria.
  final bool requiresPhoto;

  /// Al elegir este motivo, hay que escribir un texto/observación.
  final bool requiresNote;

  /// Etiqueta del campo de texto cuando [requiresNote] (p. ej. "¿Qué pasó?").
  final String? noteLabel;

  /// Orden en que se muestran los motivos (menor primero).
  final int sortOrder;

  /// Etiqueta a mostrar sobre el campo de texto (cae a "Detalle" si no se fijó).
  String get noteFieldLabel {
    final custom = noteLabel?.trim();
    return custom == null || custom.isEmpty ? 'Detalle' : custom;
  }

  static const Object _unset = Object();

  FailureReasonOption copyWith({
    String? label,
    bool? active,
    bool? requiresPhoto,
    bool? requiresNote,
    // Centinela: permite volver [noteLabel] a `null` (regla #5 del proyecto).
    Object? noteLabel = _unset,
    int? sortOrder,
  }) => FailureReasonOption(
    code: code,
    label: label ?? this.label,
    active: active ?? this.active,
    requiresPhoto: requiresPhoto ?? this.requiresPhoto,
    requiresNote: requiresNote ?? this.requiresNote,
    noteLabel: identical(noteLabel, _unset)
        ? this.noteLabel
        : noteLabel as String?,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  Map<String, Object?> toJson() => {
    'code': code,
    'label': label,
    'active': active,
    'requires_photo': requiresPhoto,
    'requires_note': requiresNote,
    'note_label': noteLabel,
    'sort_order': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      other is FailureReasonOption &&
      other.code == code &&
      other.label == label &&
      other.active == active &&
      other.requiresPhoto == requiresPhoto &&
      other.requiresNote == requiresNote &&
      other.noteLabel == noteLabel &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
    code,
    label,
    active,
    requiresPhoto,
    requiresNote,
    noteLabel,
    sortOrder,
  );
}

/// Motivos de fábrica (los de siempre). Todos visibles y sin exigencias: el
/// admin decide luego cuáles ocultar y en cuáles pedir foto o texto. Sirven de
/// respaldo mientras el backend no tenga el catálogo y como semilla offline.
const List<FailureReasonOption> kDefaultFailureReasons = [
  FailureReasonOption(
    code: 'CUSTOMER_ABSENT',
    label: 'Cliente ausente',
    sortOrder: 0,
  ),
  FailureReasonOption(
    code: 'WRONG_ADDRESS',
    label: 'Dirección incorrecta',
    sortOrder: 1,
  ),
  FailureReasonOption(code: 'REJECTED', label: 'Pedido rechazado', sortOrder: 2),
  FailureReasonOption(code: 'DAMAGED', label: 'Producto dañado', sortOrder: 3),
  FailureReasonOption(code: 'OTHER', label: 'Otro motivo', sortOrder: 4),
];
