import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/app_device_payload.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/widgets/profile_section.dart';

// Sección de perfil: nombre, correo, roles y dispositivo, con reintento. Se
// override el provider de /me con dato o error.

const _me = AppMeResponse(
  user: AppUserProfile(
    id: 1,
    name: 'Juan Pérez',
    email: 'juan@x.com',
    roles: ['chofer', 'supervisor'],
  ),
  device: AppDevicePayload(
    uuid: 'uuid-1',
    platform: 'android',
    name: 'Zebra TC',
    lastSeenAt: null,
  ),
  abilities: [],
);

Future<void> _pump(
  WidgetTester tester,
  Future<AppMeResponse> Function() load,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appMeProvider.overrideWith((ref) => load())],
      child: const MaterialApp(home: Scaffold(body: ProfileSection())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos muestra nombre, correo, roles y dispositivo', (
    tester,
  ) async {
    await _pump(tester, () async => _me);

    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('juan@x.com'), findsOneWidget);
    expect(find.text('chofer'), findsOneWidget); // pastilla de rol
    expect(find.text('supervisor'), findsOneWidget);
    expect(find.textContaining('Dispositivo: Zebra TC'), findsOneWidget);
  });

  testWidgets('en error muestra el estado con reintento', (tester) async {
    await _pump(
      tester,
      () async => throw const ApiException(status: 500, title: 'Falló'),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
