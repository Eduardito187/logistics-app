import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/user_role.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.local_shipping,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Dismac Logística',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            const TextField(decoration: InputDecoration(labelText: 'Usuario')),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'El inicio de sesión todavía no está conectado al servidor.',
                  ),
                ),
              ),
              child: const Text('Ingresar'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 40),
              const Divider(),
              Text(
                'Desarrollo: entrar como',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final role in UserRole.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    key: ValueKey('dev-login-${role.name}'),
                    icon: Icon(role.icon),
                    label: Text(role.label),
                    onPressed: () =>
                        ref.read(sessionProvider.notifier).devSignIn(role),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
