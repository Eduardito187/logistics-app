import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/printing/wifi_printer_hit.dart';
import '../../../../core/printing/wifi_scan_progress.dart';
import '../controllers/wifi_printer_discovery.dart';
import 'non_zebra_printer_dialog.dart';
import 'wifi_printer_hit_tile.dart';

/// Búsqueda automática de impresoras en la red WiFi (como "agregar impresora"
/// de Windows): barra de avance y la lista que se llena en vivo con tarjetas
/// grandes. Tocar una la elige (si no es Zebra, se pide confirmación).
///
/// La arranca quien la muestra (el paso WiFi del asistente la inicia solo al
/// entrar); al salir, el provider autoDispose cancela el barrido.
class WifiPrinterSearch extends ConsumerWidget {
  const WifiPrinterSearch({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final PrinterConfig? selected;
  final Future<void> Function(PrinterConfig config) onSelect;

  Future<void> _choose(BuildContext context, WifiPrinterHit hit) async {
    if (hit.isKnownNonZebra) {
      final ok = await NonZebraPrinterDialog.confirm(context, hit.displayName);
      if (!ok) return;
    }
    await onSelect(hit.toConfig());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(wifiPrinterDiscoveryProvider);
    final discovery = ref.read(wifiPrinterDiscoveryProvider.notifier);
    final selectedAddress = selected?.transport == PrinterTransport.wifi
        ? selected?.address
        : null;
    final partial = progress?.networks.where((n) => n.isPartial) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progress == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Busca las impresoras conectadas al mismo WiFi que este '
              'teléfono.',
            ),
          ),
        if (progress != null && progress.isRunning) ...[
          LinearProgressIndicator(value: progress.fraction),
          const SizedBox(height: 6),
          Text(runningText(progress)),
          if (progress.discoveringServices)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(searchingAnnouncedText),
            ),
          const SizedBox(height: 8),
        ],
        for (final n in partial)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'La red del teléfono (${n.fullLabel}) es muy grande: se busca '
              'en ${n.label}, la parte de este teléfono. Si la impresora está '
              'en otra parte, ingresá su IP o buscá en su red.',
            ),
          ),
        if (progress?.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              progress!.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (progress != null &&
            progress.done &&
            progress.error == null &&
            progress.found.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(notFoundText(progress)),
          ),
        if (progress != null)
          for (final hit in progress.found)
            WifiPrinterHitTile(
              hit: hit,
              selected: hit.address == selectedAddress,
              onTap: () => _choose(context, hit),
            ),
        const SizedBox(height: 8),
        if (progress != null && progress.isRunning)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: discovery.stop,
            icon: const AnimatedAppIcon(
              AppIcon.close,
              excludeFromSemantics: true,
            ),
            label: const Text('Detener búsqueda'),
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: discovery.start,
            icon: const AnimatedAppIcon(
              AppIcon.search,
              excludeFromSemantics: true,
            ),
            label: Text(
              progress == null ? 'Buscar impresoras' : 'Buscar de nuevo',
            ),
          ),
      ],
    );
  }

  /// Línea extra mientras también se consulta a las impresoras que se
  /// anuncian solas (Bonjour / WS-Discovery), sin nombrar los protocolos.
  static const String searchingAnnouncedText =
      'También buscando impresoras que se anuncian solas…';

  /// Texto del avance: porcentaje y lo encontrado (sin jerga de redes).
  static String runningText(WifiScanProgress p) {
    if (p.total == 0) return 'Detectando la red WiFi…';
    final found = p.found.length;
    final suffix = found == 0
        ? ''
        : ' · $found ${found == 1 ? 'encontrada' : 'encontradas'}';
    final percent = (p.scanned * 100 / p.total).clamp(0, 100).round();
    return 'Buscando impresoras… $percent%$suffix';
  }

  /// Sin resultados: qué se buscó y qué hacer.
  static String notFoundText(WifiScanProgress p) {
    final labels = p.networkLabels;
    final where = labels.length == 1
        ? 'en la red ${labels.single}'
        : 'en las redes ${labels.join(', ')}';
    return 'No se encontraron impresoras $where. Revisá que esté encendida '
        'y conectada al mismo WiFi. Si sabés su IP, tocá "¿No aparece? '
        'Ingresar IP".';
  }
}
