import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/biometric/biometric_authenticator.dart';
import '../../../../core/auth/biometric/biometric_credential_notifier.dart';
import '../../../../core/auth/biometric/biometric_credential_store.dart';
import '../../../../core/auth/biometric/biometric_messages.dart';
import '../../../../core/auth/biometric/biometric_result.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/widgets/app_snack.dart';
import '../widgets/biometric_offer_dialog.dart';
import 'biometric_offer_context.dart';

/// Oferta post-login: tras ingresar con contraseña (la contraseña todavía está
/// en memoria), si el teléfono tiene biometría registrada y la cuenta no la
/// tiene activada ni dijo "Ahora no", pregunta "¿Querés ingresar con … la
/// próxima vez?".
///
/// Vive fuera de la pantalla de login a propósito: al abrirse la sesión el
/// router saca al usuario del login, así que el diálogo se muestra sobre el
/// inicio (ver [biometricOfferContextProvider]).
class BiometricOfferController {
  BiometricOfferController(this._ref);

  final Ref _ref;

  /// Credenciales de un login que quedó esperando el código 2FA. Solo en
  /// memoria; se consumen al verificar el código ([offerPending]).
  ({String email, String password})? _pending;

  /// Guarda las credenciales mientras el usuario completa el 2FA.
  void remember({required String email, required String password}) =>
      _pending = (email: email, password: password);

  /// Olvida las credenciales pendientes (otro intento de login empezó).
  void discard() => _pending = null;

  /// Tras verificar el 2FA: ofrece con las credenciales del login previo.
  Future<void> offerPending() async {
    final pending = _pending;
    _pending = null;
    if (pending == null) return;
    await offer(email: pending.email, password: pending.password);
  }

  /// Ofrece activar la biometría si corresponde. Nunca lanza.
  Future<void> offer({required String email, required String password}) async {
    _pending = null;
    try {
      await _offer(email: email, password: password);
    } on Object {
      // La oferta es opcional: un fallo no debe molestar al que ya entró.
    }
  }

  Future<void> _offer({required String email, required String password}) async {
    final caps = await _ref.read(biometricAuthenticatorProvider).capabilities();
    if (!caps.isAvailable) return;

    final credentials = _ref.read(biometricCredentialProvider.notifier);
    final current = await _ref.read(biometricCredentialProvider.future);
    if (current != null && current.isFor(email)) {
      // Ya la tiene: solo se mantiene al día la contraseña guardada.
      await credentials.syncPassword(email: email, password: password);
      return;
    }
    final store = _ref.read(biometricCredentialStoreProvider);
    if (await store.hasDeclined(email)) return;

    final context = await _ref.read(biometricOfferContextProvider)();
    if (context == null || !context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) =>
          BiometricOfferDialog(capabilities: caps, replacing: current),
    );
    if (accepted != true) {
      // "Ahora no" (o tocar afuera): no se vuelve a ofrecer a esta cuenta. Se
      // puede activar cuando quiera desde el perfil.
      await store.markDeclined(email);
      return;
    }

    final result = await credentials.enable(
      email: email,
      password: password,
      capabilities: caps,
      name: _ref.read(sessionProvider)?.userName,
    );
    if (!context.mounted) return;
    final message = BiometricMessages.enable(result, caps);
    if (message == null) return;
    if (result == BiometricResult.success) {
      showSuccessSnack(context, message);
    } else {
      showErrorSnack(context, message);
    }
  }
}

final biometricOfferControllerProvider = Provider<BiometricOfferController>(
  BiometricOfferController.new,
);
