import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/session.dart';
import 'core/monitoring/crash_session_binder.dart';
import 'core/offline/offline_queue.dart';
import 'core/push/push_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/high_contrast.dart';
import 'core/version/update_required_screen.dart';

class LogisticsApp extends ConsumerWidget {
  const LogisticsApp({super.key});

  /// Español de Bolivia por defecto (la usan choferes y personal de tienda).
  static const _locales = [Locale('es', 'BO'), Locale('es')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messengerKey = ref.watch(_messengerKeyProvider);

    // Arranca el push (Firebase Cloud Messaging). `build()` del controlador es
    // seguro: devuelve estado inactivo y el init corre protegido en segundo plano.
    ref.watch(pushRegistrationProvider);

    // Crashlytics: usuario seudónimo, rol y tienda al iniciar/cerrar sesión.
    ref.watch(crashSessionBinderProvider);

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

    // Offline invisible: el usuario nunca ve "sin conexión". Lo único que se
    // informa es que, al volver la señal, la cola está subiendo lo guardado.
    ref.listen(connectivityProvider, (previous, next) async {
      final cameBack = previous?.value == false && next.value == true;
      if (!cameBack) return;
      final pending = await ref.read(offlineQueueProvider).pendingCount();
      if (pending == 0) return;
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Sincronizando...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
    });

    // Alto contraste (sol fuerte), elegido en Ajustes. Fuerza tema claro: con
    // ThemeMode.system un teléfono en modo oscuro lo ignoraría.
    final highContrast = ref.watch(highContrastProvider);

    return MaterialApp.router(
      title: 'Dismac Logística',
      // Letra del sistema muy grande desborda botones y tarjetas en teléfonos
      // chicos: se respeta la preferencia del usuario pero con tope 1.3x.
      // VersionGate: si el backend exige una versión mayor, bloquea con
      // "Actualizá la app" (X-Min-App-Version / 426).
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: VersionGate(child: child!),
      ),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
      darkTheme: highContrast ? AppTheme.highContrast() : AppTheme.dark(),
      themeMode: highContrast ? ThemeMode.light : ThemeMode.system,
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
