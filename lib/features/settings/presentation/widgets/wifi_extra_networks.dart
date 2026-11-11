import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/extra_networks_notifier.dart';

/// "Buscar también en otra red": el usuario agrega redes además de la del
/// teléfono (p. ej. la red de cable donde está la impresora). Se guardan en
/// el dispositivo y la búsqueda las barre junto con la del WiFi.
class WifiExtraNetworks extends ConsumerStatefulWidget {
  const WifiExtraNetworks({super.key});

  @override
  ConsumerState<WifiExtraNetworks> createState() => _WifiExtraNetworksState();
}

class _WifiExtraNetworksState extends ConsumerState<WifiExtraNetworks> {
  final TextEditingController _input = TextEditingController();
  String? _error;
  bool _adding = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    final error = await ref
        .read(extraNetworksProvider.notifier)
        .add(_input.text);
    if (!mounted) return;
    setState(() {
      _adding = false;
      _error = error;
      if (error == null) _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final networks = ref.watch(extraNetworksProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Buscar también en otra red', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Si la impresora está en otra red (ej. la de cable), agregá su red: '
          'los primeros 3 números de su IP.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                // `url`: teclado con números, punto y barra (para /22).
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: 'Red',
                  hintText: 'Ej. 192.168.2',
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _adding ? null : _add,
                icon: AnimatedAppIcon(
                  AppIcon.add,
                  state: _adding ? AppIconState.loading : AppIconState.idle,
                  excludeFromSemantics: true,
                ),
                label: const Text('Agregar'),
              ),
            ),
          ],
        ),
        if (networks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final network in networks)
                InputChip(
                  label: Text(network.label),
                  deleteIcon: const AnimatedAppIcon(
                    AppIcon.close,
                    size: 18,
                    excludeFromSemantics: true,
                  ),
                  deleteButtonTooltipMessage: 'Quitar ${network.label}',
                  onDeleted: () => ref
                      .read(extraNetworksProvider.notifier)
                      .remove(network),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
