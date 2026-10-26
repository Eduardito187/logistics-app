import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'version_gate.dart';

/// Abre la tienda/MDM. Se sobreescribe en tests.
final updateLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// URL de actualización (config `APP_UPDATE_URL`). Se sobreescribe en tests.
final appUpdateUrlProvider = Provider<String>((ref) => AppConfig.appUpdateUrl);

/// Envuelve toda la app: si el backend exige una versión más nueva, tapa todo
/// con [UpdateRequiredScreen]. Si no, muestra [child] tal cual.
///
/// Va en `MaterialApp.router(builder: ...)` para cubrir cualquier ruta.
class VersionGate extends ConsumerWidget {
  const VersionGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mustUpdate = ref.watch(
      versionGateProvider.select((s) => s.mustUpdate),
    );
    return mustUpdate ? const UpdateRequiredScreen() : child;
  }
}

/// Pantalla bloqueante "Actualizá la app". Sin salida: la versión instalada
/// ya no es compatible con el backend y operar con ella perdería datos.
class UpdateRequiredScreen extends ConsumerStatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  ConsumerState<UpdateRequiredScreen> createState() =>
      _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends ConsumerState<UpdateRequiredScreen> {
  bool _openFailed = false;

  Future<void> _openUpdate(Uri uri) async {
    var ok = false;
    try {
      ok = await ref.read(updateLauncherProvider)(uri);
    } on Object {
      ok = false;
    }
    if (mounted) setState(() => _openFailed = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gate = ref.watch(versionGateProvider);
    final uri = Uri.tryParse(ref.watch(appUpdateUrlProvider).trim());
    final canOpen = uri != null && uri.hasScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.system_update,
                    size: 96,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Actualizá la app',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esta versión ya no es compatible con el sistema. '
                    'Actualizala para seguir trabajando. '
                    'Lo que guardaste sin señal no se pierde.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (gate.current != null || gate.minRequired != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      [
                        if (gate.current != null) 'Instalada: ${gate.current}',
                        if (gate.minRequired != null)
                          'Mínima: ${gate.minRequired}',
                      ].join('  ·  '),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (canOpen)
                    FilledButton.icon(
                      onPressed: () => _openUpdate(uri),
                      icon: const Icon(Icons.download),
                      label: const Text('Actualizar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(64),
                        textStyle: theme.textTheme.titleLarge,
                      ),
                    ),
                  if (!canOpen || _openFailed) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Pedile a tu supervisor que actualice la app '
                      'en este teléfono.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
