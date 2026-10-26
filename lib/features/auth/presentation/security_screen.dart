import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../domain/entities/two_factor_enrollment.dart';
import 'controllers/security_controller.dart';
import 'controllers/two_factor_status.dart';

/// Pantalla de Seguridad (Ajustes): activar o desactivar la verificación en dos
/// pasos. Lee el flag [twoFactorEnabledProvider] para decidir qué mostrar y usa
/// [securityControllerProvider] para enrolar, confirmar y desactivar.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _confirmCodeController = TextEditingController();

  /// Datos del enrolamiento en curso (QR, secreto, recovery codes). Null cuando
  /// no hay activación en progreso.
  TwoFactorEnrollment? _enrollment;

  @override
  void dispose() {
    _confirmCodeController.dispose();
    super.dispose();
  }

  Future<void> _onEnrollPressed() async {
    final enrollment = await ref
        .read(securityControllerProvider.notifier)
        .enroll();
    if (!mounted) return;
    if (enrollment != null) {
      setState(() => _enrollment = enrollment);
    } else {
      final error = ref.read(securityControllerProvider).error;
      showErrorSnack(context, error ?? 'No se pudo iniciar la activación.');
    }
  }

  Future<void> _onConfirmPressed() async {
    final code = _confirmCodeController.text.trim();
    if (code.isEmpty) {
      showInfoSnack(context, 'Ingresá el código del autenticador.');
      return;
    }
    final ok = await ref
        .read(securityControllerProvider.notifier)
        .confirm(code);
    if (!mounted) return;
    if (ok) {
      showSuccessSnack(context, 'Verificación en dos pasos activada.');
      _confirmCodeController.clear();
      // La UI pasa a estado ACTIVO porque twoFactorEnabled ya es true.
      setState(() => _enrollment = null);
    } else {
      final error = ref.read(securityControllerProvider).error;
      showErrorSnack(context, error ?? 'No se pudo activar la verificación.');
    }
  }

  Future<void> _onDisablePressed() async {
    final disabled = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DisableTwoFactorSheet(),
    );
    if (!mounted || disabled != true) return;
    showSuccessSnack(context, 'Verificación en dos pasos desactivada.');
  }

  @override
  Widget build(BuildContext context) {
    final enabledValue = ref.watch(twoFactorEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: SafeArea(
        child: AsyncValueView<bool>(
          value: enabledValue,
          onRetry: () => ref.invalidate(twoFactorEnabledProvider),
          // Centrado y con ancho máximo: en tablet no se estira de borde a
          // borde (el QR, el secreto y los recovery codes quedan legibles).
          data: (enabled) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [if (enabled) _buildActive() else _buildInactive()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActive() {
    final isLoading = ref.watch(securityControllerProvider).isLoading;
    return SectionCard(
      title: 'Verificación en dos pasos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusPill(
            'Activada',
            tone: PillTone.success,
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            'Cada vez que ingresás pedimos un código de tu teléfono además de '
            'tu contraseña.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: isLoading ? null : _onDisablePressed,
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInactive() {
    final enrollment = _enrollment;
    if (enrollment == null) {
      return _buildEnrollInvite();
    }
    return _buildEnrollSteps(enrollment);
  }

  Widget _buildEnrollInvite() {
    final isLoading = ref.watch(securityControllerProvider).isLoading;
    return SectionCard(
      title: 'Verificación en dos pasos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'La verificación en dos pasos agrega un código de tu teléfono al '
            'ingresar.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isLoading ? null : _onEnrollPressed,
            child: isLoading
                ? const _ButtonSpinner()
                : const Text('Activar verificación en dos pasos'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollSteps(TwoFactorEnrollment enrollment) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(securityControllerProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Escaneá el código',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escaneá este código QR con tu app de autenticación (por ej. '
                'Google Authenticator).',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Contenedor blanco con padding para que el QR se lea también en
              // tema Noche.
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: enrollment.otpauthUri,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¿No podés escanear? Ingresá esta clave a mano en tu app '
                '("Ingresar una clave de configuración"):',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      enrollment.secret,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar clave',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () => _copy(enrollment.secret, 'Clave copiada.'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Códigos de recuperación',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guardá estos códigos de recuperación. Se muestran una '
                      'sola vez.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final code in enrollment.recoveryCodes)
                    SizedBox(
                      width: 120,
                      child: Text(
                        code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _copy(
                  enrollment.recoveryCodes.join('\n'),
                  'Códigos copiados.',
                ),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar códigos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Confirmá y activá',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _confirmCodeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _onConfirmPressed(),
                decoration: const InputDecoration(
                  labelText: 'Código del autenticador',
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : _onConfirmPressed,
                child: isLoading
                    ? const _ButtonSpinner()
                    : const Text('Confirmar y activar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copy(String text, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showInfoSnack(context, confirmation);
  }
}

/// Hoja inferior para desactivar el 2FA: pide un código del autenticador O la
/// contraseña (un toggle alterna entre ambos). Devuelve `true` por Navigator al
/// desactivar con éxito; en error muestra el aviso y se queda abierta.
class _DisableTwoFactorSheet extends ConsumerStatefulWidget {
  const _DisableTwoFactorSheet();

  @override
  ConsumerState<_DisableTwoFactorSheet> createState() =>
      _DisableTwoFactorSheetState();
}

class _DisableTwoFactorSheetState
    extends ConsumerState<_DisableTwoFactorSheet> {
  final _controller = TextEditingController();

  /// true = pedir código del autenticador; false = pedir contraseña.
  bool _useCode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      showInfoSnack(
        context,
        _useCode
            ? 'Ingresá el código del autenticador.'
            : 'Ingresá tu contraseña.',
      );
      return;
    }
    final notifier = ref.read(securityControllerProvider.notifier);
    final ok = _useCode
        ? await notifier.disableWithCode(value)
        : await notifier.disableWithPassword(value);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(securityControllerProvider).error;
      showErrorSnack(context, error ?? 'No se pudo desactivar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(securityControllerProvider).isLoading;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Desactivar verificación en dos pasos',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _useCode
                ? 'Ingresá un código de tu app de autenticación para confirmar.'
                : 'Ingresá tu contraseña para confirmar.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            obscureText: !_useCode && _obscurePassword,
            keyboardType: _useCode ? TextInputType.number : TextInputType.text,
            autocorrect: false,
            maxLength: _useCode ? 6 : null,
            inputFormatters: _useCode
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              labelText: _useCode ? 'Código del autenticador' : 'Contraseña',
              counterText: '',
              prefixIcon: Icon(
                _useCode ? Icons.pin_outlined : Icons.lock_outline,
              ),
              suffixIcon: _useCode
                  ? null
                  : IconButton(
                      tooltip: _obscurePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isLoading ? null : _onConfirm,
            child: isLoading
                ? const _ButtonSpinner()
                : const Text('Desactivar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading
                ? null
                : () => setState(() {
                    _useCode = !_useCode;
                    _controller.clear();
                  }),
            child: Text(
              _useCode ? 'Usar mi contraseña' : 'Usar código del autenticador',
            ),
          ),
        ],
      ),
    );
  }
}

/// Spinner blanco reutilizado dentro de los botones de acción.
class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
    );
  }
}
