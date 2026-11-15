import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/admin_remote_data_source.dart';
import 'staff_labels.dart';

/// Días que muestra el calendario por tanda.
const int kCalendarSpanDays = 30;

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

/// Calendario de la tanda que empieza en `from`.
final adminCalendarProvider = FutureProvider.autoDispose
    .family<List<CalendarDay>, DateTime>((ref, from) async {
      final rows = await ref
          .watch(adminRemoteDataSourceProvider)
          .getCalendar(
            from,
            from.add(const Duration(days: kCalendarSpanDays - 1)),
          );
      return consolidateCalendar(rows);
    });

/// Calendario de entregas: ver qué días tienen cupo y **bloquear / desbloquear**
/// fechas (feriados, cierres). Un día bloqueado no admite entregas ni
/// reprogramaciones.
class AdminCalendarScreen extends ConsumerStatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  ConsumerState<AdminCalendarScreen> createState() =>
      _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends ConsumerState<AdminCalendarScreen> {
  late DateTime _from = _today();
  bool _busy = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static const List<String> _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(adminCalendarProvider(_from));
      showSuccessSnack(context, done);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  Future<void> _onDayTap(CalendarDay day) async {
    final source = ref.read(adminRemoteDataSourceProvider);
    final label = staffDate(day.date);
    if (day.blocked) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Desbloquear el $label'),
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
      await _run(() => source.unblockDay(day.date), 'Día desbloqueado.');
      return;
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _BlockDayDialog(label: label),
    );
    if (reason == null || !mounted) return;
    await _run(() => source.blockDay(day.date, reason), 'Día bloqueado.');
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(adminCalendarProvider(_from));
    final to = _from.add(const Duration(days: kCalendarSpanDays - 1));
    final atStart = !_from.isAfter(_today());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de entregas'),
        actions: [
          TextButton.icon(
            onPressed: _busy ? null : _openDays,
            icon: const AnimatedAppIcon(AppIcon.add, size: 20),
            label: const Text('Abrir fechas'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Días anteriores',
                    onPressed: atStart
                        ? null
                        : () => setState(
                            () => _from = _from.subtract(
                              const Duration(days: kCalendarSpanDays),
                            ),
                          ),
                    icon: const RotatedBox(
                      quarterTurns: 2,
                      child: AnimatedAppIcon(AppIcon.chevronRight),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${staffDate(_from)} al ${staffDate(to)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Días siguientes',
                    onPressed: () => setState(
                      () => _from = _from.add(
                        const Duration(days: kCalendarSpanDays),
                      ),
                    ),
                    icon: const AnimatedAppIcon(AppIcon.chevronRight),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView<List<CalendarDay>>(
                value: days,
                onRetry: () => ref.invalidate(adminCalendarProvider(_from)),
                data: (list) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final day = list[index];
                    return Card(
                      child: ListTile(
                        onTap: _busy ? null : () => _onDayTap(day),
                        title: Text(
                          '${_weekdays[day.date.weekday - 1]} '
                          '${staffDate(day.date)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: day.blocked && day.reason != null
                            ? Text(day.reason!)
                            : null,
                        trailing: day.blocked
                            ? const StatusPill(
                                'Bloqueado',
                                tone: PillTone.danger,
                                icon: AppIcon.cancel,
                              )
                            : day.available
                            ? const StatusPill(
                                'Con cupo',
                                tone: PillTone.success,
                              )
                            : const StatusPill('Sin cupo'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pide el motivo del bloqueo (obligatorio: queda como constancia).
class _BlockDayDialog extends StatefulWidget {
  const _BlockDayDialog({required this.label});

  final String label;

  @override
  State<_BlockDayDialog> createState() => _BlockDayDialogState();
}

class _BlockDayDialogState extends State<_BlockDayDialog> {
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
      title: Text('Bloquear el ${widget.label}'),
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
