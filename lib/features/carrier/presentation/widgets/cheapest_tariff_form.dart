import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/tariff.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/models/carrier_corridor.dart';
import '../../domain/usecases/cheapest_tariff.dart';
import '../controllers/carrier_controllers.dart';
import 'cheapest_tariff_result.dart';
import 'corridor_picker.dart';

/// Formulario de búsqueda de la tarifa más barata para un corredor y tipo,
/// entre todos los transportistas.
class CheapestTariffForm extends ConsumerStatefulWidget {
  const CheapestTariffForm({super.key});

  @override
  ConsumerState<CheapestTariffForm> createState() => _CheapestTariffFormState();
}

class _CheapestTariffFormState extends ConsumerState<CheapestTariffForm> {
  CarrierCorridor? _corridor;
  AsyncValue<Tariff>? _result;

  Future<void> _query() async {
    final corridor = _corridor;
    if (corridor == null) return;

    setState(() => _result = const AsyncValue.loading());
    try {
      final tariff = await ref.read(cheapestTariffProvider)(
        corridorFrom: corridor.from,
        corridorTo: corridor.to,
        corridorType: corridor.type,
      );
      if (!mounted) return;
      setState(() => _result = AsyncValue.data(tariff));
    } on ApiException catch (e, st) {
      if (!mounted) return;
      setState(() => _result = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    // En tablets el formulario no se estira de borde a borde.
    return ResponsiveBody(
      maxWidth: AppBreakpoints.maxFormWidth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Corredor',
            child: Column(
              children: [
                CorridorPicker(
                  // El corredor sale de las liquidaciones del transportista
                  // elegido en la sesión; la tarifa sí se busca entre todos.
                  carrierId: ref.watch(selectedCarrierProvider)?.id,
                  onChanged: (corridor) => setState(() => _corridor = corridor),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _query,
                    // En acción: loop mientras se consulta.
                    icon: AnimatedAppIcon(
                      AppIcon.savings,
                      state: _result is AsyncLoading
                          ? AppIconState.loading
                          : AppIconState.idle,
                    ),
                    label: const Text('Buscar más barata'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_result != null)
            AsyncValueView<Tariff>(
              value: _result!,
              onRetry: _query,
              data: (tariff) => CheapestTariffResult(tariff: tariff),
            ),
        ],
      ),
    );
  }
}
