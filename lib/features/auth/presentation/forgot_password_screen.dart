import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import 'controllers/forgot_password_controller.dart';
import 'widgets/field_icon.dart';

/// Flujo "olvidé mi contraseña" en dos pasos dentro de una sola pantalla:
/// paso 1 pide el código al correo, paso 2 lo canjea junto con la nueva clave.
/// La respuesta del paso 1 es genérica (no revela si el correo existe).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  // Foco de cada campo: su ícono se ilumina (active) al enfocar.
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  /// 1 = pedir código, 2 = ingresar código y nueva contraseña.
  int _step = 1;

  bool _obscurePassword = true;

  /// Errores por campo del backend (422), mostrados bajo cada campo.
  String? _codeError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _onRequestCodePressed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showInfoSnack(context, 'Ingresá tu correo.');
      return;
    }
    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .requestCode(email);
    if (!mounted) return;
    if (ok) {
      setState(() => _step = 2);
      showInfoSnack(context, 'Si el correo existe, te enviamos un código.');
    } else {
      final error = ref.read(forgotPasswordControllerProvider).error;
      showErrorSnack(context, error ?? 'No se pudo enviar el código.');
    }
  }

  Future<void> _onResendPressed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showInfoSnack(context, 'Ingresá tu correo.');
      return;
    }
    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .requestCode(email);
    if (!mounted) return;
    if (ok) {
      showInfoSnack(context, 'Si el correo existe, te enviamos un código.');
    } else {
      final error = ref.read(forgotPasswordControllerProvider).error;
      showErrorSnack(context, error ?? 'No se pudo reenviar el código.');
    }
  }

  Future<void> _onResetPressed() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() {
      _codeError = null;
      _passwordError = null;
    });

    if (code.isEmpty) {
      showInfoSnack(context, 'Ingresá el código que te llegó al correo.');
      return;
    }
    if (password.length < 8) {
      showInfoSnack(context, 'La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (password != confirm) {
      showInfoSnack(context, 'Las contraseñas no coinciden.');
      return;
    }

    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .reset(email: email, code: code, password: password);
    if (!mounted) return;
    if (ok) {
      showSuccessSnack(
        context,
        'Contraseña actualizada. Ingresá con tu nueva clave.',
      );
      context.go('/login');
      return;
    }
    final error = ref.read(forgotPasswordControllerProvider).error;
    if (error is ApiException && error.fieldErrors.isNotEmpty) {
      setState(() {
        _codeError = error.fieldErrors['code']?.join(' ');
        _passwordError = error.fieldErrors['password']?.join(' ');
      });
      // Si el 422 no trae esos campos, igual mostramos un aviso general.
      if (_codeError == null && _passwordError == null) {
        showErrorSnack(context, error);
      }
    } else {
      showErrorSnack(context, error ?? 'No se pudo cambiar la contraseña.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(forgotPasswordControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxFormWidth,
            ),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: _step == 1
                  ? _buildStepOne(isLoading)
                  : _buildStepTwo(isLoading),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepOne(bool isLoading) {
    final theme = Theme.of(context);
    return [
      Text(
        'Ingresá tu correo y te enviamos un código para cambiar tu '
        'contraseña.',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enabled: !isLoading,
        onSubmitted: (_) => _onRequestCodePressed(),
        decoration: InputDecoration(
          labelText: 'Correo',
          prefixIconConstraints: FieldIcon.prefixConstraints,
          prefixIcon: FieldIcon(icon: AppIcon.mail, focusNode: _emailFocus),
        ),
      ),
      const SizedBox(height: 28),
      FilledButton(
        onPressed: isLoading ? null : _onRequestCodePressed,
        child: isLoading ? const _ButtonSpinner() : const Text('Enviar código'),
      ),
    ];
  }

  List<Widget> _buildStepTwo(bool isLoading) {
    final theme = Theme.of(context);
    return [
      Text(
        'Ingresá el código que te llegó al correo y tu nueva contraseña.',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _codeController,
        focusNode: _codeFocus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enabled: !isLoading,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Código',
          counterText: '',
          prefixIconConstraints: FieldIcon.prefixConstraints,
          prefixIcon: FieldIcon(icon: AppIcon.pin, focusNode: _codeFocus),
          errorText: _codeError,
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        enabled: !isLoading,
        decoration: InputDecoration(
          labelText: 'Nueva contraseña',
          helperText: 'Mínimo 8 caracteres',
          prefixIconConstraints: FieldIcon.prefixConstraints,
          prefixIcon: FieldIcon(
            icon: AppIcon.security,
            focusNode: _passwordFocus,
          ),
          errorText: _passwordError,
          suffixIcon: IconButton(
            tooltip: _obscurePassword
                ? 'Mostrar contraseña'
                : 'Ocultar contraseña',
            icon: AnimatedAppIcon(
              _obscurePassword ? AppIcon.visibility : AppIcon.visibilityOff,
              state: _obscurePassword ? AppIconState.idle : AppIconState.active,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _confirmController,
        focusNode: _confirmFocus,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        enabled: !isLoading,
        onSubmitted: (_) => _onResetPressed(),
        decoration: InputDecoration(
          labelText: 'Repetir contraseña',
          prefixIconConstraints: FieldIcon.prefixConstraints,
          prefixIcon: FieldIcon(
            icon: AppIcon.security,
            focusNode: _confirmFocus,
          ),
        ),
      ),
      const SizedBox(height: 28),
      FilledButton(
        onPressed: isLoading ? null : _onResetPressed,
        child: isLoading
            ? const _ButtonSpinner()
            : const Text('Cambiar contraseña'),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: isLoading ? null : _onResendPressed,
        child: const Text('Reenviar código'),
      ),
    ];
  }
}

/// Loader de marca reutilizado dentro de los botones de acción: el ícono
/// DisTrack "sincronizando" en loop, en vez del spinner gris plano.
class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      width: 24,
      child: AnimatedAppIcon(
        AppIcon.syncing,
        state: AppIconState.loading,
        size: 22,
        color: Colors.white,
        excludeFromSemantics: true,
      ),
    );
  }
}
