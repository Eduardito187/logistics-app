import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../data/admin_remote_data_source.dart';
import 'staff_labels.dart';
import '../../../core/widgets/paged_search_list.dart';
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
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
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
    final person = widget.person;
    return ResponsiveBody(
      maxWidth: AppBreakpoints.maxFormWidth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Para quién',
            child: person != null
                ? Text(
                    person.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<BroadcastAudience>(
                        segments: const [
                          ButtonSegment(
                            value: BroadcastAudience.role,
                            label: Text('Un rol'),
                          ),
                          ButtonSegment(
                            value: BroadcastAudience.node,
                            label: Text('Una tienda'),
                          ),
                        ],
                        selected: {_audience},
                        onSelectionChanged: _busy
                            ? null
                            : (s) => setState(() => _audience = s.first),
                      ),
                      const SizedBox(height: 12),
                      if (_audience == BroadcastAudience.role)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final role in _roles)
                              ChoiceChip(
                                label: Text(staffRoleLabel(role.json ?? '')),
                                selected: _role == role,
                                onSelected: _busy
                                    ? null
                                    : (_) => setState(() => _role = role),
                              ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  final choice = await showNodePickerSheet(
                                    context,
                                    currentNodeId: _node?.nodeId,
                                  );
                                  if (choice != null && mounted) {
                                    setState(() => _node = choice);
                                  }
                                },
                          icon: const AnimatedAppIcon(AppIcon.pickupStore),
                          label: Text(_node?.name ?? 'Elegir tienda'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Mensaje',
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  enabled: !_busy,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _body,
                  enabled: !_busy,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Mensaje'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
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
        ],
      ),
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
      itemBuilder: (context, item) {
        final theme = Theme.of(context);
        final recipients = item.recipientCount ?? 0;
        final read = item.readCount ?? 0;
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
                const SizedBox(height: 4),
                Text(item.body!, maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Text(
                [
                  if (item.sentAt != null) staffDateTime(item.sentAt!),
                  'Leído por $read de $recipients',
                  if (item.sentBy?.name != null) 'Envió ${item.sentBy!.name}',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
