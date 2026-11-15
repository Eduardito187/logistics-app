import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/admin_remote_data_source.dart';
import '../staff_labels.dart';
import '../../../../core/widgets/paged_search_list.dart';

/// Abre un archivo de la ficha. Los enlaces son temporales y firmados: se abren
/// tal cual, sin cabecera de sesión. Imagen → visor en la app; otro tipo (PDF)
/// → app externa.
Future<void> openStaffFile(
  BuildContext context, {
  required String url,
  required bool isImage,
  String? title,
}) async {
  if (isImage) {
    await showDialog<void>(
      context: context,
      builder: (_) => _ImageViewer(url: url, title: title),
    );
    return;
  }
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    showErrorSnack(context, 'No se pudo abrir el archivo.');
  }
}

/// Visor de una imagen a pantalla completa, con zoom.
class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url, this.title});

  final String url;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(title: Text(title ?? 'Imagen')),
        body: InteractiveViewer(
          child: Center(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No se pudo cargar la imagen.'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pestaña "Documentos": carnet, licencia, contrato… con vencimiento. Permite
/// sumar un documento sacándole una foto.
class StaffDocumentsTab extends ConsumerStatefulWidget {
  const StaffDocumentsTab({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<StaffDocumentsTab> createState() => _StaffDocumentsTabState();
}

class _StaffDocumentsTabState extends ConsumerState<StaffDocumentsTab>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<PagedSearchListState<StaffDocument>> _list = GlobalKey();
  bool _uploading = false;

  @override
  bool get wantKeepAlive => true;

  Future<XFile?> _takePhoto() => ref.read(photoPickerProvider)(
    maxWidth: kEvidencePhotoMaxWidth,
    imageQuality: kEvidencePhotoQuality,
  );

  /// Pide tipo y número, y saca la foto. El carnet y la licencia llevan DOS
  /// fotos (anverso y reverso): se guardan como dos archivos del mismo
  /// documento, cada uno con su lado.
  Future<void> _add() async {
    final form = await showDialog<StaffDocumentForm>(
      context: context,
      builder: (_) => const _DocumentDialog(),
    );
    if (form == null || !mounted) return;
    final front = await _takePhoto();
    if (front == null || !mounted) return;
    XFile? back;
    if (form.twoSides) {
      final goOn = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Ahora el reverso'),
          content: const Text('Dale vuelta al documento y sacá la otra foto.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sacar foto del reverso'),
            ),
          ],
        ),
      );
      if (goOn != true || !mounted) return;
      back = await _takePhoto();
      // Sin el reverso no se guarda nada: el documento quedaría a medias.
      if (back == null || !mounted) return;
    }
    setState(() => _uploading = true);
    try {
      final source = ref.read(adminRemoteDataSourceProvider);
      await source.uploadStaffDocument(
        widget.userId,
        documentType: form.type,
        reference: form.reference,
        side: form.twoSides ? StaffDocumentSide.front : null,
        file: File(front.path),
      );
      if (back != null) {
        await source.uploadStaffDocument(
          widget.userId,
          documentType: form.type,
          reference: form.reference,
          side: StaffDocumentSide.back,
          file: File(back.path),
        );
      }
      if (!mounted) return;
      showSuccessSnack(context, 'Documento guardado.');
      unawaited(_list.currentState?.reload());
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _add,
              icon: AnimatedAppIcon(
                AppIcon.capture,
                state: _uploading ? AppIconState.loading : AppIconState.idle,
                excludeFromSemantics: true,
              ),
              label: const Text('Agregar documento'),
            ),
          ),
        ),
        Expanded(
          child: PagedSearchList<StaffDocument>(
            key: _list,
            showSearch: false,
            emptyTitle: 'Sin documentos',
            emptyIcon: AppIcon.badge,
            fetch: (_, page) => ref
                .read(adminRemoteDataSourceProvider)
                .listStaffDocuments(widget.userId, page),
            itemBuilder: (context, doc) => _DocumentCard(document: doc),
          ),
        ),
      ],
    );
  }
}

/// Lo que se carga de un documento antes de fotografiarlo.
typedef StaffDocumentForm = ({String type, String? reference, bool twoSides});

/// Tipos de documento que se ofrecen. Los de dos caras piden anverso y
/// reverso.
const List<({String label, bool twoSides})> staffDocumentTypes = [
  (label: 'Carnet de identidad', twoSides: true),
  (label: 'Licencia de conducir', twoSides: true),
  (label: 'Contrato', twoSides: false),
  (label: 'Certificado médico', twoSides: false),
];

