import 'package:flutter/material.dart';

import 'widgets/assignment_form.dart';

/// Asignación por volumen: dado un corredor y el volumen (m³), sugiere la clase
/// de vehículo (tráiler/camión/tercero) y la tarifa más barata para esa clase.
class CarrierAssignmentScreen extends StatelessWidget {
  const CarrierAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignación por volumen')),
      body: const AssignmentForm(),
    );
  }
}
