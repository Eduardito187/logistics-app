import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/biometric/biometric_auto_prompt_gate.dart';
import '../../../core/auth/biometric/biometric_authenticator.dart';
import '../../../core/auth/biometric/biometric_capabilities_provider.dart';
import '../../../core/auth/biometric/biometric_credential_notifier.dart';
import '../../../core/auth/biometric/biometric_messages.dart';
import '../../../core/auth/biometric/biometric_result.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../domain/entities/login_result.dart';
import 'controllers/biometric_offer_controller.dart';
import 'controllers/login_controller.dart';
import 'widgets/auth_header.dart';
import 'widgets/biometric_sign_in_button.dart';
import '../../../core/widgets/field_icon.dart';

/// Pantalla de bienvenida e inicio de sesión de la app interna.
///
/// Estilo onboarding: encabezado con degradado de marca, campos grandes y un
/// solo botón de acción. "Ingresar" autentica contra la puerta /app/* (A-02):
/// email + contraseña + dispositivo → token Sanctum; el rol sale del backend.
///
/// Si el usuario activó el ingreso con biometría (perfil u oferta post-login),
/// arriba aparece "Ingresar con Face ID / huella…": pide la biometría y hace
/// el MISMO login con la credencial guardada (2FA incluido). El diálogo se
/// lanza solo al abrir el login únicamente en la primera vez de cada apertura
/// de la app (ver [BiometricAutoPromptGate]).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  // Foco de cada campo: su ícono se ilumina (active) al enfocar.
  final _userFocus = FocusNode();
  final _passwordFocus = FocusNode();

  /// Contraseña oculta (puntos) o visible (texto); se alterna con el ojo.
  bool _obscurePassword = true;

  /// Esperando la biometría (o el login que dispara): evita dos diálogos.
  bool _biometricBusy = false;

  /// El intento en curso salió de la biometría: el listener no muestra el
  /// "Usuario o contraseña incorrectos." genérico (se avisa que cambió).
  bool _biometricAttempt = false;

  /// Qué repite "Reintentar" en el aviso de sin conexión: el último intento.
  late Future<void> Function() _retry = _onSignInPressed;

  /// Al volver a la app (p. ej. tras registrar una huella en los ajustes del
  /// teléfono) se vuelve a consultar la biometría disponible.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(biometricCapabilitiesProvider),
    );
    if (ref.read(biometricAutoPromptGateProvider).consume()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoPrompt());
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Primer login de la apertura: si hay credencial y biometría, la pide sola.
  Future<void> _autoPrompt() async {
    if (!mounted) return;
    try {
      final caps = await ref.read(biometricCapabilitiesProvider.future);
      if (!mounted) return;
      final credential = await ref.read(biometricCredentialProvider.future);
      if (!mounted || credential == null || !caps.isAvailable) return;
    } on Object {
      return;
    }
    await _onBiometricPressed();
  }

  /// Ingreso con biometría: pide huella/rostro y, si pasa, hace el mismo login
  /// que el formulario con la credencial guardada.
  Future<void> _onBiometricPressed() async {
    if (_biometricBusy) return;
    final credential = ref.read(biometricCredentialProvider).value;
    final caps = ref.read(biometricCapabilitiesProvider).value;
    if (credential == null || caps == null || !caps.isAvailable) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    // Se toman antes de esperar: con sesión abierta el login se descarta.
    final credentials = ref.read(biometricCredentialProvider.notifier);
    final login = ref.read(loginControllerProvider.notifier);
    ref.read(biometricOfferControllerProvider).discard();
    setState(() => _biometricBusy = true);
    try {
      final auth = await ref
          .read(biometricAuthenticatorProvider)
          .authenticate(
            reason: 'Ingresá como ${credential.displayName}',
            cancel: 'Usar contraseña',
          );
      if (!mounted) return;
      if (auth != BiometricResult.success) {
        final message = BiometricMessages.signIn(auth, caps);
        if (auth == BiometricResult.notEnrolled) {
          ref.invalidate(biometricCapabilitiesProvider);
        }
        if (message != null) showErrorSnack(context, message);
        return;
      }
      _retry = _onBiometricPressed;
      _biometricAttempt = true;
      final result = await login.submit(
        email: credential.email,
        password: credential.password,
      );
      if (result is LoginNeedsTwoFactor) {
        if (mounted) {
          unawaited(context.push('/login/2fa', extra: result.challenge));
        }
        return;
      }
      if (result != null || !mounted) return;
      final error = ref.read(loginControllerProvider).error;
      if (_isInvalidCredentials(error)) {
        // La contraseña guardada ya no sirve: se borra y se avisa.
        await credentials.disable();
        if (mounted) {
          showErrorSnack(context, BiometricMessages.passwordChanged(caps));
        }
      }
    } finally {
      _biometricAttempt = false;
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  /// 401 del login = usuario o contraseña incorrectos (ver AuthRepositoryImpl).
  static bool _isInvalidCredentials(Object? error) =>
      error is ApiException && error.status == 401;

  Future<void> _onSignInPressed() async {
    _retry = _onSignInPressed;
    final email = _userController.text.trim();
    final password = _passwordController.text;
    // Limpiar cualquier aviso anterior AL TOCAR, no al llegar la respuesta: si no,
    // el error viejo (dura 4 s) queda visible mientras vuela el request y recién
    // se reemplaza al volver → se ven "dos errores". Al tocar, borrón y cuenta nueva.
    ScaffoldMessenger.of(context).clearSnackBars();
    if (email.isEmpty || password.isEmpty) {
      showInfoSnack(context, 'Ingresá tu usuario y contraseña.');
      return;
    }
    // Se toma antes de esperar: con sesión abierta esta pantalla se descarta.
    final biometricOffer = ref.read(biometricOfferControllerProvider)
      ..discard();
    // El router redirige solo al home cuando hay sesión (login sin 2FA). El
    // error se muestra vía el listener de `loginControllerProvider`.
    final result = await ref
        .read(loginControllerProvider.notifier)
        .submit(email: email, password: password);
    switch (result) {
      case LoginSignedIn():
        // Con la contraseña aún en memoria: "¿Ingresar con … la próxima vez?".
        unawaited(biometricOffer.offer(email: email, password: password));
      case LoginNeedsTwoFactor(:final challenge):
        // Se ofrece recién al verificar el código (pantalla 2FA).
        biometricOffer.remember(email: email, password: password);
        // Si el usuario tiene 2FA, el login no abre sesión: vamos al código.
        if (mounted) unawaited(context.push('/login/2fa', extra: challenge));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;
    final caps = ref.watch(biometricCapabilitiesProvider).value;
    final credential = ref.watch(biometricCredentialProvider).value;

    // Muestra el error del login (credenciales, sin rol, servidor) en un aviso.
    ref.listen(loginControllerProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      // Credencial biométrica vencida: lo avisa `_onBiometricPressed`.
      if (_biometricAttempt && _isInvalidCredentials(error)) return;
      // El login no pasa por la cola offline (sin sesión no hay a quién
      // atribuir la acción): el texto genérico "se guardó y se reintentará"
      // mentía. Se avisa la falta de red y se ofrece reintentar a mano.
      if (error is ApiException && error.isConnectionError) {
        showErrorSnack(
          context,
          'No se pudo conectar con el servidor. Revisá tu señal e intentá de '
          'nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => _retry(),
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
                      // Solo con credencial guardada y biometría utilizable.
                      if (caps != null &&
                          caps.isAvailable &&
                          credential != null)
                        BiometricSignInButton(
                          capabilities: caps,
                          credential: credential,
                          busy: _biometricBusy || isLoading,
                          onPressed: _onBiometricPressed,
                        ),
                      TextField(
                        controller: _userController,
                        focusNode: _userFocus,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Usuario o correo',
                          prefixIconConstraints: FieldIcon.prefixConstraints,
                          prefixIcon: FieldIcon(
                            icon: AppIcon.profile,
                            focusNode: _userFocus,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onSignInPressed(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIconConstraints: FieldIcon.prefixConstraints,
                          prefixIcon: FieldIcon(
                            icon: AppIcon.security,
                            focusNode: _passwordFocus,
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: AnimatedAppIcon(
                              _obscurePassword
                                  ? AppIcon.visibility
                                  : AppIcon.visibilityOff,
                              state: _obscurePassword
                                  ? AppIconState.idle
                                  : AppIconState.active,
                              size: 20,
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
                        // Al enviar, el botón muestra el ícono de marca
                        // "sincronizando" en loop (animación DisTrack) en vez
                        // del spinner gris plano.
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: AnimatedAppIcon(
                                  AppIcon.syncing,
                                  state: AppIconState.loading,
                                  size: 22,
                                  color: Colors.white,
                                  excludeFromSemantics: true,
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
