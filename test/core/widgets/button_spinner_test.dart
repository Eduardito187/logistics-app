import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/widgets/button_spinner.dart';

// NOTA DE UBICACIÓN: el enunciado lista ButtonSpinner entre los widgets de
// core/widgets, pero en el código vive en features/picking/.../widgets/. Como
// las reglas acotan la escritura a test/core/widgets/, su test se deja aquí e
// importa desde su ubicación real.

void main() {
  testWidgets('es un CircularProgressIndicator de 18x18 con strokeWidth 2', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ButtonSpinner())),
      ),
    );

    final sized = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sized.width, 18);
    expect(sized.height, 18);

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.strokeWidth, 2);
  });
}
