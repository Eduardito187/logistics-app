import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/connectivity_notifier.dart';
import '../../data/datasources/store_remote_data_source.dart';

/// Command: sube la foto de evidencia del POD y devuelve la referencia durable
/// (`data.path`) que el backend espera en `photo_path` de la prueba de entrega.
///
/// **Por qué existe:** el POD y la foto viajaban por caminos distintos (la foto
/// por la cola de fotos, el POD con la marca inventada `'pendiente'`), así que
/// el backend no podía ligarlos. Para encadenarlos de verdad hace falta el
/// `path` que devuelve `POST /app/deliveries/photos`, y eso requiere red.
///
/// **Cómo se respeta offline-first (regla 4):** este caso de uso NUNCA es parte
/// del camino crítico de la entrega. La pantalla lo lanza en segundo plano al
/// sacar la foto y nunca lo espera sin tope:
/// - con red, la subida termina mientras el cliente firma/confirma y el POD
///   sale con el `path` real;
/// - sin red o con rechazo devuelve `null` y la pantalla deja la foto en la
///   cola offline de fotos (`EnqueueDeliveryPhoto`), que la sube sola al
///   recuperar señal. El POD sale sin `photo_path`, igual que antes, pero sin
///   mentir con un valor inventado.
///
/// **Límites conocidos (hace falta el backend):** si no hay red, la entrega
/// queda registrada sin `photo_path` y la foto llega después por la cola: el
/// backend la liga al envío, no al POD. Para encadenarlas también offline haría
/// falta que la app genere un id de evidencia (ULID) y que el backend lo acepte
/// en los DOS lados (`POST /app/deliveries/photos` y `photo_path` /
/// `evidence_id` de `POST /app/deliveries/proof-of-delivery`), aceptando una
/// referencia a evidencia que todavía no subió. Mientras eso no exista, no se
/// puede hacer mejor sin romper la regla 4.
///
/// Va directo al data source (no al repositorio) por lo mismo que
/// [EnqueueDeliveryPhoto] va directo a la cola de fotos: es una escritura de
/// terreno con política propia, no una lectura del contrato de Tienda. El data
/// source sigue siendo la única clase del feature que toca el cliente API.
class UploadPodPhoto {
  const UploadPodPhoto(this._ref);

  final Ref _ref;

  /// Sube la foto y devuelve su `path` de evidencia, o `null` si no se pudo
  /// (sin red, timeout de red o rechazo del backend). Nunca lanza: el fallback
  /// (encolar) lo decide quien llama.
  Future<String?> call({
    required String shipmentId,
    required String filePath,
  }) async {
    // Sin red conocida ni se intenta: la foto va derecho a la cola.
    if (_knownOffline) return null;
    try {
      final evidence = await _ref
          .read(storeRemoteDataSourceProvider)
          .uploadDeliveryPhoto(shipmentId: shipmentId, photo: File(filePath));
      return evidence.path;
    } on Object {
      return null;
    }
  }

  /// `true` solo si el estado de conectividad ya se conoce y es "sin red" (no
  /// crea el provider si nadie lo levantó; lo escucha `app.dart`).
  bool get _knownOffline {
    if (!_ref.exists(connectivityProvider)) return false;
    return _ref.read(connectivityProvider).value == false;
  }
}

final uploadPodPhotoProvider = Provider<UploadPodPhoto>(UploadPodPhoto.new);
