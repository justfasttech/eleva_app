import 'package:flutter_test/flutter_test.dart';

import 'package:eleva_app/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Eleve sua fé'), findsOneWidget);
  });
}
