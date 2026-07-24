import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/main.dart';

void main() {
  testWidgets('SOMA app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SomaApp());
    expect(find.text('Dashboard'), findsWidgets);
  });
}