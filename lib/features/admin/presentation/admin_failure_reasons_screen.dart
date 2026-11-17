import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/catalog/failure_reason_option.dart';
import '../../../core/catalog/failure_reasons_repository.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';

/// Administración de los MOTIVOS de "no se pudo entregar".
///
/// El admin crea motivos, los muestra/oculta (activar-desactivar) y, por cada
/// uno, decide si al elegirlo el chofer debe adjuntar **foto** y/o escribir un
/// **texto**. El `code` (identificador que viaja al backend) nunca se muestra:
/// se genera solo a partir del nombre.
class AdminFailureReasonsScreen extends ConsumerStatefulWidget {
  const AdminFailureReasonsScreen({super.key});

  @override
  ConsumerState<AdminFailureReasonsScreen> createState() =>
      _AdminFailureReasonsScreenState();
}

class _AdminFailureReasonsScreenState
    extends ConsumerState<AdminFailureReasonsScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminFailureReasonsProvider);
      // Espera a la recarga para que la lista refleje el cambio al soltar el
      // indicador de ocupado.
      await ref.read(adminFailureReasonsProvider.future);
      if (mounted) showSuccessSnack(context, okMessage);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive(FailureReasonOption option, bool active) =>
      _run(
        () => ref
            .read(failureReasonsRepositoryProvider)
            .update(option.copyWith(active: active)),
        active ? 'Motivo activado.' : 'Motivo oculto.',
      );

  Future<void> _create(List<FailureReasonOption> current) async {
    final taken = {for (final o in current) o.code};
    final maxOrder = current.fold<int>(
      -1,
      (m, o) => o.sortOrder > m ? o.sortOrder : m,
    );
    final created = await _showEditSheet(
      initial: null,
      takenCodes: taken,
      nextOrder: maxOrder + 1,
    );
    if (created == null) return;
    await _run(
      () => ref.read(failureReasonsRepositoryProvider).create(created),
      'Motivo creado.',
    );
  }

  Future<void> _edit(
    FailureReasonOption option,
    List<FailureReasonOption> current,
  ) async {
    final taken = {for (final o in current) o.code}..remove(option.code);
    final edited = await _showEditSheet(
      initial: option,
      takenCodes: taken,
      nextOrder: option.sortOrder,
    );
    if (edited == null) return;
    await _run(
      () => ref.read(failureReasonsRepositoryProvider).update(edited),
      'Motivo guardado.',
    );
  }

  Future<FailureReasonOption?> _showEditSheet({
    required FailureReasonOption? initial,
    required Set<String> takenCodes,
    required int nextOrder,
  }) => showModalBottomSheet<FailureReasonOption>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReasonEditSheet(
      initial: initial,
      takenCodes: takenCodes,
      nextOrder: nextOrder,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminFailureReasonsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Motivos de no entrega')),
      body: AsyncValueView<List<FailureReasonOption>>(
        value: async,
        onRetry: () => ref.invalidate(adminFailureReasonsProvider),
        data: (reasons) {
          if (reasons.isEmpty) {
            return const EmptyState(
              icon: AppIcon.cancel,
              title: 'Todavía no hay motivos',
              message: 'Agregá el primero con el botón de abajo.',
            );
          }
          return ResponsiveBody(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reasons.length,
              itemBuilder: (context, i) => _ReasonTile(
                option: reasons[i],
                busy: _busy,
                onToggle: (active) => _toggleActive(reasons[i], active),
                onTap: () => _edit(reasons[i], reasons),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _BottomBar(
        busy: _busy,
        onPressed: () {
          final reasons = ref.read(adminFailureReasonsProvider).value;
          if (reasons != null) _create(reasons);
        },
      ),
    );
  }
}

/// Una fila del catálogo: nombre, qué exige y un switch para mostrar/ocultar.
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.option,
    required this.busy,
    required this.onToggle,
    required this.onTap,
  });

  final FailureReasonOption option;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = <String>[
      if (option.requiresPhoto) 'Pide foto',
      if (option.requiresNote) 'Pide texto',
    ];
    return SectionCard(
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label.isEmpty ? 'Sin nombre' : option.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: option.active
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tags.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (!option.active) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Oculto · no se le muestra al chofer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: option.active,
                onChanged: busy ? null : onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onPressed,
              icon: AnimatedAppIcon(
                AppIcon.add,
                state: busy ? AppIconState.loading : AppIconState.idle,
                excludeFromSemantics: true,
              ),
              label: const Text('Agregar motivo'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoja (bottom sheet) para crear o editar un motivo. El `code` no se muestra:
/// en alta se genera del nombre; en edición se conserva.
class _ReasonEditSheet extends StatefulWidget {
  const _ReasonEditSheet({
    required this.initial,
    required this.takenCodes,
    required this.nextOrder,
  });

  final FailureReasonOption? initial;
  final Set<String> takenCodes;
  final int nextOrder;

  @override
  State<_ReasonEditSheet> createState() => _ReasonEditSheetState();
}

class _ReasonEditSheetState extends State<_ReasonEditSheet> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initial?.label ?? '',
  );
  late final TextEditingController _noteLabel = TextEditingController(
    text: widget.initial?.noteLabel ?? '',
  );
  late bool _active = widget.initial?.active ?? true;
  late bool _requiresPhoto = widget.initial?.requiresPhoto ?? false;
  late bool _requiresNote = widget.initial?.requiresNote ?? false;

  bool get _isNew => widget.initial == null;

  @override
  void dispose() {
    _label.dispose();
    _noteLabel.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty) {
      showInfoSnack(context, 'Escribí el nombre del motivo.');
      return;
    }
    final note = _noteLabel.text.trim();
    final code = _isNew
        ? _uniqueCode(_slugify(label), widget.takenCodes)
        : widget.initial!.code;
    final option = FailureReasonOption(
      code: code,
      label: label,
      active: _active,
      requiresPhoto: _requiresPhoto,
      requiresNote: _requiresNote,
      noteLabel: _requiresNote && note.isNotEmpty ? note : null,
      sortOrder: widget.initial?.sortOrder ?? widget.nextOrder,
    );
    Navigator.of(context).pop(option);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      // La hoja mide lo que su contenido y sube con el teclado (sin aire abajo).
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isNew ? 'Nuevo motivo' : 'Editar motivo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            autofocus: _isNew,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del motivo',
              hintText: 'Ej.: Zona insegura',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar al chofer'),
            subtitle: const Text('Si lo ocultás, no aparece en la lista'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pedir foto'),
            subtitle: const Text('La foto será obligatoria con este motivo'),
            value: _requiresPhoto,
            onChanged: (v) => setState(() => _requiresPhoto = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pedir un texto'),
            subtitle: const Text('El chofer tendrá que escribir una nota'),
            value: _requiresNote,
            onChanged: (v) => setState(() => _requiresNote = v),
          ),
          if (_requiresNote) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _noteLabel,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Qué preguntarle (opcional)',
                hintText: 'Ej.: ¿Qué pasó?',
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const AnimatedAppIcon(
                AppIcon.check,
                excludeFromSemantics: true,
              ),
              label: Text(_isNew ? 'Crear motivo' : 'Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convierte un nombre en un `code` estable: sin acentos, MAYÚSCULAS y `_`.
String _slugify(String label) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = label.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  var slug = buffer
      .toString()
      .toUpperCase()
      .replaceAll(RegExp('[^A-Z0-9]+'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (slug.isEmpty) slug = 'MOTIVO';
  return slug;
}

/// Asegura que el [base] no choque con un code existente (agrega `_2`, `_3`…).
String _uniqueCode(String base, Set<String> taken) {
  if (!taken.contains(base)) return base;
  var i = 2;
  while (taken.contains('${base}_$i')) {
    i++;
  }
  return '${base}_$i';
}
