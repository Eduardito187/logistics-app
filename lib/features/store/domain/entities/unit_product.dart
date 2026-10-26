import '../../../../core/api/models/node_reception_unit.dart';
import '../../../../core/api/models/unit_tracking.dart';

/// Producto de cada unidad de una recepción, por id de unidad.
Map<String, UnitProduct> receptionProducts(List<NodeReceptionUnit>? units) => {
  for (final u in units ?? const <NodeReceptionUnit>[])
    u.unitId: UnitProduct(
      sku: u.sku,
      name: u.productName,
      imageUrl: u.productImageUrl,
      pieceIndex: u.pieceIndex,
      pieceTotal: u.pieceTotal,
    ),
};

/// Producto de una unidad del seguimiento (recojo en tienda).
UnitProduct trackingProduct(UnitTracking unit) => UnitProduct(
  sku: unit.sku,
  name: unit.productName,
  imageUrl: unit.productImageUrl,
  pieceIndex: unit.pieceIndex,
  pieceTotal: unit.pieceTotal,
);

/// Producto al que corresponde una unidad física (lo que la tienda recibe o
/// entrega). Una unidad es un producto o, si el producto viaja en varias cajas,
/// una pieza de él ([pieceIndex] de [pieceTotal]).
class UnitProduct {
  const UnitProduct({
    this.sku,
    this.name,
    this.imageUrl,
    this.pieceIndex,
    this.pieceTotal,
  });

  final String? sku;
  final String? name;
  final String? imageUrl;
  final int? pieceIndex;
  final int? pieceTotal;

  /// "Pieza 1 de 2" si el producto viaja en más de una caja; si no, `null`.
  String? get pieceLabel {
    final index = pieceIndex;
    final total = pieceTotal;
    if (index == null || total == null || total <= 1) return null;
    return 'Pieza $index de $total';
  }
}
