import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../driver_common.dart';

/// Ayuda con el precio vigente del combustible elegido, con botón para usarlo.
class PriceHint extends StatelessWidget {
  const PriceHint({super.key, required this.value, required this.onUse});

  final AsyncValue<FuelPrice> value;
  final void Function(int priceCents) onUse;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      loading: () => const Text('Consultando precio vigente…'),
      error: (_, _) => const Text('Sin precio vigente disponible.'),
      data: (price) {
        return Row(
          children: [
            Expanded(
              child: Text(
                'Precio vigente: ${formatMoneyCents(price.priceCents, price.currency)} / L',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => onUse(price.priceCents),
              child: const Text('Usar'),
            ),
          ],
        );
      },
    );
  }
}
