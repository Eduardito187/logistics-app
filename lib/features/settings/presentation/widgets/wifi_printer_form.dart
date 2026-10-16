import 'package:flutter/material.dart';

import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/app_snack.dart';

/// Formulario para una impresora WiFi: IP y puerto (default 9100) ingresados a
/// mano, ya que no hay descubrimiento de red.
class WifiPrinterForm extends StatefulWidget {
  const WifiPrinterForm({
    required this.initial,
    required this.onSave,
    super.key,
  });

  final PrinterConfig? initial;
  final Future<void> Function(PrinterConfig config) onSave;

  @override
  State<WifiPrinterForm> createState() => _WifiPrinterFormState();
}

class _WifiPrinterFormState extends State<WifiPrinterForm> {
  late final TextEditingController _ip;
  late final TextEditingController _port;

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
    _ip.dispose();
    _port.dispose();
    super.dispose();
  }

  void _save() {
    final host = _ip.text.trim();
    if (host.isEmpty) {
      showInfoSnack(context, 'Ingresá la IP de la impresora.');
      return;
    }
    final port = int.tryParse(_port.text.trim()) ?? kDefaultWifiPort;
    widget.onSave(
      PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '$host:$port',
        label: 'WiFi $host',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ip,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'IP de la impresora',
            hintText: 'Ej. 192.168.1.50',
            prefixIcon: Icon(Icons.lan),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _port,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Puerto',
            hintText: '9100',
            prefixIcon: Icon(Icons.settings_ethernet),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Guardar impresora WiFi'),
        ),
      ],
    );
  }
}
