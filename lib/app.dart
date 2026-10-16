import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/session.dart';
import 'core/push/push_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class LogisticsApp extends ConsumerWidget {
  const LogisticsApp({super.key});

  /// Español de Bolivia por defecto (la usan choferes y personal de tienda).
  static const _locales = [Locale('es', 'BO'), Locale('es')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messengerKey = ref.watch(_messengerKeyProvider);

    // Arranca el push (UnifiedPush/ntfy, ADR 014). `build()` del controlador es
    // seguro: devuelve estado inactivo y el init corre protegido en segundo plano.
    ref.watch(pushRegistrationProvider);

    // Al tocar una notificación entrante, ir a la bandeja.
    ref.listen(pushTapProvider, (_, next) {
      if (next.hasValue) {
        ref.read(routerProvider).push('/notifications');
      }
    });

    // Aviso de sesión expirada (401 global): el router ya llevó al login.
    ref.listen(sessionExpiredProvider, (_, message) {
      if (message != null) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
        ref.read(sessionExpiredProvider.notifier).clear();
      }
    });

    return MaterialApp.router(
      title: 'Dismac Logística',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'BO'),
      supportedLocales: _locales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Llave estable del ScaffoldMessenger para mostrar avisos globales (sesión
/// expirada) sin un BuildContext de pantalla.
final _messengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);
