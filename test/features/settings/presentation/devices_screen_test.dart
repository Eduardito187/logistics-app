import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/models/app_device_payload.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/api/models/device_list_item.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/devices_screen.dart';
import 'package:logistics_app/features/settings/presentation/widgets/device_card.dart';

// Pantalla "Mis dispositivos": lista, vacío, error, marca del actual y flujo de
// revocación (confirmación → acción → aviso). Se override los providers de
// lectura y el data source (para la revocación).

DeviceListItem _device(String uuid, {String? name = 'Zebra TC'}) =>
    DeviceListItem(
      uuid: uuid,
      platform: 'android',
      name: name,
      lastSeenAt: DateTime(2026, 3, 5, 14, 30),
      revoked: false,
    );

AppMeResponse _meWithDevice(String? uuid) => AppMeResponse(
  user: const AppUserProfile(
    id: 1,
    name: 'Juan',
    email: 'j@x.com',
    roles: ['chofer'],
  ),
  device: uuid == null
      ? null
      : AppDevicePayload(
          uuid: uuid,
          platform: 'android',
          name: 'Zebra',
          lastSeenAt: null,
        ),
  abilities: const [],
);

/// Data source falso: registra las revocaciones.
class _FakeSettingsRemote implements SettingsRemoteDataSource {
  final List<String> revoked = [];
  @override
  Future<AppMeResponse> getMe() async => _meWithDevice(null);
  @override
  Future<List<DeviceListItem>> listDevices() async => const [];
  @override
  Future<void> revokeDevice(String uuid) async => revoked.add(uuid);
}

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<DeviceListItem>> Function() devices,
  AppMeResponse? me,
  _FakeSettingsRemote? remote,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        devicesProvider.overrideWith((ref) => devices()),
        appMeProvider.overrideWith((ref) async => me ?? _meWithDevice(null)),
        settingsRemoteDataSourceProvider.overrideWithValue(
          remote ?? _FakeSettingsRemote(),
        ),
      ],
      child: const MaterialApp(home: DevicesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('con dispositivos muestra las tarjetas', (tester) async {
    await _pump(tester, devices: () async => [_device('a'), _device('b')]);

    expect(find.byType(DeviceCard), findsNWidgets(2));
  });

  testWidgets('sin dispositivos muestra el estado vacío', (tester) async {
    await _pump(tester, devices: () async => const []);

    expect(find.text('Sin dispositivos'), findsOneWidget);
  });

  testWidgets('error al listar muestra el estado de error', (tester) async {
    await _pump(
      tester,
      devices: () async =>
          throw const ApiException(status: 500, title: 'Falló'),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });

  testWidgets('marca el dispositivo actual según /me', (tester) async {
    await _pump(
      tester,
      devices: () async => [_device('actual'), _device('otro')],
      me: _meWithDevice('actual'),
    );

    expect(find.text('Este dispositivo'), findsOneWidget);
  });

  testWidgets('revocar: confirma y muestra "Dispositivo revocado."', (
    tester,
  ) async {
    final remote = _FakeSettingsRemote();
    await _pump(
      tester,
      devices: () async => [_device('otro')],
      me: _meWithDevice('actual'),
      remote: remote,
    );

    await tester.tap(find.text('Revocar sesión'));
    await tester.pumpAndSettle(); // diálogo de confirmación

    expect(find.text('Revocar dispositivo'), findsOneWidget);
    await tester.tap(find.text('Revocar')); // confirmar
    await tester.pump(); // cierra confirm + muestra carga
    await tester.pump(); // acción completa + cierra carga + agenda aviso
    await tester.pump(const Duration(milliseconds: 50)); // aviso visible

    expect(remote.revoked, ['otro']);
    expect(find.text('Dispositivo revocado.'), findsOneWidget);
  });
}
