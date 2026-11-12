import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_credentials.dart';
import '../../../../core/printing/printer_credentials_store.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/field_icon.dart';

/// "Esta impresora pide tu usuario": SOLO usuario (prellenado) y contraseña,
/// y "Guardar y probar". Aparece en el paso Listo cuando la detección dice
/// que la impresora de oficina pide credenciales. Dominio y código de
/// usuario quedan en Opciones avanzadas (se conservan si ya estaban).
class PrinterCredentialsPrompt extends ConsumerStatefulWidget {
  const PrinterCredentialsPrompt({
    required this.address,
    required this.onSaved,
    this.defaultUser,
    this.busy = false,
    super.key,
  });

  /// `ip:puerto` de la impresora (clave de sus credenciales).
  final String address;

  /// Después de guardar: imprime la prueba.
  final Future<void> Function() onSaved;

  final String? defaultUser;

  /// Imprimiendo: el botón queda deshabilitado.
  final bool busy;

  @override
  ConsumerState<PrinterCredentialsPrompt> createState() =>
      _PrinterCredentialsPromptState();
}

class _PrinterCredentialsPromptState
    extends ConsumerState<PrinterCredentialsPrompt> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  PrinterCredentials? _stored;
  bool _obscure = true;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await ref
        .read(printerCredentialsStoreProvider)
        .read(widget.address);
    if (!mounted) return;
    setState(() {
      _stored = saved;
      _user.text = saved?.username ?? widget.defaultUser ?? '';
      _password.text = saved?.password ?? '';
      _loaded = true;
    });
  }

  Future<void> _saveAndTest() async {
    final user = _user.text.trim();
    if (user.isEmpty) {
      showInfoSnack(context, 'Ingresá tu usuario.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(printerCredentialsStoreProvider)
          .write(
            widget.address,
            PrinterCredentials(
              username: user,
              // La contraseña no se recorta (puede tener espacios a propósito).
              password: _password.text.isEmpty ? null : _password.text,
              domain: _stored?.domain,
              userCode: _stored?.userCode,
            ),
          );
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnack(
          context,
          'No se pudo guardar el acceso. Probá de nuevo.',
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = widget.busy || _saving || !_loaded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Esta impresora pide tu usuario',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'El mismo con el que imprimís desde la PC.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _user,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Usuario',
            hintText: 'Ej. jperez',
            prefixIconConstraints: FieldIcon.prefixConstraints,
            prefixIcon: FieldIcon(icon: AppIcon.profile),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => busy ? null : _saveAndTest(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIconConstraints: FieldIcon.prefixConstraints,
            prefixIcon: const FieldIcon(icon: AppIcon.security),
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
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: busy ? null : _saveAndTest,
          icon: AnimatedAppIcon(
            AppIcon.save,
            state: _saving || widget.busy
                ? AppIconState.loading
                : AppIconState.idle,
            excludeFromSemantics: true,
          ),
          label: const Text('Guardar y probar'),
        ),
      ],
    );
  }
}
