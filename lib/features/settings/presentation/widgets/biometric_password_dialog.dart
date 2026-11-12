import 'package:flutter/material.dart';

import '../../../../core/auth/biometric/biometric_capabilities.dart';
import '../../../../core/auth/biometric/biometric_credential.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/field_icon.dart';

/// Pide la contraseña actual para activar el ingreso con biometría desde el
/// perfil (se guarda cifrada en el teléfono). Devuelve la contraseña o `null`
/// si se canceló.
///
/// No se valida contra el backend acá (re-loguear rotaría el token): si está
/// mal, el próximo ingreso con biometría falla, se borra y se avisa.
class BiometricPasswordDialog extends StatefulWidget {
  const BiometricPasswordDialog({
    super.key,
    required this.capabilities,
    this.replacing,
  });

  final BiometricCapabilities capabilities;

  /// Credencial de OTRA cuenta que se reemplazaría (una sola por teléfono).
  final BiometricCredential? replacing;

  @override
  State<BiometricPasswordDialog> createState() =>
      _BiometricPasswordDialogState();
}

class _BiometricPasswordDialogState extends State<BiometricPasswordDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() => _error = 'Escribí tu contraseña.');
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.capabilities.label;
    final other = widget.replacing;
    return AlertDialog(
      title: Text('Activar $label'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Escribí tu contraseña actual. Se guarda de forma segura en este '
            'teléfono para ingresar sin escribirla.',
          ),
          if (other != null) ...[
            const SizedBox(height: 12),
            Text(
              'Solo una cuenta puede usar $label en este teléfono: se '
              'reemplazará la de ${other.displayName}.',
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            key: const Key('biometricPasswordField'),
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              errorText: _error,
              prefixIconConstraints: FieldIcon.prefixConstraints,
              prefixIcon: FieldIcon(icon: AppIcon.security, focusNode: _focus),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: AnimatedAppIcon(
                  _obscure ? AppIcon.visibility : AppIcon.visibilityOff,
                  state: _obscure ? AppIconState.idle : AppIconState.active,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _submit,
          child: const Text('Activar'),
        ),
      ],
    );
  }
}
