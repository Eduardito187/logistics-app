import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/ipv4_subnet.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/printing/printer_reachability.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/field_icon.dart';
import '../controllers/printer_save_result.dart';
import 'wifi_test_message.dart';

/// Formulario para una impresora WiFi ingresada a mano: IP y puerto (default
/// 9100). Alternativa a la búsqueda automática (`WifiPrinterSearch`) cuando la
/// impresora está en otra subred o el operario ya conoce la IP.
class WifiPrinterForm extends StatefulWidget {
  const WifiPrinterForm({
    required this.initial,
    required this.onSave,
    this.onTest,
    this.phoneNetworks,
    super.key,
  });

  final PrinterConfig? initial;

  /// Guarda la impresora; el resultado define el ícono final del botón (el
  /// aviso lo da quien guarda).
  final Future<PrinterSaveResult> Function(PrinterConfig config) onSave;

  /// "Probar conexión" a `host:port` con diagnóstico. Sin él no se muestra el
  /// botón.
  final Future<PrinterReachability> Function(String host, int port)? onTest;

  /// Redes del teléfono, para avisar si la IP es de otra red. Opcional.
  final Future<List<Ipv4Subnet>> Function()? phoneNetworks;

  /// Cuánto queda el ícono de resultado del guardado antes de volver a reposo.
  static const Duration saveFeedback = Duration(seconds: 2);

  /// IPv4 válida (cuatro octetos 0–255).
  static bool isValidIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      if (p.isEmpty || p.length > 3) return false;
      final v = int.tryParse(p);
      if (v == null || v < 0 || v > 255) return false;
    }
    return true;
  }

  @override
  State<WifiPrinterForm> createState() => _WifiPrinterFormState();
}

class _WifiPrinterFormState extends State<WifiPrinterForm> {
  late final TextEditingController _ip;
  late final TextEditingController _port;
  bool _testing = false;
  PrinterReachability? _lastTest;
  String? _testMessage;
  bool _saving = false;
  AppIconState _saveIcon = AppIconState.idle;
  Timer? _saveIconReset;

  @override
  void initState() {
    super.initState();
    final current = widget.initial?.transport == PrinterTransport.wifi
        ? widget.initial
        : null;
    _ip = TextEditingController(text: current?.wifiHost ?? '');
    _port = TextEditingController(
      text: '${current?.wifiPort ?? kDefaultWifiPort}',
    );
  }

  @override
  void dispose() {
    _saveIconReset?.cancel();
    _ip.dispose();
    _port.dispose();
    super.dispose();
  }

  /// `(host, port)` válidos, o `null` tras avisar qué falta.
  (String, int)? _target() {
    final host = _ip.text.trim();
    if (host.isEmpty) {
      showInfoSnack(context, 'Ingresá la IP de la impresora.');
      return null;
    }
    // Solo dígitos y puntos = se pretende una IP: validarla. Otro texto se
    // acepta como nombre de host de la red.
    if (RegExp(r'^[\d.]+$').hasMatch(host) &&
        !WifiPrinterForm.isValidIpv4(host)) {
      showInfoSnack(context, 'IP inválida. Ej. 192.168.1.50');
      return null;
    }
    final port = int.tryParse(_port.text.trim());
    final validPort = port != null && port > 0 && port <= 65535
        ? port
        : kDefaultWifiPort;
    return (host, validPort);
  }

  Future<void> _save() async {
    if (_saving) return;
    final target = _target();
    if (target == null) return;
    final (host, port) = target;
    _saveIconReset?.cancel();
    setState(() {
      _saving = true;
      _saveIcon = AppIconState.loading;
    });
    PrinterSaveResult result;
    try {
      result = await widget.onSave(
        PrinterConfig(
          transport: PrinterTransport.wifi,
          address: '$host:$port',
          label: 'WiFi $host',
        ),
      );
    } on Object {
      result = PrinterSaveResult.failed;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveIcon = result == PrinterSaveResult.failed
          ? AppIconState.error
          : AppIconState.success;
    });
    // Resultado breve y vuelta a reposo.
    _saveIconReset = Timer(WifiPrinterForm.saveFeedback, () {
      if (mounted) setState(() => _saveIcon = AppIconState.idle);
    });
  }

  Future<void> _test() async {
    final onTest = widget.onTest;
    final target = _target();
    if (onTest == null || target == null) return;
    final (host, port) = target;
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    PrinterReachability result;
    try {
      result = await onTest(host, port);
    } on Object {
      result = PrinterReachability.timeout;
    }
    var networks = const <Ipv4Subnet>[];
    final readNetworks = widget.phoneNetworks;
    if (readNetworks != null) {
      try {
        networks = await readNetworks();
      } on Object {
        // Sin redes: se muestra el diagnóstico sin la nota de "otra red".
      }
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _lastTest = result;
      _testMessage = wifiTestMessage(
        host: host,
        port: port,
        reachability: result,
        phoneNetworks: networks,
      );
    });
  }

  void _clearTest() {
    if (_lastTest != null || _testMessage != null) {
      setState(() {
        _lastTest = null;
        _testMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final testMessage = _testMessage;
    final ok = _lastTest == PrinterReachability.reachable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ip,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _clearTest(),
          decoration: const InputDecoration(
            labelText: 'IP de la impresora',
            hintText: 'Ej. 192.168.1.50',
            prefixIconConstraints: FieldIcon.prefixConstraints,
            prefixIcon: FieldIcon(icon: AppIcon.lan),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _port,
          keyboardType: TextInputType.number,
          onChanged: (_) => _clearTest(),
          decoration: const InputDecoration(
            labelText: 'Puerto',
            hintText: '9100',
            prefixIconConstraints: FieldIcon.prefixConstraints,
            prefixIcon: FieldIcon(icon: AppIcon.lan),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.onTest != null) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: _testing ? null : _test,
            icon: AnimatedAppIcon(
              AppIcon.wifi,
              state: _testing
                  ? AppIconState.loading
                  : switch (_lastTest) {
                      null => AppIconState.idle,
                      PrinterReachability.reachable => AppIconState.success,
                      _ => AppIconState.error,
                    },
              excludeFromSemantics: true,
            ),
            label: Text(_testing ? 'Probando…' : 'Probar conexión'),
          ),
          if (testMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  testMessage,
                  style: TextStyle(
                    color: ok ? null : scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: _saving ? null : _save,
          icon: AnimatedAppIcon(
            AppIcon.save,
            state: _saveIcon,
            excludeFromSemantics: true,
          ),
          label: Text(_saving ? 'Guardando…' : 'Guardar impresora WiFi'),
        ),
      ],
    );
  }
}
