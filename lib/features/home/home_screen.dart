// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_card.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  final controller = PageController();
  Timer? timer;
  int slide = 0;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (controller.hasClients && !MediaQuery.of(context).disableAnimations) {
        controller.animateToPage((slide + 1) % 3,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Image.asset('assets/brand/courier.png',
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                                semanticLabel: 'Gijima Mfana courier symbol')),
                        const Expanded(
                            child: Text('Gijima Mfana',
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    color: Brand.green))),
                        IconButton(
                            onPressed: () =>
                                context.push('/account/Notifications'),
                            icon: const Badge(
                                child: Icon(Icons.notifications_outlined)))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            color: Brand.green, size: 18),
                        TextButton(
                            onPressed: () =>
                                context.push('/account/Saved addresses'),
                            child: const Text('Ermelo · Home')),
                        const Spacer(),
                        const Text('🇿🇦  Mzansi',
                            style: TextStyle(fontWeight: FontWeight.w600))
                      ]),
                      const SizedBox(height: 16),
                      const Text('Sawubona, Sihle 👋',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 4),
                      const Text('Your local favourites. A few taps away.',
                          style:
                              TextStyle(color: Colors.black54, fontSize: 16)),
                      const SizedBox(height: 20),
                      TextField(
                          readOnly: true,
                          onTap: () => context.push('/account/Shop local'),
                          decoration: const InputDecoration(
                              hintText:
                                  'Find a meal, groceries or your local shop',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: Icon(Icons.tune))),
                      const SizedBox(height: 22),
                      SizedBox(
                          height: 240,
                          child: PageView(
                              controller: controller,
                              onPageChanged: (v) => setState(() => slide = v),
                              children: [
                                _banner(
                                    'Local is lekker.',
                                    'Explore shops across Ermelo',
                                    'south-africa.jpg',
                                    'Shop local'),
                                _banner(
                                    'A proper lunch break.',
                                    'Chicken, burgers & local favourites',
                                    'chicken.jpg',
                                    'Restaurants'),
                                _banner(
                                    'Fresh for the week.',
                                    'Fill your basket with everyday essentials',
                                    'groceries.jpg',
                                    'Groceries')
                              ])),
                      const SizedBox(height: 12),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              3,
                              (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.all(3),
                                  width: slide == i ? 26 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                      color: slide == i
                                          ? Brand.green
                                          : Colors.black12,
                                      borderRadius:
                                          BorderRadius.circular(8))))),
                      const SizedBox(height: 24),
                      const Text('What do you need today?',
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Row(children: [
                        _service('Shop', 'Everyday favourites',
                            Icons.storefront, 'Shop local'),
                        const SizedBox(width: 10),
                        _service('Personal shopping', 'We’ll find it for you',
                            Icons.shopping_bag_outlined, 'Personal shopping'),
                        const SizedBox(width: 10),
                        _service('Collect & deliver', 'From A to your door',
                            Icons.delivery_dining, 'Collect & deliver')
                      ]),
                      const SizedBox(height: 26),
                      const Text('Around your neighbourhood',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 21)),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: 90,
                          child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                'KFC',
                                'McDonald’s',
                                'Highveld Farm Store',
                                'Ermelo Fresh Market',
                                'The Daily Crumb'
                              ]
                                  .map((s) => Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: ActionChip(
                                          avatar: const Icon(Icons.storefront,
                                              size: 18),
                                          label: Text(s),
                                          onPressed: () => context.push(
                                              '/account/${Uri.encodeComponent(s)}'))))
                                  .toList())),
                      const Text('Popular in Ermelo',
                          style: TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Something good, from somewhere nearby.',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 14),
                    ]))),
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
            sliver: SliverLayoutBuilder(
                builder: (context, c) => SliverGrid.builder(
                    itemCount: products.length,
                    itemBuilder: (c, i) => ProductCard(product: products[i]),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.crossAxisExtent > 1000
                            ? 4
                            : c.crossAxisExtent > 650
                                ? 3
                                : 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: .84))))
      ]);
  Widget _banner(String title, String sub, String photo, String page) =>
      ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/$photo', fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: .48)),
            Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('GIJIMA MFANA • ERMELO',
                          style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 2,
                              fontSize: 11)),
                      const SizedBox(height: 12),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      Text(sub, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 14),
                      FilledButton(
                          onPressed: () => context.push('/account/$page'),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Brand.green),
                          child: const Text('Explore now  →'))
                    ]))
          ]));
  Widget _service(String title, String sub, IconData icon, String page) =>
      Expanded(
          child: InkWell(
              onTap: () => context.push('/account/$page'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                  height: 135,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Brand.mint,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: Brand.green, size: 29),
                        const Spacer(),
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(sub,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54))
                      ]))));
}
