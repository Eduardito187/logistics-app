import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/admin/domain/entities/admin_vehicle.dart';
import 'package:logistics_app/features/admin/presentation/admin_staff_profile_screen.dart';
import 'package:logistics_app/features/admin/presentation/admin_staff_screen.dart';
import 'package:logistics_app/features/admin/presentation/staff_labels.dart';

import 'fake_admin.dart';

// Personal del administrador: lista con buscador/rol y la ficha por pestañas
// (una sola vista; el contenido cambia según el rol de la persona).

StaffMember _member({
  required int id,
  required String name,
  required List<String> roles,
  StaffNode? node,
  String? city,
  String? cityName,
}) => StaffMember(
  id: id,
  name: name,
  email: '$id@dismac.test',
  roles: roles,
  city: city,
  cityName: cityName,
  node: node,
  driverId: null,
  carrierId: null,
  phone: null,
  nationalId: null,
  photoUrl: null,
);

StaffProfile _profile({
  required int id,
  required String name,
  required List<String> roles,
  StaffNode? node,
  String? driverId,
  StaffDriverData? driver,
  String? city,
  String? cityName,
  CurrentVehicle? currentVehicle,
}) => StaffProfile(
  id: id,
  name: name,
  email: '$id@dismac.test',
  roles: roles,
  city: city,
  cityName: cityName,
  node: node,
  driverId: driverId,
  carrierId: null,
  phone: null,
  nationalId: null,
  photoUrl: null,
  createdAt: null,
  personal: const StaffPersonalData(),
  driver: driver,
  currentVehicle: currentVehicle,
  devices: const [],
);

final _driver = _profile(
  id: 7,
  name: 'Iker Corona',
  roles: ['chofer'],
  driverId: 'drv-1',
  driver: const StaffDriverData(licenseNumber: 'LIC-9', licenseCategory: 'C'),
);

final _storeClerk = _profile(
  id: 9,
  name: 'Ana Tienda',
  roles: ['tienda'],
  node: const StaffNode(id: 'node-1', name: 'Tienda Norte', city: 'Santa Cruz'),
);

