import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/carrier.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/carrier_controllers.dart';

/// Asegura que haya un transportista elegido antes de mostrar [builder].
/// Si no hay ninguno, ofrece la lista de transportistas activos para elegir.
class CarrierGuard extends ConsumerWidget {
  const CarrierGuard({super.key, required this.builder});

  final Widget Function(BuildContext context, Carrier carrier) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCarrierProvider);
    if (selected != null) {
      return builder(context, selected);
    }

    final carriers = ref.watch(carriersListProvider);
    return AsyncValueView<List<Carrier>>(
      value: carriers,
      onRetry: () => ref.invalidate(carriersListProvider),
      // Lista perezosa y centrada en tablets; la cabecera es el ítem 0.
      data: (list) => ResponsiveBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Elige tu transportista',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              );
            }
            final carrier = list[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SectionCard(
                onTap: () =>
                    ref.read(selectedCarrierProvider.notifier).select(carrier),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            carrier.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text('NIT ${carrier.taxId}'),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
