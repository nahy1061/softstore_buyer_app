import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/app/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SoftstoreBuyerApp());
    expect(find.byType(SoftstoreBuyerApp), findsOneWidget);
  });
}
