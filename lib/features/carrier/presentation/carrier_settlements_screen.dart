import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/icons.dart';
import 'controllers/carrier_controllers.dart';
import 'widgets/carrier_guard.dart';
import 'widgets/settlements_list.dart';

/// Lista de liquidaciones del transportista elegido.
class CarrierSettlementsScreen extends ConsumerWidget {
  const CarrierSettlementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo importa si hay transportista elegido: no se reconstruye la AppBar
    // por otros cambios del objeto.
    final hasCarrier = ref.watch(
      selectedCarrierProvider.select((carrier) => carrier != null),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis liquidaciones'),
        actions: [
          if (hasCarrier) ...[
            IconButton(
              tooltip: 'Ver tarifas',
              icon: const AnimatedAppIcon(AppIcon.payments),
              onPressed: () => context.push('/carrier/tariff'),
            ),
            IconButton(
              tooltip: 'Cambiar transportista',
              icon: const AnimatedAppIcon(AppIcon.swap),
              onPressed: () =>
                  ref.read(selectedCarrierProvider.notifier).clear(),
            ),
          ],
        ],
      ),
      body: CarrierGuard(
        builder: (context, carrier) => SettlementsList(carrier: carrier),
      ),
    );
  }
}
