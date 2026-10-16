import 'package:flutter/material.dart';

/// Controladores de una línea editable del formulario de etiquetas.
class LineDraft {
  LineDraft({
    String sku = '',
    String name = '',
    int quantity = 1,
    int pieces = 1,
  }) : sku = TextEditingController(text: sku),
       name = TextEditingController(text: name),
       quantity = TextEditingController(text: '$quantity'),
       pieces = TextEditingController(text: '$pieces');

  final TextEditingController sku;
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController pieces;

  void dispose() {
    sku.dispose();
    name.dispose();
    quantity.dispose();
    pieces.dispose();
  }
}
