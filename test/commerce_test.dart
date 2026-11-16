import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gijima_mfana/data/mock/catalog.dart';
import 'package:gijima_mfana/data/repositories/commerce.dart';
import 'package:gijima_mfana/data/repositories/local_store.dart';

void main() {
  late ProviderContainer c;
  late CommerceController repo;
  setUp(() {
    c = ProviderContainer();
    repo = c.read(commerceProvider.notifier);
  });
  tearDown(() => c.dispose());
  BasketState basket() => BasketState({products.first.name: 2},
      products.first.store, {products.first.name: 'Please choose intact eggs'});
  String checkout({String outcome = 'Successful', String address = 'home'}) =>
      repo.checkout(
          basket: basket(),
          addressId: address,
          note: 'At the gate',
          code: 'LOCAL10',
          method: 'Instant EFT',
          outcome: outcome);
  Record request({bool collection = false}) => {
        'type': collection ? 'Collect & deliver' : 'Personal shopping',
        'name': 'School supplies',
        'description': 'Blue notebooks',
        'quantity': 2,
        'budget': 20000,
        'business': 'Ermelo Paper & Pen',
        'collection': collection ? '10 Main Street, Ermelo' : null,
        'reference': 'DEMO-123',
        'recipient': 'Demo recipient',
        'collectionTime':
            DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'urgency': 'Today',
        'instructions': 'Keep dry',
        'addressId': 'home'
      };
  test(
      'checkout fee/discount calculations use integer cents and snapshot order data',
      () {
    final t = basketTotals(basket(), 'LOCAL10');
    expect(t.discount, 919);
    expect(t.total, 9198 + 2500 + 500 - 919);
    final id = checkout();
    final o = repo.find('orders', id)!;
    expect(o['total'], t.total);
    expect(o['payment'], 'Successful');
    expect((o['items'] as List).first['note'], 'Please choose intact eggs');
    repo.saveAddress({
      'id': 'home',
      'label': 'Home',
      'street': 'Changed street',
      'city': 'Ermelo',
      'postal': '2351',
      'default': true
    });
    expect((o['address'] as Map)['street'], '12 Acacia Street');
  });
  test(
      'minimum order and coverage block checkout; address default survives deletion',
      () {
    expect(
        () => repo.checkout(
            basket: BasketState({products.first.name: 0}, products.first.store),
            addressId: 'home',
            note: '',
            code: '',
            method: 'Card',
            outcome: 'Successful'),
        throwsStateError);
    repo.saveAddress({
      'id': 'outside',
      'label': 'Other',
      'street': '1 Demo Street',
      'city': 'Cape Town',
      'postal': '8001'
    });
    expect(() => checkout(address: 'outside'), throwsStateError);
    repo.defaultAddress('work');
    repo.deleteAddress('work');
    expect(c.read(commerceProvider).defaultAddress, isNotNull);
    expect(covered(c.read(commerceProvider).address('outside')!), false);
  });
  test('payment failures/pending retry and completed/cancelled histories', () {
    final id = checkout(outcome: 'Pending');
    repo.advanceOrder(id);
    expect(repo.find('orders', id)!['step'], 0);
    repo.retryPayment(id, 'Failed');
    expect(repo.find('orders', id)!['payment'], 'Failed');
    repo.retryPayment(id, 'Successful');
    for (var i = 0; i < 10; i++) {
      repo.advanceOrder(id);
    }
    expect(repo.find('orders', id)!['step'], orderSteps.length - 1);
    repo.cancelOrder(id);
    expect(repo.find('orders', id)!['cancelled'], false);
    final second = checkout();
    repo.cancelOrder(second);
    expect(repo.find('orders', second)!['cancelled'], true);
  });
  test('shopping quote review/accept/pay creates exactly one linked order', () {
    final id = repo.submitRequest(request());
    repo.review(id);
    expect(repo.find('requests', id)!['status'], 'Under review');
    repo.review(id);
    expect(repo.find('requests', id)!['itemPrice'], 18000);
    repo.quoteDecision(id, true);
    expect(repo.payRequest(id, 'Card', 'Pending'), null);
    final order = repo.payRequest(id, 'Card', 'Successful')!;
    expect(repo.payRequest(id, 'Card', 'Successful'), order);
    expect(c.read(commerceProvider).orders.length, 1);
    for (var i = 0; i < 10; i++) {
      repo.advanceOrder(order);
    }
    expect(repo.find('requests', id)!['status'], 'Delivered');
  });
  test('rejected quote cannot be paid; collection quotes include no item cost',
      () {
    final rejected = repo.submitRequest(request());
    repo.review(rejected);
    repo.review(rejected);
    repo.quoteDecision(rejected, false);
    expect(repo.payRequest(rejected, 'Card', 'Successful'), null);
    final id = repo.submitRequest(request(collection: true));
    final quote = repo.find('requests', id)!;
    expect(quote['status'], 'Quotation received');
    expect(quote['itemPrice'], 0);
    repo.quoteDecision(id, true);
    final order = repo.payRequest(id, 'Digital wallet', 'Successful')!;
    expect(repo.find('orders', order)!['total'], 5000);
    expect(repo.find('orders', order)!['reference'], 'DEMO-123');
  });
  test(
      'order support, conversations and refund are linked and generate notifications',
      () {
    final order = checkout();
    final ticket =
        repo.support(order, 'Refund request', 'Item arrived damaged');
    repo.reply(ticket, 'Please review the packaging');
    repo.reviewTicket(ticket);
    expect(repo.find('tickets', ticket)!['status'], 'Under review');
    repo.reviewTicket(ticket);
    expect(
        repo.find('tickets', ticket)!['refund'], 'Simulated refund approved');
    expect(repo.find('orders', order)!['refund'], 'Approved');
    expect(() => repo.support(order, 'Refund request', 'Again please'),
        throwsStateError);
    expect(
        c
            .read(commerceProvider)
            .notifications
            .any((n) => n['route'] == '/support/$ticket'),
        true);
    repo.readAll();
    expect(
        c.read(commerceProvider).notifications.every((n) => n['read'] == true),
        true);
  });
  test(
      'preferences store restores basket, notes, favourites, addresses, requests, orders and tickets',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PreferencesStore(prefs);
    final first = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    final r = first.read(commerceProvider.notifier),
        b = first.read(basketProvider.notifier);
    b.add(products.first);
    b.note(products.first.name, 'Pack carefully');
    first.read(favoritesProvider.notifier).state = {products.first.name};
    r.toggleShop('KFC');
    r.saveAddress({
      'id': 'saved',
      'label': 'Other',
      'street': '3 Demo Street',
      'city': 'Wesselton',
      'postal': '2351',
      'default': true
    });
    final req = r.submitRequest(request());
    final id = r.checkout(
        basket: basket(),
        addressId: 'saved',
        note: '',
        code: '',
        method: 'Card',
        outcome: 'Successful');
    r.support(id, 'Missing item', 'One egg was missing');
    await store.write('flush', {});
    first.dispose();
    final second = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(PreferencesStore(prefs))
    ]);
    addTearDown(second.dispose);
    expect(second.read(basketProvider).count, 1);
    expect(second.read(basketProvider).notes[products.first.name],
        'Pack carefully');
    expect(second.read(favoritesProvider), contains(products.first.name));
    final state = second.read(commerceProvider);
    expect(state.savedShops, contains('KFC'));
    expect(state.defaultAddress!['id'], 'saved');
    expect(state.requests.first['id'], req);
    expect(state.orders.first['id'], id);
    expect(state.tickets.length, 1);
    expect(state.notifications, isNotEmpty);
  });
}
