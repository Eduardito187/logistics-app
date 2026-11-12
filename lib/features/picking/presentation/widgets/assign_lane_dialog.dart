import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/field_icon.dart';
import '../../data/available_vehicles.dart';

/// Diálogo para asignar el vehículo de reparto de un pedido preparado.
///
/// Se ELIGE de la flota real (`/app/fleet/vehicles`), no se escribe a mano:
/// escribir cualquier placa rompía el flujo (el tracking iba a un camión
/// inexistente). Un buscador filtra por placa; tocar un camión lo asigna.
/// Devuelve el [Vehicle] elegido (o null si se cancela) por `Navigator.pop`:
/// hace falta su `id` para atar el pedido al vehículo en el backend, no solo
/// la placa.
///
/// Sin escaneo: los camiones de Dismac no tienen etiqueta de código.
class AssignLaneDialog extends ConsumerStatefulWidget {
  const AssignLaneDialog({super.key, this.initial});

  /// Placa ya asignada (se resalta en la lista).
  final String? initial;

  @override
  ConsumerState<AssignLaneDialog> createState() => _AssignLaneDialogState();
}

class _AssignLaneDialogState extends ConsumerState<AssignLaneDialog> {
  String _query = '';

  List<Vehicle> _filter(List<Vehicle> all) {
    final q = _query.trim().toUpperCase();
    if (q.isEmpty) return all;
    return all
        .where((v) => (v.plate ?? '').toUpperCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehiclesAsync = ref.watch(availableVehiclesProvider);
    return AlertDialog(
      title: const Text('Vehículo de reparto'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                labelText: 'Buscar placa',
                hintText: 'Ej. 904U10',
                prefixIconConstraints: FieldIcon.prefixConstraints,
                prefixIcon: FieldIcon(icon: AppIcon.search),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: vehiclesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _Error(
                  message: e is ApiException
                      ? e.message
                      : 'No se pudo cargar la flota.',
                  onRetry: () => ref.invalidate(availableVehiclesProvider),
                ),
                data: (all) {
                  final list = _filter(all);
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        all.isEmpty
                            ? 'No hay vehículos en la flota.'
                            : 'Ningún vehículo coincide con "$_query".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final v = list[i];
                      final plate = v.plate ?? '';
                      final selected = plate == widget.initial;
                      return ListTile(
                        leading: const AnimatedAppIcon(AppIcon.deliver),
                        title: Text(
                          plate,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(_subtitle(v)),
                        trailing: selected
                            ? const AnimatedAppIcon(
                                AppIcon.check,
                                state: AppIconState.success,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(v),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  /// Capacidad y estado del vehículo, legible.
  static String _subtitle(Vehicle v) {
    final parts = <String>[];
    if (v.capacityKg != null) parts.add('${v.capacityKg} kg');
    final status = (v.status ?? '').trim();
    if (status.isNotEmpty) parts.add(_statusLabel(status));
    return parts.join(' · ');
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'in_service':
        return 'En servicio';
      case 'maintenance':
        return 'En mantenimiento';
      case 'disabled':
        return 'Deshabilitado';
      default:
        return status;
    }
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const AnimatedAppIcon(AppIcon.syncing),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
