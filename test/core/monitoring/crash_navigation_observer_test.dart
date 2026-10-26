import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/monitoring/crash_navigation_observer.dart';

import 'fake_crash_reporter.dart';

void main() {
  testWidgets('deja migas de navegación sin ids concretos', (tester) async {
    final reporter = FakeCrashReporter();
    final router = GoRouter(
      observers: [CrashNavigationObserver(reporter)],
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('inicio')),
        GoRoute(
          path: '/shipments/:id',
          builder: (_, state) => Text('envío ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    unawaited(router.push('/shipments/123456'));
    await tester.pumpAndSettle();

    expect(reporter.breadcrumbs.first, 'nav.push /');
    expect(reporter.breadcrumbs, contains('nav.push /shipments/:id'));
    expect(reporter.breadcrumbs.join(), isNot(contains('123456')));

    router.pop();
    await tester.pumpAndSettle();
    expect(reporter.breadcrumbs.last, 'nav.pop /shipments/:id');
  });

  testWidgets('ignora diálogos (no son PageRoute)', (tester) async {
    final reporter = FakeCrashReporter();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [CrashNavigationObserver(reporter)],
        home: const SizedBox(),
      ),
    );
    reporter.breadcrumbs.clear();
    unawaited(
      showDialog<void>(
        context: key.currentContext!,
        builder: (_) => const Text('diálogo'),
      ),
    );
    await tester.pumpAndSettle();
    expect(reporter.breadcrumbs, isEmpty);
  });
}
