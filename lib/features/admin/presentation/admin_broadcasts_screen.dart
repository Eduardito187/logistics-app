import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/paged_search_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../notifications/presentation/widgets/inbox_item_card.dart';
import '../data/admin_remote_data_source.dart';
import 'staff_labels.dart';
import 'widgets/staff_pickers.dart';

/// A quién va el aviso.
enum BroadcastAudience { role, node, person }

/// Persona destinataria (cuando se abre desde su ficha).
typedef BroadcastPerson = ({int userId, String name});

/// Avisos al personal: enviar a **todos los de un rol** (p. ej. todos los
/// choferes), a **una tienda** o a **una persona**, y ver lo ya enviado. El
/// aviso llega como notificación al teléfono y queda en la bandeja de cada uno.
class AdminBroadcastsScreen extends StatelessWidget {
  const AdminBroadcastsScreen({super.key, this.person});

  /// Si viene, el aviso es solo para esa persona.
  final BroadcastPerson? person;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Avisos al personal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Enviar'),
              Tab(text: 'Enviados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SendTab(person: person),
            const _SentTab(),
          ],
        ),
      ),
    );
  }
}

class _SendTab extends ConsumerStatefulWidget {
  const _SendTab({this.person});

  final BroadcastPerson? person;

  @override
  ConsumerState<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends ConsumerState<_SendTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  late BroadcastAudience _audience = widget.person == null
      ? BroadcastAudience.role
      : BroadcastAudience.person;
  StaffRoleName _role = StaffRoleName.chofer;
  NodeChoice? _node;
  bool _busy = false;

  static const List<StaffRoleName> _roles = [
    StaffRoleName.chofer,
    StaffRoleName.preparador,
    StaffRoleName.tienda,
    StaffRoleName.transportista,
    StaffRoleName.supervisor,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // La vista previa se arma con lo que se va escribiendo.
    _title.addListener(_refresh);
    _body.addListener(_refresh);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _pickNode() async {
    final choice = await showNodePickerSheet(
      context,
      currentNodeId: _node?.nodeId,
    );
    if (choice != null && mounted) setState(() => _node = choice);
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      showInfoSnack(context, 'Escribí el título y el mensaje.');
      return;
    }
    final node = _node;
    if (_audience == BroadcastAudience.node && node?.nodeId == null) {
      showInfoSnack(context, 'Elegí la tienda.');
      return;
    }
    setState(() => _busy = true);
    try {
      final recipients = await ref
          .read(adminRemoteDataSourceProvider)
          .sendBroadcast(
            title: title,
            body: body,
            role: _audience == BroadcastAudience.role ? _role : null,
            nodeId: _audience == BroadcastAudience.node ? node?.nodeId : null,
            userIds: _audience == BroadcastAudience.person
                ? [widget.person!.userId]
                : null,
          );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      showSuccessSnack(
        context,
        recipients == 1
            ? 'Aviso enviado a 1 persona.'
            : 'Aviso enviado a $recipients personas.',
      );
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final person = widget.person;
    final title = _title.text.trim();
    final body = _body.text.trim();
    const gap = SizedBox(height: 16);
    return Column(
      children: [
        Expanded(
          child: ResponsiveBody(
            maxWidth: AppBreakpoints.maxFormWidth,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: 'Para quién',
                  child: person != null
                      ? Row(
                          children: [
                            const AnimatedAppIcon(
                              AppIcon.profile,
                              excludeFromSemantics: true,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                person.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<BroadcastAudience>(
                              value: _audience,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Enviar a',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: BroadcastAudience.role,
                                  child: Text('Todos los de un rol'),
                                ),
                                DropdownMenuItem(
                                  value: BroadcastAudience.node,
                                  child: Text('El personal de una tienda'),
                                ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) => setState(
                                      () => _audience =
                                          value ?? BroadcastAudience.role,
                                    ),
                            ),
                            gap,
                            if (_audience == BroadcastAudience.role)
                              DropdownButtonFormField<StaffRoleName>(
                                value: _role,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Rol',
                                ),
                                items: [
                                  for (final role in _roles)
                                    DropdownMenuItem(
                                      value: role,
                                      child: Text(
                                        staffRoleLabel(role.json ?? ''),
                                      ),
                                    ),
                                ],
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(
                                        () => _role = value ?? _role,
                                      ),
                              )
                            else
                              InkWell(
                                onTap: _busy ? null : _pickNode,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Tienda',
                                    suffixIcon: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: AnimatedAppIcon(
                                        AppIcon.expandMore,
                                        excludeFromSemantics: true,
                                      ),
                                    ),
                                  ),
                                  child: Text(_node?.name ?? 'Elegir tienda'),
                                ),
                              ),
                          ],
                        ),
                ),
                gap,
                SectionCard(
                  title: 'Mensaje',
                  child: Column(
                    children: [
                      TextField(
                        controller: _title,
                        enabled: !_busy,
                        maxLength: 120,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Título'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _body,
                        enabled: !_busy,
                        maxLength: 1000,
                        minLines: 4,
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Mensaje',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (title.isNotEmpty || body.isNotEmpty) ...[
                  gap,
                  Text(
                    'Así lo va a ver',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // La misma tarjeta que ve el personal en sus notificaciones.
                  IgnorePointer(
                    child: InboxItemCard(
                      item: StaffInboxItem(
                        title: title.isEmpty ? 'Título' : title,
                        body: body.isEmpty ? null : body,
                        sentAt: DateTime.now(),
                      ),
                      read: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // FIJO al pie: no hay que deslizar para enviar.
        Material(
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
                  onPressed: _busy ? null : _send,
                  icon: AnimatedAppIcon(
                    AppIcon.send,
                    state: _busy ? AppIconState.loading : AppIconState.idle,
                    excludeFromSemantics: true,
                  ),
                  label: const Text('Enviar aviso'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avisos ya enviados, con a cuántos llegó y cuántos lo leyeron.
class _SentTab extends ConsumerStatefulWidget {
  const _SentTab();

  @override
  ConsumerState<_SentTab> createState() => _SentTabState();
}

class _SentTabState extends ConsumerState<_SentTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedSearchList<StaffBroadcast>(
      showSearch: false,
      emptyTitle: 'Todavía no enviaste avisos',
      emptyIcon: AppIcon.send,
      fetch: (_, page) =>
          ref.read(adminRemoteDataSourceProvider).listBroadcasts(page),
      itemBuilder: (context, item) => _SentCard(item: item),
    );
  }
}

/// Un aviso enviado: el mensaje completo, cuándo y quién lo envió, y una
/// barra con cuántos ya lo leyeron.
class _SentCard extends StatelessWidget {
  const _SentCard({required this.item});

  final StaffBroadcast item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recipients = item.recipientCount ?? 0;
    final read = (item.readCount ?? 0).clamp(0, recipients);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title ?? 'Aviso',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (item.body != null) ...[
            const SizedBox(height: 6),
            Text(item.body!),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: recipients == 0 ? 0 : read / recipients,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Leído por $read de $recipients',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (item.sentAt != null) inboxWhen(item.sentAt!),
              if (item.sentBy?.name != null) 'Envió ${item.sentBy!.name}',
            ].join(' · '),
            style: muted,
          ),
        ],
      ),
    );
  }
}
