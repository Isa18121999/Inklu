import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklu/main.dart';

void main() {
  test('el filtro Retirada reconoce el estado completo de la postulación', () {
    expect(
      applicationStatusMatchesFilter('Retirada por candidato', 'Retirada'),
      isTrue,
    );
    expect(
      applicationStatusMatchesFilter('Postulado', 'Retirada'),
      isFalse,
    );
    expect(
      applicationStatusMatchesFilter('Postulada', 'Postulado'),
      isTrue,
    );
  });


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


  testWidgets('Las recomendaciones explican los criterios de coincidencia', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: JobRecommendationCard(
              job: {
                '_id': 'job-tech',
                'title': 'Desarrolladora Flutter',
                'companyId': {'name': 'Empresa inclusiva'},
                'matchScore': 82,
                'matchReasons': ['Área profesional relacionada con tu carrera o CV', 'Habilidades relacionadas: Flutter, Dart'],
                'matchedSkills': ['Flutter', 'Dart'],
                'matchedPreferredSkills': ['Git'],
                'experienceRequired': 1,
                'experienceFit': true,
              },
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Coincidencia estimada: 82%'), findsOneWidget);
    await tester.ensureVisible(find.text('Ver por qué se recomienda'));
    await tester.tap(find.text('Ver por qué se recomienda'));
    await tester.pumpAndSettle();

    expect(find.text('¿Por qué te recomendamos esta oferta?'), findsOneWidget);
    expect(find.text('Habilidades de tu perfil que coinciden'), findsOneWidget);
    expect(find.textContaining('No garantiza una entrevista'), findsOneWidget);
  });

  testWidgets('La empresa puede expandir la información profesional de un postulante', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompanyApplicationCard(
              token: 'test-token',
              onStatusChanged: (_) {},
              application: {
                '_id': 'application-1',
                'status': 'Postulado',
                'candidateId': {
                  'name': 'Candidata Demo',
                  'profile': {
                    'education': 'Ingeniería de Sistemas',
                    'professionalSummary': 'Desarrolladora con experiencia en aplicaciones móviles.',
                    'experience': 2,
                    'skills': ['Flutter', 'Dart'],
                    'projects': ['Aplicación móvil inclusiva'],
                    'certifications': ['Curso de accesibilidad digital'],
                  },
                  'cvAnalysis': {'skills': ['Flutter']},
                  'cv': {'fileName': 'cv-demo.pdf', 'size': 1024},
                },
                'jobId': {'title': 'Desarrolladora Flutter'},
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Candidata Demo'), findsOneWidget);
    await tester.ensureVisible(find.text('Ver perfil profesional'));
    await tester.tap(find.text('Ver perfil profesional'));
    await tester.pumpAndSettle();

    expect(find.text('Ingeniería de Sistemas'), findsOneWidget);
    expect(find.text('Desarrolladora con experiencia en aplicaciones móviles.'), findsOneWidget);
    expect(find.text('Aplicación móvil inclusiva'), findsOneWidget);
    expect(find.text('Curso de accesibilidad digital'), findsOneWidget);
  });

  testWidgets('Las pantallas esenciales no desbordan con texto ampliado al 200%', (WidgetTester tester) async {
    for (final page in <Widget>[
      const Welcome(),
      const Login(),
      const PrivacyPolicyPage(),
      JobRecommendationCard(
        job: {
          '_id': 'accessibility-job',
          'title': 'Especialista en accesibilidad digital',
          'companyId': {'name': 'Empresa inclusiva'},
          'matchScore': 84,
          'matchReasons': [
            'Área profesional relacionada con tu carrera o CV',
            'Habilidades relacionadas: accesibilidad digital, Flutter, documentación',
          ],
          'matchedSkills': ['Accesibilidad digital', 'Flutter'],
          'matchedPreferredSkills': ['Pruebas de usabilidad'],
          'experienceRequired': 1,
          'experienceFit': true,
        },
        onTap: () {},
      ),
      CompanyApplicationCard(
        token: 'test-token',
        onStatusChanged: (_) {},
        application: {
          '_id': 'accessibility-application',
          'status': 'Postulado',
          'candidateId': {
            'name': 'Persona candidata de prueba',
            'profile': {
              'education': 'Ingeniería de Sistemas',
              'professionalSummary': 'Perfil de prueba con resumen profesional largo para comprobar el flujo accesible.',
              'experience': 2,
              'skills': ['Flutter', 'SQL', 'Accesibilidad digital'],
              'projects': ['Aplicación móvil inclusiva'],
              'certifications': ['Curso de accesibilidad digital'],
            },
            'cvAnalysis': {'skills': ['Flutter']},
          },
          'jobId': {'title': 'Desarrolladora Flutter'},
        },
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(2.0),
              ),
              child: page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });


  testWidgets('La tarjeta de recomendación explica las coincidencias y sus límites', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: JobRecommendationCard(
                job: {
                  '_id': 'job-test',
                  'title': 'Analista de datos',
                  'companyId': {'name': 'Empresa de prueba'},
                  'matchScore': 82,
                  'matchReasons': ['Área profesional relacionada con tu carrera o CV', 'Habilidades relacionadas: SQL, Python'],
                  'matchedSkills': ['SQL', 'Python'],
                  'matchedPreferredSkills': ['Power BI'],
                  'experienceRequired': 1,
                  'experienceFit': true,
                },
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final explanationButton = find.text('Ver por qué se recomienda');
    expect(explanationButton, findsOneWidget);
    await tester.ensureVisible(explanationButton);
    await tester.tap(explanationButton);
    await tester.pumpAndSettle();

    expect(find.text('¿Por qué te recomendamos esta oferta?'), findsOneWidget);
    expect(find.text('82% de coincidencia orientativa'), findsOneWidget);
    expect(find.text('Habilidades de tu perfil que coinciden'), findsOneWidget);
    expect(find.textContaining('No garantiza una entrevista ni una contratación'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

}
