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
  final addresses = [
    'Home · 12 Acacia Street, Ermelo',
    'Work · 8 Church Street, Ermelo'
  ];
  bool read = false;
  bool enabled = true;
  String language = 'English';
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
    return Scaffold(appBar: AppBar(title: Text(title)), body: _body(title));
  }

  Widget _body(String title) {
    if (title == 'Personal shopping' || title == 'Collect & deliver') {
      return const RequestsScreen();
    }
    if (['Shop local', 'Restaurants', 'Groceries'].contains(title)) {
      return const ExploreScreen();
    }
    if (title == 'Favourites') {
      final saved = ref.watch(favoritesProvider);
      final list = products.where((p) => saved.contains(p.name)).toList();
      return list.isEmpty
          ? const Center(
              child: Text('Tap a heart on any product to save it here.'))
          : GridView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 290,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12),
              itemBuilder: (c, i) => ProductCard(product: list[i]));
    }
    if (title == 'Saved addresses') {
      return ListView(padding: const EdgeInsets.all(18), children: [
        ...addresses.map((a) => Card(
            child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(a),
                trailing: IconButton(
                    onPressed: () => setState(() => addresses.remove(a)),
                    icon: const Icon(Icons.delete_outline))))),
        FilledButton.icon(
            onPressed: () => _address(),
            icon: const Icon(Icons.add),
            label: const Text('Add an address'))
      ]);
    }
    if (title == 'Notifications') {
      return ListView(padding: const EdgeInsets.all(18), children: [
        TextButton(
            onPressed: () => setState(() => read = true),
            child: const Text('Mark all as read')),
        ...[
          'Welcome to Gijima Mfana',
          'Your demo order is being prepared',
          'Your personal shopping quote is ready'
        ].map((m) => Card(
            child: ListTile(
                leading: Icon(read
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread_outlined),
                title: Text(m),
                subtitle: const Text('Local demo update · Ermelo'))))
      ]);
    }
    if (title == 'Help centre') {
      return ListView(padding: const EdgeInsets.all(18), children: [
        const Text('How can we help?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ...[
          'Where do you deliver?',
          'How do personal shopping requests work?',
          'How do I report a missing item?'
        ].map((q) => ExpansionTile(title: Text(q), children: const [
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Our demonstration service covers Ermelo. Use Requests to arrange shopping, or describe your issue below. All support activity stays in this demo.'))
            ])),
        ...messages.map((m) => Card(
            child: Padding(padding: const EdgeInsets.all(16), child: Text(m)))),
        TextField(
            controller: message,
            decoration:
                const InputDecoration(labelText: 'Describe your issue')),
        FilledButton(
            onPressed: () {
              if (message.text.trim().isNotEmpty) {
                setState(() {
                  messages.add(
                      'Ticket GM-${messages.length + 1}: ${message.text}\nReceived. Our demo support team will review your issue.');
                  message.clear();
                });
              }
            },
            child: const Text('Create demo support ticket'))
      ]);
    }
    if (title == 'Appearance') {
      return const Center(
          child: Text('Light mode is on ☀️\nGijima Mfana · Emerald & charcoal',
              textAlign: TextAlign.center));
    }
    if (title == 'Privacy & terms') {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Gijima Mfana customer prototype\n\nAll accounts, orders and payments are simulated. No real payment credentials are collected. KFC and McDonald’s are illustrative demo listings; no partnership or availability is implied. Photography is illustrative. Full service terms will be supplied before launch.'));
    }
    if (title == 'Payment preferences') {
      return ListView(children: [
        ...['Debit or credit card', 'Instant EFT', 'Digital wallet'].map((m) =>
            SwitchListTile(
                title: Text(m),
                subtitle: const Text('Demo preference only'),
                value: enabled,
                onChanged: (v) => setState(() => enabled = v)))
      ]);
    }
    if (title == 'Sign out') {
      return Center(
          child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue browsing as a guest')));
    }
    final items = products.where((p) => p.store == title).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
              items.isEmpty
                  ? 'assets/images/groceries.jpg'
                  : productImage(items.first),
              height: 220,
              fit: BoxFit.cover)),
      const SizedBox(height: 16),
      Text(title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const Text(
          'Ermelo, Mpumalanga · Demo storefront\n25–40 min · Delivery from R 25.00'),
      const SizedBox(height: 12),
      const Text(
          'Illustrative menu and sample prices. No affiliation or live ordering.'),
      const SizedBox(height: 16),
      ...items.map((p) => SizedBox(height: 300, child: ProductCard(product: p)))
    ]);
  }

  void _address() {
    final controller = TextEditingController();
    showDialog(
        context: context,
        builder: (d) => AlertDialog(
                title: const Text('Add delivery address'),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        hintText: 'Label · Street address, Ermelo')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) return;
                        setState(() => addresses.add(controller.text.trim()));
                        Navigator.pop(d);
                      },
                      child: const Text('Save address'))
                ]));
  }
}
