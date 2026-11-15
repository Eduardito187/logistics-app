import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Vector de marca (logo, isotipo) PRECOMPILADO.
///
/// `SvgPicture.asset` interpreta el SVG al vuelo en un hilo secundario
/// (isolate) en release; en algunos arranques ese hilo no respondía y el logo
/// quedaba EN BLANCO hasta cerrar y abrir la app. Acá se carga el binario ya
/// compilado (`<asset>.vec`, generado con `vector_graphics_compiler`), que se
/// lee directo del bundle: sin interpretar nada y sin hilo secundario.
///
/// Al cambiar un SVG de `assets/brand/` hay que regenerar su `.vec`:
/// `dart run vector_graphics_compiler -i assets/brand/x.svg -o assets/brand/x.svg.vec`
class BrandVector extends StatelessWidget {
  const BrandVector(
    this.svgAsset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
    this.errorBuilder,
  });

  /// Ruta del SVG fuente (`assets/brand/x.svg`); se carga su `.vec`.
  final String svgAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticsLabel;
  final Widget Function(BuildContext, Object, StackTrace)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return SvgPicture(
      _CompiledAssetLoader('$svgAsset.vec'),
      width: width,
      height: height,
      fit: fit,
      semanticsLabel: semanticsLabel,
      errorBuilder: errorBuilder,
    );
  }
}

/// Lee del bundle un vector ya compilado. Sin isolate.
class _CompiledAssetLoader extends BytesLoader {
  const _CompiledAssetLoader(this.asset);

  final String asset;

  @override
  Future<ByteData> loadBytes(BuildContext? context) => rootBundle.load(asset);

  @override
  int get hashCode => asset.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _CompiledAssetLoader && other.asset == asset;
}
