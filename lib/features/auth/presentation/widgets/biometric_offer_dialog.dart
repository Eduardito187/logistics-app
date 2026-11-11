import 'package:flutter/material.dart';

import '../../../../core/auth/biometric/biometric_capabilities.dart';
import '../../../../core/auth/biometric/biometric_credential.dart';
import '../../../../core/icons/icons.dart';

/// Oferta post-login: "¿Querés ingresar con Face ID la próxima vez?".
/// Devuelve `true` (Sí) o `false` (Ahora no); tocar afuera cuenta como
/// "Ahora no".
class BiometricOfferDialog extends StatelessWidget {
  const BiometricOfferDialog({
    super.key,
    required this.capabilities,
    this.replacing,
  });

  final BiometricCapabilities capabilities;

  /// Credencial de OTRA cuenta que se reemplazaría (una sola por teléfono).
  final BiometricCredential? replacing;

  @override
  Widget build(BuildContext context) {
    final label = capabilities.label;
    final other = replacing;
    return AlertDialog(
      icon: AnimatedAppIcon(
        capabilities.appIcon,
        state: AppIconState.active,
        size: 40,
      ),
      title: Text('¿Querés ingresar con $label la próxima vez?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Entrás sin escribir tu contraseña.'),
          if (other != null) ...[
            const SizedBox(height: 12),
            Text(
              'Solo una cuenta puede usar $label en este teléfono: se '
              'reemplazará la de ${other.displayName}.',
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sí, activar'),
        ),
      ],
    );
  }
}
