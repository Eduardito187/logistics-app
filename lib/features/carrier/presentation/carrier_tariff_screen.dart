import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/carrier_guard.dart';
import 'widgets/tariff_form.dart';

/// Consulta de tarifa por corredor y clase de vehículo (solo lectura).
class CarrierTariffScreen extends StatelessWidget {
  const CarrierTariffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas por corredor'),
        actions: [
          IconButton(
            tooltip: 'Asignación por volumen',
            icon: const Icon(Icons.local_shipping),
            onPressed: () => context.push('/carrier/assignment'),
          ),
          IconButton(
            tooltip: 'Tarifa más barata',
            icon: const Icon(Icons.savings),
            onPressed: () => context.push('/carrier/tariff/cheapest'),
          ),
        ],
      ),
      body: CarrierGuard(
        builder: (context, carrier) => TariffForm(carrier: carrier),
      ),
    );
  }
}
