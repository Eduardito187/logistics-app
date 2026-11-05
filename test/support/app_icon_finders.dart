import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/icons/icons.dart';

/// Busca un [AnimatedAppIcon] por su [AppIcon] (reemplaza a `find.byIcon(Icons.x)`
/// desde que la app usa los íconos custom DisTrack).
Finder findAppIcon(AppIcon icon) => find.byWidgetPredicate(
  (Widget w) => w is AnimatedAppIcon && w.icon == icon,
  description: 'AnimatedAppIcon($icon)',
);

/// Igual que [findAppIcon] pero exigiendo además un [AppIconState].
Finder findAppIconInState(AppIcon icon, AppIconState state) =>
    find.byWidgetPredicate(
      (Widget w) => w is AnimatedAppIcon && w.icon == icon && w.state == state,
      description: 'AnimatedAppIcon($icon, $state)',
    );
