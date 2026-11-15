import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/admin_remote_data_source.dart';
import 'staff_labels.dart';
import 'widgets/staff_avatar.dart';
import 'widgets/staff_pickers.dart';
import 'widgets/staff_tabs.dart';

/// Ficha completa de una persona (se vuelve a pedir tras cada asignación).
final adminStaffProfileProvider = FutureProvider.autoDispose
    .family<StaffProfile, int>(
      (ref, userId) =>
          ref.watch(adminRemoteDataSourceProvider).getStaff(userId),
    );

/// Ficha del personal: UNA vista para todos los roles, por pestañas.
///
/// - **Datos:** identidad, tienda asignada y, si es chofer, licencia y camión
///   (asignar / cambiar / quitar desde acá).
/// - **Documentos**, **Actividad** y **Fotos:** cada una paginada y cargada
///   recién al abrir su pestaña.
class AdminStaffProfileScreen extends ConsumerWidget {
  const AdminStaffProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(adminStaffProfileProvider(userId));
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile.value?.name ?? 'Personal'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Datos'),
              Tab(text: 'Documentos'),
              Tab(text: 'Actividad'),
              Tab(text: 'Fotos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AsyncValueView<StaffProfile>(
              value: profile,
              onRetry: () => ref.invalidate(adminStaffProfileProvider(userId)),
              data: (data) => _StaffInfoTab(userId: userId, profile: data),
            ),
            StaffDocumentsTab(userId: userId),
            StaffActivityTab(userId: userId),
            StaffPhotosTab(userId: userId),
          ],
        ),
      ),
    );
  }
}

/// Pestaña "Datos": lo que cambia según el rol de la persona.
class _StaffInfoTab extends ConsumerStatefulWidget {
  const _StaffInfoTab({required this.userId, required this.profile});

  final int userId;
  final StaffProfile profile;

  @override
  ConsumerState<_StaffInfoTab> createState() => _StaffInfoTabState();
}

class _StaffInfoTabState extends ConsumerState<_StaffInfoTab> {
  bool _busy = false;

  StaffProfile get _profile => widget.profile;

