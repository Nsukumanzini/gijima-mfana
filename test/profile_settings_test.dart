import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gijima_mfana/data/repositories/commerce.dart';
import 'package:gijima_mfana/data/repositories/customer_preferences.dart';
import 'package:gijima_mfana/data/repositories/local_store.dart';

void main() {
  test('profile and notification preferences persist and filter new updates',
      () async {
    final store = MemoryStore();
    final container = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    container.read(customerNameProvider.notifier).state = 'Thandi Nkosi';
    container
        .read(customerSettingsProvider.notifier)
        .update(orders: false, support: false);
    final commerce = container.read(commerceProvider.notifier);
    commerce.notify('Order', '/orders/1');
    commerce.notify('Request', '/requests/1');
    commerce.notify('Support', '/support/1');
    expect(container.read(commerceProvider).notifications.map((n) => n['text']),
        ['Request']);
    await Future<void>.delayed(Duration.zero);
    final restored = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(restored.dispose);
    expect(restored.read(customerNameProvider), 'Thandi Nkosi');
    expect(restored.read(customerSettingsProvider).orders, false);
    expect(restored.read(customerSettingsProvider).requests, true);
    expect(restored.read(customerSettingsProvider).support, false);
  });
}
