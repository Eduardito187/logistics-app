import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack.dart';
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
    // El router redirige solo al home cuando hay sesión. El error se muestra
    // vía el listener de `loginControllerProvider`.
    await ref
        .read(loginControllerProvider.notifier)
        .submit(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    // Muestra el error del login (credenciales, sin rol, servidor) en un aviso.
    ref.listen(loginControllerProvider, (_, next) {
      final error = next.error;
      if (error != null) {
        showErrorSnack(context, error);
      }
    });

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AuthHeader(),
            Padding(
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
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onSignInPressed(),
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
