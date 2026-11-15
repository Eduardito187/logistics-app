import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/labels/label_format_exception.dart';
import '../../../core/labels/signed_label.dart';
import '../../../core/location/location_service.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/sharing/share_service.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../data/datasources/signature_file_store.dart';
import '../domain/usecases/enqueue_delivery_photo.dart';
import 'controllers/driver_controllers.dart';
import 'controllers/locally_settled_stops.dart';
import 'driver_common.dart';
import 'signature_pad_screen.dart';
import 'widgets/evidence_photo_preview.dart';

/// Marcador de `confirmation` cuando el cliente firma en pantalla (la imagen
/// de la firma viaja aparte como evidencia por la cola de fotos).
const String kDigitalSignatureConfirmation = 'FIRMA_DIGITAL';

/// `kind` de la firma del cliente: va al endpoint de EVIDENCIA anti-fraude
/// (`/app/deliveries/evidence`) LIGADA al cliente (snapshot) y se valida en el
/// backend (docs/backend-requests/2026-11-05-evidencia-ligada-al-cliente-antifraude.md).
const String kSignatureEvidenceKind = 'signature';

/// `kind` de la foto del documento (carnet) del cliente: evidencia anti-fraude
/// ligada al cliente; el backend hace OCR del nº y lo cruza con el documento del
/// cliente.
const String kDocumentEvidenceKind = 'id_document';

/// Prueba de entrega (POD): producto (validado contra el envío) + firma del
/// cliente en pantalla + foto obligatoria + GPS. El registro es offline-first;
/// la foto y la firma se suben aparte, por la cola de fotos. (No hay "QR del
/// cliente": el cliente no tiene un código que escanear; confirma firmando.)
class PodScreen extends ConsumerStatefulWidget {
  const PodScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  ConsumerState<PodScreen> createState() => _PodScreenState();
}

class _PodScreenState extends ConsumerState<PodScreen> {
  /// Productos escaneados para esta entrega, en orden y sin repetir. Un pedido
  /// de N productos se entrega escaneando los N productos (no uno solo).
  final List<String> _unitIds = <String>[];

  /// SKU de cada producto escaneado (por `unit_id`), cuando se pudo leer de la
  /// etiqueta (QR). Sirve para la guardia anti-duplicados por SKU: dos etiquetas
  /// DISTINTAS del MISMO producto (misma orden + mismo SKU, p. ej. tras una
  /// re-emisión) no pueden sumar una entrega de más.
  final Map<String, String> _skuByUnitId = <String, String>{};

  /// Cantidad de productos esperados del envío, o `null` si todavía no se pudo
  /// saber (sin red / el backend aún no la expone). Con `null` no se exige un
  /// total: alcanza con ≥1 producto para poder cerrar (offline-first).
  int? _expectedCount;
  String? _confirmation;
  XFile? _photo;

  /// Foto del documento (carnet) del cliente — evidencia anti-fraude OPCIONAL.
  XFile? _document;

