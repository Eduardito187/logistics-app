import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/sharing/share_service.dart';
import '../../../core/widgets/app_snack.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import '../domain/usecases/record_pod.dart';
import '../domain/usecases/upload_pod_photo.dart';
import 'controllers/store_controllers.dart';
import 'unit_scan.dart';
import 'widgets/bottom_action_bar.dart';
import 'widgets/pickup_pod_cards.dart';

export 'widgets/pickup_pod_cards.dart' show kPhotoPreviewCacheWidth;

/// Cuánto espera el POD, como MÁXIMO, a que termine de subir la foto de
/// evidencia para mandar su `photo_path` real. Mismo criterio que
/// [kSubmitWaitBudget] de la cola offline: con buena señal la subida ya
/// terminó (la foto se saca antes de escanear) y el POD sale encadenado; si
/// no, sale igual sin la foto (regla 4: la entrega nunca espera a la red).
const Duration kPodPhotoAttachBudget = Duration(milliseconds: 1500);

/// Prueba de entrega en mostrador (recojo en tienda): se confirma al cliente,
/// se toma una foto como evidencia y se registra el POD por cada producto
/// retirado.
class PickupPodScreen extends ConsumerStatefulWidget {
  const PickupPodScreen({super.key, required this.shipment});

  final Shipment shipment;

  @override
  ConsumerState<PickupPodScreen> createState() => _PickupPodScreenState();
}

class _PickupPodScreenState extends ConsumerState<PickupPodScreen> {
  final TextEditingController _confirmationController = TextEditingController();
  File? _photoFile;

  /// Referencia durable de la evidencia (`data.path` que devolvió el backend):
  /// es lo que el POD manda en `photo_path`. `null` mientras la subida no
  /// terminó o si la foto quedó en la cola offline.
  String? _photoPath;

  /// Subida en curso de la foto actual (ver [_attachPhoto]). El POD la espera
  /// como máximo [kPodPhotoAttachBudget].
  Future<String?>? _photoUpload;

  /// Sube con cada "Volver a tomar": la subida de una foto reemplazada ya no
  /// debe pisar [_photoPath].
  int _photoGeneration = 0;

  bool _busy = false;

  /// Si hay confirmación escrita. Se cachea para reconstruir solo cuando
  /// cambia (no en cada tecla, que redibujaría la foto y la lista de productos).
  bool _hasConfirmation = false;
  final Set<String> _delivered = <String>{};

  Shipment get _shipment => widget.shipment;

