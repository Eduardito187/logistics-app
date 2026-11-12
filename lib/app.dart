import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/session.dart';
import 'core/home_widgets/home_widgets_provider.dart';
import 'core/labels/label_keys_notifier.dart';
import 'core/live_updates/route_live_updates_provider.dart';
import 'core/shortcuts/app_shortcuts_provider.dart';
import 'core/monitoring/crash_session_binder.dart';
import 'core/offline/offline_queue.dart';
import 'core/power/power_status_notifier.dart';
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

    // El push (Firebase Cloud Messaging) lo arranca `main.dart` después del
    // primer cuadro (no demora la apertura ni reconstruye MaterialApp).

    // Crashlytics: usuario seudónimo, rol y tienda al iniciar/cerrar sesión.
    ref.listen(crashSessionBinderProvider, (_, _) {});

    // Energía del teléfono (batería / ahorro): se mantiene vivo toda la sesión
    // para que el GPS del chofer, el polling y las animaciones decorativas se
    // recorten con ahorro de energía o batería < 20 %. Sin canal nativo
    // (tests/escritorio) queda "desconocido" = comportamiento normal.
    ref.listen(powerStatusProvider, (_, _) {});
    // Ruta en vivo del chofer (Live Updates Android 16 / Dynamic Island iOS) y
    // accesos directos del ícono según el rol de la sesión.
    ref.listen(routeLiveUpdatesProvider, (_, _) {});
    ref.listen(appShortcutsProvider, (_, _) {});
    // Widgets de la pantalla de inicio: contenido por rol, vacíos al salir.
    ref.listen(homeWidgetsProvider, (_, _) {});

    // Al tocar una notificación entrante, ir a la bandeja.
    ref.listen(pushTapProvider, (_, next) {
      if (next.hasValue) {
        ref.read(routerProvider).push('/notifications');
      }
    });

    // Al abrir sesión (login exitoso) se descartan los avisos que hayan quedado
    // en el messenger RAÍZ de un intento anterior en el login (p. ej. el error
    // "sin rol de terreno" de otro usuario): ese snackbar vive a nivel app y, si
    // no se limpia, se arrastra a la pantalla de inicio del nuevo usuario al que
    // NO le corresponde. Solo al entrar (null -> sesión); el cierre de sesión y
    // su aviso de "sesión expirada" van por otro camino.
    ref.listen(sessionProvider, (previous, next) {
      if (previous == null && next != null) {
        messengerKey.currentState?.clearSnackBars();
        // Refresca claves de etiquetas y el MODO ABIERTO en cada sesión activa
        // (login Y restauración al reabrir la app), no solo al iniciar sesión.
        // Así, si el backend está en modo abierto, el escáner no vuelve a
        // verificar firma al reabrir y NINGUNA etiqueta se marca inválida.
        unawaited(ref.read(labelKeysProvider.notifier).refresh());
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
      title: 'DisTrack',
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
      // Cambiar de tema (alto contraste) es instantáneo: la animación de 200 ms
      // interpolaba el tema completo reconstruyendo la app en cada cuadro.
      themeAnimationDuration: Duration.zero,
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
