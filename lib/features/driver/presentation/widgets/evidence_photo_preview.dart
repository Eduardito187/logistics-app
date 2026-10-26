import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Ancho de decodificación de la vista previa de la foto (px). La vista previa
/// mide 180 dp de alto; 800 px alcanza con nitidez sin cargar la foto entera.
const int kEvidencePreviewCacheWidth = 800;

/// Alto de decodificación de la vista previa de la firma (px): el recuadro
/// mide ~104 dp útiles; 3x alcanza para pantallas de alta densidad.
const int kSignaturePreviewCacheHeight = 312;

/// Vista previa de la foto de evidencia: decodificada a
/// [kEvidencePreviewCacheWidth] (no a la resolución de la cámara) y, al
/// cambiar de foto o salir de la pantalla, se saca del caché de imágenes (en
/// teléfonos de 1 GB no tiene sentido retener ~2 MB por foto ya encolada).
class EvidencePhotoPreview extends StatefulWidget {
  const EvidencePhotoPreview({super.key, required this.path});

  /// Ruta del archivo de la foto en disco.
  final String path;

  @override
  State<EvidencePhotoPreview> createState() => _EvidencePhotoPreviewState();
}

class _EvidencePhotoPreviewState extends State<EvidencePhotoPreview> {
  late ImageProvider _image = _providerFor(widget.path);

  static ImageProvider _providerFor(String path) =>
      ResizeImage(FileImage(File(path)), width: kEvidencePreviewCacheWidth);

  @override
  void didUpdateWidget(EvidencePhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      unawaited(_image.evict());
      _image = _providerFor(widget.path);
    }
  }

  @override
  void dispose() {
    unawaited(_image.evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: _image,
        height: 180,
        fit: BoxFit.cover,
        semanticLabel: 'Foto adjunta',
        errorBuilder: (context, _, _) => const _PreviewError(height: 180),
      ),
    );
  }
}

/// Vista previa de la firma del cliente (PNG en memoria), decodificada chica y
/// liberada del caché al cambiar de firma o salir de la pantalla.
class SignaturePreview extends StatefulWidget {
  const SignaturePreview({super.key, required this.png});

  final Uint8List png;

  @override
  State<SignaturePreview> createState() => _SignaturePreviewState();
}

class _SignaturePreviewState extends State<SignaturePreview> {
  late ImageProvider _image = _providerFor(widget.png);

  static ImageProvider _providerFor(Uint8List png) => ResizeImage(
    MemoryImage(png),
    height: kSignaturePreviewCacheHeight,
    policy: ResizeImagePolicy.fit,
  );

  @override
  void didUpdateWidget(SignaturePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.png, widget.png)) {
      unawaited(_image.evict());
      _image = _providerFor(widget.png);
    }
  }

  @override
  void dispose() {
    unawaited(_image.evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _image,
      fit: BoxFit.contain,
      semanticLabel: 'Firma del cliente',
      errorBuilder: (context, _, _) => const _PreviewError(),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
          semanticLabel: 'No se pudo mostrar la imagen',
        ),
      ),
    );
  }
}
