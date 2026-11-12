import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/settlement_actions_permissions.dart';

// Permisos de las acciones financieras de una liquidación: aprobar y pagar son
// de oficina (fail-closed), disputar es la acción propia del transportista.

Session _session(UserRole role, List<String> abilities) =>
    Session(userName: 'u', role: role, abilities: abilities);

void main() {
  test('sin sesión: ninguna acción', () {
    final permissions = SettlementActionsPermissions.fromSession(null);

    expect(permissions.canApprove, isFalse);
    expect(permissions.canDispute, isFalse);
    expect(permissions.canPay, isFalse);
  });

  test('transportista (carriers:write): solo puede disputar', () {
    final permissions = SettlementActionsPermissions.fromSession(
      _session(UserRole.carrier, const ['carriers:write', 'execution:read']),
    );

    expect(permissions.canDispute, isTrue);
    expect(permissions.canApprove, isFalse);
    expect(permissions.canPay, isFalse);
  });

  test('oficina (planning:write): puede aprobar, pagar y disputar', () {
    final permissions = SettlementActionsPermissions.fromSession(
      _session(UserRole.supervisor, const ['planning:write', 'carriers:read']),
    );

    expect(permissions.canApprove, isTrue);
    expect(permissions.canPay, isTrue);
    expect(permissions.canDispute, isTrue);
  });

  test('comodín del admin: puede todo', () {
    final permissions = SettlementActionsPermissions.fromSession(
      _session(UserRole.supervisor, const ['*']),
    );

    expect(permissions.canApprove, isTrue);
    expect(permissions.canDispute, isTrue);
    expect(permissions.canPay, isTrue);
  });

  test('abilities vacías: disputar sí (degradación), aprobar/pagar no', () {
    // dev-login o `/me` caído: no sabemos qué puede el usuario. Su acción
    // propia no se oculta; las de plata sí (fail-closed).
    final permissions = SettlementActionsPermissions.fromSession(
      _session(UserRole.carrier, const []),
    );

    expect(permissions.canDispute, isTrue);
    expect(permissions.canApprove, isFalse);
    expect(permissions.canPay, isFalse);
  });

  test('isOffice: admin y oficina sí, transportista y sin sesión no', () {
    expect(
      SettlementActionsPermissions.isOffice(
        _session(UserRole.supervisor, const ['planning:write']),
      ),
      isTrue,
    );
    expect(
      SettlementActionsPermissions.isOffice(
        _session(UserRole.supervisor, const ['*']),
      ),
      isTrue,
    );
    expect(
      SettlementActionsPermissions.isOffice(
        _session(UserRole.carrier, const ['carriers:write']),
      ),
      isFalse,
    );
    expect(SettlementActionsPermissions.isOffice(null), isFalse);
  });

  test('abilities sin ninguna de escritura: ninguna acción', () {
    final permissions = SettlementActionsPermissions.fromSession(
      _session(UserRole.carrier, const ['carriers:read', 'execution:read']),
    );

    expect(permissions.canDispute, isFalse);
    expect(permissions.canApprove, isFalse);
    expect(permissions.canPay, isFalse);
  });
}
