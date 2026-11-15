import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/location/location_service.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/sharing/share_service.dart';
import '../../../core/widgets/app_snack.dart';
// Mismo proceso que la entrega del chofer (pedido del dueño): se reutilizan su
// pad de firma, su almacén temporal de la firma y sus `kind` de evidencia.
import '../../driver/data/datasources/signature_file_store.dart';
import '../../driver/presentation/pod_screen.dart'
    show
        kDigitalSignatureConfirmation,
        kDocumentEvidenceKind,
        kSignatureEvidenceKind;
import '../../driver/presentation/signature_pad_screen.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import '../domain/usecases/record_pod.dart';
import '../domain/usecases/upload_pod_photo.dart';
import 'controllers/store_controllers.dart';
import 'controllers/store_shipments_notifier.dart';
import 'unit_scan.dart';
import 'widgets/bottom_action_bar.dart';
import 'widgets/pickup_pod_cards.dart';

export 'widgets/pickup_pod_cards.dart' show kPhotoPreviewCacheWidth;

/// Cuánto espera el POD, como MÁXIMO, a que termine de subir la foto de
/// evidencia para mandar su `photo_path` real. Mismo criterio que
/// [kSubmitWaitBudget] de la cola offline: con buena señal la subida ya
/// terminó (la foto se saca antes de registrar) y el POD sale encadenado; si
/// no, sale igual sin la foto (regla 4: la entrega nunca espera a la red).
const Duration kPodPhotoAttachBudget = Duration(milliseconds: 1500);

/// Captura de la firma del cliente (inyectable: en tests no se abre el pad).
typedef SignatureCapture = Future<Uint8List?> Function(BuildContext context);

/// Por defecto, el mismo pad de firma a pantalla completa del chofer.
final pickupSignatureCaptureProvider = Provider<SignatureCapture>(
  (ref) => captureCustomerSignature,
);

/// Entrega de un pedido que el CLIENTE retira en la tienda (recojo en tienda).
///
/// Mismo proceso que la entrega del chofer: se escanean los productos del
/// pedido, el cliente firma en pantalla, se toma la foto de la entrega
/// (obligatoria) y, si se quiere, la del documento (opcional). Recién al tocar
/// "Registrar entrega" se registra la prueba de entrega de cada producto y el
/// pedido pasa a ENTREGADO. Escanear solo NO entrega nada.
class PickupPodScreen extends ConsumerStatefulWidget {
  const PickupPodScreen({super.key, required this.shipment});

  final Shipment shipment;

  @override
  ConsumerState<PickupPodScreen> createState() => _PickupPodScreenState();
}

class _PickupPodScreenState extends ConsumerState<PickupPodScreen> {
  /// PNG de la firma del cliente.
  Uint8List? _signature;

  File? _photoFile;

  /// Foto del documento (carnet) del cliente — evidencia OPCIONAL.
  File? _document;

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

  /// Productos escaneados en esta pantalla, todavía SIN registrar: se entregan
  /// todos juntos al tocar "Registrar entrega".
  final Set<String> _scanned = <String>{};

  /// Productos ya entregados: los que el servidor confirmó antes de abrir la
  /// pantalla (ver [initState]) más los registrados acá. No es solo memoria: así
  /// un reinicio de la app a mitad del retiro no permite entregar dos veces el
  /// mismo producto.
  final Set<String> _delivered = <String>{};

  /// Mantiene viva la consulta de lo ya entregado mientras dura el retiro.
  ProviderSubscription<AsyncValue<Set<String>>>? _deliveredSub;

  Shipment get _shipment => widget.shipment;

  @override
  void initState() {
    super.initState();
    final provider = deliveredUnitIdsProvider(_shipment.id);
    // Se escucha SIN esperarla (regla 4): el retiro arranca igual y lo ya
    // entregado se siembra en cuanto llegue. Si no hay red el provider devuelve
    // vacío y no se bloquea nada.
    _deliveredSub = ref.listenManual(
      provider,
      (_, next) => _seedDelivered(next.value),
    );
    // Si la respuesta ya estaba en caché (volver a entrar a la pantalla) el
    // listener no dispara: se siembra acá, antes del primer build.
    _delivered.addAll(ref.read(provider).value ?? const <String>{});
  }

