import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/carrier.dart';
import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/tariff.dart';
import '../../../../core/api/models/vehicle_class.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/usecases/get_tariff.dart';
import 'corridor_format.dart';
import 'tariff_result.dart';

/// Formulario de consulta de tarifa por corredor y clase de vehículo para el
/// transportista elegido (solo lectura).
class TariffForm extends ConsumerStatefulWidget {
  const TariffForm({super.key, required this.carrier});

  final Carrier carrier;

  @override
  ConsumerState<TariffForm> createState() => _TariffFormState();
}

class _TariffFormState extends ConsumerState<TariffForm> {
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  CorridorType _corridorType = CorridorType.cdToStore;
  VehicleClass _vehicleClass = VehicleClass.truck;
  AsyncValue<Tariff>? _result;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    final from = _from.text.trim();
    final to = _to.text.trim();
    if (from.isEmpty || to.isEmpty) return;

    setState(() => _result = const AsyncValue.loading());
    try {
      final tariff = await ref.read(getTariffProvider)(
        carrierId: widget.carrier.id,
        corridorFrom: from,
        corridorTo: to,
        corridorType: _corridorType,
        vehicleClass: _vehicleClass,
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
                TextField(
                  controller: _from,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Origen (código)',
                    hintText: 'Ej. LPB',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _to,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Destino (código)',
                    hintText: 'Ej. SCZ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CorridorType>(
                  value: _corridorType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de corredor',
                  ),
                  items: [
                    for (final type in CorridorType.$valuesDefined)
                      DropdownMenuItem(
                        value: type,
                        child: Text(corridorTypeLabel(type)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _corridorType = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VehicleClass>(
                  value: _vehicleClass,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Clase de vehículo',
                  ),
                  items: [
                    for (final vClass in VehicleClass.$valuesDefined)
                      DropdownMenuItem(
                        value: vClass,
                        child: Text(vehicleClassLabel(vClass)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _vehicleClass = value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _query,
                    icon: const Icon(Icons.search),
                    label: const Text('Consultar tarifa'),
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
              data: (tariff) => TariffResult(tariff: tariff),
            ),
        ],
      ),
    );
  }
}
