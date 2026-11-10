import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/driver_controllers.dart';

/// Indicadores de utilización del vehículo en los últimos 30 días. El backend
/// devuelve un objeto libre; acá se muestran SOLO las métricas útiles, con
/// etiquetas en español y valores formateados (nada de uuid ni fechas crudas).
class UtilizationCard extends ConsumerWidget {
  const UtilizationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilization = ref.watch(vehicleUtilizationProvider);
    return SectionCard(
      title: 'Utilización (últimos 30 días)',
      child: AsyncValueView<Map<String, Object?>>(
        value: utilization,
        onRetry: () => ref.invalidate(vehicleUtilizationProvider),
        data: (data) {
          final rows = _metrics(data);
          if (rows.isEmpty) {
            return const Text('Sin datos de utilización disponibles.');
          }
          return Column(
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(row.label)),
                      const SizedBox(width: 12),
                      Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Arma las filas mostrables desde el objeto del backend. Oculta los campos
  /// técnicos (uuid del vehículo, rango de fechas) y formatea números/fechas.
  List<({String label, String value})> _metrics(Map<String, Object?> data) {
    final n = NumberFormat.decimalPattern('es');
    int? asInt(String key) {
      final v = data[key];
      return v is num ? v.toInt() : null;
    }

    final rows = <({String label, String value})>[];
    void addInt(String key, String label, {String suffix = ''}) {
      final v = asInt(key);
      if (v != null) rows.add((label: label, value: '${n.format(v)}$suffix'));
    }

    addInt('departures_count', 'Salidas');
    addInt('km_traveled', 'Km recorridos', suffix: ' km');
    addInt('hours_on_road', 'Horas en ruta', suffix: ' h');

    final odometer = asInt('last_odometer_km');
    if (odometer != null) {
      final readAt = _date(data['last_odometer_read_at']);
      rows.add((
        label: readAt == null ? 'Odómetro' : 'Odómetro ($readAt)',
        value: '${n.format(odometer)} km',
      ));
    }
    return rows;
  }

  /// Fecha corta en español (ej. "4 nov") desde un ISO, o `null`.
  String? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateFormat('d MMM', 'es').format(parsed.toLocal());
  }
}
