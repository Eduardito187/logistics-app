import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tamaños de pantalla reales para probar el layout (en dp lógicos).
///
/// Un desborde ("A RenderFlex overflowed by N pixels") en cualquiera de ellos
/// hace fallar el test solo: el framework lo reporta como excepción.
enum TestScreen {
  /// Teléfono chico/barato (p. ej. 1 GB de RAM, 4.5"–5"): 320 x 568 dp.
  smallPhone(Size(320, 568)),

  /// Teléfono típico: 360 x 780 dp.
  phone(Size(360, 780)),

  /// Tablet en vertical: 800 x 1280 dp.
  tabletPortrait(Size(800, 1280)),

  /// Tablet grande en horizontal: 1280 x 800 dp.
  tabletLandscape(Size(1280, 800));

  const TestScreen(this.size);

  final Size size;
}

/// Configura la superficie del test con [screen] (dpr 1) y la restaura al
/// terminar. [textScale] simula la letra grande del sistema (la app la limita
/// a 1.3x en `app.dart`; las pantallas sueltas se prueban con `MediaQuery`).
void useScreen(WidgetTester tester, TestScreen screen) {
  tester.view.physicalSize = screen.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Envuelve [child] con letra escalada (como la preferencia del sistema).
Widget withTextScale(Widget child, {double scale = 1.3}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child,
  ),
);

/// Corre [body] una vez por cada tamaño de [screens] como tests separados:
/// `testOnScreens('inicio no se desborda', (tester, screen) async {...});`
void testOnScreens(
  String description,
  Future<void> Function(WidgetTester tester, TestScreen screen) body, {
  List<TestScreen> screens = TestScreen.values,
}) {
  for (final screen in screens) {
    testWidgets('$description [${screen.name}]', (tester) async {
      useScreen(tester, screen);
      await body(tester, screen);
    });
  }
}
