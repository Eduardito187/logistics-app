import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/push/push_arrived.dart';
import 'package:logistics_app/core/widgets/paged.dart';
import 'package:logistics_app/features/notifications/data/datasources/inbox_remote_data_source.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/inbox_section.dart';

// Los avisos de la empresa se ven DENTRO de las notificaciones y se vuelven a
// pedir solos cuando llega un push con la app abierta.

class _Inbox implements InboxRemoteDataSource {
  List<StaffInboxItem> items = const [];
  int lists = 0;
  final List<String> read = [];

  @override
  Future<Paged<StaffInboxItem>> list(int page) async {
    lists++;
    return Paged(items: items, hasMore: false);
  }

  @override
  Future<void> markRead(String broadcastId) async => read.add(broadcastId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StaffInboxItem _notice(String id, String title) => StaffInboxItem.fromJson({
  'id': id,
  'kind': 'notice',
  'title': title,
  'body': 'Detalle',
  'read': false,
});

void main() {
  testWidgets('muestra los avisos, marca leído y se refresca con un push', (
    tester,
  ) async {
    final inbox = _Inbox()..items = [_notice('b1', 'Renovar licencia')];
    late WidgetRef outer;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inboxRemoteDataSourceProvider.overrideWithValue(inbox)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                outer = ref;
                return const InboxSection();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Avisos de la empresa'), findsOneWidget);
    expect(find.text('Renovar licencia'), findsOneWidget);
    expect(find.text('Nuevo'), findsOneWidget);

    await tester.tap(find.text('Renovar licencia'));
    await tester.pumpAndSettle();
    expect(inbox.read, ['b1']);
    expect(find.text('Nuevo'), findsNothing);

    // Llega un push: la bandeja se vuelve a pedir y aparece el aviso nuevo.
    final before = inbox.lists;
    inbox.items = [_notice('b2', 'Reunión mañana'), ...inbox.items];
    outer.read(pushArrivedProvider.notifier).bump();
    await tester.pumpAndSettle();

    expect(inbox.lists, greaterThan(before));
    expect(find.text('Reunión mañana'), findsOneWidget);
  });

  testWidgets('sin avisos no ocupa lugar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inboxRemoteDataSourceProvider.overrideWithValue(_Inbox())],
        child: const MaterialApp(home: Scaffold(body: InboxSection())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Avisos de la empresa'), findsNothing);
  });
}
