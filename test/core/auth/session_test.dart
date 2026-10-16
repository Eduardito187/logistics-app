import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';

// Modelo inmutable [Session] y su chequeo plano de permisos [Session.can].

void main() {
  group('Session (constructor y valores por defecto)', () {
    test(
      'token y abilities tienen valores por defecto (null y lista vacía)',
      () {
        const session = Session(userName: 'ana', role: UserRole.store);
        expect(session.userName, 'ana');
        expect(session.role, UserRole.store);
        expect(session.token, isNull);
        expect(session.abilities, isEmpty);
      },
    );

    test('conserva token y abilities cuando se pasan', () {
      const session = Session(
        userName: 'luis',
        role: UserRole.driver,
        token: 'abc',
        abilities: ['routes.read', 'pod.create'],
      );
      expect(session.token, 'abc');
      expect(session.abilities, ['routes.read', 'pod.create']);
    });

    test('acepta token vacío como valor distinto de null', () {
      const session = Session(userName: 'x', role: UserRole.picker, token: '');
      expect(session.token, '');
      expect(session.token, isNotNull);
    });
  });

  group('Session.can', () {
    const session = Session(
      userName: 'ana',
      role: UserRole.supervisor,
      abilities: ['dashboard.read', 'incidents.read'],
    );

    test('devuelve true si la ability está en la lista', () {
      expect(session.can('dashboard.read'), isTrue);
      expect(session.can('incidents.read'), isTrue);
    });

    test('devuelve false si la ability no está', () {
      expect(session.can('dashboard.write'), isFalse);
    });

    test('es sensible a mayúsculas/minúsculas (comparación exacta)', () {
      expect(session.can('Dashboard.read'), isFalse);
    });

    test('con abilities vacías siempre devuelve false', () {
      const empty = Session(userName: 'x', role: UserRole.driver);
      expect(empty.can('cualquier'), isFalse);
      expect(empty.can(''), isFalse);
    });
  });
}
