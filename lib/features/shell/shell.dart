import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/catalog.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../requests/requests_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    ExploreScreen(),
    RequestsScreen(),
    OrdersScreen(),
    ProfileScreen()
  ];
  @override
  Widget build(BuildContext context) {
    final count = ref.watch(basketProvider).count;
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      floatingActionButton: count == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _cart(context),
              icon: const Icon(Icons.shopping_basket_outlined),
              label: Text('Cart · $count')),
      bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Requests'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile')
          ]),
    );
  }

  void _cart(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => const CartSheet());
  }
}

class CartSheet extends ConsumerWidget {
  const CartSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final fee = basket.lines.isEmpty ? 0 : 2500;
    return SafeArea(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Your basket',
                            style: TextStyle(
                                fontSize: 23, fontWeight: FontWeight.w800))),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ]),
                  if (basket.merchant != null)
                    Text('From ${basket.merchant}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  if (basket.lines.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Your basket is empty. Explore local favourites to get started.')),
                  ...basket.lines.entries.map((e) {
                    final p = products.firstWhere((p) => p.name == e.key);
                    return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        subtitle: Text(
                            'R ${(p.priceCents / 100).toStringAsFixed(2)}'),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              onPressed: () => ref
                                  .read(basketProvider.notifier)
                                  .quantity(e.key, e.value - 1),
                              icon: const Icon(Icons.remove_circle_outline)),
                          Text('${e.value}'),
                          IconButton(
                              onPressed: () => ref
                                  .read(basketProvider.notifier)
                                  .quantity(e.key, e.value + 1),
                              icon: const Icon(Icons.add_circle_outline))
                        ]));
                  }),
                  if (basket.count > 0) ...[
                    const Divider(),
                    _money('Subtotal', basket.subtotal),
                    _money('Delivery fee', fee),
                    _money('Total', basket.subtotal + fee, bold: true),
                    const SizedBox(height: 12),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            onPressed: () => context.push('/checkout'),
                            child: const Text('Continue to checkout')))
                  ]
                ])));
  }

  Widget _money(String label, int cents, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(fontWeight: bold ? FontWeight.bold : null))),
        Text('R ${(cents / 100).toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null))
      ]));
}
