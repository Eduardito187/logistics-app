import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../icons/icons.dart';
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
    // Mientras la consulta está EN CURSO (primera carga O recarga tras un error)
    // se muestra el CARGANDO, NUNCA el error: el error de una consulta anterior
    // no debe tapar la nueva que está corriendo. Antes `.when` caía al error
    // durante la recarga y "No se pudo cargar" parpadeaba hasta que llegaba el
    // dato. El error SOLO se muestra cuando la consulta YA TERMINÓ en error
    // (sin estar cargando) y no hay ningún dato para mostrar.
    if (value.isLoading && !value.hasValue) {
      return const LoadingView();
    }
    // Con dato: se muestra (aunque esté refrescando en segundo plano) → la
    // pantalla nunca queda vacía ni con error mientras revalida.
    if (value.hasValue) {
      return data(value.requireValue);
    }
    // Sin dato y sin estar cargando: ahí sí es un error real.
    final error = value.error;
    final message = error is ApiException ? error.message : 'Ocurrió un error.';
    return EmptyState(
      icon: AppIcon.cloudOff,
      title: 'No se pudo cargar',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const AnimatedAppIcon(AppIcon.refresh),
              label: const Text('Reintentar'),
            ),
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
        child: RepaintBoundary(child: BrandLoader()),
        // (BrandLoader() es const dentro del árbol const de arriba.)
      ),
    );
  }
}
