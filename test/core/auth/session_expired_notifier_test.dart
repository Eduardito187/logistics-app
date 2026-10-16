import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session_expired_notifier.dart';

// Aviso de sesión expirada: estado String? donde null = sin aviso pendiente.

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('arranca en null (sin aviso)', () {
    expect(container.read(sessionExpiredProvider), isNull);
  });

  test('set guarda el mensaje', () {
    container.read(sessionExpiredProvider.notifier).set('expiró');
    expect(container.read(sessionExpiredProvider), 'expiró');
  });

  test('set sobreescribe el mensaje anterior', () {
    final notifier = container.read(sessionExpiredProvider.notifier);
    notifier.set('uno');
    notifier.set('dos');
    expect(container.read(sessionExpiredProvider), 'dos');
  });

  test('clear vuelve a null', () {
    final notifier = container.read(sessionExpiredProvider.notifier);
    notifier.set('expiró');
    notifier.clear();
    expect(container.read(sessionExpiredProvider), isNull);
  });

  test('clear sobre estado ya vacío es idempotente', () {
    final notifier = container.read(sessionExpiredProvider.notifier);
    notifier.clear();
    expect(container.read(sessionExpiredProvider), isNull);
  });
}
