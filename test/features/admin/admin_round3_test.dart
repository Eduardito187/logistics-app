import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/features/admin/domain/entities/admin_vehicle.dart';
import 'package:logistics_app/features/admin/presentation/widgets/send_to_maintenance_sheet.dart';
import 'package:logistics_app/features/admin/presentation/widgets/staff_tabs.dart';

import '../../support/fake_photo_picker.dart';
import 'fake_admin.dart';

// Mantenimiento: reasignar pedidos solo si el camión los tiene. Documentos del
// personal: tipo elegible, número, y anverso + reverso en carnet y licencia.
// Fotos: nunca evidencia de entregas (dato del cliente).

const _vehicle = AdminVehicle(
  id: 'v1',
  plate: '161W94',
  status: AdminVehicleStatus.available,
);

void main() {
  group('mandar a mantenimiento', () {
    testWidgets('sin pedidos no ofrece pasarlos a otro camión', (tester) async {
      await pumpAdmin(
        tester,
        FakeAdmin(),
        const Scaffold(body: SendToMaintenanceSheet(vehicle: _vehicle)),
      );

      expect(find.textContaining('Pasarlos a otro camión'), findsNothing);
      expect(find.textContaining('opcional)'), findsNWidgets(2)); // campos
    });

    testWidgets('con pedidos pendientes dice cuántos y deja reasignar', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        FakeAdmin()..pendingOrders = 3,
        const Scaffold(body: SendToMaintenanceSheet(vehicle: _vehicle)),
      );

      expect(
        find.text('Este camión tiene 3 pedidos pendientes'),
        findsOneWidget,
      );
      expect(find.text('Pasarlos a otro camión'), findsOneWidget);
    });
  });

  group('documentos', () {
    Future<void> open(WidgetTester tester, FakeAdmin fake, int photos) =>
        pumpAdmin(
          tester,
          fake,
          const Scaffold(body: StaffDocumentsTab(userId: 7)),
          overrides: [
            photoPickerProvider.overrideWithValue(
              FakePhotoPicker([
                for (var i = 1; i <= photos; i++) '/tmp/doc$i.jpg',
              ]).call,
            ),
          ],
        );

    testWidgets('carnet: número + anverso y reverso', (tester) async {
      final fake = FakeAdmin();
      await open(tester, fake, 2);

      await tester.tap(find.text('Agregar documento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tipo de documento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carnet de identidad').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Número del documento'),
        '6284531',
      );
      // Dos recuadros: cada uno se toca para sacar su foto. Sin las dos no
      // se puede guardar.
      expect(find.text('Anverso'), findsOneWidget);
      expect(find.text('Reverso'), findsOneWidget);
      await tester.tap(find.text('Anverso'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Guardar documento'),
                matching: find.bySubtype<FilledButton>(),
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Reverso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar documento'));
      await tester.pumpAndSettle();

      expect(fake.uploads.map((u) => u.side), [
        StaffDocumentSide.front,
        StaffDocumentSide.back,
      ]);
      expect(fake.uploads.map((u) => u.type).toSet(), {'Carnet de identidad'});
      expect(fake.uploads.map((u) => u.reference).toSet(), {'6284531'});
      expect(fake.uploads.map((u) => u.path), [
        '/tmp/doc1.jpg',
        '/tmp/doc2.jpg',
      ]);
    });

    testWidgets('contrato: una sola foto', (tester) async {
      final fake = FakeAdmin();
      await open(tester, fake, 1);

      await tester.tap(find.text('Agregar documento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tipo de documento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contrato').last);
      await tester.pumpAndSettle();
      expect(find.text('Reverso'), findsNothing);
      await tester.tap(find.text('Foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar documento'));
      await tester.pumpAndSettle();

      expect(fake.uploads.single.type, 'Contrato');
      expect(fake.uploads.single.side, isNull);
    });
  });

  testWidgets('fotos: la evidencia de entregas no se muestra', (tester) async {
    await pumpAdmin(
      tester,
      FakeAdmin(photos: const [StaffPhoto(kind: StaffPhotoKind.profile)]),
      const Scaffold(body: StaffPhotosTab(userId: 7)),
    );

    expect(find.text('Foto de perfil'), findsOneWidget);
    expect(find.text('signature'), findsNothing);
  });
}
