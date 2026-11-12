import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/empty_state.dart';
import 'settlement_actions_permissions.dart';

/// ¿Esta sesión puede usar las herramientas de COMPRA/COSTEO de oficina del
/// módulo transportistas (asignación por volumen y tarifa más barata entre
/// TODOS los transportistas)?
///
/// Son herramientas de la oficina: un proveedor externo no debería ver con qué
/// competidor sale más barato. El backend ya responde 403 al transportista en
/// esos dos endpoints, así que acá ni se le muestran.
///
/// Mismo criterio que las acciones financieras de oficina (aprobar / marcar
/// como pagada): se reusa [SettlementActionsPermissions.isOffice], que ya
/// resuelve el comodín `*` del admin y es fail-closed, en vez de duplicar la
/// regla. Es decir: admin (comodín) o `planning:write` (supervisor), nunca el
/// transportista. Es el mismo estilo de filtro por ability que
/// `visibleTasksFor` aplica a las tarjetas del inicio, pero fail-closed: acá no
/// se degrada a "mostrar" cuando no sabemos qué puede el usuario, porque sería
/// filtrar datos de otros transportistas.
bool canUseCarrierOfficeTools(Session? session) =>
    SettlementActionsPermissions.isOffice(session);

/// Deja pasar a [child] solo si la sesión es de oficina
/// ([canUseCarrierOfficeTools]); si no, muestra la pantalla como no disponible.
///
/// Envuelve las rutas de oficina del módulo para que no se puedan alcanzar por
/// navegación directa (deep link, push o un `push` que quede en el código).
class CarrierOfficeOnly extends ConsumerWidget {
  const CarrierOfficeOnly({
    super.key,
    required this.title,
    required this.child,
  });

  /// Título de la pantalla (se mantiene igual al bloquear).
  final String title;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = canUseCarrierOfficeTools(ref.watch(sessionProvider));
    if (allowed) return child;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyState(
        icon: AppIcon.security,
        title: 'Solo para la oficina',
        message:
            'Esta herramienta de compra y costeo no está disponible para tu '
            'rol.',
      ),
    );
  }
}