/// Pide el tipo (de una lista) y el número del documento antes de sacarle la
/// foto.
class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog();

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  final TextEditingController _other = TextEditingController();
  final TextEditingController _reference = TextEditingController();

  /// Valor del desplegable para un documento que no está en la lista.
  static const String _otherKey = 'Otro documento';

  String? _type;

  @override
  void dispose() {
    _other.dispose();
    _reference.dispose();
    super.dispose();
  }

  bool get _twoSides =>
      staffDocumentTypes.any((t) => t.label == _type && t.twoSides);

  void _accept() {
    final type = _type == _otherKey ? _other.text.trim() : (_type ?? '');
    if (type.isEmpty) return;
    final reference = _reference.text.trim();
    Navigator.of(context).pop((
      type: type,
      reference: reference.isEmpty ? null : reference,
      twoSides: _twoSides,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar documento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
              items: [
                for (final type in staffDocumentTypes)
                  DropdownMenuItem(value: type.label, child: Text(type.label)),
                const DropdownMenuItem(
                  value: _otherKey,
                  child: Text(_otherKey),
                ),
              ],
              onChanged: (value) => setState(() => _type = value),
            ),
            if (_type == _otherKey) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _other,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: '¿Qué documento?'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _reference,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Número del documento',
              ),
            ),
            if (_twoSides) ...[
              const SizedBox(height: 12),
              const Text('Se piden dos fotos: anverso y reverso.'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _type == null ? null : _accept,
          child: Text(_twoSides ? 'Sacar foto del anverso' : 'Sacar foto'),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final StaffDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = document.url;
    final isImage = (document.mimeType ?? '').startsWith('image/');
    final expires = document.expiresOn;
    final title = staffDocumentTitle(document);
    return SectionCard(
      onTap: url == null
          ? null
          : () => openStaffFile(
              context,
              url: url,
              isImage: isImage,
              title: title,
            ),
      child: Row(
        children: [
          AnimatedAppIcon(isImage ? AppIcon.image : AppIcon.badge, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [title, ?staffSideLabel(document.side)].join(' · '),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (document.reference != null)
                  Text('Nº ${document.reference}'),
                if (expires != null) ...[
                  const SizedBox(height: 6),
                  StatusPill(
                    '${document.expired == true ? 'Venció' : 'Vence'} el '
                    '${staffDate(expires)}',
                    tone: document.expired == true
                        ? PillTone.danger
                        : PillTone.success,
                  ),
                ],
                if (url == null)
                  Text(
                    'Sin archivo adjunto',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (url != null)
            const AnimatedAppIcon(
              AppIcon.chevronRight,
              excludeFromSemantics: true,
            ),
        ],
      ),
    );
  }
}

/// Pestaña "Actividad": historial de lo que hizo la persona, según su rol
/// (escaneos, asignaciones de camión, inspecciones, conexiones).
class StaffActivityTab extends ConsumerStatefulWidget {
  const StaffActivityTab({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<StaffActivityTab> createState() => _StaffActivityTabState();
}

class _StaffActivityTabState extends ConsumerState<StaffActivityTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedSearchList<StaffActivity>(
      showSearch: false,
      emptyTitle: 'Sin actividad registrada',
      emptyIcon: AppIcon.orders,
      fetch: (_, page) => ref
          .read(adminRemoteDataSourceProvider)
          .listStaffActivity(widget.userId, page),
      itemBuilder: (context, activity) => Card(
        child: ListTile(
          leading: AnimatedAppIcon(_icon(activity.type)),
          title: Text(
            staffActivityTitle(activity),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              if (activity.detail != null && activity.detail!.isNotEmpty)
                activity.detail!,
              if (activity.at != null) staffDateTime(activity.at!),
            ].join('\n'),
          ),
          isThreeLine: activity.detail != null && activity.at != null,
        ),
      ),
    );
  }

  static AppIcon _icon(StaffActivityType? type) => switch (type) {
    StaffActivityType.scan => AppIcon.scan,
    StaffActivityType.assignment => AppIcon.deliver,
    StaffActivityType.checklist => AppIcon.checklist,
    StaffActivityType.device => AppIcon.devices,
    _ => AppIcon.orders,
  };
}

/// Pestaña "Fotos": la foto de perfil, las de documentos y la evidencia que
/// subió la persona (entregas, daños).
class StaffPhotosTab extends ConsumerStatefulWidget {
  const StaffPhotosTab({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<StaffPhotosTab> createState() => _StaffPhotosTabState();
}

class _StaffPhotosTabState extends ConsumerState<StaffPhotosTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedSearchList<StaffPhoto>(
      showSearch: false,
      emptyTitle: 'Sin fotos',
      emptyIcon: AppIcon.image,
      fetch: (_, page) => ref
          .read(adminRemoteDataSourceProvider)
          .listStaffPhotos(widget.userId, page),
      itemBuilder: (context, photo) => _PhotoCard(photo: photo),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo});

  final StaffPhoto photo;

  @override
  Widget build(BuildContext context) {
    final url = photo.url;
    // El backend manda un código en `label`: se muestra en español.
    final title = switch (photo.kind) {
      StaffPhotoKind.profile => 'Foto de perfil',
      StaffPhotoKind.document => [
        photo.label ?? 'Documento',
        ?staffSideLabel(photo.side),
      ].join(' · '),
      _ => 'Foto',
    };
    return SectionCard(
      onTap: url == null
          ? null
          : () => openStaffFile(context, url: url, isImage: true, title: title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 180,
                fit: BoxFit.cover,
                // Miniatura: no se decodifica la foto a resolución completa.
                cacheWidth: 800,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 80,
                  child: Center(
                    child: AnimatedAppIcon(AppIcon.image, size: 40),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (photo.at != null) Text(staffDateTime(photo.at!)),
        ],
      ),
    );
  }
}
