import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/auth/token_store.dart';
import 'core/network/auth_headers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Formatos de fecha/número en español (America/La_Paz) para toda la app.
  await initializeDateFormatting('es');

  final container = ProviderContainer();

  // El identificador de dispositivo acompaña a cada escaneo y al Bearer de la
  // puerta /app/*. Se genera una sola vez y se carga antes del primer request.
  final deviceId = await container.read(tokenStoreProvider).deviceId();
  container.read(authHeadersProvider.notifier).setDeviceId(deviceId);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LogisticsApp(),
    ),
  );
}
