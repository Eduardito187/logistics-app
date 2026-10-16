import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/domain/dashboard_metrics.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/dashboard_body.dart';

// DashboardBody: tarjeta de resumen + grilla de mosaicos. Complementa al test de
// pantalla (supervisor_dashboard_screen_test) probando directamente el cuerpo y
// el caso de cumplimiento indefinido ('—').

void main() {
  testWidgets('muestra resumen, totales, alertas y mosaicos', (tester) async {
    const metrics = DashboardMetrics(
      received: 2,
      planned: 1,
      inExecution: 4,
      delivered: 6,
      failed: 2,
      cancelled: 0,
      activePlans: 7,
      openAlerts: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardBody(metrics: metrics, date: DateTime(2026, 3, 9)),
        ),
      ),
    );

    // Cabecera de resumen con la fecha formateada dd/MM/yyyy.
    expect(find.text('Resumen de 09/03/2026'), findsOneWidget);
    // total = 2+1+4+6+2+0 = 15.
    expect(find.text('15 envíos del día en total'), findsOneWidget);
    expect(find.text('5 alertas sin reconocer'), findsOneWidget);

    // Mosaicos (valores elegidos únicos para aserción exacta).
    expect(find.text('Entregadas'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // entregadas
    expect(find.text('En ruta'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // en ruta
    expect(find.text('Fallidas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // fallidas
    expect(find.text('Por salir'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // pending = received + planned
    expect(find.text('Rutas en curso'), findsOneWidget);
    expect(find.text('7'), findsOneWidget); // activePlans
    // Cumplimiento = 6 / (6+2) = 75 %.
    expect(find.text('Cumplimiento'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('sin entregas resueltas el cumplimiento es "—"', (tester) async {
    const metrics = DashboardMetrics(
      received: 5,
      planned: 0,
      inExecution: 0,
      delivered: 0,
      failed: 0,
      cancelled: 0,
      activePlans: 0,
      openAlerts: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardBody(metrics: metrics, date: DateTime(2026, 3, 9)),
        ),
      ),
    );

    expect(find.text('Cumplimiento'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0 alertas sin reconocer'), findsOneWidget);
  });
}
