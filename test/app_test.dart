import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gijima_mfana/app/app.dart';

void main() {
  testWidgets('launches the customer home and persistent navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: GijimaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Ermelo · Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
  });
}
