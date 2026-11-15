import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gijima_mfana/data/mock/catalog.dart';

void main() {
  test('basket uses cents and rejects a second merchant', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final basket = container.read(basketProvider.notifier);
    expect(basket.add(products[0]), isTrue);
    expect(basket.add(products[0]), isTrue);
    expect(container.read(basketProvider).count, 2);
    expect(container.read(basketProvider).subtotal, products[0].priceCents * 2);
    final otherMerchant =
        products.firstWhere((p) => p.store != products[0].store);
    expect(basket.add(otherMerchant), isFalse);
    basket.quantity(products[0].name, 0);
    expect(container.read(basketProvider).count, 0);
  });
}
