import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pruebasai/main.dart';

void main() {
  testWidgets('App boots and shows the pick button', (WidgetTester tester) async {
    await tester.pumpWidget(const PruebasAIApp());
    expect(find.text('Seleccionar audio y transcribir'), findsOneWidget);
    expect(find.byIcon(Icons.audio_file), findsOneWidget);
  });
}
