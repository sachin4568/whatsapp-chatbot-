//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:organization_chat/main.dart';

void main() {
  testWidgets('shows the prototype mode selection screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WhatsAppSchoolPrototype());

    expect(find.text('School WhatsApp Prototype'), findsOneWidget);
    expect(find.text('Start User Mode'), findsOneWidget);
    expect(find.text('Add New Business'), findsOneWidget);
    expect(find.text('Open Business Mode'), findsOneWidget);
  });
}
