import 'label_format_exception.dart';

/// "N de M": la unidad 1 de 2 del mismo producto, o la pieza (caja) 2 de 3.
class Fraction {
  Fraction(this.index, this.total) {
    if (total < 1 || total > 999) {
      throw LabelFormatException('total fuera de rango (1..999): $total');
    }
    if (index < 1 || index > total) {
      throw LabelFormatException('índice $index fuera de 1..$total');
    }
  }

  final int index;
  final int total;

  String toCanonical() => '$index/$total';

  @override
  bool operator ==(Object other) =>
      other is Fraction && other.index == index && other.total == total;

  @override
  int get hashCode => Object.hash(index, total);
}
