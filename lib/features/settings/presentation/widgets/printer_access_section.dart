import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/printing/printer_credentials.dart';
import '../../../../core/printing/printer_credentials_store.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/field_icon.dart';
import '../controllers/printer_save_result.dart';

/// "Acceso a la impresora" de la impresora WiFi activa (dentro de Opciones
/// avanzadas): tipo (Zebra u oficina), cómo se envía y las credenciales
/// completas que pide la impresora (como Windows al imprimir en una impresora
/// con usuario de dominio). La prueba se imprime desde la tarjeta.
///
/// El teléfono NO puede leer el usuario del WiFi corporativo ni del dominio
/// (Android 10+ e iOS no lo permiten): se ingresa acá y queda cifrado en el
/// almacén seguro, por impresora.
class PrinterAccessSection extends ConsumerStatefulWidget {
  const PrinterAccessSection({
    required this.printer,
    required this.onSaveConfig,
    this.defaultUser,
    this.detecting = false,
    this.detectionSummary,
    this.onDetect,
    super.key,
  });

  /// Impresora WiFi activa.
  final PrinterConfig printer;

  /// Guarda el perfil (tipo/protocolo) de la impresora activa.
  final Future<PrinterSaveResult> Function(PrinterConfig config) onSaveConfig;

  /// Usuario sugerido (parte local del email de la sesión).
  final String? defaultUser;

  /// Detección automática del tipo de impresora en curso / resultado.
  final bool detecting;
  final String? detectionSummary;
  final VoidCallback? onDetect;

  /// Texto de ayuda (fijo, lo pidió el dueño).
  static const String helpText =
      'Si tu impresora pide usuario de dominio (como en la PC), ingresalo '
      'acá. Por seguridad, el teléfono no puede leer el usuario del WiFi.';

  /// Aviso para el envío directo (puerto 9100, sin IPP).
  static const String rawHelpText =
      'En envío directo (puerto 9100) solo funciona el código de usuario '
      '(Ricoh). El usuario y la contraseña necesitan "Con confirmación" (IPP).';

  @override
  ConsumerState<PrinterAccessSection> createState() =>
      _PrinterAccessSectionState();
}

class _PrinterAccessSectionState extends ConsumerState<PrinterAccessSection> {
  final _user = TextEditingController();
  final _domain = TextEditingController();
  final _password = TextEditingController();
  final _userCode = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PrinterAccessSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.printer.address != widget.printer.address) {
      _loaded = false;
      _load();
    } else if (_loaded &&
        _user.text.isEmpty &&
        (widget.defaultUser ?? '').isNotEmpty) {
      _user.text = widget.defaultUser!;
    }
  }

  @override
  void dispose() {
    _user.dispose();
    _domain.dispose();
    _password.dispose();
    _userCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final address = widget.printer.address;
    final saved = await ref.read(printerCredentialsStoreProvider).read(address);
    if (!mounted || address != widget.printer.address) return;
    setState(() {
      _user.text = saved?.username ?? widget.defaultUser ?? '';
      _domain.text = saved?.domain ?? '';
      _password.text = saved?.password ?? '';
      _userCode.text = saved?.userCode ?? '';
      _loaded = true;
    });
  }

  PrinterCredentials? _credentials() {
    final user = _user.text.trim();
    if (user.isEmpty) return null;
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    return PrinterCredentials(
      username: user,
      domain: opt(_domain),
      // La contraseña no se recorta (puede tener espacios a propósito).
      password: _password.text.isEmpty ? null : _password.text,
      userCode: opt(_userCode),
    );
  }

  /// Guarda las credenciales y avisa el resultado.
  Future<void> _saveAccess() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(printerCredentialsStoreProvider)
          .write(widget.printer.address, _credentials());
      if (mounted) {
        showSuccessSnack(context, 'Acceso a la impresora guardado.');
      }
    } on Object {
      if (mounted) {
        showErrorSnack(
          context,
          'No se pudo guardar el acceso. Probá de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setLanguage(PrinterLanguage? language) {
    if (language == null || language == widget.printer.language) return;
    widget.onSaveConfig(
      widget.printer.copyWith(
        language: language,
        // Oficina: IPP por defecto (confirma y autentica). Zebra: 9100.
        protocol: language == PrinterLanguage.office
            ? PrinterProtocol.ipp
            : PrinterProtocol.raw9100,
      ),
    );
  }

  void _setProtocol(PrinterProtocol? protocol) {
    if (protocol == null || protocol == widget.printer.protocol) return;
    widget.onSaveConfig(widget.printer.copyWith(protocol: protocol));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final printer = widget.printer;
    final office = printer.isOffice;
    final summary = widget.detectionSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acceso a la impresora',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        if (widget.onDetect != null)
          OutlinedButton.icon(
            onPressed: widget.detecting ? null : widget.onDetect,
            icon: AnimatedAppIcon(
              AppIcon.search,
              state: widget.detecting
                  ? AppIconState.loading
                  : AppIconState.idle,
              excludeFromSemantics: true,
            ),
            label: Text(
              widget.detecting ? 'Detectando…' : 'Detectar tipo de impresora',
            ),
          ),
        if (summary != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(liveRegion: true, child: Text(summary)),
          ),
        const SizedBox(height: 8),
        Text('Tipo de impresora', style: theme.textTheme.labelLarge),
        Text(
          'Zebra = etiquetas. Oficina = láser o tinta (Ricoh, HP…).',
          style: theme.textTheme.bodySmall,
        ),
        for (final language in PrinterLanguage.values)
          RadioListTile<PrinterLanguage>(
            contentPadding: EdgeInsets.zero,
            value: language,
            groupValue: printer.language,
            onChanged: _setLanguage,
            title: Text(language.label),
          ),
        if (office) ...[
          Text('Cómo se envía', style: theme.textTheme.labelLarge),
          for (final (protocol, label) in const [
            (
              PrinterProtocol.ipp,
              'Con confirmación (IPP, recomendado): avisa si imprimió',
            ),
            (
              PrinterProtocol.raw9100,
              'Envío directo (puerto 9100): no confirma',
            ),
          ])
            RadioListTile<PrinterProtocol>(
              contentPadding: EdgeInsets.zero,
              value: protocol,
              groupValue: printer.protocol,
              onChanged: _setProtocol,
              title: Text(label),
            ),
          const SizedBox(height: 4),
          Text(PrinterAccessSection.helpText, style: theme.textTheme.bodySmall),
          if (printer.protocol == PrinterProtocol.raw9100)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                PrinterAccessSection.rawHelpText,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          TextField(
            controller: _domain,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Dominio (opcional)',
              hintText: 'Ej. DISMAC',
              prefixIconConstraints: FieldIcon.prefixConstraints,
              prefixIcon: FieldIcon(icon: AppIcon.lan),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Contraseña (opcional)',
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
          const SizedBox(height: 8),
          TextField(
            controller: _userCode,
            keyboardType: TextInputType.number,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Código de usuario (opcional, Ricoh)',
              prefixIconConstraints: FieldIcon.prefixConstraints,
              prefixIcon: FieldIcon(icon: AppIcon.badge),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: _saving || !_loaded ? null : _saveAccess,
            icon: AnimatedAppIcon(
              AppIcon.save,
              state: _saving ? AppIconState.loading : AppIconState.idle,
              excludeFromSemantics: true,
            ),
            label: const Text('Guardar acceso'),
          ),
        ],
      ],
    );
  }
}
