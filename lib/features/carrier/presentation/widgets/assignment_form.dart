import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/assignment.dart';
import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/usecases/assign_for_volume.dart';
import 'assignment_result.dart';
import 'corridor_format.dart';

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
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  final TextEditingController _volume = TextEditingController();
  CorridorType _corridorType = CorridorType.cdToStore;
  AsyncValue<Assignment>? _result;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _volume.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    final from = _from.text.trim();
    final to = _to.text.trim();
    final volume = double.tryParse(_volume.text.trim().replaceAll(',', '.'));
    if (from.isEmpty || to.isEmpty || volume == null || volume <= 0) return;

    setState(() => _result = const AsyncValue.loading());
    try {
      final assignment = await ref.read(assignForVolumeProvider)(
        corridorFrom: from,
        corridorTo: to,
        corridorType: _corridorType,
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
                    icon: const Icon(Icons.local_shipping),
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
