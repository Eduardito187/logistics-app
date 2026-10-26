import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/supervisor_controllers.dart';
import '../supervisor_labels.dart';

/// Barra superior de la lista de planes: muestra el día y permite cambiarlo.
class PlansDateBar extends ConsumerWidget {
  const PlansDateBar({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      // Wrap: en tablet fecha y botón van en una fila; en un teléfono chico con
      // letra grande el botón baja a la línea siguiente en vez de desbordar.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            'Planes de ${formatDay(date)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          OutlinedButton.icon(
            // El tema pide ancho completo (Size.fromHeight); acá el botón va
            // junto al texto y se dimensiona a su contenido.
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56)),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Cambiar fecha'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2024),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                ref.read(plansDateProvider.notifier).select(picked);
              }
            },
          ),
        ],
      ),
    );
  }
}
