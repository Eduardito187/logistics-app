import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/catalog/failure_reason_option.dart';
import 'package:logistics_app/core/catalog/failure_reasons_repository.dart';
import 'package:logistics_app/features/admin/presentation/admin_failure_reasons_screen.dart';

import '../../../support/button_finders.dart';
import '../../../support/screen_sizes.dart';

/// Repositorio de motivos falso: sirve una lista en memoria y registra las
/// creaciones/ediciones (sin tocar red).
class _FakeReasonsRepo implements FailureReasonsRepository {
  _FakeReasonsRepo(this.items);

  List<FailureReasonOption> items;
  final List<FailureReasonOption> created = [];
  final List<FailureReasonOption> updated = [];

  @override
  Future<List<FailureReasonOption>> listActive() async =>
      items.where((e) => e.active).toList();

  @override
  Future<List<FailureReasonOption>> listAll() async => items;

  @override
  Future<void> create(FailureReasonOption option) async {
    created.add(option);
    items = [...items, option];
  }

  @override
  Future<void> update(FailureReasonOption option) async {
    updated.add(option);
    items = [
      for (final o in items) if (o.code == option.code) option else o,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _FakeReasonsRepo repo, {
  bool scaled = false,
}) async {
  Widget app = const MaterialApp(home: AdminFailureReasonsScreen());
  if (scaled) app = withTextScale(app);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [failureReasonsRepositoryProvider.overrideWithValue(repo)],
      child: app,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista los motivos con su switch de mostrar/ocultar', (
    tester,
  ) async {
    final repo = _FakeReasonsRepo([
      const FailureReasonOption(code: 'CUSTOMER_ABSENT', label: 'Cliente ausente'),
      const FailureReasonOption(
        code: 'DAMAGED',
        label: 'Producto dañado',
        requiresPhoto: true,
      ),
    ]);
    await _pump(tester, repo);

    expect(find.text('Motivos de no entrega'), findsOneWidget);
    expect(find.text('Cliente ausente'), findsOneWidget);
    expect(find.text('Producto dañado'), findsOneWidget);
    // La etiqueta de exigencia del motivo que pide foto.
    expect(find.text('Pide foto'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.text('Agregar motivo'), findsOneWidget);
  });

  testWidgets('desactivar un motivo lo manda como active=false', (tester) async {
    final repo = _FakeReasonsRepo([
      const FailureReasonOption(code: 'REJECTED', label: 'Pedido rechazado'),
    ]);
    await _pump(tester, repo);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repo.updated, hasLength(1));
    expect(repo.updated.single.code, 'REJECTED');
    expect(repo.updated.single.active, isFalse);
  });

  testWidgets('crear un motivo: nombre → código generado y create()', (
    tester,
  ) async {
    final repo = _FakeReasonsRepo([
      const FailureReasonOption(code: 'OTHER', label: 'Otro motivo'),
    ]);
    await _pump(tester, repo);

    await tester.tap(find.text('Agregar motivo'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo motivo'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Zona insegura');
    // Pedir foto para este motivo.
    await tester.tap(find.text('Pedir foto'));
    await tester.pump();

    await tester.tap(find.text('Crear motivo'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
    final created = repo.created.single;
    expect(created.label, 'Zona insegura');
    // El código se genera del nombre (sin acentos, MAYÚSCULAS, `_`).
    expect(created.code, 'ZONA_INSEGURA');
    expect(created.requiresPhoto, isTrue);
    expect(created.active, isTrue);
  });

  testWidgets('el nuevo motivo pide texto: aparece la etiqueta del campo', (
    tester,
  ) async {
    final repo = _FakeReasonsRepo([
      const FailureReasonOption(code: 'OTHER', label: 'Otro motivo'),
    ]);
    await _pump(tester, repo);

    await tester.tap(find.text('Agregar motivo'));
    await tester.pumpAndSettle();

    // El campo "qué preguntar" solo aparece al activar "Pedir un texto".
    expect(find.text('Qué preguntarle (opcional)'), findsNothing);
    await tester.tap(find.text('Pedir un texto'));
    await tester.pump();
    expect(find.text('Qué preguntarle (opcional)'), findsOneWidget);
  });

  testOnScreens('la pantalla de motivos no se desborda', (tester, screen) async {
    final repo = _FakeReasonsRepo([
      for (final r in kDefaultFailureReasons) r,
    ]);
    await _pump(tester, repo, scaled: true);

    expect(find.text('Motivos de no entrega'), findsOneWidget);
    expect(findButtonWithText<FilledButton>('Agregar motivo'), findsOneWidget);
  });
}
