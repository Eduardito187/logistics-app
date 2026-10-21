import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:logistics_app/features/auth/domain/usecases/sign_in.dart';
import 'package:logistics_app/features/auth/presentation/login_screen.dart';
import 'package:logistics_app/features/auth/presentation/widgets/auth_header.dart';

import '../../../support/button_finders.dart';
import '../../../support/screen_sizes.dart';

// Layout del login en los 4 tamaños (letra normal y 1.3x), en horizontal y con
// el teclado abierto. Un desborde hace fallar el test solo.

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<void> login({required String email, required String password}) async {}
}

Future<void> _pump(WidgetTester tester, {double textScale = 1.0}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        signInProvider.overrideWithValue(SignIn(_NoopAuthRepository())),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => withTextScale(child!, scale: textScale),
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testOnScreens('login no se desborda (letra 1.3x)', (tester, screen) async {
    await _pump(tester, textScale: 1.3);

    expect(find.byType(AuthHeader), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    // El botón se alcanza desplazando si no entra.
    await tester.ensureVisible(findButtonWithText<FilledButton>('Ingresar'));
    await tester.pumpAndSettle();
    expect(
      findButtonWithText<FilledButton>('Ingresar').hitTestable(),
      findsOne,
    );
  });

  testOnScreens('formulario angosto y centrado; encabezado a todo el ancho', (
    tester,
    screen,
  ) async {
    await _pump(tester);

    final width = screen.size.width;
    final field = tester.getRect(find.byType(TextField).first);
    final header = tester.getRect(find.byType(AuthHeader));
    expect(header.width, width);
    if (width > AppBreakpoints.maxFormWidth) {
      // Tablet: campos dentro de maxFormWidth (menos el padding de 24) y
      // centrados en la pantalla.
      expect(field.width, AppBreakpoints.maxFormWidth - 48);
      expect(field.center.dx, closeTo(width / 2, 0.5));
      // El logo de marca (SVG) arranca alineado con el formulario.
      final brand = tester.getRect(
        find.bySemanticsLabel(RegExp('DisTrack')).first,
      );
      expect(brand.left, closeTo(field.left, 0.5));
    } else {
      // Teléfono: el formulario usa el ancho disponible.
      expect(field.width, width - 48);
    }
  });

  testWidgets('teléfono en horizontal con teclado abierto: se desplaza', (
    tester,
  ) async {
    // 568 x 320 (teléfono chico acostado): se toca el campo y el teclado tapa
    // 200 dp; quedan 120 dp visibles.
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pump(tester, textScale: 1.3);

    // Encabezado compacto en horizontal: deja lugar al formulario.
    expect(tester.getSize(find.byType(AuthHeader)).height, lessThan(180));

    await tester.showKeyboard(find.byType(TextField).first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();

    // El campo con foco queda a la vista (el scroll lo acerca).
    expect(find.byType(TextField).first.hitTestable(), findsOne);

    // Sin desborde y el botón se puede alcanzar con scroll.
    await tester.ensureVisible(findButtonWithText<FilledButton>('Ingresar'));
    await tester.pumpAndSettle();
    expect(
      findButtonWithText<FilledButton>('Ingresar').hitTestable(),
      findsOne,
    );
  });
}
