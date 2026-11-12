import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/assignment.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/models/carrier_corridor.dart';
import '../../domain/usecases/assign_for_volume.dart';
import '../controllers/carrier_controllers.dart';
import 'assignment_result.dart';
import 'corridor_picker.dart';

/// Formulario de asignación por volumen: corredor + volumen (m³) y el resultado
/// con la clase de vehículo sugerida.
class AssignmentForm extends ConsumerStatefulWidget {
  const AssignmentForm({super.key});

  @override
  ConsumerState<AssignmentForm> createState() => _AssignmentFormState();
}

/// Solo dígitos y separador decimal. Se crea una vez (no un RegExp por build).
final TextInputFormatter _volumeFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9.,]'),
);

class _AssignmentFormState extends ConsumerState<AssignmentForm> {
  final TextEditingController _volume = TextEditingController();
  CarrierCorridor? _corridor;
  AsyncValue<Assignment>? _result;

  @override
  void dispose() {
    _volume.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    final corridor = _corridor;
    final volume = double.tryParse(_volume.text.trim().replaceAll(',', '.'));
    if (corridor == null || volume == null || volume <= 0) return;

    setState(() => _result = const AsyncValue.loading());
    try {
      final assignment = await ref.read(assignForVolumeProvider)(
        corridorFrom: corridor.from,
        corridorTo: corridor.to,
        corridorType: corridor.type,
        volumeM3: volume,
      );
      if (!mounted) return;
      setState(() => _result = AsyncValue.data(assignment));
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
            title: 'Corredor y volumen',
            child: Column(
              children: [
                CorridorPicker(
                  carrierId: ref.watch(selectedCarrierProvider)?.id,
                  onChanged: (corridor) => setState(() => _corridor = corridor),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _volume,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_volumeFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Volumen (m³)',
                    hintText: 'Ej. 12.5',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _query,
                    // En acción: loop mientras se consulta.
                    icon: AnimatedAppIcon(
                      AppIcon.deliver,
                      state: _result is AsyncLoading
                          ? AppIconState.loading
                          : AppIconState.idle,
                    ),
                    label: const Text('Calcular asignación'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_result != null)
            AsyncValueView<Assignment>(
              value: _result!,
              onRetry: _query,
              data: (assignment) => AssignmentResult(assignment: assignment),
            ),
        ],
      ),
    );
  }
}
