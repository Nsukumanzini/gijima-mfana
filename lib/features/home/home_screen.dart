import '../../data/repositories/customer_preferences.dart';
import '../../shared/components/brand_logo.dart';
import '../../app/localization/strings.dart';
import '../../shared/components/brand_text.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_card.dart';
import '../shared/product_visual.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/local_store.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  final controller = PageController();
  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  final scrollController = ScrollController();
  String searchQuery = '';
  final List<String> recentSearches = [];
  String shopSort = 'Recommended';
  bool showToTop = false;
  Timer? timer;
  int slide = 0;
  @override
  void initState() {
    super.initState();
    final savedSearches = ref
        .read(localStoreProvider)
        .read('home-searches.v1')?['items'] as List?;
    if (savedSearches != null) {
      recentSearches.addAll(savedSearches.whereType<String>().take(6));
    }
    searchFocus.addListener(_onSearchFocusChanged);
    scrollController.addListener(_onScrollChanged);
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (controller.hasClients &&
          !searchFocus.hasFocus &&
          searchQuery.trim().isEmpty &&
          !MediaQuery.of(context).disableAnimations) {
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
    searchFocus.removeListener(_onSearchFocusChanged);
    searchFocus.dispose();
    scrollController.removeListener(_onScrollChanged);
    scrollController.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onScrollChanged() {
    final next = scrollController.hasClients && scrollController.offset > 700;
    if (next != showToTop && mounted) setState(() => showToTop = next);
  }

  void _recordSearch(String raw) {
    final value = raw.trim();
    if (value.length < 2) return;
    recentSearches
      ..removeWhere((item) => item.toLowerCase() == value.toLowerCase())
      ..insert(0, value);
    if (recentSearches.length > 6) {
      recentSearches.removeRange(6, recentSearches.length);
    }
    unawaited(_persistSearches());
    setState(() {});
  }

  Future<void> _persistSearches() async {
    try {
      await ref
          .read(localStoreProvider)
          .write('home-searches.v1', {'items': recentSearches.toList()});
      if (mounted) ref.read(saveErrorProvider.notifier).state = null;
    } catch (_) {
      if (mounted) {
        ref.read(saveErrorProvider.notifier).state =
            'Changes are in memory, but device storage is unavailable. Keep this page open.';
      }
    }
  }

  void _selectSearch(String value) {
    searchController.text = value;
    searchController.selection =
        TextSelection.collapsed(offset: searchController.text.length);
    _recordSearch(value);
    setState(() => searchQuery = value);
    searchFocus.unfocus();
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
    final recentProducts = ref.watch(recentlyViewedProvider);
    final commerce = ref.watch(commerceProvider);
    final basket = ref.watch(basketProvider);
    final basketSavings = (basket.subtotal * 10 ~/ 100).clamp(0, 5000);
    final address = commerce.defaultAddress;
    final shopNames = <String>[
      'KFC',
      'McDonald’s',
      'Spur',
      'Steers',
      'Nando’s',
      'Mzansi Braai Kitchen',
      'Highveld Farm Store',
      'Ermelo Fresh Market'
    ];
    switch (shopSort) {
      case 'Top rated':
        shopNames.sort((a, b) => _shopRating(b).compareTo(_shopRating(a)));
      case 'Fastest delivery':
        shopNames
            .sort((a, b) => _deliveryMinutes(a).compareTo(_deliveryMinutes(b)));
      default:
        break;
    }
    final suggestions = matchingProducts.take(4).toList();
    return Stack(children: [
      CustomScrollView(controller: scrollController, slivers: [
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: const BrandLogo(size: 46)),
                        const Expanded(
                            child: BrandText('Gijima Mfana',
                                style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    color: Brand.green))),
                        IconButton(
                            onPressed: () => context.push('/notifications'),
                            icon: Badge(
                                isLabelVisible: commerce.notifications
                                    .any((n) => n['read'] != true),
                                label: AppText(
                                    '${commerce.notifications.where((n) => n['read'] != true).length}'),
                                child:
                                    const Icon(Icons.notifications_outlined)))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            color: Brand.green, size: 18),
                        Expanded(
                            child: TextButton(
                                onPressed: () => context.push('/addresses'),
                                child: AppText(
                                    address == null
                                        ? 'Choose delivery address'
                                        : '${address['city']} · ${address['label']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis))),
                        const AppText('🇿🇦  Mzansi',
                            style: TextStyle(fontWeight: FontWeight.w600))
                      ]),
                      if (address != null && covered(address))
                        Padding(
                          padding: const EdgeInsets.only(left: 26, top: 1),
                          child: Row(children: [
                            const Icon(Icons.schedule_outlined,
                                color: Brand.green, size: 15),
                            const SizedBox(width: 5),
                            const AppText('Estimated 25–40 minutes · Demo',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                          ]),
                        ),
                      const SizedBox(height: 10),
                      Text(
                          '${tr(context, 'Hello')}, ${ref.watch(customerNameProvider)} 👋',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 4),
                      const AppText('Your local favourites. A few taps away.',
                          style:
                              TextStyle(color: Colors.black54, fontSize: 16)),
                      const SizedBox(height: 14),
                      TextField(
                          controller: searchController,
                          focusNode: searchFocus,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                          onSubmitted: (value) {
                            _recordSearch(value);
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                              hintText: tr(context,
                                  'Find a meal, groceries or your local shop'),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: isSearching
                                  ? IconButton(
                                      tooltip: tr(context, 'Clear search'),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() => searchQuery = '');
                                      },
                                      icon: const Icon(Icons.close))
                                  : null)),
                      if (searchFocus.hasFocus &&
                          !isSearching &&
                          recentSearches.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _recentSearchPanel(),
                      ],
                      if (searchFocus.hasFocus && isSearching) ...[
                        const SizedBox(height: 10),
                        _liveSuggestions(
                            matchingShops.take(3).toList(), suggestions),
                      ],
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
                          ...matchingShops.map((name) => GlassCard(
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
                          GlassCard(
                              color: Brand.mint,
                              child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(children: [
                                    const Icon(Icons.search_off,
                                        color: Brand.green, size: 34),
                                    const SizedBox(height: 8),
                                    const AppText(
                                        'No matches found. Try another product, category or shop.'),
                                    TextButton.icon(
                                        onPressed: () {
                                          searchController.clear();
                                          setState(() => searchQuery = '');
                                          searchFocus.requestFocus();
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const AppText('Clear search')),
                                  ]))),
                      ],
                      if (!isSearching) ...[
                        const SizedBox(height: 22),
                        SizedBox(
                            height: MediaQuery.sizeOf(context).width < 520
                                ? 235
                                : 275,
                            child: PageView(
                                controller: controller,
                                onPageChanged: (v) => setState(() => slide = v),
                                children: [
                                  _banner(
                                      'Local is lekker.',
                                      'Find Ermelo neighbourhood favourites',
                                      'boerewors-pap.png',
                                      '/discover'),
                                  _banner(
                                      'A proper lunch break.',
                                      'Peri-peri, pap and flame-grilled favourites',
                                      'chicken.jpg',
                                      '/explore?category=restaurants'),
                                  _banner(
                                      'Fresh for the week.',
                                      'From local produce to your kitchen',
                                      'groceries.jpg',
                                      '/explore?category=groceries')
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
                        AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: GlassCard(
                                key: ValueKey('$basketSavings-${basket.count}'),
                                color: Brand.mint,
                                child: ListTile(
                                    leading: const Icon(
                                        Icons.local_offer_outlined,
                                        color: Brand.green),
                                    title: const AppText('Deals & offers',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const AppText(
                                              'Save 10% on items with LOCAL10'),
                                          const AppText('Ends 30 Nov 2026'),
                                          AppText(basket.count == 0
                                              ? 'Up to R 50 off items with LOCAL10'
                                              : '${tr(context, 'Estimated savings')}: R ${(basketSavings / 100).toStringAsFixed(2)}'),
                                        ]),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context.push('/deals')))),
                        const SizedBox(height: 16),
                        const AppText('What do you need today?',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        _serviceGroup(),
                        const SizedBox(height: 26),
                        Row(children: [
                          const Expanded(
                              child: AppText('Around your neighbourhood',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 21))),
                          TextButton(
                              onPressed: () => context.push('/discover'),
                              child: const AppText('See all')),
                          PopupMenuButton<String>(
                              tooltip: tr(context, 'Sort local shops'),
                              initialValue: shopSort,
                              onSelected: (value) =>
                                  setState(() => shopSort = value),
                              itemBuilder: (context) => [
                                    'Recommended',
                                    'Top rated',
                                    'Fastest delivery'
                                  ]
                                      .map((value) => PopupMenuItem(
                                          value: value, child: AppText(value)))
                                      .toList()),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                            height: 160,
                            child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: shopNames.map((s) {
                                  final item =
                                      products.firstWhere((p) => p.store == s);
                                  return Container(
                                      width: 170,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: GlassCard(
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                              onTap: () => context.push(
                                                  '/shop/${Uri.encodeComponent(s)}'),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                        child: Stack(
                                                            fit:
                                                                StackFit.expand,
                                                            children: [
                                                          Image.asset(
                                                              productImage(
                                                                  item),
                                                              width: double
                                                                  .infinity,
                                                              fit:
                                                                  BoxFit.cover),
                                                          Positioned(
                                                              top: 8,
                                                              left: 8,
                                                              child:
                                                                  _shopMark(s)),
                                                        ])),
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets
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
                                                              Row(children: [
                                                                const Icon(
                                                                    Icons.star,
                                                                    color: Color(
                                                                        0xffd18a00),
                                                                    size: 13),
                                                                const SizedBox(
                                                                    width: 2),
                                                                Text(_shopRating(
                                                                        s)
                                                                    .toStringAsFixed(
                                                                        1)),
                                                                const SizedBox(
                                                                    width: 8),
                                                                AppText(
                                                                    _deliveryRangeLabel(
                                                                        s),
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Colors
                                                                            .black54)),
                                                              ])
                                                            ]))
                                                  ]))));
                                }).toList())),
                        const SizedBox(height: 22),
                        Row(children: [
                          const Expanded(
                              child: AppText('Recently viewed',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 21))),
                          if (recentProducts.isNotEmpty)
                            TextButton(
                                onPressed: () => context.push('/history'),
                                child: const AppText('See all'))
                        ]),
                        if (recentProducts.isEmpty)
                          GlassCard(
                              color: Colors.white,
                              child: ListTile(
                                  leading: const CircleAvatar(
                                      backgroundColor: Brand.mint,
                                      child: Icon(Icons.history,
                                          color: Brand.green)),
                                  title: const AppText(
                                      'Your recently viewed items will appear here.'),
                                  subtitle: const AppText(
                                      'Explore local favourites to get started.'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.push('/explore')))
                        else
                          SizedBox(
                              height: 100,
                              child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: recentProducts.take(6).map((name) {
                                    final p = products.firstWhere(
                                        (item) => item.name == name);
                                    return Container(
                                        width: 230,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        child: GlassCard(
                                            child: ListTile(
                                                leading: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
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
                    itemBuilder: (c, i) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 220 + (i % 8) * 35),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child)),
                        child: ProductCard(
                            product:
                                isSearching ? matchingProducts[i] : products[i],
                            showDeliveryEstimate: true)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.crossAxisExtent > 1000
                            ? 4
                            : c.crossAxisExtent > 650
                                ? 3
                                : 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: .76))))
      ]),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        right: 18,
        bottom: showToTop ? 18 : -80,
        child: IgnorePointer(
          ignoring: !showToTop,
          child: AnimatedScale(
            scale: showToTop ? 1 : .75,
            duration: const Duration(milliseconds: 180),
            child: FloatingActionButton.small(
              heroTag: 'home-scroll-to-top',
              tooltip: tr(context, 'Back to top'),
              onPressed: () => scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic),
              child: const Icon(Icons.arrow_upward),
            ),
          ),
        ),
      )
    ]);
  }

  Widget _banner(String title, String sub, String photo, String route) =>
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
                          onPressed: () => context.push(route),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Brand.green),
                          child: const AppText('Explore now  →'))
                    ]))
          ]));
  Widget _serviceGroup() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final services = [
      ('Shop', 'Everyday favourites', Icons.storefront, 'Shop local'),
      (
        'Personal shopping',
        'We’ll find it for you',
        Icons.shopping_bag_outlined,
        'Personal shopping'
      ),
      (
        'Collect & deliver',
        'From A to your door',
        Icons.delivery_dining,
        'Collect & deliver'
      ),
    ];
    if (compact) {
      return SizedBox(
        height: 132,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: services
              .map((service) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _service(
                      service.$1, service.$2, service.$3, service.$4,
                      compact: true)))
              .toList(),
        ),
      );
    }
    return Row(children: [
      for (var i = 0; i < services.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        _service(
            services[i].$1, services[i].$2, services[i].$3, services[i].$4),
      ]
    ]);
  }

  Widget _service(String title, String sub, IconData icon, String page,
      {bool compact = false}) {
    final card = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)), child: child)),
      child: InkWell(
        onTap: () => context.push('/account/$page'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: compact ? 178 : null,
          height: compact ? 120 : 165,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Brand.mint, borderRadius: BorderRadius.circular(20)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Brand.green, size: 29),
            const Spacer(),
            AppText(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 4),
            AppText(sub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.black54))
          ]),
        ),
      ),
    );
    return compact ? card : Expanded(child: card);
  }

  Widget _recentSearchPanel() => GlassCard(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                  child: AppText('Recent searches',
                      style: TextStyle(fontWeight: FontWeight.w800))),
              TextButton(
                  onPressed: () {
                    recentSearches.clear();
                    unawaited(_persistSearches());
                    setState(() {});
                  },
                  child: const AppText('Clear history'))
            ]),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: recentSearches
                  .map((term) => ActionChip(
                      avatar: const Icon(Icons.history, size: 16),
                      label: Text(term),
                      onPressed: () => _selectSearch(term)))
                  .toList(),
            )
          ]),
        ),
      );

  Widget _liveSuggestions(List<String> shops, List<ShopProduct> items) {
    if (shops.isEmpty && items.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (shops.isNotEmpty) ...[
            const AppText('Shops',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: shops
                  .map((shop) => ActionChip(
                      avatar: const Icon(Icons.storefront_outlined, size: 16),
                      label: Text(shop),
                      onPressed: () => _selectSearch(shop)))
                  .toList(),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 5),
            const AppText('Products',
                style: TextStyle(fontWeight: FontWeight.w800)),
            for (final item in items.take(4))
              ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          ProductVisual(product: item, width: 38, height: 38)),
                  title: AppText(item.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: AppText(item.store),
                  onTap: () => _selectSearch(item.name)),
          ]
        ]),
      ),
    );
  }

  Widget _shopMark(String name) => CircleAvatar(
        radius: 18,
        backgroundColor: _shopColor(name),
        child: Text(_shopMonogram(name),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900)),
      );
}

