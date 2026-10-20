import 'package:flutter/material.dart';

/// Marca del tema de alto contraste. Los widgets compartidos (p. ej. la
/// pastilla de estado) la leen para cambiar a colores sólidos y bordes gruesos
/// sin depender de comparar instancias de [ThemeData].
@immutable
class AppContrast extends ThemeExtension<AppContrast> {
  const AppContrast({required this.high});

  /// `true` en el tema de alto contraste (sol fuerte).
  final bool high;

  /// Lee la marca del tema actual; `false` si el tema no la trae.
  static bool isHigh(BuildContext context) =>
      Theme.of(context).extension<AppContrast>()?.high ?? false;

  @override
  AppContrast copyWith({bool? high}) => AppContrast(high: high ?? this.high);

  @override
  AppContrast lerp(covariant AppContrast? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
