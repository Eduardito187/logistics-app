import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/theme/high_contrast.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_controllers.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/settings_screen.dart';
import 'package:logistics_app/features/settings/presentation/widgets/field_use_section.dart';

import '../../../core/auth/test_fakes.dart';
import '../../../support/screen_sizes.dart';

// Ajustes con el tema de alto contraste (como lo cablea app.dart cuando el
// switch está activo) en los 4 tamaños y letra 1.3x: sin desbordes y con la
// sección "Uso en terreno" accesible y el switch encendido.

const _me = AppMeResponse(
  user: AppUserProfile(
    id: 1,
    name: 'María Fernanda de los Ángeles Gutiérrez Quispe',
    email: 'maria.fernanda.gutierrez.quispe@dismac.com.bo',
    roles: ['chofer'],
  ),
  device: null,
  abilities: [],
);

class _FakeLabelPrinter implements LabelPrinter {
  @override
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {}
  @override
  Future<List<PrinterDevice>> discover(PrinterTransport transport) async =>
      const [];
  @override
  Future<PrinterConfig?> selectedPrinter() async => null;
  @override
  Future<void> selectPrinter(PrinterConfig config) async {}
}

/// Raíz equivalente a la de app.dart: el tema sale de [highContrastProvider].
class _ThemedRoot extends ConsumerWidget {
  const _ThemedRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final high = ref.watch(highContrastProvider);
    return MaterialApp(
      theme: high ? AppTheme.highContrast() : AppTheme.light(),
      builder: (context, child) => withTextScale(child!),
      home: const SettingsScreen(),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testOnScreens('ajustes en alto contraste (1.3x)', (tester, screen) async {
    final storage = FakeSecureStorage()
      ..seed(HighContrastNotifier.storageKey, 'true');
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        labelPrinterProvider.overrideWithValue(_FakeLabelPrinter()),
        appMeProvider.overrideWith((ref) async => _me),
        selectedPrinterProvider.overrideWith((ref) async => null),
        for (final t in PrinterTransport.values)
          discoveredPrintersProvider(t).overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).devSignIn(UserRole.driver);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _ThemedRoot(),
      ),
    );
    await tester.pumpAndSettle();

    // El tema activo es el de alto contraste (cargado del almacén).
    final context = tester.element(find.byType(SettingsScreen));
    expect(AppContrast.isHigh(context), isTrue);
    expect(Theme.of(context).scaffoldBackgroundColor, Colors.white);

    await tester.scrollUntilVisible(
      find.text('Vibrar y sonar al escanear'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(FieldUseSection), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('highContrastSwitch')))
          .value,
      isTrue,
    );

    // Apagarlo vuelve al tema normal al instante.
    await tester.ensureVisible(find.text('Alto contraste (sol)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alto contraste (sol)'));
    await tester.pumpAndSettle();
    expect(
      AppContrast.isHigh(tester.element(find.byType(SettingsScreen))),
      isFalse,
    );
    expect(storage.data[HighContrastNotifier.storageKey], 'false');
  });
}
