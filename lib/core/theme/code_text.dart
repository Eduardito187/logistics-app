import 'package:flutter/material.dart';

/// Texto monoespaciado para VALORES tipo código/identificador: números de
/// pedido (SC-104832), ids de bulto, SKU, ids de liquidación/plan, uuid de
/// dispositivo, referencias de tracking/envío, etc.
///
/// Aplica IBM Plex Mono 500 (familia `IBMPlexMono`, ya bundleada y declarada en
/// `pubspec.yaml`), según el brand kit DisTrack. La regla es conservadora: la
/// mono va SOLO en el valor, nunca en la etiqueta ni en el texto corrido.
///
/// Hereda tamaño y color del estilo del contexto (`DefaultTextStyle` y, cuando
/// se pasa, de `style`): solo cambia la familia y activa cifras tabulares para
/// que los dígitos no "bailen" al alinearse en listas. Úsalo como reemplazo
/// directo de un `Text` que muestra únicamente el valor:
///
/// ```dart
/// CodeText(order.number)                 // en vez de Text(order.number)
/// CodeText(label.sku, style: titleStyle) // hereda el titleStyle y lo pasa a mono
/// ```
///
/// Para casos donde ya se arma un `TextStyle` con `copyWith`, usá
/// [CodeText.mono] para aplicar la familia mono sobre ese estilo base.
class CodeText extends StatelessWidget {
  const CodeText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
  });

  /// El valor tipo código a mostrar (ya formateado por quien llama).
  final String data;

  /// Estilo base opcional; se le superpone la familia mono conservando lo demás.
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;

  /// Superpone la familia mono (IBM Plex Mono) y las cifras tabulares sobre
  /// [base], conservando tamaño, color y peso. Útil en llamadas a `copyWith`:
  /// `theme.textTheme.titleMedium.let(CodeText.mono)` o directamente
  /// `CodeText.mono(theme.textTheme.titleMedium)`.
  static TextStyle mono(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(
        fontFamily: 'IBMPlexMono',
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  @override
  Widget build(BuildContext context) {
    final effective = style == null ? mono(const TextStyle()) : mono(style);
    return Text(
      data,
      style: effective,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}
