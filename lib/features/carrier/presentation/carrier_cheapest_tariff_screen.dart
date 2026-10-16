import 'package:flutter/material.dart';

import 'widgets/cheapest_tariff_form.dart';

/// Tarifa más barata para un corredor y tipo, entre todos los transportistas.
class CarrierCheapestTariffScreen extends StatelessWidget {
  const CarrierCheapestTariffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarifa más barata')),
      body: const CheapestTariffForm(),
    );
  }
}
