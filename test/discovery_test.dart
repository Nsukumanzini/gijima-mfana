// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gijima_mfana/app/app.dart';
import 'package:gijima_mfana/data/mock/catalog.dart';
import 'package:gijima_mfana/data/repositories/commerce.dart';
import 'package:gijima_mfana/data/repositories/local_store.dart';

void main() {
  test('recent views are deduplicated and restored from device storage',
      () async {
    final store = MemoryStore();
    final c = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    c.read(recentlyViewedProvider.notifier).record(products[0].name);
    c.read(recentlyViewedProvider.notifier).record(products[1].name);
    c.read(recentlyViewedProvider.notifier).record(products[0].name);
    await store.write('flush', {});
    expect(
        c.read(recentlyViewedProvider), [products[0].name, products[1].name]);
    c.dispose();
    final other = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(other.dispose);
    expect(other.read(recentlyViewedProvider),
        [products[0].name, products[1].name]);
    other.read(recentlyViewedProvider.notifier).clear();
    expect(other.read(recentlyViewedProvider), isEmpty);
  });
  testWidgets('product quantity, notes, favourites, and shop filtering work',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c
        .read(routerProvider)
        .go('/product/${Uri.encodeComponent(products.first.name)}');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const GijimaApp()));
    await tester.pumpAndSettle();
    expect(c.read(recentlyViewedProvider), [products.first.name]);
    await tester.tap(find.byTooltip('Save to favourites'));
    await tester.pumpAndSettle();
    expect(c.read(favoritesProvider), contains(products.first.name));
    await tester.tap(find.byTooltip('Remove from favourites'));
    await tester.pumpAndSettle();
    expect(c.read(favoritesProvider), isEmpty);
    await tester.scrollUntilVisible(find.byIcon(Icons.add_circle_outline), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.enterText(find.byType(TextField), 'Handle carefully');
    await tester.scrollUntilVisible(find.textContaining('Add to basket ·'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.textContaining('Add to basket ·'));
    await tester.pumpAndSettle();
    expect(c.read(basketProvider).count, 2);
    expect(
        c.read(basketProvider).notes[products.first.name], 'Handle carefully');
    c.read(routerProvider).go('/discover');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'KFC');
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'KFC'),
        findsOneWidget);
    expect(find.text('1 shop'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reorder asks before replacing a different merchant basket',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final repo = c.read(commerceProvider.notifier);
    final item = products.first;
    final id = repo.checkout(
        basket: BasketState(
            {item.name: 2}, item.store, {item.name: 'Please pack well'}),
        addressId: 'home',
        note: '',
        code: '',
        method: 'Card',
        outcome: 'Successful');
    final other = products.firstWhere((p) => p.store != item.store);
    c.read(basketProvider.notifier).add(other);
    c.read(routerProvider).go('/orders/$id');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const GijimaApp()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Add these items to basket again'), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Add these items to basket again'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new basket?'), findsOneWidget);
    await tester.tap(find.text('Keep basket'));
    await tester.pumpAndSettle();
    expect(c.read(basketProvider).merchant, other.store);
    await tester.tap(find.text('Add these items to basket again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace basket'));
    await tester.pumpAndSettle();
    expect(c.read(basketProvider).lines[item.name], 2);
    expect(c.read(basketProvider).notes[item.name], 'Please pack well');
    await tester.pumpWidget(const SizedBox());
  });
}
