import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'brand_loader.dart';
import 'empty_state.dart';

/// Render estándar de un `AsyncValue`: cargando, error (con reintento) y dato.
/// Unifica el manejo de red en todas las pantallas.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: data,
      loading: () => const LoadingView(),
      error: (error, _) {
        final message = error is ApiException
            ? error.message
            : 'Ocurrió un error.';
        return EmptyState(
          icon: Icons.cloud_off,
          title: 'No se pudo cargar',
          message: message,
          action: onRetry == null
              ? null
              : FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
        );
      },
    );
  }
}

/// Indicador de carga centrado con la marca DisTrack (isotipo con pulso suave).
///
/// Va en un [RepaintBoundary]: la animación repinta seguido y, sin el límite,
/// arrastra a repintar al resto de la pantalla (lo que más se nota en teléfonos
/// de gama baja). El [BrandLoader] respeta reduced-motion (queda estático).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        // Sin `message`: el propio BrandLoader ya anuncia "Cargando" por
        // accesibilidad (un solo nodo) y queda visualmente limpio.
        child: RepaintBoundary(
          child: BrandLoader(),
        ),
        // (BrandLoader() es const dentro del árbol const de arriba.)
      ),
    );
  }
}
