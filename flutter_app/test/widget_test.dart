import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklu/main.dart';

void main() {
  testWidgets('La pantalla de bienvenida presenta las opciones principales', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Welcome()));

    expect(find.text('INKLU'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Ya tengo una cuenta'), findsOneWidget);
    expect(find.text('Privacidad y uso de datos'), findsOneWidget);
  });

  testWidgets('El inicio de sesión muestra mantener sesión y recuperar contraseña', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Login()));

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Mantener sesión iniciada'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });

  testWidgets('La pantalla de privacidad explica el uso de los datos', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));

    expect(find.text('Privacidad y datos'), findsOneWidget);
    expect(find.text('Cómo utiliza INKLU tu información'), findsOneWidget);
    expect(find.text('Recomendaciones automáticas'), findsOneWidget);
    expect(find.text('Acceso y eliminación'), findsOneWidget);
  });
}
