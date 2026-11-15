import 'package:flutter/material.dart';

/// Foto chica de un producto (lista de un pedido). Sin foto, o si no carga,
/// no ocupa lugar. Se decodifica al tamaño en que se muestra (memoria).
class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.imageUrl, this.size = 56});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final cache = (size * dpr).round();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image(
          image: ResizeImage(
            NetworkImage(url),
            width: cache,
            height: cache,
            policy: ResizeImagePolicy.fit,
          ),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