int _deliveryMinutes(String shop) => switch (shop) {
      'KFC' || 'McDonald’s' => 25,
      'Spur' || 'Steers' || 'Nando’s' => 30,
      _ => 35,
    };

String _deliveryRangeLabel(String shop) => switch (_deliveryMinutes(shop)) {
      25 => '25–35 min · Demo',
      30 => '30–40 min · Demo',
      _ => '35–45 min · Demo',
    };

double _shopRating(String shop) {
  final items = products.where((product) => product.store == shop).toList();
  if (items.isEmpty) return 0;
  return items.fold<double>(0, (sum, item) => sum + item.rating) / items.length;
}

String _shopMonogram(String shop) {
  const marks = {
    'KFC': 'KFC',
    'McDonald’s': 'M',
    'Spur': 'SP',
    'Steers': 'ST',
    'Nando’s': 'N',
    'Mzansi Braai Kitchen': 'MB',
    'Highveld Farm Store': 'HF',
    'Ermelo Fresh Market': 'EF',
  };
  return marks[shop] ?? shop.characters.first.toUpperCase();
}

Color _shopColor(String shop) => switch (shop) {
      'KFC' => const Color(0xffc8102e),
      'McDonald’s' => const Color(0xffd99a00),
      'Spur' => const Color(0xff963d31),
      'Steers' => const Color(0xffbd1f2d),
      'Nando’s' => const Color(0xffce3a24),
      _ => Brand.green,
    };
