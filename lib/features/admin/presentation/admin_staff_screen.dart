import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/widgets/section_card.dart';
import '../data/admin_remote_data_source.dart';
import 'staff_labels.dart';
import '../../../core/widgets/paged_search_list.dart';
import 'widgets/staff_avatar.dart';

/// Personal de la app para el administrador: buscar por nombre o correo y
/// filtrar por rol. Cada persona abre SU ficha (la misma vista para todos los
/// roles; el contenido cambia según el rol).
class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  /// `null` = todos los roles.
  Role? _role;

  static const List<Role> _filters = [
    Role.chofer,
    Role.preparador,
    Role.tienda,
    Role.transportista,
    Role.supervisor,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal')),
      body: PagedSearchList<StaffMember>(
        searchLabel: 'Buscar persona',
        searchHint: 'Nombre o correo',
        emptyTitle: 'Sin personal',
        emptyIcon: AppIcon.profile,
        filterKey: _role,
        filters: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('Todos', null),
              for (final role in _filters)
                _chip(staffRoleLabel(role.json ?? ''), role),
            ],
          ),
        ),
        fetch: (query, page) => ref
            .read(adminRemoteDataSourceProvider)
            .listStaff(query: query, role: _role, page: page),
        itemBuilder: (context, member) => _StaffCard(member: member),
      ),
    );
  }

  Widget _chip(String label, Role? role) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _role == role,
      onSelected: (_) => setState(() => _role = role),
    ),
  );
}

/// Tarjeta de una persona: foto/inicial, nombre, rol y tienda.
class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = member.id;
    final node = member.node?.name;
    return SectionCard(
      onTap: () => context.push('/admin/staff/$id'),
      child: Row(
        children: [
          StaffAvatar(name: member.name, photoUrl: member.photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  staffRolesText(member.roles),
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  node ?? 'Sin tienda asignada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const AnimatedAppIcon(
            AppIcon.chevronRight,
            excludeFromSemantics: true,
          ),
        ],
      ),
    );
  }
}
