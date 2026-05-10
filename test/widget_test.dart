import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smarttranslate_app/screens/welcome_page.dart';

void main() {
  testWidgets('Welcome page shows primary actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));

    expect(find.text('SmartPath Translator'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
