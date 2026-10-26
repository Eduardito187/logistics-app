import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/version/app_build_info.dart';
import 'package:logistics_app/core/version/update_required_screen.dart';
import 'package:logistics_app/core/version/version_gate.dart';

void main() {
  late ProviderContainer container;
  late List<Uri> opened;
  late bool launchResult;

  Future<void> pump(WidgetTester tester, {String updateUrl = ''}) async {
    opened = [];
    launchResult = true;
    container = ProviderContainer(
      overrides: [
        appBuildInfoLoaderProvider.overrideWithValue(
          () async => const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        ),
        appUpdateUrlProvider.overrideWithValue(updateUrl),
        updateLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return launchResult;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => VersionGate(child: child!),
          home: const Scaffold(body: Text('Inicio del chofer')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin bloqueo muestra la app normal', (tester) async {
    await pump(tester);
    expect(find.text('Inicio del chofer'), findsOneWidget);
    expect(find.text('Actualizá la app'), findsNothing);
  });

  testWidgets('con mínima mayor tapa toda la app y abre la tienda', (
    tester,
  ) async {
    await pump(tester, updateUrl: 'https://play.google.com/store/apps/x');
    container.read(versionGateProvider.notifier).reportMinVersion('1.2.0');
    await tester.pumpAndSettle();

    expect(find.text('Inicio del chofer'), findsNothing);
    expect(find.text('Actualizá la app'), findsOneWidget);
    expect(find.text('Instalada: 1.0.0  ·  Mínima: 1.2.0'), findsOneWidget);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://play.google.com/store/apps/x');
    expect(find.textContaining('supervisor'), findsNothing);
  });

  testWidgets('sin URL configurada pide avisar al supervisor', (tester) async {
    await pump(tester);
    container.read(versionGateProvider.notifier).reportUpgradeRequired();
    await tester.pumpAndSettle();

    expect(find.text('Actualizar'), findsNothing);
    expect(find.textContaining('supervisor'), findsOneWidget);
  });

  testWidgets('si no se puede abrir la tienda, avisa al supervisor', (
    tester,
  ) async {
    await pump(tester, updateUrl: 'market://details?id=x');
    launchResult = false;
    container.read(versionGateProvider.notifier).reportUpgradeRequired();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('supervisor'), findsOneWidget);
  });
}
