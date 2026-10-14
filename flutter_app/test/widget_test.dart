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

    // El título y el botón principal comparten el mismo texto.
    expect(find.text('Iniciar sesión'), findsNWidgets(2));
    expect(find.text('Mantener sesión iniciada'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });

  testWidgets('La pantalla de privacidad explica el uso de los datos', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));

    expect(find.text('Privacidad y datos'), findsOneWidget);
    expect(find.text('Cómo utiliza INKLU tu información'), findsOneWidget);
    expect(find.text('Datos que puedes proporcionar'), findsOneWidget);
  });
  testWidgets('El panel muestra el aviso para verificar el correo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EmailVerificationBanner(token: 'test-token'),
          ),
        ),
      ),
    );

    expect(find.text('Verifica tu correo electrónico'), findsOneWidget);
    expect(find.text('Verificar / reenviar correo'), findsOneWidget);
  });

}
