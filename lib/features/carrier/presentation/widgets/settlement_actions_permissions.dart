import '../../../../core/auth/session.dart';

/// Permiso del usuario sobre cada acción financiera de una liquidación
/// (aprobar / disputar / marcar como pagada). Es independiente del ESTADO de la
/// liquidación: el detalle muestra un botón solo si el estado lo permite Y el
/// usuario tiene el permiso.
///
/// Se deriva de las abilities del token (`/app/auth/me`), igual que
/// `visibleTasksFor` para las tarjetas del inicio. El backend
/// (`App\Enums\Ability`) todavía NO tiene una ability financiera propia
/// (`settlements:approve` / `settlements:pay` no existen), así que se usa la más
/// cercana de las que el token ya trae:
///
/// - Disputar → `carriers:write`: es la acción que el backend habilita al
///   propio transportista sobre SU liquidación (`EnsureCarrierScope`
///   MODE_SETTLEMENT), y `carriers:write` es la única ability de escritura del
///   contexto transportistas que su token trae.
/// - Aprobar y marcar como pagada → `planning:write`: son acciones de OFICINA
///   (`EnsureCarrierScope` MODE_OFFICE, solo admin/supervisor; segregación de
///   funciones: el transportista no aprueba ni da por pagada su propia
///   factura). `carriers:write` no sirve para distinguirlas porque el
///   transportista también la tiene; `planning:write` es la ability más cercana
///   que el backend concede exactamente a los roles de oficina (supervisor y
///   admin) y nunca al transportista. Pedido pendiente al backend: una ability
///   financiera propia; cuando exista solo se cambia esta clase.
class SettlementActionsPermissions {
  const SettlementActionsPermissions({
    required this.canApprove,
    required this.canDispute,
    required this.canPay,
  });

  /// Deriva los permisos de la sesión actual. Sin sesión no hay ninguna acción.
  factory SettlementActionsPermissions.fromSession(Session? session) {
    if (session == null) {
      return none;
    }
    // El admin lleva el comodín en vez de la lista de abilities.
    final hasWildcard = session.can(wildcardAbility);
    // Aprobar y pagar son fail-closed: mueven plata y son de oficina, así que
    // sin permiso confirmado NO se muestran.
    final isOffice = hasWildcard || session.can(officeApprovalAbility);
    // Mismo criterio de degradación que `visibleTasksFor`: si todavía no
    // sabemos qué puede el usuario (abilities vacías: dev-login, login sin
    // `/me` o `/me` caído) no se le oculta SU acción propia (disputar), que el
    // backend valida igual. Disputar es de la oficina O del propio
    // transportista (`EnsureCarrierScope` MODE_SETTLEMENT).
    final knowsAbilities = session.abilities.isNotEmpty;
    final canDispute =
        isOffice || !knowsAbilities || session.can(carrierWriteAbility);
    return SettlementActionsPermissions(
      canApprove: isOffice,
      canDispute: canDispute,
      canPay: isOffice,
    );
  }

  /// Comodín de abilities del backend (solo admin): concede todas.
  static const String wildcardAbility = '*';

  /// Escritura del contexto transportistas (la trae el transportista).
  static const String carrierWriteAbility = 'carriers:write';

  /// Ability de oficina usada para aprobar/pagar (ver docblock de la clase).
  static const String officeApprovalAbility = 'planning:write';

  /// Sin ninguna acción financiera habilitada.
  static const SettlementActionsPermissions none = SettlementActionsPermissions(
    canApprove: false,
    canDispute: false,
    canPay: false,
  );

  final bool canApprove;
  final bool canDispute;
  final bool canPay;
}
