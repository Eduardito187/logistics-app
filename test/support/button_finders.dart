import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Buscadores de botones que aceptan subclases. En Flutter 3.32,
// `FilledButton.icon` / `OutlinedButton.icon` crean una subclase privada y
// `find.byType` / `find.widgetWithText` (que comparan el tipo EXACTO) no los
// encuentran; en versiones nuevas son la misma clase. Con estos los tests
// funcionan en ambas.

/// Botones de tipo [T] (o subclase) que contienen el texto [text].
Finder findButtonWithText<T extends Widget>(String text) => find.ancestor(
  of: find.text(text),
  matching: find.byWidgetPredicate((w) => w is T),
);

/// Botones de tipo [T] (o subclase).
Finder findButton<T extends Widget>() => find.byWidgetPredicate((w) => w is T);
