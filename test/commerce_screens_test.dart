// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gijima_mfana/app/app.dart';
import 'package:gijima_mfana/data/mock/catalog.dart';
import 'package:gijima_mfana/data/repositories/commerce.dart';

void main() {
  for (final width in [360.0, 1280.0]) {
    testWidgets('connected commerce screens fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final repo = c.read(commerceProvider.notifier),
          basket = c.read(basketProvider.notifier);
      basket.add(products.first);
      basket.add(products.first);
      final order = repo.checkout(
          basket: c.read(basketProvider),
          addressId: 'home',
          note: 'At the gate',
          code: 'LOCAL10',
          method: 'Card',
          outcome: 'Successful');
      final request = repo.submitRequest({
        'type': 'Personal shopping',
        'name': 'School supplies',
        'description': 'Blue notebooks',
        'quantity': 2,
        'budget': 20000,
        'business': 'Ermelo Paper & Pen',
        'instructions': 'Keep dry',
        'addressId': 'home'
      });
      repo.review(request);
      repo.review(request);
      final ticket = repo.support(order, 'Missing item', 'One egg was missing');
      await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const GijimaApp()));
      await tester.pumpAndSettle();
      for (final path in [
        '/addresses',
        '/notifications',
        '/request/new/shopping',
        '/request/new/collection',
        '/requests/$request',
        '/orders/$order',
        '/support?order=$order',
        '/support/$ticket',
        '/shop/KFC',
        '/checkout'
      ]) {
        c.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), null, reason: path);
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -1200));
          await tester.pumpAndSettle();
          expect(tester.takeException(), null, reason: 'Scrolled $path');
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('checkout creates an order and an update opens that order',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final basket = c.read(basketProvider.notifier);
    basket.add(products.first);
    basket.add(products.first);
    c.read(routerProvider).go('/checkout');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const GijimaApp()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.textContaining('Simulate payment ·'), 500,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.textContaining('Simulate payment ·'));
    await tester.pumpAndSettle();
    expect(c.read(commerceProvider).orders.length, 1);
    expect(c.read(basketProvider).count, 0);
    final order = c.read(commerceProvider).orders.first;
    expect(find.text(order['id'] as String), findsOneWidget);
    c.read(routerProvider).go('/notifications');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Payment Successful'));
    await tester.pumpAndSettle();
    expect(find.text(order['id'] as String), findsOneWidget);
    expect(c.read(commerceProvider).notifications.first['read'], true);
    await tester.pumpWidget(const SizedBox());
  });
}
