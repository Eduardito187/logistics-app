import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/widgets/paged.dart';
import 'package:logistics_app/features/notifications/data/datasources/inbox_remote_data_source.dart';
import 'package:logistics_app/features/notifications/presentation/inbox_screen.dart';

// Bandeja de avisos de la empresa (cualquier rol): lista, "Nuevo" en los no
// leídos y marcar como leído al tocar.

class _FakeInbox implements InboxRemoteDataSource {
  _FakeInbox(this.items);

  final List<StaffInboxItem> items;
  final List<String> read = [];
  int readAll = 0;

  @override
  Future<Paged<StaffInboxItem>> list(int page) async =>
      Paged(items: items, hasMore: false);

  @override
  Future<int> unreadCount() async =>
      items.where((i) => !(i.read ?? false)).length;

  @override
  Future<void> markRead(String broadcastId) async => read.add(broadcastId);

  @override
  Future<void> markAllRead() async => readAll++;
}

Future<void> _pump(WidgetTester tester, _FakeInbox fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inboxRemoteDataSourceProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: InboxScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final items = [
    const StaffInboxItem(
      id: 'b1',
      title: 'Inventario',
      body: 'Mañana cerramos a las 16:00.',
      read: false,
    ),
    const StaffInboxItem(id: 'b2', title: 'Feriado', read: true),
  ];

  testWidgets('lista los avisos y marca "Nuevo" solo los no leídos', (
    tester,
  ) async {
    await _pump(tester, _FakeInbox(items));

    expect(find.text('Inventario'), findsOneWidget);
    expect(find.text('Mañana cerramos a las 16:00.'), findsOneWidget);
    expect(find.text('Feriado'), findsOneWidget);
    expect(find.text('Nuevo'), findsOneWidget);
  });

  testWidgets('tocar un aviso nuevo lo marca como leído', (tester) async {
    final fake = _FakeInbox(items);
    await _pump(tester, fake);

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(fake.read, ['b1']);
    expect(find.text('Nuevo'), findsNothing);

    // Uno ya leído no se vuelve a marcar.
    await tester.tap(find.text('Feriado'));
    await tester.pumpAndSettle();
    expect(fake.read, ['b1']);
  });

  testWidgets('"Marcar leídos" marca todos', (tester) async {
    final fake = _FakeInbox(items);
    await _pump(tester, fake);

    await tester.tap(find.text('Marcar leídos'));
    await tester.pumpAndSettle();

    expect(fake.readAll, 1);
  });

  testWidgets('sin avisos muestra el estado vacío', (tester) async {
    await _pump(tester, _FakeInbox(const []));

    expect(find.text('Sin avisos'), findsOneWidget);
  });
}
