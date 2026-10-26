import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../domain/entities/login_result.dart';
import 'controllers/login_controller.dart';
import 'widgets/auth_header.dart';

/// Pantalla de bienvenida e inicio de sesión de la app interna.
///
/// Estilo onboarding: encabezado con degradado de marca, campos grandes y un
/// solo botón de acción. "Ingresar" autentica contra la puerta /app/* (A-02):
/// email + contraseña + dispositivo → token Sanctum; el rol sale del backend.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Contraseña oculta (puntos) o visible (texto); se alterna con el ojo.
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignInPressed() async {
    final email = _userController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      showInfoSnack(context, 'Ingresá tu usuario y contraseña.');
      return;
    }
    // El router redirige solo al home cuando hay sesión (login sin 2FA). El
    // error se muestra vía el listener de `loginControllerProvider`.
    final result = await ref
        .read(loginControllerProvider.notifier)
        .submit(email: email, password: password);
    if (!mounted) return;
    // Si el usuario tiene 2FA, el login no abre sesión: vamos al paso del código.
    if (result is LoginNeedsTwoFactor) {
      unawaited(context.push('/login/2fa', extra: result.challenge));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    // Muestra el error del login (credenciales, sin rol, servidor) en un aviso.
    ref.listen(loginControllerProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      // El login no pasa por la cola offline (sin sesión no hay a quién
      // atribuir la acción): el texto genérico "se guardó y se reintentará"
      // mentía. Se avisa la falta de red y se ofrece reintentar a mano.
      if (error is ApiException && error.isConnectionError) {
        showErrorSnack(
          context,
          'No se pudo conectar con el servidor. Revisá tu señal e intentá de '
          'nuevo.',
          actionLabel: 'Reintentar',
          onAction: _onSignInPressed,
        );
        return;
      }
      showErrorSnack(context, error);
    });

    return Scaffold(
      body: SafeArea(
        top: false,
        // ListView: con el teclado abierto (horizontal o teléfono chico) el
        // formulario se desplaza en vez de desbordar.
        child: ListView(
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const AuthHeader(),
            // En tablet el formulario queda centrado y angosto (maxFormWidth);
            // el encabezado de marca sí ocupa todo el ancho.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxFormWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ingresá a tu cuenta',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _userController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Usuario o correo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onSignInPressed(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: isLoading ? null : _onSignInPressed,
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push('/login/forgot'),
                        child: const Text('Olvidé mi contraseña'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
