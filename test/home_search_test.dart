// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gijima_mfana/app/app.dart';

void main() {
  testWidgets(
      'Home search filters shops and products without leaving Home, then clears',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const GijimaApp()));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(
        TextField, 'Find a meal, groceries or your local shop');
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/');
    await tester.enterText(field, ' kFc ');
    await tester.pumpAndSettle();
    expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/');
    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('1 product · 1 shop'), findsOneWidget);
    expect(find.text('Streetwise chicken meal'), findsOneWidget);
    expect(find.text('Popular in Ermelo'), findsNothing);
    await tester.enterText(field, 'nothing matches 839');
    await tester.pumpAndSettle();
    expect(
        find.text('No matches found. Try another product, category or shop.'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Popular in Ermelo'), findsOneWidget);
    expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/');
    await tester.pumpWidget(const SizedBox());
  });
}
