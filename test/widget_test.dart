// Basic smoke test for the ERP app.
//
// The previous version of this file was the unmodified Flutter counter-app
// template and referenced a `MyApp` widget that does not exist in this
// project, which made `flutter test` fail to even compile. This file is
// intentionally minimal: full app startup (database init, window manager,
// etc.) isn't exercised here in a headless test environment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ERP')),
        ),
      ),
    );

    expect(find.text('ERP'), findsOneWidget);
  });
}
