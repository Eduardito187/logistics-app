import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _add() async {
    final type = await showDialog<String>(
      context: context,
      builder: (_) => const _DocumentTypeDialog(),
    );
    if (type == null || !mounted) return;
    final photo = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (photo == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await ref
          .read(adminRemoteDataSourceProvider)
          .uploadStaffDocument(
            widget.userId,
            documentType: type,
            file: File(photo.path),
          );
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

/// Pide el tipo del documento antes de sacarle la foto.
class _DocumentTypeDialog extends StatefulWidget {
  const _DocumentTypeDialog();

  @override
  State<_DocumentTypeDialog> createState() => _DocumentTypeDialogState();
}

class _DocumentTypeDialogState extends State<_DocumentTypeDialog> {
  final TextEditingController _type = TextEditingController();

  static const List<String> _suggested = [
    'Carnet de identidad',
    'Licencia de conducir',
    'Contrato',
    'Certificado médico',
  ];

  @override
  void dispose() {
    _type.dispose();
    super.dispose();
  }

  void _accept() {
    final value = _type.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Qué documento es?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in _suggested)
                ActionChip(
                  label: Text(option),
                  onPressed: () => setState(() => _type.text = option),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _type,
            onSubmitted: (_) => _accept(),
            decoration: const InputDecoration(labelText: 'Tipo de documento'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _accept, child: const Text('Sacar foto')),
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
                  title,
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
    final title =
        photo.label ??
        switch (photo.kind) {
          StaffPhotoKind.profile => 'Foto de perfil',
          StaffPhotoKind.document => 'Documento',
          StaffPhotoKind.evidence => 'Evidencia de entrega',
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
