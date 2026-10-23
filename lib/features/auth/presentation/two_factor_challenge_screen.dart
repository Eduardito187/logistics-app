import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../domain/entities/two_factor_challenge.dart';
import 'controllers/two_factor_challenge_controller.dart';

/// Pantalla del reto de doble factor que aparece después del login cuando el
/// usuario tiene 2FA activo. Pide el código de 6 dígitos del autenticador (o un
/// código de recuperación) y, al verificar con éxito, el router redirige solo al
/// inicio porque la sesión ya quedó abierta.
class TwoFactorChallengeScreen extends ConsumerStatefulWidget {
  const TwoFactorChallengeScreen({super.key, required this.challenge});

  final TwoFactorChallenge challenge;

  @override
  ConsumerState<TwoFactorChallengeScreen> createState() =>
      _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState
    extends ConsumerState<TwoFactorChallengeScreen> {
  final _codeController = TextEditingController();

  /// Modo recuperación: el campo acepta un código XXXX-XXXX en vez del TOTP.
  bool _recoveryMode = false;

  /// Segundos restantes de vida del reto. A 0 ya no se puede verificar.
  late int _remaining = widget.challenge.expiresInSeconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  /// Countdown de 1 s; no es crítico, solo deshabilita el botón al expirar.
  void _startCountdown() {
    if (_remaining <= 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  bool get _expired => _remaining <= 0;

  /// mm:ss restantes para el texto del countdown.
  String get _remainingLabel {
    final minutes = (_remaining ~/ 60).toString();
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _goToLogin() {
    context.go('/login');
  }

  Future<void> _onVerifyPressed() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showInfoSnack(context, 'Ingresá el código para continuar.');
      return;
    }
    final entered = await ref
        .read(twoFactorChallengeControllerProvider.notifier)
        .verify(challengeId: widget.challenge.challengeId, code: code);
    if (!mounted || entered) {
      // Si entró NO navegamos: el router redirige solo al abrirse la sesión.
      return;
    }
    final error = ref.read(twoFactorChallengeControllerProvider).error;
    if (error is ApiException && error.isValidation) {
      showErrorSnack(context, 'Código inválido o expirado');
    } else {
      showErrorSnack(context, error ?? 'No se pudo verificar el código.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(twoFactorChallengeControllerProvider).isLoading;
    final canVerify = !isLoading && !_expired;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificación en dos pasos')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxFormWidth,
            ),
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                Text(
                  _recoveryMode
                      ? 'Ingresá uno de tus códigos de recuperación con el '
                            'formato XXXX-XXXX.'
                      : 'Abrí tu app de autenticación (por ej. Google '
                            'Authenticator) e ingresá el código de 6 dígitos.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  enabled: canVerify,
                  keyboardType: _recoveryMode
                      ? TextInputType.text
                      : TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onVerifyPressed(),
                  autocorrect: false,
                  maxLength: _recoveryMode ? 9 : 6,
                  inputFormatters: _recoveryMode
                      ? null
                      : [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: _recoveryMode ? 2 : 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: _recoveryMode ? 'XXXX-XXXX' : '000000',
                  ),
                ),
                const SizedBox(height: 12),
                if (!_expired)
                  Text(
                    'El código vence en $_remainingLabel',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'El código venció. Volvé al login para empezar de nuevo.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 24),
                if (_expired)
                  FilledButton(
                    onPressed: _goToLogin,
                    child: const Text('Volver al login'),
                  )
                else
                  FilledButton(
                    onPressed: canVerify ? _onVerifyPressed : null,
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verificar'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() {
                          _recoveryMode = !_recoveryMode;
                          _codeController.clear();
                        }),
                  child: Text(
                    _recoveryMode
                        ? 'Usar código del autenticador'
                        : 'Usar código de recuperación',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
