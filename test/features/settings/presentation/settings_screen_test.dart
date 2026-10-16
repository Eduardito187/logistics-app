import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_controllers.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/settings_screen.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_section.dart';
import 'package:logistics_app/features/settings/presentation/widgets/profile_section.dart';
import 'package:logistics_app/features/settings/presentation/widgets/session_section.dart';

// Pantalla de ajustes: perfil, impresora (con impresión de prueba ZPL), sesión,
// dispositivos y sincronización. Se override los providers de lectura, la
// sesión y el core de impresión (falso) para no tocar red ni hardware.

const _me = AppMeResponse(
  user: AppUserProfile(
    id: 1,
    name: 'Juan',
    email: 'j@x.com',
    roles: ['chofer'],
  ),
  device: null,
  abilities: [],
);

/// Impresora falsa: registra el ZPL enviado o lanza una PrinterException.
class _FakeLabelPrinter implements LabelPrinter {
  _FakeLabelPrinter({this.printError});
  final PrinterException? printError;
  String? lastZpl;

  @override
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {
    lastZpl = zpl;
    if (printError != null) throw printError!;
  }

  @override
  Future<List<PrinterDevice>> discover(PrinterTransport transport) async =>
      const [];
  @override
  Future<PrinterConfig?> selectedPrinter() async => null;
  @override
  Future<void> selectPrinter(PrinterConfig config) async {}
}

Future<_FakeLabelPrinter> _pump(
  WidgetTester tester, {
  PrinterException? printError,
}) async {
  final printer = _FakeLabelPrinter(printError: printError);
  final container = ProviderContainer(
    overrides: [
      labelPrinterProvider.overrideWithValue(printer),
      appMeProvider.overrideWith((ref) async => _me),
      selectedPrinterProvider.overrideWith((ref) async => null),
      discoveredPrintersProvider(PrinterTransport.bluetooth)
          .overrideWith((ref) async => const []),
    ],
  );
  addTearDown(container.dispose);
  // Sesión de dev (sin token): la sección de sesión se dibuja igual.
  container.read(sessionProvider.notifier).devSignIn(UserRole.driver);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return printer;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('muestra las secciones y accesos de ajustes', (tester) async {
    await _pump(tester);

    expect(find.text('Ajustes'), findsOneWidget); // título del AppBar
    expect(find.byType(ProfileSection), findsOneWidget);
    expect(find.byType(PrinterSection), findsOneWidget);
    expect(find.byType(SessionSection), findsOneWidget);
    expect(find.text('Mis dispositivos'), findsOneWidget);
    expect(find.text('Estado de sincronización'), findsOneWidget);
  });

  testWidgets('imprimir prueba envía el ZPL fijo y avisa del éxito', (
    tester,
  ) async {
    final printer = await _pump(tester);

    await tester.tap(find.text('Imprimir prueba'));
    await tester.pump(); // dispara impresión
    await tester.pump(const Duration(milliseconds: 50)); // aviso

    expect(printer.lastZpl, '^XA^FO40,40^A0N,40,40^FDPrueba Dismac^FS^XZ');
    expect(find.text('Etiqueta de prueba enviada.'), findsOneWidget);
  });

  testWidgets('error de impresión muestra el mensaje del operario', (
    tester,
  ) async {
    await _pump(
      tester,
      printError: const PrinterException('No hay impresora seleccionada.'),
    );

    await tester.tap(find.text('Imprimir prueba'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // PrinterException se muestra tal cual (showInfoSnack), no mapeada.
    expect(find.text('No hay impresora seleccionada.'), findsOneWidget);
  });
}
