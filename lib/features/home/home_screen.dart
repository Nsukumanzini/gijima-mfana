import '../../app/localization/strings.dart';
import '../../shared/components/brand_text.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_card.dart';
import '../shared/product_visual.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/commerce.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  final controller = PageController();
  final searchController = TextEditingController();
  String searchQuery = '';
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
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = searchQuery.trim().toLowerCase();
    final isSearching = term.isNotEmpty;
    final matchingProducts = products
        .where((p) =>
            '${p.name} ${p.store} ${p.category} ${tr(context, p.category)}'
                .toLowerCase()
                .contains(term))
        .toList();
    final matchingShops = products
        .map((p) => p.store)
        .toSet()
        .where((name) => name.toLowerCase().contains(term))
        .toList()
      ..sort();
    return CustomScrollView(slivers: [
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
                          child: BrandText('Gijima Mfana',
                              style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: Brand.green))),
                      IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: Badge(
                              isLabelVisible: ref
                                  .watch(commerceProvider)
                                  .notifications
                                  .any((n) => n['read'] != true),
                              label: AppText(
                                  '${ref.watch(commerceProvider).notifications.where((n) => n['read'] != true).length}'),
                              child: const Icon(Icons.notifications_outlined)))
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          color: Brand.green, size: 18),
                      Expanded(
                          child: TextButton(
                              onPressed: () => context.push('/addresses'),
                              child: AppText(
                                  ref.watch(commerceProvider).defaultAddress ==
                                          null
                                      ? 'Choose delivery address'
                                      : '${ref.watch(commerceProvider).defaultAddress!['city']} · ${ref.watch(commerceProvider).defaultAddress!['label']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis))),
                      const AppText('🇿🇦  Mzansi',
                          style: TextStyle(fontWeight: FontWeight.w600))
                    ]),
                    const SizedBox(height: 16),
                    const AppText('Sawubona, Sihle 👋',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1)),
                    const SizedBox(height: 4),
                    const AppText('Your local favourites. A few taps away.',
                        style: TextStyle(color: Colors.black54, fontSize: 16)),
                    const SizedBox(height: 20),
                    TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                            hintText: tr(context,
                                'Find a meal, groceries or your local shop'),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: isSearching
                                ? IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() => searchQuery = '');
                                    },
                                    icon: const Icon(Icons.close))
                                : null)),
                    if (isSearching) ...[
                      const SizedBox(height: 20),
                      AppText('Search results',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      AppText(
                          '${matchingProducts.length} ${tr(context, matchingProducts.length == 1 ? 'product' : 'products')} · ${matchingShops.length} ${tr(context, matchingShops.length == 1 ? 'shop' : 'shops')}',
                          style: const TextStyle(color: Colors.black54)),
                      if (matchingShops.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const AppText('Shops',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        ...matchingShops.map((name) => Card(
                            child: ListTile(
                                leading: const CircleAvatar(
                                    backgroundColor: Brand.mint,
                                    child: Icon(Icons.storefront_outlined,
                                        color: Brand.green)),
                                title: AppText(name),
                                subtitle: const AppText('View shop'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  context.push(
                                      '/shop/${Uri.encodeComponent(name)}');
                                }))),
                      ],
                      if (matchingProducts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const AppText('Products',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold))
                      ],
                      if (matchingProducts.isEmpty && matchingShops.isEmpty)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: AppText(
                                'No matches found. Try another product, category or shop.')),
                    ],
                    if (!isSearching) ...[
                      const SizedBox(height: 22),
                      SizedBox(
                          height: 285,
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
                      Card(
                          color: Brand.mint,
                          child: ListTile(
                              leading: const Icon(Icons.local_offer_outlined,
                                  color: Brand.green),
                              title: const AppText('Deals & offers',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: const AppText(
                                  'Save 10% on items with LOCAL10'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/deals'))),
                      const SizedBox(height: 16),
                      const AppText('What do you need today?',
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
                      Row(children: [
                        const Expanded(
                            child: AppText('Around your neighbourhood',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 21))),
                        TextButton(
                            onPressed: () => context.push('/discover'),
                            child: const AppText('See all'))
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: 160,
                          child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                'KFC',
                                'McDonald’s',
                                'Spur',
                                'Steers',
                                'Nando’s',
                                'Mzansi Braai Kitchen',
                                'Highveld Farm Store',
                                'Ermelo Fresh Market'
                              ].map((s) {
                                final item =
                                    products.firstWhere((p) => p.store == s);
                                return Container(
                                    width: 170,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                            onTap: () => context.push(
                                                '/shop/${Uri.encodeComponent(s)}'),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      child: Image.asset(
                                                          productImage(item),
                                                          width:
                                                              double.infinity,
                                                          fit: BoxFit.cover)),
                                                  Padding(
                                                      padding: const EdgeInsets
                                                          .fromLTRB(
                                                          10, 6, 10, 8),
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            AppText(s,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            const AppText(
                                                                '25–40 min · Demo',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .black54))
                                                          ]))
                                                ]))));
                              }).toList())),
                      const SizedBox(height: 22),
                      if (ref.watch(recentlyViewedProvider).isNotEmpty) ...[
                        Row(children: [
                          const Expanded(
                              child: AppText('Recently viewed',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 21))),
                          TextButton(
                              onPressed: () => context.push('/history'),
                              child: const AppText('See all'))
                        ]),
                        SizedBox(
                            height: 100,
                            child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: ref
                                    .watch(recentlyViewedProvider)
                                    .take(6)
                                    .map((name) {
                                  final p = products
                                      .firstWhere((item) => item.name == name);
                                  return Container(
                                      width: 230,
                                      margin: const EdgeInsets.only(right: 10),
                                      child: Card(
                                          child: ListTile(
                                              leading: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: ProductVisual(
                                                      product: p,
                                                      width: 52,
                                                      height: 52)),
                                              title: AppText(p.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              subtitle: AppText(
                                                  'R ${(p.priceCents / 100).toStringAsFixed(2)}'),
                                              onTap: () => context.push(
                                                  '/product/${Uri.encodeComponent(p.name)}'))));
                                }).toList())),
                        const SizedBox(height: 22),
                      ],
                      const AppText('Popular in Ermelo',
                          style: TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const AppText('Something good, from somewhere nearby.',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 14),
                    ],
                  ]))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
          sliver: SliverLayoutBuilder(
              builder: (context, c) => SliverGrid.builder(
                  itemCount:
                      isSearching ? matchingProducts.length : products.length,
                  itemBuilder: (c, i) => ProductCard(
                      product: isSearching ? matchingProducts[i] : products[i]),
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
  }

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
                      const BrandText('Ermelo · Mpumalanga',
                          style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 2,
                              fontSize: 11)),
                      const SizedBox(height: 12),
                      AppText(title,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      AppText(sub, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 14),
                      FilledButton(
                          onPressed: () => context.push('/account/$page'),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Brand.green),
                          child: const AppText('Explore now  →'))
                    ]))
          ]));
  Widget _service(String title, String sub, IconData icon, String page) =>
      Expanded(
          child: InkWell(
              onTap: () => context.push('/account/$page'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                  height: 165,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Brand.mint,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: Brand.green, size: 29),
                        const Spacer(),
                        AppText(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(height: 4),
                        AppText(sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54))
                      ]))));
}
