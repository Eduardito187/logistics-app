import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/inspection_history_controller.dart';

/// Recordatorio diario de la inspección del camión (diésel): si HOY todavía no
/// se hizo la inspección, muestra un aviso llamativo que lleva al checklist. Si
/// ya se hizo hoy —o no se pudo leer el historial— no ocupa espacio
/// (`SizedBox.shrink`): es complementario, nunca muestra un error de carga.
class DailyInspectionReminder extends ConsumerWidget {
  const DailyInspectionReminder({
    super.key,
    required this.vehicleId,
    required this.onTap,
    this.currentRouteId,
  });

  final String vehicleId;

  /// Ruta del día en curso (si hay). Con el checklist POR RUTA, el recordatorio
  /// se muestra cuando FALTA la inspección de ESA ruta; sin backend por ruta,
  /// cae al criterio diario.
  final String? currentRouteId;

  /// Acción al tocar: el coordinador lo manda al checklist pre-salida.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(inspectionHistoryProvider(vehicleId));
    // En cargando/error NO se muestra nada (es un recordatorio, no un dato
    // crítico que el chofer deba resolver). Solo se muestra si HAY datos y falta
    // la inspección de la salida actual.
    final show = history.maybeWhen(
      data: (items) {
        // En modo por ruta sin ruta asignada todavía no se molesta al chofer.
        if (perRouteChecklistMode(items) && currentRouteId == null) {
          return false;
        }
        return inspectionForCurrentRoute(
              items,
              currentRouteId,
              DateTime.now(),
            ) ==
            null;
      },
      orElse: () => false,
    );
    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const AnimatedAppIcon(
                  AppIcon.checklist,
                  size: 28,
                  color: AppColors.accentInk,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Revisá el camión hoy',
                        style: TextStyle(
                          color: AppColors.accentInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Agua, frenos y motor antes de salir.',
                        style: TextStyle(color: AppColors.accentInk),
                      ),
                    ],
                  ),
                ),
                const AnimatedAppIcon(
                  AppIcon.chevronRight,
                  size: 22,
                  color: AppColors.accentInk,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
