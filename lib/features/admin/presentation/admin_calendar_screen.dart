import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/performance/cache_for.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/admin_remote_data_source.dart';
import 'staff_labels.dart';

/// Un día del calendario ya consolidado (el backend manda una fila por
/// municipio; acá se resume por fecha).
typedef CalendarDay = ({
  DateTime date,
  bool blocked,
  String? reason,
  bool available,
});

/// Resume las filas del backend por fecha: un día está BLOQUEADO si alguna fila
/// lo está, y DISPONIBLE si alguna tiene cupos.
List<CalendarDay> consolidateCalendar(List<Days> rows) {
  final byDate = <DateTime, CalendarDay>{};
  for (final row in rows) {
    final raw = row.date;
    if (raw == null) continue;
    final date = DateTime(raw.year, raw.month, raw.day);
    final previous = byDate[date];
    byDate[date] = (
      date: date,
      blocked: (previous?.blocked ?? false) || (row.blocked ?? false),
      reason: previous?.reason ?? row.reason,
      available: (previous?.available ?? false) || (row.available ?? false),
    );
  }
  return byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

/// Calendario del MES que empieza en `month` (día 1). Caché corta: ir y
/// volver de un mes no lo vuelve a pedir.
final adminCalendarProvider = FutureProvider.autoDispose
    .family<List<CalendarDay>, DateTime>((ref, month) async {
      ref.cacheFor(CacheTtl.short);
      final rows = await ref
          .watch(adminRemoteDataSourceProvider)
          .getCalendar(month, DateTime(month.year, month.month + 1, 0));
      return consolidateCalendar(rows);
    });

/// Franjas horarias, unidades y municipios que acepta el calendario. Casi no
/// cambian: caché larga.
final calendarOptionsProvider =
    FutureProvider.autoDispose<DeliveryCalendarOptionsData>((ref) {
      ref.cacheFor(CacheTtl.long);
      return ref.watch(adminRemoteDataSourceProvider).calendarOptions();
    });

/// Franjas horarias de un día con sus cupos (`null` = el backend todavía no
/// ofrece el detalle por hora).
final calendarDaySlotsProvider = FutureProvider.autoDispose
    .family<List<CalendarHourSlot>?, DateTime>(
      (ref, date) => ref.watch(adminRemoteDataSourceProvider).daySlots(date),
    );

const List<String> _weekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> _months = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Calendario de entregas: el mes de un vistazo (con cupo, sin cupo,
/// bloqueado) y, al tocar un día, sus acciones: **agregar cupos por hora**,
/// **bloquear / desbloquear** el día (feriados, cierres) o una hora puntual.
/// Un día bloqueado no admite entregas ni reprogramaciones.
class AdminCalendarScreen extends ConsumerStatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  ConsumerState<AdminCalendarScreen> createState() =>
      _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends ConsumerState<AdminCalendarScreen> {
  late DateTime _month = DateTime(_today().year, _today().month);
  late DateTime _selected = _today();
  bool _busy = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(adminCalendarProvider(_month));
      ref.invalidate(calendarDaySlotsProvider(_selected));
      showSuccessSnack(context, done);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goToMonth(int delta) {
    final month = DateTime(_month.year, _month.month + delta);
    final today = _today();
    setState(() {
      _month = month;
      // Al cambiar de mes se elige hoy (si es este mes) o su día 1.
      _selected = month.year == today.year && month.month == today.month
          ? today
          : month;
    });
  }

  /// Abre fechas de envío: elige un rango y el backend genera los cupos por
  /// defecto de sus reglas para todos los municipios (en segundo plano).
  Future<void> _openDays() async {
    final today = _today();
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      helpText: 'Fechas de envío a abrir',
      saveText: 'Abrir',
    );
    if (range == null || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(
      () => source.openDays(range.start, range.end),
      'Fechas abiertas. Los cupos se generan en unos segundos.',
    );
  }

  Future<void> _blockDay(CalendarDay day) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ReasonDialog(title: 'Bloquear el ${staffDate(day.date)}'),
    );
    if (reason == null || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(() => source.blockDay(day.date, reason), 'Día bloqueado.');
  }

  Future<void> _unblockDay(CalendarDay day) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desbloquear el ${staffDate(day.date)}'),
        content: Text(
          day.reason == null
              ? 'El día vuelve a admitir entregas.'
              : 'Motivo del bloqueo: ${day.reason}.\n'
                    'El día vuelve a admitir entregas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(() => source.unblockDay(day.date), 'Día desbloqueado.');
  }

  /// Agrega cupos a una franja horaria del día elegido.
  Future<void> _addHourSlot(DateTime date) async {
    final form = await showModalBottomSheet<HourSlotForm>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HourSlotSheet(date: date),
    );
    if (form == null || !mounted) return;
    final source = ref.read(adminRemoteDataSourceProvider);
    await _run(
      () => source.openHourSlot(
        date: date,
        timeSlot: form.timeSlot,
        unit: form.unit,
        quantity: form.quantity,
        municipalityIds: form.municipalityIds,
      ),
      'Cupos agregados. Se ven en unos segundos.',
    );
  }

  Future<void> _toggleHour(DateTime date, CalendarHourSlot slot) async {
    final source = ref.read(adminRemoteDataSourceProvider);
    if (slot.blocked) {
      await _run(
        () => source.unblockHourSlot(date, slot.timeSlot),
        'Hora desbloqueada.',
      );
      return;
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ReasonDialog(title: 'Bloquear ${hourSlotLabel(slot.timeSlot)}'),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => source.blockHourSlot(date, slot.timeSlot, reason),
      'Hora bloqueada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ref.watch(adminCalendarProvider(_month));
    final today = _today();
    final atStart = _month.year == today.year && _month.month == today.month;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de entregas')),
      // FIJO al pie: abrir fechas es la acción principal de la pantalla.
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
                onPressed: _busy ? null : _openDays,
                icon: const AnimatedAppIcon(
                  AppIcon.add,
                  excludeFromSemantics: true,
                ),
                label: const Text('Abrir fechas'),
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxContentWidth,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: atStart ? null : () => _goToMonth(-1),
                  icon: const RotatedBox(
                    quarterTurns: 2,
                    child: AnimatedAppIcon(AppIcon.chevronRight),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${_months[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: () => _goToMonth(1),
                  icon: const AnimatedAppIcon(AppIcon.chevronRight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AsyncValueView<List<CalendarDay>>(
              value: days,
              onRetry: () => ref.invalidate(adminCalendarProvider(_month)),
              data: (list) {
                final byDate = {for (final day in list) day.date: day};
                final selected =
                    byDate[_selected] ??
                    (
                      date: _selected,
                      blocked: false,
                      reason: null,
                      available: false,
                    );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MonthGrid(
                      month: _month,
                      today: today,
                      selected: _selected,
                      days: byDate,
                      onSelect: (date) => setState(() => _selected = date),
                    ),
                    const SizedBox(height: 12),
                    const _Legend(),
                    const SizedBox(height: 16),
                    _DayCard(
                      day: selected,
                      past: selected.date.isBefore(today),
                      busy: _busy,
                      onBlock: () => _blockDay(selected),
                      onUnblock: () => _unblockDay(selected),
                      onAddHours: () => _addHourSlot(selected.date),
                      onToggleHour: (slot) => _toggleHour(selected.date, slot),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// "08:00-12:00" → "08:00 a 12:00".
String hourSlotLabel(String timeSlot) {
  final parts = timeSlot.split('-');
  return parts.length == 2 ? '${parts[0]} a ${parts[1]}' : timeSlot;
}

/// Color de un día según su estado.
Color _dayColor(BuildContext context, CalendarDay? day) {
  if (day == null) return Theme.of(context).colorScheme.outline;
  if (day.blocked) return Theme.of(context).colorScheme.error;
  if (day.available) return AppColors.success;
  return Theme.of(context).colorScheme.outline;
}

/// El mes en una grilla de lunes a domingo. Cada día se pinta por su estado
/// y se toca para ver su detalle abajo.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.days,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final Map<DateTime, CalendarDay> days;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = DateTime(month.year, month.month + 1, 0).day;
    // Huecos antes del día 1 (la semana empieza en lunes).
    final offset = month.weekday - 1;
    final cells = offset + count;
    final rows = (cells / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    name.substring(0, 2),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(child: _cell(context, row * 7 + column - offset + 1)),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int dayNumber) {
    final count = DateTime(month.year, month.month + 1, 0).day;
    if (dayNumber < 1 || dayNumber > count) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime(month.year, month.month, dayNumber);
    final day = days[date];
    final color = _dayColor(context, day);
    final isSelected = date == selected;
    final isToday = date == today;
    final past = date.isBefore(today);
    final marked = day != null && (day.blocked || day.available);
    final status = day == null
        ? 'sin cupo'
        : day.blocked
        ? 'bloqueado'
        : day.available
        ? 'con cupo'
        : 'sin cupo';
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Semantics(
          button: true,
          selected: isSelected,
          label: '${_weekdays[date.weekday - 1]} ${staffDate(date)}, $status',
          excludeSemantics: true,
          child: Material(
            color: marked
                ? color.withValues(alpha: past ? 0.08 : 0.2)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? scheme.primary
                    : isToday
                    ? scheme.onSurface
                    : Colors.transparent,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelect(date),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: past ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: marked ? color : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Qué significa cada color.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        item(AppColors.success, 'Con cupo'),
        item(scheme.outline, 'Sin cupo'),
        item(scheme.error, 'Bloqueado'),
      ],
    );
  }
}

/// Detalle del día elegido: su estado, sus horas y lo que se puede hacer.
class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.past,
    required this.busy,
    required this.onBlock,
    required this.onUnblock,
    required this.onAddHours,
    required this.onToggleHour,
  });

  final CalendarDay day;
  final bool past;
  final bool busy;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onAddHours;
  final ValueChanged<CalendarHourSlot> onToggleHour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final slots = ref.watch(calendarDaySlotsProvider(day.date)).value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_weekdays[day.date.weekday - 1]} ${staffDate(day.date)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (day.blocked)
                const StatusPill(
                  'Bloqueado',
                  tone: PillTone.danger,
                  icon: AppIcon.cancel,
                )
              else if (day.available)
                const StatusPill('Con cupo', tone: PillTone.success)
              else
                const StatusPill('Sin cupo'),
            ],
          ),
          if (day.blocked && day.reason != null) ...[
            const SizedBox(height: 6),
            Text('Motivo: ${day.reason}', style: muted),
          ],
          if (slots != null && slots.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Horas del día',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final slot in slots)
              _HourRow(
                slot: slot,
                enabled: !busy && !past && !day.blocked,
                onToggle: () => onToggleHour(slot),
              ),
          ],
          if (past) ...[
            const SizedBox(height: 8),
            Text('Este día ya pasó.', style: muted),
          ] else ...[
            const SizedBox(height: 14),
            if (!day.blocked) ...[
              FilledButton.tonalIcon(
                onPressed: busy ? null : onAddHours,
                icon: const AnimatedAppIcon(
                  AppIcon.add,
                  excludeFromSemantics: true,
                ),
                label: const Text('Agregar cupos por hora'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: busy ? null : (day.blocked ? onUnblock : onBlock),
              icon: AnimatedAppIcon(
                day.blocked ? AppIcon.check : AppIcon.cancel,
                excludeFromSemantics: true,
              ),
              label: Text(
                day.blocked ? 'Desbloquear el día' : 'Bloquear el día',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Una franja horaria del día: sus cupos y el botón para bloquearla.
class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.slot,
    required this.enabled,
    required this.onToggle,
  });

  final CalendarHourSlot slot;
  final bool enabled;
  final VoidCallback onToggle;

  static String _n(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final capacity = slot.capacity;
    final used = slot.used ?? 0;
    final detail = slot.blocked
        ? (slot.reason == null ? 'Bloqueada' : 'Bloqueada: ${slot.reason}')
        : capacity == null
        ? 'Sin cupos'
        : '${_n(used)} de ${_n(capacity)} cupos usados';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hourSlotLabel(slot.timeSlot),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: slot.blocked
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: enabled ? onToggle : null,
            child: Text(slot.blocked ? 'Desbloquear' : 'Bloquear'),
          ),
        ],
      ),
    );
  }
}

/// Lo que se elige al agregar cupos a una hora.
typedef HourSlotForm = ({
  String timeSlot,
  String unit,
  num quantity,
  List<String> municipalityIds,
});

/// Hoja para agregar cupos a una franja horaria: hora, cantidad y alcance,
/// todo con opciones que da el backend.
class _HourSlotSheet extends ConsumerStatefulWidget {
  const _HourSlotSheet({required this.date});

  final DateTime date;

  @override
  ConsumerState<_HourSlotSheet> createState() => _HourSlotSheetState();
}

class _HourSlotSheetState extends ConsumerState<_HourSlotSheet> {
  final TextEditingController _quantity = TextEditingController();
  String? _timeSlot;
  DeliveryCalendarUnitOptionValue? _unit;

  /// `null` = todos los municipios.
  String? _municipalityId;

  @override
  void initState() {
    super.initState();
    _quantity.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  num? get _amount {
    final value = num.tryParse(_quantity.text.trim());
    return value != null && value > 0 ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = ref.watch(calendarOptionsProvider);
    const gap = SizedBox(height: 16);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: AsyncValueView<DeliveryCalendarOptionsData>(
          value: options,
          onRetry: () => ref.invalidate(calendarOptionsProvider),
          data: (data) {
            final units = [
              for (final unit in data.units)
                if (unit.value.json != null) unit,
            ];
            final unit = _unit ?? (units.isEmpty ? null : units.first.value);
            final amount = _amount;
            final ready =
                _timeSlot != null && unit?.json != null && amount != null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Agregar cupos por hora',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_weekdays[widget.date.weekday - 1]} '
                  '${staffDate(widget.date)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                gap,
                DropdownButtonFormField<String>(
                  value: _timeSlot,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Hora'),
                  items: [
                    for (final slot in data.timeSlots)
                      DropdownMenuItem(
                        value: slot,
                        child: Text(hourSlotLabel(slot)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _timeSlot = value),
                ),
                gap,
                TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cupos'),
                ),
                if (units.length > 1) ...[
                  gap,
                  DropdownButtonFormField<DeliveryCalendarUnitOptionValue>(
                    value: unit,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Se cuenta en',
                    ),
                    items: [
                      for (final option in units)
                        DropdownMenuItem(
                          value: option.value,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _unit = value),
                  ),
                ],
                gap,
                DropdownButtonFormField<String?>(
                  value: _municipalityId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Municipio'),
                  items: [
                    const DropdownMenuItem(child: Text('Todos los municipios')),
                    for (final municipality in data.municipalities)
                      DropdownMenuItem(
                        value: municipality.id,
                        child: Text(municipality.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _municipalityId = value),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: !ready
                        ? null
                        : () => Navigator.of(context).pop((
                            timeSlot: _timeSlot!,
                            unit: unit!.json!,
                            quantity: amount,
                            municipalityIds: _municipalityId == null
                                ? [for (final m in data.municipalities) m.id]
                                : [_municipalityId!],
                          )),
                    child: const Text('Agregar cupos'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pide el motivo de un bloqueo (obligatorio: queda como constancia).
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});

  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _accept() {
    final value = _reason.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _reason,
        autofocus: true,
        onSubmitted: (_) => _accept(),
        decoration: const InputDecoration(
          labelText: 'Motivo',
          hintText: 'Feriado, cierre por inventario…',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _accept, child: const Text('Bloquear')),
      ],
    );
  }
}
