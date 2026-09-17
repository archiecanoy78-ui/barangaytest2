import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:barangaytest/app_state.dart';
import 'package:barangaytest/main.dart';

void main() {
  testWidgets('BarangayApp smoke test: reference UI announcement feed and centralized report modal', (WidgetTester tester) async {
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

    // Verify Role Selection Screen displays
    expect(find.text('E-Reportyan'), findsOneWidget);
    expect(find.text('I am a Resident'), findsOneWidget);

    // Tap 'I am a Resident' to login as resident
    await tester.tap(find.text('I am a Resident'));
    await tester.pumpAndSettle();

    // Verify Reference UI Top Bar
    expect(find.text('BARANGAY CENTRAL'), findsOneWidget);
    expect(find.text('Announcements'), findsOneWidget);

    // Verify Reference Filter Chips
    expect(find.text('All Updates'), findsOneWidget);
    expect(find.text('⚠️ Urgent Advisories'), findsOneWidget);
    expect(find.text('🏥 Health & Safety'), findsOneWidget);

    // Verify High Priority Card
    expect(find.text('HIGH PRIORITY'), findsOneWidget);
    expect(find.text('Scheduled Water Supply Interruption & Relief Tank Station Setup'), findsOneWidget);

    // Verify Community Assistance Banner
    expect(find.text('Need Community Assistance?'), findsOneWidget);

    // Verify Community Feed Section & Items
    expect(find.text('COMMUNITY FEED'), findsOneWidget);
    expect(find.text('Barangay Health Center'), findsOneWidget);
    expect(find.text('Barangay Security & Tanod Desk'), findsOneWidget);

    // Verify bottom navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Directory'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap central Report button in bottom nav
    await tester.tap(find.byIcon(Icons.campaign_rounded));
    await tester.pumpAndSettle();

    // Verify Centralized Report modal opens with options
    expect(find.text('Centralized Report Portal'), findsOneWidget);
    expect(find.text('Emergency Assistance (SOS)'), findsOneWidget);
    expect(find.text('Standard Community Report'), findsOneWidget);
  });
}
