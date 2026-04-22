// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mess_management_system/mess/mess_app.dart';

void main() {
  testWidgets('Mess app renders login screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const MessMenuApp());
    await tester.pumpAndSettle();

    expect(find.text('Mess Menu + Rating'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