  /// PNG de la firma del cliente (solo si confirmó firmando en pantalla).
  Uint8List? _signature;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // GPS caliente al entrar: al registrar, el fix ya está y no se espera.
    ref.read(locationServiceProvider).prefetch();
    // Total de productos del pedido. Fuente AUTORITATIVA: `unit_ids` de la
    // parada (un id por producto etiquetado). La cantidad de los ÍTEMS
    // (`items[].quantity`) NO siempre coincide con la cantidad de productos
    // etiquetados —un ítem puede salir en 2 etiquetas, o 3 ítems en 1— así que
    // solo se usa como respaldo si el backend aún no manda unit_ids.
    // Con esto el escaneo se LIMITA al total real del pedido.
    final unitIds = widget.stop.unitIds;
    final fromItems = widget.stop.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    if (unitIds != null && unitIds.isNotEmpty) {
      // El total NUNCA puede superar la cantidad real de productos del pedido.
      // Unidades DUPLICADAS (misma orden+SKU, distinto id, p. ej. tras una
      // re-emisión) inflan `unit_ids`, pero la suma de cantidades de los ítems
      // es el tope real a entregar. Se toma el MENOR: así una etiqueta duplicada
      // no suma un producto de más. (Si no hay ítems, manda `unit_ids`.)
      _expectedCount = fromItems > 0
          ? math.min(unitIds.length, fromItems)
          : unitIds.length;
    } else if (fromItems > 0) {
      _expectedCount = fromItems;
    } else {
      // Ni `unit_ids` ni ítems en la parada: se intenta por el endpoint.
      _loadExpectedCount();
    }
  }

  Future<void> _loadExpectedCount() async {
    try {
      final units = await ref.read(
        driverShipmentUnitsProvider(widget.stop.shipmentId).future,
      );
      if (mounted && units.isNotEmpty) {
        setState(() => _expectedCount = units.length);
      }
    } on Object {
      // Sin red / error: se queda en null (no se exige total).
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se puede CERRAR con al menos un producto y —si se sabe el total— todos
    // los productos del pedido; + confirmación del cliente + foto (obligatoria).
    final canClose =
        _unitIds.isNotEmpty &&
        (_expectedCount == null || _unitIds.length >= _expectedCount!);
    final ready = canClose && _confirmation != null && _photo != null;
    // Se deja de ESCANEAR solo cuando se CONOCE el total y ya se llegó. Si el
    // total es desconocido (el backend no lo expone), NUNCA se corta el escaneo:
    // así un pedido de N productos se puede seguir escaneando (bug: antes se
    // cortaba en 1 cuando no se sabía el total).
    final reachedKnownTotal =
        _expectedCount != null && _unitIds.length >= _expectedCount!;
    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante de entrega')),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: '1. Productos entregados',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_unitsSummary(), style: _unitsSummaryStyle(context)),
                  if (_unitIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (var i = 0; i < _unitIds.length; i++)
                      _ScannedUnitTile(
                        index: i + 1,
                        unitId: _unitIds[i],
                        onRemove: _busy
                            ? null
                            : () => setState(() {
                                _skuByUnitId.remove(_unitIds[i]);
                                _unitIds.removeAt(i);
                              }),
                      ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy || reachedKnownTotal ? null : _scanUnit,
                    icon: const AnimatedAppIcon(AppIcon.scan),
                    label: Text(
                      _unitIds.isEmpty
                          ? 'Escanear producto'
                          : 'Escanear siguiente',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '2. Confirmación del cliente',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_signature != null) ...[
                    const Text('Firmado por el cliente.'),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SignaturePreview(
                        key: const ValueKey('signature-preview'),
                        png: _signature!,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _shareSignature,
                        icon: const AnimatedAppIcon(AppIcon.send, size: 18),
                        label: const Text('Compartir firma'),
                      ),
                    ),
                  ] else
                    const Text('Pedile al cliente que firme.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _sign,
                    icon: const AnimatedAppIcon(AppIcon.signature),
                    label: Text(
                      _signature == null
                          ? 'Firma del cliente'
                          : 'Volver a firmar',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '3. Foto de entrega (obligatoria)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Decodificada chica y liberada del caché al salir.
                  if (_photo != null) ...[
                    EvidencePhotoPreview(path: _photo!.path),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _sharePhoto,
                        icon: const AnimatedAppIcon(AppIcon.send, size: 18),
                        label: const Text('Compartir foto'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _takePhoto,
                    icon: const AnimatedAppIcon(AppIcon.capture),
                    label: Text(
                      _photo == null ? 'Tomar foto' : 'Volver a tomar',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '4. Documento del cliente (opcional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_document != null) ...[
                    EvidencePhotoPreview(path: _document!.path),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _shareDocument,
                        icon: const AnimatedAppIcon(AppIcon.send, size: 18),
                        label: const Text('Compartir documento'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _takeDocument,
                    icon: const AnimatedAppIcon(AppIcon.capture),
                    label: Text(
                      _document == null
                          ? 'Foto del documento'
                          : 'Volver a tomar',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: ready && !_busy ? _register : null,
              icon: AnimatedAppIcon(
                AppIcon.success,
                state: _busy ? AppIconState.loading : AppIconState.idle,
              ),
              label: const Text('Registrar entrega'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanUnit() async {
    final qr = await scanCode(
      context,
      title: 'Escanear producto',
      helper: 'Apunta al QR del producto',
      formats: kLabelScanFormats,
    );
    if (qr == null || !mounted) return;
    // No cerrar un pedido que no corresponde: la etiqueta DEBE ser de ESTA orden.
    // La pertenencia se valida POR ORDEN (QR.o == orden de la parada): sobrevive
    // reimpresiones/revocaciones y, como el QR abierto no lleva firma, NUNCA se
    // rechaza por la firma. Si no se puede saber la orden (Code128), no bloquea.
    if (!_belongsByOrder(qr)) {
      final orderRef = widget.stop.orderReference;
      showInfoSnack(
        context,
        orderRef == null
            ? 'Ese producto es de otro pedido.'
            : 'Ese producto es de otro pedido. Escaneá un producto de $orderRef.',
      );
      return;
    }
    final unitId = await verifyUnitLabel(ref, qr);
    if (!mounted) return;
    if (unitId == null) {
      showInfoSnack(context, 'Etiqueta no válida');
      return;
    }
    // Mismo producto escaneado dos veces (MISMA etiqueta): avisar y no duplicar.
    if (_unitIds.contains(unitId)) {
      showInfoSnack(context, 'Ese producto ya lo escaneaste.');
      return;
    }
    // Guardia anti-DUPLICADOS por SKU: una etiqueta distinta del MISMO producto
    // (misma orden y mismo SKU, otro id) no puede sumar una entrega de más. Si
    // ya se escanearon todas las unidades que el pedido tiene de ese SKU, se
    // rechaza. Solo aplica si se conoce el SKU de la etiqueta (QR) y el pedido
    // lista ese SKU; si no, no bloquea (offline-first, Code128 sin SKU).
    final sku = _skuOf(qr);
    if (sku != null) {
      final expectedForSku = _expectedQtyForSku(sku);
      if (expectedForSku != null) {
        final alreadyForSku = _skuByUnitId.values.where((s) => s == sku).length;
        if (alreadyForSku >= expectedForSku) {
          showInfoSnack(
            context,
            'Ese producto ($sku) ya está completo: esa etiqueta está duplicada.',
          );
          return;
        }
      }
    }
    setState(() {
      _unitIds.add(unitId);
      if (sku != null) _skuByUnitId[unitId] = sku;
    });
  }

  /// SKU de la etiqueta del QR, o `null` si no se puede leer (Code128 sin SKU,
  /// o no es un QR de etiqueta): en ese caso la guardia por SKU no aplica.
  String? _skuOf(String qr) {
    try {
      return SignedLabel.fromQrContent(qr).payload.sku;
    } on LabelFormatException {
      return null;
    }
  }

  /// Cantidad de unidades que el pedido tiene del [sku] (suma de las cantidades
  /// de los ítems con ese SKU), o `null` si el pedido no lista ese SKU (no se
  /// puede acotar por SKU → no bloquea).
  int? _expectedQtyForSku(String sku) {
    final matching = widget.stop.items.where((i) => i.sku == sku);
    if (matching.isEmpty) return null;
    return matching.fold<int>(0, (sum, i) => sum + i.quantity);
  }

  /// Pertenencia POR ORDEN: la etiqueta pertenece a la parada si su `o`
  /// (order_reference del QR) coincide con la orden de la parada. Devuelve
  /// `true` también cuando no se puede determinar (Code128 sin `o`, o la parada
  /// no trae orden): offline-first, nunca se rechaza una etiqueta válida de más.
  bool _belongsByOrder(String qr) {
    final stopOrder = widget.stop.orderReference;
    if (stopOrder == null) return true;
    try {
      return SignedLabel.fromQrContent(qr).payload.orderNumber == stopOrder;
    } on LabelFormatException {
      return true; // no es un QR de etiqueta (Code128): no se puede saber → acepta
    }
  }

  /// Resumen del avance de escaneo para la cabecera de la sección 1.
  String _unitsSummary() {
    final total = _expectedCount;
    if (_unitIds.isEmpty) {
      return total == null
          ? 'Escaneá cada producto a entregar.'
          : 'Escaneá los $total productos del pedido.';
    }
    return total == null
        ? 'Escaneados: ${_unitIds.length}'
        : 'Escaneados ${_unitIds.length} de $total';
  }

  TextStyle? _unitsSummaryStyle(BuildContext context) {
    final complete =
        _expectedCount != null && _unitIds.length >= _expectedCount!;
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: complete ? scheme.primary : null,
      fontWeight: complete ? FontWeight.w600 : null,
    );
  }

  Future<void> _sign() async {
    final png = await captureCustomerSignature(context);
    if (png != null && mounted) {
      setState(() {
        _signature = png;
        _confirmation = kDigitalSignatureConfirmation;
      });
    }
  }

  /// Comparte la firma del cliente por el menú nativo (WhatsApp, correo, etc.).
  Future<void> _shareSignature() async {
    final sig = _signature;
    if (sig == null || _busy) return;
    final cliente = widget.stop.customerName ?? 'Entrega';
    await ref
        .read(shareServiceProvider)
        .shareImagePng(
          sig,
          filename: 'firma_${widget.stop.shipmentId}.png',
          text: 'Firma del cliente · $cliente',
        );
  }

  /// Comparte la foto de evidencia (documento/entrega) por el menú nativo.
  Future<void> _sharePhoto() async {
    final photo = _photo;
    if (photo == null || _busy) return;
    final cliente = widget.stop.customerName ?? 'Entrega';
    await ref
        .read(shareServiceProvider)
        .shareFile(photo.path, text: 'Foto de entrega · $cliente');
  }

  Future<void> _takePhoto() async {
    // Foto reducida (ancho y calidad acotados): en teléfonos de 1 GB una foto
    // de 12 MP a resolución completa ocupa ~48 MB al decodificarse.
    final photo = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _takeDocument() async {
    final doc = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (doc != null && mounted) setState(() => _document = doc);
  }

  Future<void> _shareDocument() async {
    final doc = _document;
    if (doc == null || _busy) return;
    final cliente = widget.stop.customerName ?? 'Cliente';
    await ref
        .read(shareServiceProvider)
        .shareFile(doc.path, text: 'Documento del cliente · $cliente');
  }

  /// Snapshot del cliente para LIGAR la evidencia a su identidad (anti-fraude):
  /// nombre, teléfono, ubicación de captura y momento. El backend cruza el envío
  /// con el cliente; esto deja constancia de a quién dijo el chofer que entregó.
  Map<String, Object?> _clientSnapshot(GpsFix? fix) => {
    if (widget.stop.customerName != null)
      'customer_name': widget.stop.customerName,
    if (widget.stop.customerPhone != null)
      'customer_phone': widget.stop.customerPhone,
    if (fix != null) 'lat': fix.lat,
    if (fix != null) 'lng': fix.lng,
    'captured_at': DateTime.now().toUtc().toIso8601String(),
  };

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      // El GPS se pide primero: su posición va en el snapshot del cliente de la
      // evidencia anti-fraude (firma/documento) y en el POD. Suele salir de la
      // caché (se precalentó al abrir).
      final fix = await currentFix(ref);
      if (!mounted) return;
      final snapshot = _clientSnapshot(fix);
      // La foto, la firma y el documento se encolan aparte y se suben
      // idempotentemente (offline-first). El POD no espera a la subida.
      final enqueue = ref.read(enqueueDeliveryPhotoProvider);
      final photo = _photo;
      if (photo != null) {
        await enqueue(
          shipmentId: widget.stop.shipmentId,
          filePath: photo.path,
          kind: 'pod',
        );
      }
      final document = _document;
      if (document != null) {
        await enqueue(
          shipmentId: widget.stop.shipmentId,
          filePath: document.path,
          kind: kDocumentEvidenceKind,
          clientSnapshot: snapshot,
        );
      }
      final signature = _signature;
      if (signature != null) {
        final store = ref.read(signatureFileStoreProvider);
        try {
          final path = await store.save(signature);
          await enqueue(
            shipmentId: widget.stop.shipmentId,
            filePath: path,
            kind: kSignatureEvidenceKind,
            clientSnapshot: snapshot,
          );
          // La cola ya copió el archivo a su directorio persistente.
          await store.discard(path);
        } on FileSystemException {
          // Sin disco para la imagen no se frena la entrega: el POD viaja
          // igual con el marcador FIRMA_DIGITAL.
        }
      }
      if (!mounted) return;
      final now = DateTime.now();
      // Un POD por CADA producto del pedido (pedido de N productos = N
      // registros).
      // Cada submit lleva su propio Idempotency-Key (lo pone la cola), así que
      // reintentar no duplica. Se cierra la parada solo si TODOS se registraron
      // (encolados cuenta como registrados: offline-first).
      final queue = ref.read(offlineQueueProvider);
      final cliente = widget.stop.customerName ?? 'Entrega';
      final outcomes = <SubmitOutcome>[];
      // Motivo real del PRIMER rechazo del backend (si lo hay), para mostrarlo
      // en vez del genérico "No se pudo registrar". `onReject` solo corre en un
      // 4xx permanente dentro del presupuesto de espera.
      String? rejectDetail;
      for (var i = 0; i < _unitIds.length; i++) {
        outcomes.add(
          await queue.submit(
            onReject: (error) => rejectDetail ??= error.message,
            kind: 'recordProofOfDelivery',
            payload: ProofOfDeliveryRequest(
              shipmentId: widget.stop.shipmentId,
              unitId: _unitIds[i],
              lat: fix?.lat ?? 0,
              lng: fix?.lng ?? 0,
              occurredAt: now,
              confirmation: _confirmation!,
              // La foto va por SU cola (`enqueueDeliveryPhotoProvider`) y el
              // backend la LIGA al envío cuando llega (queda `pod_photo_pending`
              // hasta entonces). NUNCA mandar una ruta inventada: el backend
              // rechaza con 422 (`errors.photo_path`) un `photo_path` que no
              // existe en disco de evidencia. Se OMITE y la entrega sale igual
              // (opción A, offline-first); antes mandaba `'pendiente'` y el POD
              // fallaba con "No se pudo registrar".
              photoPath: null,
            ).toJson(),
            label: _unitIds.length > 1
                ? 'POD · $cliente · producto ${i + 1}/${_unitIds.length}'
                : 'POD · $cliente',
            occurredAt: now,
          ),
        );
      }
      // Veredicto combinado: si alguno falló → falló; si alguno quedó encolado
      // (sin red) → "Registrado."; si todos se enviaron → "Enviado".
      final combined = outcomes.contains(SubmitOutcome.failed)
          ? SubmitOutcome.failed
          : outcomes.contains(SubmitOutcome.queued)
          ? SubmitOutcome.queued
          : SubmitOutcome.sent;
      if (!mounted) return;
      showSubmitOutcome(context, combined, failureDetail: rejectDetail);
      if (combined != SubmitOutcome.failed) {
        // Encolado o enviado: la parada queda resuelta en la UI ya mismo (la
        // entrega en curso pasa a la siguiente aunque no haya señal).
        ref
            .read(locallySettledStopsProvider.notifier)
            .settle(widget.stop.id, DriverRouteStopStatus.completed);
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Una fila de la lista de productos escaneados en el POD: número de orden, id
/// del producto y un botón para quitarlo (por si se escaneó de más).
class _ScannedUnitTile extends StatelessWidget {
  const _ScannedUnitTile({
    required this.index,
    required this.unitId,
    required this.onRemove,
  });

  final int index;
  final String unitId;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(unitId, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Quitar',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const AnimatedAppIcon(AppIcon.close, size: 18),
            ),
        ],
      ),
    );
  }
}
