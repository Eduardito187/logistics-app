import 'package:flutter/material.dart';

import '../../../../core/auth/biometric/biometric_capabilities.dart';
import '../../../../core/auth/biometric/biometric_credential.dart';
import '../../../../core/icons/icons.dart';

/// Botón grande "Ingresar con Face ID / huella…" del login, con la cuenta
/// guardada debajo ("como Juan Pérez") y el separador hacia el formulario.
/// Solo se muestra si hay credencial guardada y el teléfono sigue pudiendo.
class BiometricSignInButton extends StatelessWidget {
  const BiometricSignInButton({
    super.key,
    required this.capabilities,
    required this.credential,
    required this.busy,
    required this.onPressed,
  });

  final BiometricCapabilities capabilities;
  final BiometricCredential credential;

  /// Esperando la biometría o el login: el ícono gira y el botón se apaga.
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('biometricSignInButton'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          onPressed: busy ? null : onPressed,
          icon: AnimatedAppIcon(
            capabilities.appIcon,
            state: busy ? AppIconState.loading : AppIconState.idle,
            excludeFromSemantics: true,
          ),
          label: Text(
            capabilities.switchTitle,
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'como ${credential.displayName}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 20),
        // El texto se limita al 70 % del ancho: en teléfonos chicos (320 dp)
        // o con letra grande del sistema baja a dos líneas en vez de
        // desbordar, y las líneas laterales siguen viéndose.
        LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              const Expanded(child: Divider()),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o con tu contraseña',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