void main() {
  group('lista', () {
    final staff = [
      _member(id: 7, name: 'Iker Corona', roles: ['chofer']),
      _member(
        id: 9,
        name: 'Ana Tienda',
        roles: ['tienda'],
        city: 'santa_cruz',
        cityName: 'Santa Cruz',
        node: const StaffNode(id: 'node-1', name: 'Tienda Norte'),
      ),
    ];

    testWidgets('muestra nombre, rol en español y tienda', (tester) async {
      await pumpAdmin(
        tester,
        FakeAdmin(staff: staff),
        const AdminStaffScreen(),
      );

      expect(find.text('Iker Corona'), findsOneWidget);
      expect(find.text('Chofer'), findsWidgets);
      expect(find.text('Santa Cruz · Tienda Norte'), findsOneWidget);
      expect(find.text('Sin ciudad · Sin tienda asignada'), findsOneWidget);
    });

    testWidgets('filtrar por ciudad consulta al servidor', (tester) async {
      final fake = FakeAdmin(staff: staff);
      await pumpAdmin(tester, fake, const AdminStaffScreen());

      await tester.tap(find.text('Todas las ciudades'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cochabamba').last);
      await tester.pumpAndSettle();
      expect(fake.cityFilters.last, (
        city: Department.cochabamba,
        withoutCity: false,
      ));

      await tester.tap(find.text('Cochabamba'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sin ciudad asignada').last);
      await tester.pumpAndSettle();
      expect(fake.cityFilters.last, (city: null, withoutCity: true));
    });

    testWidgets('filtrar por rol consulta al servidor', (tester) async {
      final fake = FakeAdmin(staff: staff);
      await pumpAdmin(tester, fake, const AdminStaffScreen());

      await tester.tap(find.text('Todos los roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tienda').last);
      await tester.pumpAndSettle();

      expect(fake.staffRequests.last.role, Role.tienda);
      expect(find.text('Ana Tienda'), findsOneWidget);
      expect(find.text('Iker Corona'), findsNothing);
    });

    testWidgets('buscar por nombre consulta al servidor', (tester) async {
      final fake = FakeAdmin(staff: staff);
      await pumpAdmin(tester, fake, const AdminStaffScreen());

      await tester.enterText(find.byType(TextField), 'iker');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(fake.staffRequests.last.query, 'iker');
      expect(find.text('Ana Tienda'), findsNothing);
    });
  });

  group('ficha', () {
    testWidgets('cuatro pestañas para cualquier rol', (tester) async {
      await pumpAdmin(
        tester,
        FakeAdmin(profile: _storeClerk),
        const AdminStaffProfileScreen(userId: 9),
      );

      for (final tab in ['Datos', 'Documentos', 'Actividad', 'Fotos']) {
        expect(find.widgetWithText(Tab, tab), findsOneWidget);
      }
    });

    testWidgets('chofer: muestra licencia y camión; tienda: no', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        FakeAdmin(profile: _driver),
        const AdminStaffProfileScreen(userId: 7),
      );
      expect(find.text('Camión asignado'), findsOneWidget);
      expect(find.text('Licencia de conducir'), findsOneWidget);
      expect(find.text('LIC-9 · Categoría C'), findsOneWidget);

      await pumpAdmin(
        tester,
        FakeAdmin(profile: _storeClerk),
        const AdminStaffProfileScreen(userId: 9),
      );
      expect(find.text('Camión asignado'), findsNothing);
      expect(find.text('Licencia de conducir'), findsNothing);
      expect(find.text('Tienda Norte'), findsOneWidget);
    });

    testWidgets('asignar la ciudad desde los datos personales', (tester) async {
      final fake = FakeAdmin(profile: _driver);
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 7));
      expect(find.text('Sin ciudad asignada'), findsOneWidget);

      await tester.tap(find.text('Editar datos personales'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sin ciudad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('La Paz').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Teléfono secundario'),
        '70000001',
      );
      expect(find.text('Elegir fecha'), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(fake.profileUpdates.single.city, Department.laPaz);
      expect(fake.profileUpdates.single.changeCity, isTrue);
      expect(fake.profileUpdates.single.phoneSecondary, '70000001');
      // Lo que no se tocó viaja como estaba (acá, sin fecha).
      expect(fake.profileUpdates.single.birthDate, isNull);
    });

    testWidgets('con tienda asignada la ciudad no se elige', (tester) async {
      final fake = FakeAdmin(profile: _storeClerk);
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 9));

      await tester.tap(find.text('Editar datos personales'));
      await tester.pumpAndSettle();
      expect(find.text('La define la tienda asignada'), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(fake.profileUpdates.single.changeCity, isFalse);
    });

    testWidgets('la tienda solo se asigna al personal de tienda', (
      tester,
    ) async {
      // Un chofer no tiene "Tienda asignada"; su tarjeta es la del camión.
      await pumpAdmin(
        tester,
        FakeAdmin(profile: _driver),
        const AdminStaffProfileScreen(userId: 7),
      );
      expect(find.text('Tienda asignada'), findsNothing);
      expect(find.text('Camión asignado'), findsOneWidget);
    });

    testWidgets('asignar a una tienda desde la ficha', (tester) async {
      final fake = FakeAdmin(
        profile: _profile(id: 9, name: 'Ana Tienda', roles: ['tienda']),
        nodes: [
          adminNode(),
          adminNode(id: 'node-2', name: 'Tienda Sur'),
        ],
      );
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 9));

      expect(find.text('Camión asignado'), findsNothing);
      await tester.tap(find.text('Asignar a una tienda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tienda Sur'));
      await tester.pumpAndSettle();

      expect(fake.nodeAssignments.single, (userId: 9, nodeId: 'node-2'));
      expect(find.text('Asignado a Tienda Sur.'), findsOneWidget);
    });

    testWidgets('asignar un camión al chofer desde la ficha', (tester) async {
      final fake = FakeAdmin(
        profile: _driver,
        vehicles: const [
          AdminVehicle(
            id: 'v1',
            plate: '904U10',
            status: AdminVehicleStatus.available,
          ),
        ],
      );
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 7));

      await tester.tap(find.text('Asignar camión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('904U10'));
      await tester.pumpAndSettle();

      expect(fake.vehicleAssignments.single, (
        driverId: 'drv-1',
        vehicleId: 'v1',
      ));
      expect(find.text('Camión 904U10 asignado para hoy.'), findsOneWidget);
    });

    testWidgets(
      'cambiar de camión REEMPLAZA: quita el de hoy y arma el nuevo',
      (tester) async {
        final fake = FakeAdmin(
          profile: _profile(
            id: 7,
            name: 'Iker Corona',
            roles: ['chofer'],
            driverId: 'drv-1',
            currentVehicle: CurrentVehicle(
              crewId: 'crew-viejo',
              vehicleId: 'v0',
              plate: '904U10',
              assembledFor: DateTime.now(),
            ),
          ),
          vehicles: const [
            AdminVehicle(
              id: 'v2',
              plate: '131017',
              status: AdminVehicleStatus.available,
            ),
          ],
        );
        await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 7));

        await tester.tap(find.text('Cambiar camión'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('131017'));
        await tester.pumpAndSettle();

        expect(fake.removedCrews, ['crew-viejo']);
        expect(fake.vehicleAssignments.single, (
          driverId: 'drv-1',
          vehicleId: 'v2',
        ));
      },
    );

    testWidgets('la asignación de un día anterior no se toca', (tester) async {
      final fake = FakeAdmin(
        profile: _profile(
          id: 7,
          name: 'Iker Corona',
          roles: ['chofer'],
          driverId: 'drv-1',
          currentVehicle: CurrentVehicle(
            crewId: 'crew-ayer',
            vehicleId: 'v0',
            plate: '904U10',
            assembledFor: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
        vehicles: const [
          AdminVehicle(
            id: 'v2',
            plate: '131017',
            status: AdminVehicleStatus.available,
          ),
        ],
      );
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 7));

      await tester.tap(find.text('Cambiar camión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('131017'));
      await tester.pumpAndSettle();

      expect(fake.removedCrews, isEmpty);
      expect(fake.vehicleAssignments, hasLength(1));
    });

    testWidgets('camión con otro chofer hoy: pregunta antes de quitárselo', (
      tester,
    ) async {
      final fake = FakeAdmin(
        profile: _driver,
        vehicles: const [
          AdminVehicle(
            id: 'v1',
            plate: '904U10',
            status: AdminVehicleStatus.available,
          ),
        ],
      )..vehicleTaken = true;
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 7));

      await tester.tap(find.text('Asignar camión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('904U10'));
      await tester.pumpAndSettle();

      expect(find.text('El camión 904U10 ya tiene chofer'), findsOneWidget);
      expect(fake.vehicleAssignments, isEmpty);

      await tester.tap(find.text('Asignar igual'));
      await tester.pumpAndSettle();

      expect(fake.vehicleAssignments, hasLength(1));
      expect(fake.replaceFlags, [true]);
    });

    testWidgets('documentos: vencido en rojo y sin archivo avisado', (
      tester,
    ) async {
      final fake = FakeAdmin(
        profile: _driver,
        documents: [
          StaffDocument(
            id: 'd1',
            documentType: 'licencia_de_conducir',
            reference: 'LIC-9',
            expiresOn: DateTime(2026, 1, 15),
            expired: true,
          ),
        ],
      );
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 7));

      await tester.tap(find.widgetWithText(Tab, 'Documentos'));
      await tester.pumpAndSettle();

      expect(find.text('Licencia de conducir'), findsOneWidget);
      expect(find.text('Nº LIC-9'), findsOneWidget);
      expect(find.text('Venció el 15/01/2026'), findsOneWidget);
      expect(find.text('Sin archivo adjunto'), findsOneWidget);
    });

    testWidgets('actividad: traduce los códigos del backend', (tester) async {
      final fake = FakeAdmin(
        profile: _driver,
        activity: [
          StaffActivity(
            type: StaffActivityType.assignment,
            title: 'vehicle_assigned',
            detail: '904U10',
            at: DateTime(2026, 11, 14, 8, 30),
          ),
          const StaffActivity(
            type: StaffActivityType.checklist,
            title: 'checklist_failed',
          ),
        ],
      );
      await pumpAdmin(tester, fake, const AdminStaffProfileScreen(userId: 7));

      await tester.tap(find.widgetWithText(Tab, 'Actividad'));
      await tester.pumpAndSettle();

      expect(find.text('Camión asignado'), findsOneWidget);
      expect(find.text('Inspección con fallas'), findsOneWidget);
    });
  });

  test('un código desconocido se muestra legible, sin guiones', () {
    expect(
      staffActivityTitle(const StaffActivity(title: 'nuevo_evento_raro')),
      'Nuevo evento raro',
    );
    expect(
      staffActivityTitle(const StaffActivity(type: StaffActivityType.scan)),
      'Escaneo',
    );
  });
}
