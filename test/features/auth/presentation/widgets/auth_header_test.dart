import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/auth/presentation/widgets/auth_header.dart';

// Encabezado de marca del login (DisTrack): logo SVG, wordmark+lema y bajada.
// Widget puro.

void main() {
  testWidgets('muestra el logo de marca y la bajada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AuthHeader())),
    );

    // Logo/wordmark DisTrack como SVG (con etiqueta semántica de marca).
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('DisTrack')), findsWidgets);
    expect(
      find.text('La operación de reparto y tienda, en una sola app.'),
      findsOneWidget,
    );
  });
}
