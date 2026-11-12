import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/icons/icons.dart';
import '../../domain/models/carrier_corridor.dart';
import '../controllers/carrier_controllers.dart';
import 'corridor_format.dart';

/// Selector de corredor: UN solo control que resuelve origen, destino y tipo.
///
/// Lista los corredores REALES del transportista (derivados de sus
/// liquidaciones) con nombres legibles; al elegir uno queda definido el par
/// origen→destino y su tipo, así que no hay códigos que tipear ni 404 por un
/// typo. Si el transportista todavía no tiene liquidaciones (o no se pudieron
/// traer), degrada a una entrada manual explicando por qué.
class CorridorPicker extends ConsumerStatefulWidget {
  const CorridorPicker({
    super.key,
    required this.carrierId,
    required this.onChanged,
  });

  /// Transportista dueño de los corredores. `null` = todavía no se eligió uno
  /// (la pantalla cae en la entrada manual).
  final String? carrierId;

  /// Corredor elegido, o `null` mientras esté incompleto.
  final ValueChanged<CarrierCorridor?> onChanged;

  @override
  ConsumerState<CorridorPicker> createState() => _CorridorPickerState();
}

class _CorridorPickerState extends ConsumerState<CorridorPicker> {
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  CorridorType _manualType = CorridorType.cdToStore;
  CarrierCorridor? _picked;

  @override
  void initState() {
    super.initState();
    _from.addListener(_emitManual);
    _to.addListener(_emitManual);
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  /// La entrada manual avisa en cada tecla: el botón del formulario queda
  /// habilitado/deshabilitado sin esperar a que el campo pierda el foco.
  void _emitManual() {
    final from = _from.text.trim().toLowerCase();
    final to = _to.text.trim().toLowerCase();
    widget.onChanged(
      from.isEmpty || to.isEmpty
          ? null
          : CarrierCorridor(from: from, to: to, type: _manualType),
    );
  }

  void _pick(CarrierCorridor? corridor) {
    setState(() => _picked = corridor);
    widget.onChanged(corridor);
  }

  @override
  Widget build(BuildContext context) {
    final carrierId = widget.carrierId;
    if (carrierId == null) {
      return _manualEntry(
        'Elegí tu transportista para ver tus corredores, o escribí el origen y '
        'el destino a mano.',
      );
    }

    final corridors = ref.watch(carrierCorridorsProvider(carrierId));
    return corridors.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: _loading,
      // Sin corredores no se bloquea la pantalla: se puede escribir el corredor.
      error: (_, _) => _manualEntry(
        'No pudimos traer tus corredores ahora. Escribí el origen y el destino '
        'tal como figuran en tu contrato.',
      ),
      data: (list) => list.isEmpty
          ? _manualEntry(
              'Todavía no tenemos corredores tuyos (aparecen con tu primera '
              'liquidación). Escribí el origen y el destino tal como figuran '
              'en tu contrato.',
            )
          : _dropdown(list),
    );
  }

  Widget _loading() => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Buscando tus corredores…'),
      SizedBox(height: 8),
      LinearProgressIndicator(minHeight: 6),
    ],
  );

  Widget _dropdown(List<CarrierCorridor> corridors) {
    // Si la lista cambió y el elegido ya no está, se descarta (el dropdown
    // exige que su valor sea uno de sus ítems).
    final picked = corridors.contains(_picked) ? _picked : null;

    // Con un solo corredor no se le pide elegir: ya queda puesto.
    if (picked == null && corridors.length == 1) {
      final only = corridors.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pick(only);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CarrierCorridor>(
          value: picked,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Corredor',
            helperText: 'Tus rutas, según tus liquidaciones',
          ),
          hint: const Text('Elegí tu corredor'),
          items: [
            for (final corridor in corridors)
              DropdownMenuItem<CarrierCorridor>(
                value: corridor,
                child: Text(
                  corridorPairLabel(corridor.from, corridor.to),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _pick,
        ),
        if (picked != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const AnimatedAppIcon(
                AppIcon.route,
                size: 20,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Tipo: ${corridorTypeLabel(picked.type)}')),
            ],
          ),
        ],
      ],
    );
  }

  /// Último recurso: se escribe el corredor. [reason] explica en una línea por
  /// qué no hay lista (sin tecnicismos).
  Widget _manualEntry(String reason) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          reason,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _from,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Origen',
            hintText: 'cd-santa-cruz',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _to,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Destino',
            hintText: 'store-scz-centro',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CorridorType>(
          value: _manualType,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo de corredor'),
          items: [
            for (final type in CorridorType.$valuesDefined)
              DropdownMenuItem<CorridorType>(
                value: type,
                child: Text(corridorTypeLabel(type)),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _manualType = value);
            _emitManual();
          },
        ),
      ],
    );
  }
}
