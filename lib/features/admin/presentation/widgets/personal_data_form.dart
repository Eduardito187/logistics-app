import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/widgets/section_card.dart';
import '../staff_labels.dart';

/// Datos personales editados en el formulario. Un campo vacío se borra.
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

/// Abre el formulario de datos personales. Devuelve `null` si se cancela.
Future<StaffPersonalEdit?> showPersonalDataForm(
  BuildContext context,
  StaffProfile profile,
) => showDialog<StaffPersonalEdit>(
  context: context,
  builder: (_) =>
      Dialog.fullscreen(child: PersonalDataFormScreen(profile: profile)),
);

/// Formulario de datos personales (vale para cualquier rol), a pantalla
/// completa y agrupado por tema —identidad, contacto, domicilio, emergencia—
/// con "Guardar" fijo al pie.
class PersonalDataFormScreen extends StatefulWidget {
  const PersonalDataFormScreen({super.key, required this.profile});

  final StaffProfile profile;

  @override
  State<PersonalDataFormScreen> createState() => _PersonalDataFormScreenState();
}

class _PersonalDataFormScreenState extends State<PersonalDataFormScreen> {
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _phoneSecondary = TextEditingController(
    text: widget.profile.personal.phoneSecondary ?? '',
  );
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
  late DateTime? _birthDate = widget.profile.personal.birthDate;
  late Department? _city = departmentOf(widget.profile.city);

  /// Con tienda asignada la ciudad es la de la tienda: no se elige acá.
  bool get _cityFixed => widget.profile.node?.id != null;

  @override
  void dispose() {
    _phone.dispose();
    _phoneSecondary.dispose();
    _nationalId.dispose();
    _address.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

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

  /// Texto recortado, o `null` si quedó vacío (se borra).
  static String? _value(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  void _save() => Navigator.of(context).pop((
    city: _city,
    changeCity: !_cityFixed,
    phone: _value(_phone),
    phoneSecondary: _value(_phoneSecondary),
    birthDate: _birthDate,
    nationalId: _value(_nationalId),
    address: _value(_address),
    emergencyName: _value(_emergencyName),
    emergencyPhone: _value(_emergencyPhone),
  ));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: const Text('Datos personales')),
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
                onPressed: _save,
                icon: const AnimatedAppIcon(
                  AppIcon.save,
                  excludeFromSemantics: true,
                ),
                label: const Text('Guardar'),
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
            Text(
              widget.profile.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            gap,
            SectionCard(
              title: 'Identidad',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nationalId,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Documento de identidad',
                    ),
                  ),
                  gap,
                  InkWell(
                    onTap: _pickBirthDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                      ),
                      child: Text(
                        _birthDate == null
                            ? 'Elegir fecha'
                            : staffDate(_birthDate!),
                      ),
                    ),
                  ),
                  gap,
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
                ],
              ),
            ),
            gap,
            SectionCard(
              title: 'Contacto',
              child: Column(
                children: [
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  gap,
                  TextField(
                    controller: _phoneSecondary,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono secundario',
                    ),
                  ),
                  gap,
                  TextField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                ],
              ),
            ),
            gap,
            SectionCard(
              title: 'En caso de emergencia',
              child: Column(
                children: [
                  TextField(
                    controller: _emergencyName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Contacto de emergencia',
                    ),
                  ),
                  gap,
                  TextField(
                    controller: _emergencyPhone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de emergencia',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