  /// Corre una acción de asignación, avisa el resultado y refresca la ficha.
  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(adminStaffProfileProvider(widget.userId));
      showSuccessSnack(context, done);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignNode() async {
    final choice = await showNodePickerSheet(
      context,
      currentNodeId: _profile.node?.id,
    );
    if (choice == null || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(
      () => source.assignStaffNode(widget.userId, choice.nodeId),
      choice.nodeId == null
          ? 'Quedó sin tienda asignada.'
          : 'Asignado a ${choice.name}.',
    );
  }

  Future<void> _assignVehicle(String driverId) async {
    final vehicle = await showVehiclePickerSheet(context);
    if (vehicle == null || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(
      () => source.assignVehicle(
        driverId: driverId,
        vehicleId: vehicle.id,
        // La asignación de camión es por día: se arma la de HOY.
        date: DateTime.now(),
      ),
      'Camión ${vehicle.displayPlate} asignado para hoy.',
    );
  }

  /// Saca una foto y la deja como foto de perfil de la persona.
  Future<void> _changePhoto() async {
    final photo = await ref.read(photoPickerProvider)(
      maxWidth: kEvidencePhotoMaxWidth,
      imageQuality: kEvidencePhotoQuality,
    );
    if (photo == null || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(
      () => source.uploadStaffPhoto(widget.userId, File(photo.path)),
      'Foto actualizada.',
    );
  }

  /// Edita ciudad, teléfono, documento, dirección y contacto de emergencia.
  Future<void> _editPersonalData() async {
    final data = await showDialog<StaffPersonalEdit>(
      context: context,
      builder: (_) => _PersonalDataDialog(profile: _profile),
    );
    if (data == null || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(
      () => source.updateStaffProfile(
        widget.userId,
        phone: data.phone,
        phoneSecondary: data.phoneSecondary,
        birthDate: data.birthDate,
        nationalId: data.nationalId,
        address: data.address,
        emergencyContactName: data.emergencyName,
        emergencyContactPhone: data.emergencyPhone,
        city: data.city,
        changeCity: data.changeCity,
      ),
      'Datos actualizados.',
    );
  }

  Future<void> _removeVehicle(String crewId) async {
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(() => source.removeCrew(crewId), 'Asignación quitada.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final node = _profile.node;
    final driver = _profile.driver;
    final driverId = _profile.driverId;
    final vehicle = _profile.currentVehicle;
    final devices = _profile.devices;
    final isDriver = staffIsDriver(driverId, _profile.roles);
    final emergencyName = _profile.personal.emergencyContactName;
    final emergencyPhone = _profile.personal.emergencyContactPhone;
    final emergency = emergencyName == null
        ? null
        : [emergencyName, ?emergencyPhone].join(' · ');

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Row(
              children: [
                // Tocar la foto la cambia (cualquier rol puede tener foto).
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _busy ? null : _changePhoto,
                  child: Tooltip(
                    message: 'Cambiar foto',
                    child: StaffAvatar(
                      name: _profile.name,
                      photoUrl: _profile.photoUrl,
                      radius: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(staffRolesText(_profile.roles)),
                      Text(_profile.email, style: muted),
                      Text(
                        _profile.cityName == null
                            ? 'Sin ciudad asignada'
                            : 'Ciudad: ${_profile.cityName}',
                        style: muted,
                      ),
                      if (_profile.phone != null)
                        Text('Teléfono: ${_profile.phone}', style: muted),
                      if (_profile.personal.birthDate != null)
                        Text(
                          'Nacimiento: '
                          '${staffDate(_profile.personal.birthDate!)}',
                          style: muted,
                        ),
                      if (_profile.nationalId != null)
                        Text('Documento: ${_profile.nationalId}', style: muted),
                      if (_profile.personal.address != null)
                        Text(_profile.personal.address!, style: muted),
                      if (emergency != null)
                        Text('Emergencia: $emergency', style: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _editPersonalData,
            icon: const AnimatedAppIcon(
              AppIcon.badge,
              excludeFromSemantics: true,
            ),
            label: const Text('Editar datos personales'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(
              '/admin/broadcasts',
              extra: (userId: widget.userId, name: _profile.name),
            ),
            icon: const AnimatedAppIcon(
              AppIcon.send,
              excludeFromSemantics: true,
            ),
            label: const Text('Enviarle un aviso'),
          ),
          // La tienda se asigna SOLO al personal de tienda; el camión, solo al
          // chofer. El resto de los roles no muestra ninguna de las dos.
          if (staffIsStore(_profile.roles)) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Tienda asignada',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    node?.name ?? 'Sin tienda asignada',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (node?.city != null) Text(node!.city!, style: muted),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _assignNode,
                    icon: const AnimatedAppIcon(
                      AppIcon.pickupStore,
                      excludeFromSemantics: true,
                    ),
                    label: Text(
                      node == null ? 'Asignar a una tienda' : 'Cambiar tienda',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isDriver) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Camión asignado',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    vehicle?.plate ?? 'Sin camión asignado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (vehicle?.assembledFor != null)
                    Text(
                      'Para el ${staffDate(vehicle!.assembledFor!)}',
                      style: muted,
                    ),
                  const SizedBox(height: 12),
                  if (driverId == null)
                    Text(
                      'Esta persona todavía no tiene ficha de chofer: no se le '
                      'puede asignar un camión.',
                      style: muted,
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _assignVehicle(driverId),
                      icon: const AnimatedAppIcon(
                        AppIcon.deliver,
                        excludeFromSemantics: true,
                      ),
                      label: Text(
                        vehicle == null ? 'Asignar camión' : 'Cambiar camión',
                      ),
                    ),
                  if (vehicle?.crewId != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _removeVehicle(vehicle!.crewId!),
                      child: const Text('Quitar asignación'),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (driver != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Licencia de conducir',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      driver.licenseNumber ?? 'Sin número',
                      if (driver.licenseCategory != null)
                        'Categoría ${driver.licenseCategory}',
                    ].join(' · '),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (driver.licenseExpiry != null) ...[
                    const SizedBox(height: 6),
                    StatusPill(
                      '${driver.licenseExpired == true ? 'Venció' : 'Vence'} '
                      'el ${staffDate(driver.licenseExpiry!)}',
                      tone: driver.licenseExpired == true
                          ? PillTone.danger
                          : PillTone.success,
                    ),
                  ],
                  if (driver.emergencyContactName != null) ...[
                    const SizedBox(height: 12),
                    Text('Contacto de emergencia', style: muted),
                    Text(
                      [
                        driver.emergencyContactName!,
                        if (driver.emergencyContactPhone != null)
                          driver.emergencyContactPhone!,
                      ].join(' · '),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (devices.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Teléfonos con sesión',
              child: Column(
                children: [
                  for (final device in devices)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const AnimatedAppIcon(AppIcon.devices),
                      title: Text(device.name ?? device.model ?? 'Teléfono'),
                      subtitle: Text(
                        [
                          if (device.appVersion != null)
                            'App ${device.appVersion}',
                          if (device.lastSeenAt != null)
                            'Visto ${staffDateTime(device.lastSeenAt!)}',
                        ].join(' · '),
                      ),
                      trailing: device.revoked == true
                          ? const StatusPill('Baja', tone: PillTone.neutral)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Datos personales editados en el diálogo. Un campo vacío se borra.
/// [changeCity] es `false` cuando la ciudad la define la tienda asignada.
typedef StaffPersonalEdit = ({
  Department? city,
  bool changeCity,
  String? phoneSecondary,
  DateTime? birthDate,
  String? phone,
  String? nationalId,
  String? address,
  String? emergencyName,
  String? emergencyPhone,
});

/// Formulario de datos personales (vale para cualquier rol).
class _PersonalDataDialog extends StatefulWidget {
  const _PersonalDataDialog({required this.profile});

  final StaffProfile profile;

  @override
  State<_PersonalDataDialog> createState() => _PersonalDataDialogState();
}

class _PersonalDataDialogState extends State<_PersonalDataDialog> {
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _nationalId = TextEditingController(
    text: widget.profile.nationalId ?? '',
  );
  late final _address = TextEditingController(
    text: widget.profile.personal.address ?? '',
  );
  late final _emergencyName = TextEditingController(
    text: widget.profile.personal.emergencyContactName ?? '',
  );
  late final _emergencyPhone = TextEditingController(
    text: widget.profile.personal.emergencyContactPhone ?? '',
  );

  late final _phoneSecondary = TextEditingController(
    text: widget.profile.personal.phoneSecondary ?? '',
  );
  late DateTime? _birthDate = widget.profile.personal.birthDate;
  late Department? _city = departmentOf(widget.profile.city);

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year, now.month, now.day - 1),
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  /// Con tienda asignada la ciudad es la de la tienda: no se elige acá.
  bool get _cityFixed => widget.profile.node?.id != null;

  @override
  void dispose() {
    _phoneSecondary.dispose();
    _phone.dispose();
    _nationalId.dispose();
    _address.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  /// Texto recortado, o `null` si quedó vacío (se borra).
  static String? _value(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Datos personales'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cityFixed)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  helperText: 'La define la tienda asignada',
                ),
                child: Text(widget.profile.cityName ?? 'Sin ciudad'),
              )
            else
              DropdownButtonFormField<Department?>(
                value: _city,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                items: [
                  const DropdownMenuItem(child: Text('Sin ciudad')),
                  for (final department in staffDepartments)
                    DropdownMenuItem(
                      value: department,
                      child: Text(departmentLabel(department)),
                    ),
                ],
                onChanged: (value) => setState(() => _city = value),
              ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: _phoneSecondary,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono secundario',
              ),
            ),
            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                ),
                child: Text(
                  _birthDate == null ? 'Sin fecha' : staffDate(_birthDate!),
                ),
              ),
            ),
            TextField(
              controller: _nationalId,
              decoration: const InputDecoration(
                labelText: 'Documento de identidad',
              ),
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            TextField(
              controller: _emergencyName,
              decoration: const InputDecoration(
                labelText: 'Contacto de emergencia',
              ),
            ),
            TextField(
              controller: _emergencyPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono de emergencia',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            city: _city,
            changeCity: !_cityFixed,
            phone: _value(_phone),
            phoneSecondary: _value(_phoneSecondary),
            birthDate: _birthDate,
            nationalId: _value(_nationalId),
            address: _value(_address),
            emergencyName: _value(_emergencyName),
            emergencyPhone: _value(_emergencyPhone),
          )),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
