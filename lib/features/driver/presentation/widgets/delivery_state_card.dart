import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/icons/icons.dart';

import '../../../../core/api/export.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/driver_controllers.dart';
import 'info_row.dart';

/// Estado detallado de la entrega del envío (status real + escaneos), leído del
/// backend. Complementa el estado de la parada con lo que ya se registró.
///
/// Es información COMPLEMENTARIA: una parada pendiente todavía no tiene actividad
/// de entrega y el backend puede no devolver nada. En ese caso (o si no se pudo
/// leer) se muestra un estado neutro "Sin movimientos…", NUNCA un error con
/// "Reintentar": no es una falla que el chofer deba resolver en terreno.
class DeliveryStateCard extends ConsumerWidget {
  const DeliveryStateCard({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryStateProvider(shipmentId));
    return SectionCard(
      title: 'Estado de la entrega',
      child: state.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        // Sin datos aún (o no se pudo leer): neutro, sin alarmar.
        error: (_, _) => const InfoRow(
          icon: AppIcon.pending,
          text: 'Sin movimientos registrados todavía.',
        ),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: InfoRow(icon: AppIcon.pending, text: 'Cargando…'),
        ),
        data: (delivery) {
          final reason = delivery.failureReason;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                _deliveryStatusLabel(delivery.status),
                tone: _deliveryStatusTone(delivery.status),
              ),
              const SizedBox(height: 8),
              InfoRow(
                icon: AppIcon.scan,
                text: '${delivery.scans.length} escaneo(s) registrados',
              ),
              if (delivery.podConfirmation != null)
                InfoRow(
                  icon: AppIcon.verified,
                  text: 'Firma/confirmación: ${delivery.podConfirmation!}',
                ),
              if (reason != null)
                InfoRow(
                  icon: AppIcon.error,
                  text: 'Motivo de falla: ${_failureReasonLabel(reason)}',
                ),
              // Foto de la entrega ya registrada (la devuelve el backend como
              // URL): se muestra al reentrar a una parada entregada.
              if (delivery.podPhotoUrl != null) ...[
                const SizedBox(height: 10),
                _PodPhoto(url: delivery.podPhotoUrl!),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Foto de la entrega (POD) ya registrada, servida por el backend. Se decodifica
/// chica (no a resolución de cámara) y, si falla la descarga, muestra un ícono
/// neutro: nunca un error que alarme (es evidencia histórica, no una acción).
class _PodPhoto extends StatelessWidget {
  const _PodPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 800,
        semanticLabel: 'Foto de la entrega',
        errorBuilder: (context, _, _) => _PodPhotoFallback(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const _PodPhotoFallback(loading: true),
      ),
    );
  }
}

class _PodPhotoFallback extends StatelessWidget {
  const _PodPhotoFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      alignment: Alignment.center,
      color: scheme.surfaceContainerHighest,
      child: AnimatedAppIcon(
        AppIcon.image,
        size: 40,
        state: loading ? AppIconState.loading : AppIconState.idle,
        color: scheme.outline,
        semanticLabel: loading ? 'Cargando foto' : 'Foto de la entrega',
      ),
    );
  }
}

String _deliveryStatusLabel(DeliveryStatus status) => switch (status) {
  DeliveryStatus.pending => 'Pendiente',
  DeliveryStatus.prepared => 'Preparada',
  DeliveryStatus.loaded => 'Cargada',
  DeliveryStatus.inTransit => 'En tránsito',
  DeliveryStatus.delivered => 'Entregada',
  DeliveryStatus.failed => 'Fallida',
  _ => 'Desconocido',
};

PillTone _deliveryStatusTone(DeliveryStatus status) => switch (status) {
  DeliveryStatus.delivered => PillTone.success,
  DeliveryStatus.failed => PillTone.danger,
  DeliveryStatus.inTransit => PillTone.info,
  _ => PillTone.neutral,
};

String _failureReasonLabel(FailureReason reason) => switch (reason) {
  FailureReason.customerAbsent => 'Cliente ausente',
  FailureReason.wrongAddress => 'Dirección incorrecta',
  FailureReason.rejected => 'Pedido rechazado',
  FailureReason.damaged => 'Producto dañado',
  FailureReason.other => 'Otro motivo',
  _ => 'Motivo desconocido',
};
