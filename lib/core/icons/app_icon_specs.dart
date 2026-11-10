import 'generated/app_icon.g.dart';
import 'icon_motion.dart';
import 'specs/nav_specs.dart';
import 'specs/role_a_specs.dart';
import 'specs/role_b_specs.dart';
import 'specs/state_a_specs.dart';
import 'specs/state_b_specs.dart';
import 'specs/util_a_specs.dart';
import 'specs/util_b_specs.dart';

/// Animación de cada [AppIcon], reunida de los lotes (navegación, acciones de
/// rol, estados y utilitarios). Un ícono sin entrada usa [AppIconSpec.fallback].
final Map<AppIcon, AppIconSpec> kAppIconSpecs = {
  ...kNavIconSpecs,
  ...kRoleAIconSpecs,
  ...kRoleBIconSpecs,
  ...kStateAIconSpecs,
  ...kStateBIconSpecs,
  ...kUtilAIconSpecs,
  ...kUtilBIconSpecs,
};

AppIconSpec appIconSpecFor(AppIcon icon) =>
    kAppIconSpecs[icon] ?? AppIconSpec.fallback;
