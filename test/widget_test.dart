import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:barangaytest/app_state.dart';
import 'package:barangaytest/main.dart';

void main() {
  testWidgets('BarangayApp smoke test: app renders login screen successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const BarangayApp(),
      ),
    );

    // Verify App renders successfully without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
