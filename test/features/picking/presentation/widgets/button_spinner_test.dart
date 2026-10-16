import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/widgets/button_spinner.dart';

// Spinner pequeño para dentro de un botón mientras hay una operación en curso.

void main() {
  testWidgets('muestra un CircularProgressIndicator de 18x18', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ButtonSpinner())),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final box = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(SizedBox),
      ),
    );
    expect(box.width, 18);
    expect(box.height, 18);

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.strokeWidth, 2);
  });
}
