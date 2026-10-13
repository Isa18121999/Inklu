import 'package:flutter_test/flutter_test.dart';
import 'package:inklu/main.dart';

void main() {
  testWidgets('INKLU welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const InkluApp());
    await tester.pump();
    expect(find.text('Comenzar'), findsOneWidget);
  });
}
