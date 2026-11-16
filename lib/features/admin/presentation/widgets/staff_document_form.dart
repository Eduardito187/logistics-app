import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/media/photo_picker.dart';

/// Lo que se carga de un documento: tipo, número y sus fotos. Los de dos
/// caras traen [front] y [back]; el resto solo [front].
typedef StaffDocumentForm = ({
  String type,
  String? reference,
  bool twoSides,
  File front,
  File? back,
});

/// Tipos de documento que se ofrecen. Los de dos caras piden anverso y
/// reverso.
const List<({String label, bool twoSides})> staffDocumentTypes = [
  (label: 'Carnet de identidad', twoSides: true),
  (label: 'Licencia de conducir', twoSides: true),
  (label: 'Contrato', twoSides: false),
  (label: 'Certificado médico', twoSides: false),
];

/// Abre el formulario de un documento nuevo. Devuelve `null` si se cancela.
Future<StaffDocumentForm?> showStaffDocumentForm(BuildContext context) =>
    showDialog<StaffDocumentForm>(
      context: context,
      builder: (_) => const Dialog.fullscreen(child: StaffDocumentFormScreen()),
    );

/// Formulario de un documento del personal, en una sola pantalla: tipo (de
/// una lista), número y las fotos. Cada foto es un recuadro que se toca para
/// sacarla y que después muestra su vista previa (se toca de nuevo para
/// cambiarla). El carnet y la licencia muestran DOS recuadros: anverso y
/// reverso. "Guardar documento" va fijo al pie y se habilita cuando está todo.
class StaffDocumentFormScreen extends ConsumerStatefulWidget {
  const StaffDocumentFormScreen({super.key});

  @override
  ConsumerState<StaffDocumentFormScreen> createState() =>
      _StaffDocumentFormScreenState();
}

class _StaffDocumentFormScreenState
    extends ConsumerState<StaffDocumentFormScreen> {
  final TextEditingController _other = TextEditingController();
  final TextEditingController _reference = TextEditingController();

  /// Valor del desplegable para un documento que no está en la lista.
  static const String _otherKey = 'Otro documento';

  String? _type;
  File? _front;
  File? _back;

  @override
  void initState() {
    super.initState();
    _other.addListener(_refresh);
  }

  @override
  void dispose() {
    _other.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _twoSides =>
      staffDocumentTypes.any((t) => t.label == _type && t.twoSides);

  String get _typeName =>
      _type == _otherKey ? _other.text.trim() : (_type ?? '');

  bool get _complete =>
      _typeName.isNotEmpty && _front != null && (!_twoSides || _back != null);

  Future<void> _take({required bool back}) async {
    final photo = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (photo == null || !mounted) return;
    setState(() {
      if (back) {
        _back = File(photo.path);
      } else {
        _front = File(photo.path);
      }
    });
  }

  void _save() {
    final front = _front;
    if (!_complete || front == null) return;
    final reference = _reference.text.trim();
    Navigator.of(context).pop((
      type: _typeName,
      reference: reference.isEmpty ? null : reference,
      twoSides: _twoSides,
      front: front,
      back: _twoSides ? _back : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar documento')),
      bottomNavigationBar: Material(
        elevation: 8,
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _complete ? _save : null,
                icon: const AnimatedAppIcon(
                  AppIcon.save,
                  excludeFromSemantics: true,
                ),
                label: const Text('Guardar documento'),
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
              onChanged: (value) => setState(() {
                _type = value;
                // Un documento de una sola cara no lleva reverso.
                if (!_twoSides) _back = null;
              }),
            ),
            if (_type == _otherKey) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _other,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: '¿Qué documento?'),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _reference,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Número del documento',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _twoSides ? 'Fotos del documento' : 'Foto del documento',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_twoSides)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DocumentPhotoTile(
                      label: 'Anverso',
                      file: _front,
                      onTap: () => _take(back: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DocumentPhotoTile(
                      label: 'Reverso',
                      file: _back,
                      onTap: () => _take(back: true),
                    ),
                  ),
                ],
              )
            else
              DocumentPhotoTile(
                label: 'Foto',
                file: _front,
                wide: true,
                onTap: () => _take(back: false),
              ),
          ],
        ),
      ),
    );
  }
}

/// Recuadro de una foto del documento: vacío invita a tocarlo; con foto
/// muestra la vista previa y se toca para cambiarla.
class DocumentPhotoTile extends StatelessWidget {
  const DocumentPhotoTile({
    super.key,
    required this.label,
    required this.file,
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final File? file;
  final VoidCallback onTap;

  /// Un solo recuadro a todo el ancho (documentos de una cara).
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photo = file;
    final taken = photo != null;
    return Semantics(
      button: true,
      label: taken ? '$label, foto lista. Tocar para cambiarla' : label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: wide ? 16 / 9 : 4 / 3,
              child: Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: taken ? scheme.primary : scheme.outlineVariant,
                    width: taken ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: taken
                      ? Image.file(
                          photo,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                          errorBuilder: (_, _, _) => const Center(
                            child: AnimatedAppIcon(
                              AppIcon.capture,
                              state: AppIconState.success,
                              size: 36,
                            ),
                          ),
                        )
                      : Center(
                          child: AnimatedAppIcon(
                            AppIcon.capture,
                            size: 36,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              taken ? 'Tocá para cambiarla' : 'Tocá para sacarla',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
