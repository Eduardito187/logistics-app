import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/home/presentation/home_prefetch.dart';
import 'package:logistics_app/features/home/presentation/role_home_screen.dart';
import 'package:logistics_app/features/home/presentation/widgets/profile_header.dart';
import 'package:logistics_app/features/home/presentation/widgets/task_card.dart';

import '../../../support/screen_sizes.dart';

// Layout del inicio por rol en teléfono chico, teléfono y tablets (vertical y
// horizontal), con letra normal y 1.3x. Usa las tarjetas reales de cada rol y
// el tema real de la app. Un desborde hace fallar el test solo.

Future<void> _pump(
  WidgetTester tester,
  UserRole role, {
  double textScale = 1.0,
}) async {
  // Sin precarga: acá solo se mide el layout (y no se toca la red).
  final container = ProviderContainer(
    overrides: [homePrefetcherProvider.overrideWithValue(const _NoPrefetch())],
  );
  addTearDown(container.dispose);
  container.read(sessionProvider.notifier).devSignIn(role);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => withTextScale(child!, scale: textScale),
        home: const RoleHomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _NoPrefetch extends HomePrefetcher {
  const _NoPrefetch();

  @override
  void call(WidgetRef ref, UserRole role) {}
}

/// Columnas reales: cuántas tarjetas comparten la fila de la primera.
int _columnsOnFirstRow(WidgetTester tester) {
  final cards = find.byType(TaskCard);
  final firstTop = tester.getTopLeft(cards.first).dy;
  return tester
      .widgetList(cards)
      .where((w) => tester.getTopLeft(find.byWidget(w)).dy == firstTop)
      .length;
}

void main() {
  const roles = [
    UserRole.driver,
    UserRole.picker,
    UserRole.store,
    UserRole.carrier,
    UserRole.supervisor,
  ];

  for (final role in roles) {
    testOnScreens('inicio de ${role.name} no se desborda (letra 1.3x)', (
      tester,
      screen,
    ) async {
      await _pump(tester, role, textScale: 1.3);

      expect(find.byType(ProfileHeader), findsOneWidget);
      expect(find.byType(TaskCard), findsWidgets);
      expect(find.byTooltip('Notificaciones'), findsOneWidget);
      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    });
  }

  testOnScreens('columnas de la grilla según el tamaño', (
    tester,
    screen,
  ) async {
    // El supervisor tiene varias tarjetas: alcanza para llenar 3 columnas.
    await _pump(tester, UserRole.supervisor);

    final expected = switch (screen) {
      TestScreen.smallPhone || TestScreen.phone => 1,
      TestScreen.tabletPortrait => 2,
      TestScreen.tabletLandscape => 3,
    };
    final available = find.byType(TaskCard).evaluate().length;
    expect(
      _columnsOnFirstRow(tester),
      expected < available ? expected : available,
    );
    if (expected == 1) {
      expect(find.byType(SliverGrid), findsNothing);
    } else {
      expect(find.byType(SliverGrid), findsOneWidget);
    }
  });

  testOnScreens(
    'en tablet el contenido no se estira de borde a borde',
    (tester, screen) async {
      await _pump(tester, UserRole.driver);

      final width = screen.size.width;
      final firstCard = tester.getRect(find.byType(TaskCard).first);
      final avatar = tester.getRect(find.byType(CircleAvatar));
      // El avatar del perfil queda alineado con la primera columna.
      expect(avatar.left, closeTo(firstCard.left, 0.5));
      // Grilla centrada: mismo margen a izquierda y derecha.
      final lastCard = tester.getRect(find.byType(TaskCard).last);
      final right = find.byType(TaskCard).evaluate().length >= 3
          ? width - tester.getRect(find.byType(TaskCard).at(2)).right
          : width - lastCard.right;
      expect(firstCard.left, greaterThanOrEqualTo(16));
      if (screen == TestScreen.tabletLandscape) {
        expect(firstCard.left, closeTo(right, 0.5));
        expect(firstCard.left, greaterThan(16));
      }
    },
    screens: const [TestScreen.tabletPortrait, TestScreen.tabletLandscape],
  );

  testWidgets('nombre muy largo en teléfono chico: elipsis, sin desborde', (
    tester,
  ) async {
    useScreen(tester, TestScreen.smallPhone);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).devSignIn(UserRole.carrier);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              height: 150,
              child: ProfileHeader(
                name: 'María Fernanda de los Ángeles Gutiérrez Quispe',
                role: 'Transportista externo',
                icon: Icons.local_shipping,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(find.textContaining('María Fernanda'));
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
  });
}
