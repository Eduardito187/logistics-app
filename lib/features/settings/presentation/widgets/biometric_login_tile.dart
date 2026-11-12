import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/biometric/biometric_capabilities.dart';
import '../../../../core/auth/biometric/biometric_capabilities_provider.dart';
import '../../../../core/auth/biometric/biometric_credential_notifier.dart';
import '../../../../core/auth/biometric/biometric_messages.dart';
import '../../../../core/auth/biometric/biometric_result.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/app_snack.dart';
import 'biometric_password_dialog.dart';

/// Switch del perfil "Ingresar con Face ID / huella…".
///
/// - Teléfono sin biometría: no se muestra nada.
/// - Con sensor pero nada registrado: ítem deshabilitado con "Configurá … en
///   los ajustes del teléfono para usarlo acá.".
/// - Disponible: al encender pide la contraseña y la biometría; al apagar
///   borra la credencial guardada.
class BiometricLoginTile extends ConsumerStatefulWidget {
  const BiometricLoginTile({super.key, required this.email, this.name});

  /// Cuenta en sesión (de `/app/auth/me`).
  final String email;
  final String? name;

  @override
  ConsumerState<BiometricLoginTile> createState() => _BiometricLoginTileState();
}

class _BiometricLoginTileState extends ConsumerState<BiometricLoginTile> {
  bool _busy = false;

  /// Al volver de los ajustes del teléfono (registró una huella) se refresca.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(biometricCapabilitiesProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _enable(BiometricCapabilities caps) async {
    final notifier = ref.read(biometricCredentialProvider.notifier);
    final current = ref.read(biometricCredentialProvider).value;
    final replacing = current != null && !current.isFor(widget.email)
        ? current
        : null;
    final password = await showDialog<String>(
      context: context,
      builder: (_) =>
          BiometricPasswordDialog(capabilities: caps, replacing: replacing),
    );
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await notifier.enable(
        email: widget.email,
        password: password,
        capabilities: caps,
        name: widget.name,
      );
      if (!mounted) return;
      if (result == BiometricResult.notEnrolled) {
        ref.invalidate(biometricCapabilitiesProvider);
      }
      final message = BiometricMessages.enable(result, caps);
      if (message == null) return;
      if (result == BiometricResult.success) {
        showSuccessSnack(context, message);
      } else {
        showErrorSnack(context, message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable(BiometricCapabilities caps) async {
    setState(() => _busy = true);
    try {
      await ref.read(biometricCredentialProvider.notifier).disable();
      if (mounted) {
        showInfoSnack(context, 'Se desactivó el ingreso con ${caps.label}.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = ref.watch(biometricCapabilitiesProvider).value;
    // Sin biometría (o todavía consultando): no se muestra.
    if (caps == null || !caps.supported) return const SizedBox.shrink();

    final credential = ref.watch(biometricCredentialProvider).value;
    final enabled = credential != null && credential.isFor(widget.email);
    final usable = caps.enrolled;

    final ValueChanged<bool>? onChanged;
    if (_busy) {
      onChanged = null;
    } else if (enabled) {
      // Apagar siempre se puede (aunque se haya borrado la huella).
      onChanged = (value) {
        if (!value) unawaited(_disable(caps));
      };
    } else if (usable) {
      onChanged = (value) {
        if (value) unawaited(_enable(caps));
      };
    } else {
      onChanged = null;
    }

    final String subtitle;
    if (!usable && !enabled) {
      subtitle = caps.setupHint;
    } else if (enabled) {
      subtitle = 'Entrás sin escribir tu contraseña en este teléfono.';
    } else {
      subtitle = 'Entrá sin escribir tu contraseña en este teléfono.';
    }

    return SwitchListTile(
      key: const Key('biometricLoginSwitch'),
      contentPadding: EdgeInsets.zero,
      secondary: AnimatedAppIcon(
        caps.appIcon,
        state: _busy
            ? AppIconState.loading
            : enabled
            ? AppIconState.active
            : AppIconState.idle,
        excludeFromSemantics: true,
      ),
      title: Text(caps.switchTitle),
      subtitle: Text(subtitle),
      value: enabled,
      onChanged: onChanged,
    );
  }
}
