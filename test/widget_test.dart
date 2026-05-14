// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:tiermetry/main.dart';

void main() {
  testWidgets('App boots (smoke test)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Let initial mocked fetch timers complete (they use Future.delayed).
    await tester.pump(const Duration(seconds: 3));

    // Root top bar title on the initial tab.
    expect(find.text('TIERMETRY'), findsOneWidget);

    // Flush timers scheduled by staggered animations.
    await tester.pump(const Duration(milliseconds: 250));
  });
}
