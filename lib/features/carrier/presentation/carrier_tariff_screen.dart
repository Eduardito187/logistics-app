import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/icons/icons.dart';
import 'widgets/carrier_guard.dart';
import 'widgets/carrier_office_only.dart';
import 'widgets/tariff_form.dart';

/// Consulta de tarifa por corredor y clase de vehículo (solo lectura).
class CarrierTariffScreen extends ConsumerWidget {
  const CarrierTariffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Atajos a las herramientas de compra/costeo: solo para la oficina. Al
    // transportista no se le muestran (y la ruta también los bloquea).
    final office = canUseCarrierOfficeTools(ref.watch(sessionProvider));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas por corredor'),
        actions: [
          if (office) ...[
            IconButton(
              tooltip: 'Asignación por volumen',
              icon: const AnimatedAppIcon(AppIcon.deliver),
              onPressed: () => context.push('/carrier/assignment'),
            ),
            IconButton(
              tooltip: 'Tarifa más barata',
              icon: const AnimatedAppIcon(AppIcon.savings),
              onPressed: () => context.push('/carrier/tariff/cheapest'),
            ),
          ],
        ],
      ),
      body: CarrierGuard(
        builder: (context, carrier) => TariffForm(carrier: carrier),
      ),
    );
  }
}
