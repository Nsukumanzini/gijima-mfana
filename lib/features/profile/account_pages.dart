import '../../data/repositories/local_store.dart';
import '../commerce/addresses.dart';
import '../commerce/notifications.dart';
import '../commerce/support.dart';
import '../commerce/storefront.dart';
import '../../data/repositories/commerce.dart';
import 'package:go_router/go_router.dart';
import '../../shared/components/brand_text.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_card.dart';
import '../requests/requests_screen.dart';
import '../explore/explore_screen.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key, required this.title});
  final String title;
  @override
  ConsumerState<AccountPage> createState() => _AccountState();
}

class _AccountState extends ConsumerState<AccountPage> {
  final message = TextEditingController();
  final messages = <String>[];
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    if (title == 'Personal shopping') {
      return const RequestForm(collection: false);
    }
    if (title == 'Collect & deliver') {
      return const RequestForm(collection: true);
    }
    if (title == 'Saved addresses') return const AddressesScreen();
    if (title == 'Notifications') return const NotificationsScreen();
    if (title == 'Help centre') return const SupportScreen();
    if (![
      'Shop local',
      'Restaurants',
      'Groceries',
      'Favourites',
      'Appearance',
      'Privacy & terms',
      'Payment preferences',
      'Sign out'
    ].contains(title)) {
      return Storefront(name: title);
    }
    return Scaffold(appBar: AppBar(title: Text(title)), body: _body(title));
  }

  Widget _body(String title) {
    if (title == 'Personal shopping') {
      return const RequestForm(collection: false);
    }
    if (title == 'Collect & deliver') {
      return const RequestForm(collection: true);
    }
    if (title == 'Saved addresses') return const AddressesScreen();
    if (title == 'Notifications') return const NotificationsScreen();
    if (title == 'Help centre') return const SupportScreen();
    if (['Shop local', 'Restaurants', 'Groceries'].contains(title)) {
      return ExploreScreen(
          initialCategory: title == 'Shop local' ? 'All' : title);
    }
    if (title == 'Favourites') {
      final saved = ref.watch(favoritesProvider),
          shops = ref.watch(commerceProvider).savedShops;
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Saved businesses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (shops.isEmpty) const Text('Save a business from its storefront.'),
        ...shops.map((s) => ListTile(
            title: Text(s),
            trailing: IconButton(
                onPressed: () =>
                    ref.read(commerceProvider.notifier).toggleShop(s),
                icon: const Icon(Icons.favorite)),
            onTap: () => context.push('/shop/${Uri.encodeComponent(s)}'))),
        const Text('Saved products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (saved.isEmpty) const Text('Tap a product heart to save it.'),
        ...products
            .where((p) => saved.contains(p.name))
            .map((p) => SizedBox(height: 290, child: ProductCard(product: p))),
      ]);
    }
    if (title == 'Appearance') {
      return const Center(
          child: BrandText(
              'Light mode is on ☀️\nGijima Mfana · Emerald & charcoal',
              textAlign: TextAlign.center));
    }
    if (title == 'Privacy & terms') {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: BrandText(
              'Gijima Mfana customer prototype\n\nAll accounts, orders and payments are simulated. No real payment credentials are collected. KFC and McDonald’s are illustrative demo listings; no partnership or availability is implied. Photography is illustrative. Full service terms will be supplied before launch.'));
    }
    if (title == 'Payment preferences') {
      final selected = ref.watch(preferredPaymentProvider);
      return RadioGroup<String>(
          groupValue: selected,
          onChanged: (v) =>
              ref.read(preferredPaymentProvider.notifier).state = v!,
          child: ListView(children: [
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                    'Choose the default online method for demo payments. No payment credentials are stored.')),
            ...['Card', 'Instant EFT', 'Digital wallet']
                .map((m) => RadioListTile<String>(value: m, title: Text(m))),
          ]));
    }
    if (title == 'Sign out') {
      return Center(
          child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue browsing as a guest')));
    }
    return Storefront(name: title);
  }
}