  @override
  void dispose() {
    _confirmationController.dispose();
    _evictPreview(_photoFile);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo importa si los productos ya cargaron, no su contenido.
    final unitsLoaded = ref.watch(
      shipmentUnitsProvider(_shipment.id).select((a) => a.hasValue),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Recojo en tienda')),
      body: ResponsiveBody(
        child: Column(
          children: [
            // Slivers: la lista de productos (paso 3) es perezosa; con 100+
            // productos con foto solo se arman las filas visibles.
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverList.list(
                          children: [
                            PickupCustomerCard(shipment: _shipment),
                            const SizedBox(height: 16),
                            PickupConfirmationCard(
                              controller: _confirmationController,
                              onChanged: _onConfirmationChanged,
                              onScan: _scanConfirmation,
                            ),
                            const SizedBox(height: 16),
                            PickupPhotoCard(
                              photo: _photoFile,
                              busy: _busy,
                              onTakePhoto: _takePhoto,
                              onShare: _photoFile == null ? null : _sharePhoto,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        PickupUnitsCard(
                          shipmentId: _shipment.id,
                          hasConfirmation: _hasConfirmation,
                          delivered: _delivered,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Escaneo seguido de productos: botón fijo al pie, a mano del pulgar;
            // los avisos flotan encima (kBottomActionClearance).
            BottomActionBar(
              child: FilledButton.icon(
                onPressed: !_hasConfirmation || _busy || !unitsLoaded
                    ? null
                    : _scanAndDeliver,
                // _busy solo cubre la ráfaga de escaneo: barrido mientras la
                // cámara está abierta.
                icon: AnimatedAppIcon(
                  AppIcon.scan,
                  state: _busy ? AppIconState.loading : AppIconState.idle,
                  excludeFromSemantics: true,
                ),
                label: const Text('Escanear y entregar producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirmationChanged(String _) {
    final has = _confirmationController.text.trim().isNotEmpty;
    if (has != _hasConfirmation) setState(() => _hasConfirmation = has);
  }

  Future<void> _scanConfirmation() async {
    final qr = await scanCode(
      context,
      title: 'QR del cliente',
      helper: 'Apunta al código del cliente que retira.',
    );
    if (qr == null || !mounted) return;
    _confirmationController.text = qr;
    _onConfirmationChanged(qr);
  }

  /// Comparte la foto de evidencia/documento por el menú nativo (WhatsApp, etc.).
  Future<void> _sharePhoto() async {
    final file = _photoFile;
    if (file == null || _busy) return;
    final cliente = _shipment.customerName;
    await ref
        .read(shareServiceProvider)
        .shareFile(file.path, text: 'Foto de entrega · $cliente');
  }

  Future<void> _takePhoto() async {
    final picked = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (picked == null || !mounted) return;
    // La vista previa anterior ya no se muestra: se libera de la caché.
    _evictPreview(_photoFile);
    final generation = ++_photoGeneration;
    setState(() {
      _photoFile = File(picked.path);
      _photoPath = null;
    });
    // La evidencia se encadena en segundo plano: la pantalla no espera ni a la
    // subida ni a la cola (regla 4). Ver [_attachPhoto].
    _photoUpload = _attachPhoto(generation, picked.path);
  }

  /// Encadena la foto al POD y nunca lanza.
  ///
  /// 1. Intenta subirla YA (`POST /app/deliveries/photos`): su `path` es lo que
  ///    el backend exige en `photo_path` de la prueba de entrega.
  /// 2. Si no se pudo (sin red, timeout o rechazo), la foto NO se pierde: se
  ///    deja en la cola offline de fotos, que la sube al recuperar señal. El
  ///    POD sale sin `photo_path` y el backend la liga al envío.
  ///
  /// Límite conocido: en el caso 2 la foto no queda ligada al POD (ver
  /// `UploadPodPhoto`, que documenta lo que falta pedirle al backend). Y si la
  /// subida muere por timeout de red después de que el servidor la guardó, la
  /// cola la sube otra vez: el backend queda con una foto repetida del mismo
  /// envío (molesto, no incorrecto). Lo mismo con "Volver a tomar": la foto
  /// descartada ya subida queda en el envío, sin ligar al POD.
  Future<String?> _attachPhoto(int generation, String filePath) async {
    final path = await ref
        .read(uploadPodPhotoProvider)
        .call(shipmentId: _shipment.id, filePath: filePath);
    // Se volvió a tomar la foto mientras subía: esta ya no es la vigente.
    if (generation != _photoGeneration) return null;
    if (path != null) {
      if (mounted) setState(() => _photoPath = path);
      return path;
    }
    try {
      await ref
          .read(enqueueDeliveryPhotoProvider)
          .call(shipmentId: _shipment.id, filePath: filePath, kind: 'pod');
    } on Object {
      // Falla local (copiar a disco), no de red: la foto no quedó guardada en
      // ningún lado, así que se descarta la vista previa y hay que repetirla.
      if (generation == _photoGeneration && mounted) {
        _evictPreview(_photoFile);
        setState(() => _photoFile = null);
        showErrorSnack(
          context,
          'No se pudo guardar la foto. Intentá de nuevo.',
          bottomClearance: kBottomActionClearance,
        );
      }
    }
    return null;
  }

  /// `photo_path` para el POD: la referencia real si la subida ya terminó; si
  /// está en vuelo se le da el margen acotado [kPodPhotoAttachBudget] y, si no
  /// llega, el POD sale sin ella (la foto igual viaja por su cola).
  Future<String?> _photoPathForPod() {
    final path = _photoPath;
    if (path != null) return Future.value(path);
    final upload = _photoUpload;
    if (upload == null) return Future.value();
    return upload.timeout(kPodPhotoAttachBudget, onTimeout: () => null);
  }

  /// Saca de la caché de imágenes la vista previa decodificada de [file].
  void _evictPreview(File? file) {
    if (file == null) return;
    unawaited(
      ResizeImage(FileImage(file), width: kPhotoPreviewCacheWidth).evict(),
    );
  }

  /// Escaneo CONTINUO (tras la confirmación del cliente): la cámara queda
  /// abierta y cada producto se entrega al leerlo, con aviso sobre la cámara.
  Future<void> _scanAndDeliver() async {
    // El GPS se calienta junto con la cámara: el POD no lo espera aparte.
    warmUpLocation(ref);
    final before = _delivered.length;
    setState(() => _busy = true);
    try {
      await scanContinuous(
        context,
        title: 'Escanear producto',
        helper: 'Apunta al QR de la etiqueta del producto.',
        formats: kLabelScanFormats,
        onCode: _deliverCode,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final delivered = _delivered.length - before;
    if (delivered <= 0) return;
    showSuccessSnack(
      context,
      delivered == 1
          ? '1 producto entregado.'
          : '$delivered productos entregados.',
      bottomClearance: kBottomActionClearance,
    );
  }

  /// Procesa un código de la ráfaga de entrega.
  Future<ScanFeedback> _deliverCode(String qr) async {
    final scan = await resolveUnitScan(ref, qr);
    if (!mounted) return const ScanFeedback.error('Pantalla cerrada');
    // Validación de etiqueta en el cliente (offline): firma inválida o clave
    // desconocida, igual que transportista.
    if (scan.verified == false) {
      return ScanFeedback.error(unitScanShortError(scan));
    }

    // Solo productos de este envío y una sola vez: si no, se entregaría al cliente
    // algo ajeno o se encolaría un POD duplicado.
    final units = ref.read(shipmentUnitsProvider(_shipment.id)).value;
    final unitId = scan.unitId;
    if (units != null && !units.any((u) => u.unitId == unitId)) {
      return const ScanFeedback.error('No es de este pedido');
    }
    if (_delivered.contains(unitId)) {
      return const ScanFeedback.error('Ya entregado');
    }

    // Feedback inmediato: el producto se marca entregado apenas se lee; el POD
    // se guarda local y sube por la cola.
    setState(() => _delivered.add(unitId));
    final photoPath = await _photoPathForPod();
    if (!mounted) return const ScanFeedback.error('Pantalla cerrada');
    final outcome = await ref
        .read(recordPodProvider)
        .call(
          shipmentId: _shipment.id,
          unitId: unitId,
          confirmation: _confirmationController.text.trim(),
          customerName: _shipment.customerName,
          photoPath: photoPath,
          location: prefetchFix(ref),
        );
    if (outcome == SubmitOutcome.failed) {
      // Rechazado por el backend: no queda como entregado.
      if (mounted) setState(() => _delivered.remove(unitId));
      return ScanFeedback.error(submitOutcomeMessage(outcome));
    }
    final total = units?.length;
    return ScanFeedback.ok(
      total == null
          ? 'Producto entregado'
          : 'Producto entregado (${_delivered.length}/$total)',
    );
  }
}
