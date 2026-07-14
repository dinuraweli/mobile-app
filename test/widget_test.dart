// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sallimate_prototype/screens/financial_tools_screen.dart';

void main() {
  testWidgets('Financial tools opens the detailed tax calculator screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FinancialToolsScreen()));

    await tester.tap(find.text('APIT / PAYE Tax Calculator'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Your Monthly Earnings'), findsOneWidget);
    expect(find.text('APIT, EPF & ETF Calculator'), findsOneWidget);
  });
}
