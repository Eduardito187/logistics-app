import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';

/// Pausa entre las dos vibraciones del aviso de error: se distingue del
/// "click" de éxito aun con el teléfono en el bolsillo o con guantes.
const Duration kScanErrorVibrationGap = Duration(milliseconds: 180);

/// Aviso de lectura correcta: vibración fuerte + sonido corto del sistema.
///
/// Nunca lanza: si la plataforma no tiene vibrador o sonido, se ignora (el
/// escaneo sigue igual, el aviso es un extra).
Future<void> scanSuccessFeedback() async {
  await _safe(HapticFeedback.heavyImpact);
  await _safe(() => SystemSound.play(SystemSoundType.click));
}

/// Aviso de lectura rechazada (código inválido, ajeno, repetido): doble
/// vibración, sin sonido de éxito.
Future<void> scanErrorFeedback() async {
  await _safe(HapticFeedback.vibrate);
  await Future<void>.delayed(kScanErrorVibrationGap);
  await _safe(HapticFeedback.vibrate);
}

/// Aviso de éxito o error respetando la preferencia "Vibrar y sonar al
/// escanear". Pensado para pantallas que no son `Consumer`: busca el
/// `ProviderScope` del [context]; sin él, el aviso queda activado (default).
Future<void> scanFeedbackFor(
  BuildContext context, {
  required bool success,
}) async {
  if (!_enabledFor(context)) return;
  await (success ? scanSuccessFeedback() : scanErrorFeedback());
}

bool _enabledFor(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(scanFeedbackEnabledProvider);
  } on StateError {
    return true;
  }
}

Future<void> _safe(Future<void> Function() call) async {
  try {
    await call();
  } on Object {
    // Sin vibrador/sonido o canal no disponible: no se interrumpe el flujo.
  }
}

/// Preferencia "Vibrar y sonar al escanear" (por defecto activada), persistida
/// en el almacén seguro. Carga en segundo plano: el primer escaneo no espera.
class ScanFeedbackEnabledNotifier extends Notifier<bool> {
  /// Clave en el almacén seguro.
  static const storageKey = 'pref_scan_feedback';

  bool _changedByUser = false;

  @override
  bool build() {
    unawaited(_load());
    return true;
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(secureStorageProvider).read(key: storageKey);
      if (!ref.mounted || _changedByUser || raw == null) return;
      state = raw != 'false';
    } on Object {
      // Almacén no disponible: queda activado (default).
    }
  }

  /// Activa o desactiva el aviso y lo guarda.
  Future<void> set(bool value) async {
    _changedByUser = true;
    state = value;
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: storageKey, value: value.toString());
    } on Object {
      // Si no se pudo guardar, igual rige para esta sesión de la app.
    }
  }
}

/// `true` si al escanear se vibra y suena (default).
final scanFeedbackEnabledProvider =
    NotifierProvider<ScanFeedbackEnabledNotifier, bool>(
      ScanFeedbackEnabledNotifier.new,
    );

/// Atajo para pantallas `Consumer`: aviso de éxito/error según la preferencia.
Future<void> scanFeedbackWithRef(WidgetRef ref, {required bool success}) async {
  if (!ref.read(scanFeedbackEnabledProvider)) return;
  await (success ? scanSuccessFeedback() : scanErrorFeedback());
}
