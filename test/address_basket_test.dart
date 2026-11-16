// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gijima_mfana/app/app.dart';
import 'package:gijima_mfana/data/mock/catalog.dart';
import 'package:gijima_mfana/data/repositories/commerce.dart';
import 'package:gijima_mfana/features/shell/shell.dart';

void main() {
  testWidgets('address editor saves user input and supports subsequent edits',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(routerProvider).go('/addresses');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const GijimaApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add address'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Label (Home, Work or Other)'),
        'Other');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Street and building'),
        '4 Demo Road');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    final saved = c.read(commerceProvider).addresses.last;
    expect(saved['street'], '4 Demo Road');
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Street and building'),
        '5 Demo Road');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(c.read(commerceProvider).addresses.last['street'], '5 Demo Road');
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'basket scrolls on a phone and item instructions update local state',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(basketProvider.notifier).add(products.first);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: CartSheet()))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Pack carefully');
    await tester.pumpAndSettle();
    expect(c.read(basketProvider).notes[products.first.name], 'Pack carefully');
    expect(find.text('Service fee'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });
}