  @override
  void dispose() {
    _deliveredSub?.close();
    _evictPreview(_photoFile);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(shipmentUnitsProvider(_shipment.id)).value;
    // Lo que todavía falta escanear: ni entregado ni escaneado.
    final missing = units
        ?.where(
          (u) => !_delivered.contains(u.unitId) && !_scanned.contains(u.unitId),
        )
        .length;
    final allDelivered =
        units != null &&
        units.isNotEmpty &&
        _scanned.isEmpty &&
        units.every((u) => _delivered.contains(u.unitId));
    // Se registra con TODOS los productos pendientes escaneados + firma + foto.
    final scanComplete = missing == 0 && _scanned.isNotEmpty;
    final ready = scanComplete && _signature != null && _photoFile != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Recojo en tienda')),
      body: ResponsiveBody(
        child: Column(
          children: [
            // Slivers: la lista de productos (paso 4) es perezosa; con 100+
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
                            PickupSignatureCard(
                              signature: _signature,
                              busy: _busy,
                              onSign: _sign,
                            ),
                            const SizedBox(height: 16),
                            PickupPhotoCard(
                              photo: _photoFile,
                              busy: _busy,
                              onTakePhoto: _takePhoto,
                              onShare: _photoFile == null ? null : _sharePhoto,
                            ),
                            const SizedBox(height: 16),
                            PickupDocumentCard(
                              document: _document,
                              busy: _busy,
                              onTakeDocument: _takeDocument,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        PickupUnitsCard(
                          shipmentId: _shipment.id,
                          scanned: _scanned,
                          delivered: _delivered,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Un solo botón fijo al pie, a mano del pulgar, que va cambiando con
            // el paso: primero escanear; con todo escaneado, registrar. Los
            // avisos flotan encima (kBottomActionClearance).
            BottomActionBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (scanComplete && !ready)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _missingStepsText(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (allDelivered)
                    const FilledButton(
                      onPressed: null,
                      child: Text('Pedido entregado'),
                    )
                  else if (scanComplete)
                    FilledButton.icon(
                      onPressed: ready && !_busy ? _register : null,
                      icon: AnimatedAppIcon(
                        AppIcon.success,
                        state: _busy ? AppIconState.loading : AppIconState.idle,
                        excludeFromSemantics: true,
                      ),
                      label: const Text('Registrar entrega'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _busy || units == null ? null : _scanProducts,
                      // _busy cubre la ráfaga de escaneo: barrido mientras la
                      // cámara está abierta.
                      icon: AnimatedAppIcon(
                        AppIcon.scan,
                        state: _busy ? AppIconState.loading : AppIconState.idle,
                        excludeFromSemantics: true,
                      ),
                      label: const Text('Escanear productos'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Qué falta para poder registrar, con los productos ya escaneados.
  String _missingStepsText() {
    final missing = [
      if (_signature == null) 'la firma del cliente',
      if (_photoFile == null) 'la foto de entrega',
    ];
    return 'Falta ${missing.join(' y ')}.';
  }

  /// Suma lo que el servidor ya tiene entregado a [_delivered]. Solo agrega:
  /// nunca borra un producto registrado en esta sesión (que todavía puede estar
  /// en la cola offline y por eso el servidor aún no lo reporta).
  void _seedDelivered(Set<String>? confirmed) {
    if (confirmed == null || !mounted) return;
    final missing = confirmed.difference(_delivered);
    if (missing.isEmpty) return;
    setState(() {
      _delivered.addAll(missing);
      // Lo que el servidor ya tiene entregado no se vuelve a registrar.
      _scanned.removeAll(missing);
    });
  }

  Future<void> _sign() async {
    final png = await ref.read(pickupSignatureCaptureProvider)(context);
    if (png != null && mounted) setState(() => _signature = png);
  }

  /// Comparte la foto de evidencia por el menú nativo (WhatsApp, etc.).
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

  Future<void> _takeDocument() async {
    final picked = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (picked == null || !mounted) return;
    setState(() => _document = File(picked.path));
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

  /// Escaneo CONTINUO de los productos del pedido: la cámara queda abierta y
  /// cada producto queda "Escaneado" al leerlo. NO registra la entrega.
  Future<void> _scanProducts() async {
    // El GPS se calienta junto con la cámara: el registro no lo espera aparte.
    warmUpLocation(ref);
    setState(() => _busy = true);
    try {
      await scanContinuous(
        context,
        title: 'Escanear producto',
        helper: 'Apunta al QR de la etiqueta del producto.',
        formats: kLabelScanFormats,
        onCode: _scanCode,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Procesa un código de la ráfaga de escaneo.
  Future<ScanFeedback> _scanCode(String qr) async {
    final scan = await resolveUnitScan(ref, qr);
    if (!mounted) return const ScanFeedback.error('Pantalla cerrada');
    // Validación de etiqueta en el cliente (offline): firma inválida o clave
    // desconocida, igual que transportista.
    if (scan.verified == false) {
      return ScanFeedback.error(unitScanShortError(scan));
    }

    // Solo productos de este pedido y una sola vez: si no, se entregaría al
    // cliente algo ajeno o se registraría un POD duplicado.
    final units = ref.read(shipmentUnitsProvider(_shipment.id)).value;
    final unitId = scan.unitId;
    if (units != null && !units.any((u) => u.unitId == unitId)) {
      return const ScanFeedback.error('No es de este pedido');
    }
    if (_delivered.contains(unitId)) {
      return const ScanFeedback.error('Este producto ya fue entregado');
    }
    if (_scanned.contains(unitId)) {
      return const ScanFeedback.error('Ese producto ya lo escaneaste');
    }

    setState(() => _scanned.add(unitId));
    final pending = units?.where((u) => !_delivered.contains(u.unitId)).length;
    return ScanFeedback.ok(
      pending == null
          ? 'Producto escaneado'
          : 'Producto escaneado (${_scanned.length}/$pending)',
    );
  }

  /// Snapshot del cliente para LIGAR la evidencia (firma/documento) a su
  /// identidad (anti-fraude), igual que en la entrega del chofer.
  Map<String, Object?> _clientSnapshot(GpsFix? fix) => {
    'customer_name': _shipment.customerName,
    if (_shipment.customerPhone != null)
      'customer_phone': _shipment.customerPhone,
    if (_shipment.customerDocumentId != null)
      'customer_document_id': _shipment.customerDocumentId,
    if (fix != null) 'lat': fix.lat,
    if (fix != null) 'lng': fix.lng,
    'captured_at': DateTime.now().toUtc().toIso8601String(),
  };

  /// Registra la entrega: evidencia (documento y firma) a su cola y una prueba
  /// de entrega por CADA producto escaneado. Offline-first: lo encolado cuenta
  /// como registrado.
  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      final fix = await prefetchFix(ref);
      if (!mounted) return;
      final snapshot = _clientSnapshot(fix);
      final enqueue = ref.read(enqueueDeliveryPhotoProvider);
      final document = _document;
      if (document != null) {
        try {
          await enqueue(
            shipmentId: _shipment.id,
            filePath: document.path,
            kind: kDocumentEvidenceKind,
            clientSnapshot: snapshot,
          );
        } on Object {
          // El documento es opcional: sin disco para guardarlo, la entrega
          // sigue.
        }
      }
      final signature = _signature;
      if (signature != null) {
        final store = ref.read(signatureFileStoreProvider);
        try {
          final path = await store.save(signature);
          await enqueue(
            shipmentId: _shipment.id,
            filePath: path,
            kind: kSignatureEvidenceKind,
            clientSnapshot: snapshot,
          );
          // La cola ya copió el archivo a su directorio persistente.
          await store.discard(path);
        } on Object {
          // Sin disco para la imagen no se frena la entrega: el POD viaja
          // igual con el marcador FIRMA_DIGITAL.
        }
      }
      final photoPath = await _photoPathForPod();
      if (!mounted) return;

      final recordPod = ref.read(recordPodProvider);
      var failed = false;
      var queued = false;
      for (final unitId in _scanned.toList(growable: false)) {
        final outcome = await recordPod(
          shipmentId: _shipment.id,
          unitId: unitId,
          confirmation: kDigitalSignatureConfirmation,
          customerName: _shipment.customerName,
          photoPath: photoPath,
          location: Future.value(fix),
        );
        if (!mounted) return;
        if (outcome == SubmitOutcome.failed) {
          // Rechazado por el backend: ese producto sigue "escaneado" para
          // reintentar; los que sí entraron ya no se repiten.
          failed = true;
          continue;
        }
        if (outcome == SubmitOutcome.queued) queued = true;
        setState(() {
          _scanned.remove(unitId);
          _delivered.add(unitId);
        });
      }
      final combined = failed
          ? SubmitOutcome.failed
          : queued
          ? SubmitOutcome.queued
          : SubmitOutcome.sent;
      showSubmitOutcome(
        context,
        combined,
        bottomClearance: kBottomActionClearance,
      );
      if (combined == SubmitOutcome.failed) return;
      // Entregado: la bandeja de recojos se refresca (el pedido cambió de
      // estado) y se vuelve a ella.
      ref.invalidate(storeShipmentsPagedProvider);
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
