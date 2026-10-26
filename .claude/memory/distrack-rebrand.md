---
name: distrack-rebrand
description: "La app se renombró a DisTrack (oct 2026); marca, assets, dónde está cada cosa"
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-22T02:32:07.130Z
---

La app Flutter se renombró de "Dismac Logística" a **DisTrack** (tagline **DE ANDÉN A PUERTA.**). El backend NO se renombra (sigue siendo la plataforma/ API logística Dismac). El paquete Dart sigue siendo `logistics_app` y el repo `logistics-app` (no se tocan para no romper imports).

**Marca (brand kit v1, 21-oct-2026):** Rojo Dismac `#E30613` (marca/acción), Noche `#141414` (fondos/texto), Ámbar seguridad `#FFB000` (alertas/pendientes, NUNCA en el logo), Andén `#F3F3F1` (fondo claro). Fuentes OFL: Barlow (texto/botones/wordmark), Barlow Condensed 800 (títulos), IBM Plex Mono 500 (códigos).

**Qué cambió en la app:**
- `lib/core/theme/app_colors.dart` + `app_theme.dart`: paleta DisTrack (mismos nombres de símbolo) + fuentes (base Barlow, títulos BarlowCondensed, appbar BarlowCondensed 800). Fondo claro = `AppColors.platformLight` (Andén).
- Nombre visible: AndroidManifest `android:label`, iOS `CFBundleDisplayName`, `app.dart` title, notificación de tracking → "DisTrack".
- `lib/features/auth/.../auth_header.dart`: logo/wordmark+lema como SVG (flutter_svg), sin el ícono camión ni el texto viejo. Fondo del header de login = Noche `[nightBg, nightSurface]` (NO rojo): los SVG inverso llevan rojo `#E30613` que sobre fondo rojo quedaba invisible.
- Logo en el header de la app: `lib/core/brand/distrack_app_bar_logo.dart` (`DisTrackAppBarLogo`, SVG claro/inverso según tema) a la izquierda del `SliverAppBar` en `role_home_screen.dart` (antes el lado opuesto a la campana quedaba vacío).
- Rojo neutralizado en `app_theme.dart`/`app_colors.dart`: `onSurfaceVariant`/`outline` a grises, íconos a Noche/`onSurface`, indicador GPS activo a `AppColors.success` (el exceso de rojo ensuciaba íconos y SVG).
- Assets en `assets/brand/` (logos/isotipo SVG, splash-animation.json, PNG) y `assets/fonts/` (TTF OFL). Declarados en pubspec (assets + fonts).
- Deps nuevas: `flutter_svg`, `lottie`; dev: `flutter_launcher_icons`, `flutter_native_splash` (con sus bloques de config en pubspec).
- Íconos de app (Android adaptive fondo #141414 + iOS) y splash nativo (#141414 + isotipo) GENERADOS y commiteados. Para regenerarlos: `dart run flutter_launcher_icons` y `dart run flutter_native_splash:create`.
- Splash animado Lottie: widget `lib/core/brand/brand_splash.dart` (respeta reduced-motion), YA CABLEADO al arranque vía `BootSplashGate` one-shot en `main.dart` (detalle y guardas en [[perf-rebrand-stability-fixes]]). El splash nativo (#141414 + isotipo) cubre el cold start antes.
- Kit original del usuario: `C:\Users\ehhuallata\Downloads\distrack-brand-kit.zip` (+ .md/.html). El .zip trae también web/favicon y páginas de error (web/ops, NO parte de la app Flutter).

Pendiente de verificación: `flutter analyze` quedó limpio en WSL (solo infos de deprecación por SDK 3.47.6 vs 3.32 del proyecto); la suite completa la valida la CI (Linux 3.32). Ver [[test-battery-and-infra]].
