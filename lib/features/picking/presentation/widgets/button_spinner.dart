import 'package:flutter/material.dart';

/// Spinner pequeño para usar dentro de un botón mientras hay una operación en
/// curso (reemplaza al ícono del botón).
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
