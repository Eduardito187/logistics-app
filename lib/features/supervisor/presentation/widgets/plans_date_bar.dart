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
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Planes de ${formatDay(date)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          OutlinedButton.icon(
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
