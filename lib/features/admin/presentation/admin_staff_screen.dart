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

  /// Filtro por ciudad: `null` = todas.
  Department? _city;

  /// Solo el personal al que todavía no se le asignó ciudad.
  bool _withoutCity = false;

  /// Valor del desplegable para "Sin ciudad asignada".
  static const String _noCity = '-';

  static const List<Role> _filters = [
    Role.chofer,
    Role.preparador,
    Role.tienda,
    Role.transportista,
    Role.supervisor,
    Role.planificador,
    Role.admin,
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
        filterKey: (_role, _city, _withoutCity),
        filters: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Role?>(
              value: _role,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: [
                const DropdownMenuItem(child: Text('Todos los roles')),
                for (final role in _filters)
                  DropdownMenuItem(
                    value: role,
                    child: Text(staffRoleLabel(role.json ?? '')),
                  ),
              ],
              onChanged: (value) => setState(() => _role = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _withoutCity ? _noCity : (_city?.json ?? ''),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ciudad'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todas las ciudades'),
                ),
                for (final department in staffDepartments)
                  DropdownMenuItem(
                    value: department.json,
                    child: Text(departmentLabel(department)),
                  ),
                const DropdownMenuItem(
                  value: _noCity,
                  child: Text('Sin ciudad asignada'),
                ),
              ],
              onChanged: (value) => setState(() {
                _withoutCity = value == _noCity;
                _city = _withoutCity ? null : departmentOf(value);
              }),
            ),
          ],
        ),
        fetch: (query, page) => ref
            .read(adminRemoteDataSourceProvider)
            .listStaff(
              query: query,
              role: _role,
              city: _city,
              withoutCity: _withoutCity,
              page: page,
            ),
        itemBuilder: (context, member) => _StaffCard(member: member),
      ),
    );
  }
}

/// Tarjeta de una persona: foto/inicial, nombre, rol, ciudad y tienda.
class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = member.id;
    final place = [
      member.cityName ?? 'Sin ciudad',
      member.node?.name ?? 'Sin tienda asignada',
    ].join(' · ');
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
                  place,
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
