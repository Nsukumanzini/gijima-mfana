import 'dart:math' as math;
import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../shared/product_card.dart';
import '../shared/product_visual.dart';

class Storefront extends ConsumerStatefulWidget {
  const Storefront({super.key, required this.name});
  final String name;
  @override
  ConsumerState<Storefront> createState() => _StoreState();
}

class _StoreState extends ConsumerState<Storefront> {
  final _searchController = TextEditingController();
  String query = '', category = 'All', sortOrder = 'Recommended';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ShopProduct product, String text, BuildContext context) {
    final value = text.trim().toLowerCase();
    if (value.isEmpty) return true;
    return product.name.toLowerCase().contains(value) ||
        tr(context, product.name).toLowerCase().contains(value) ||
        product.category.toLowerCase().contains(value) ||
        tr(context, product.category).toLowerCase().contains(value);
  }

  List<ShopProduct> _sort(List<ShopProduct> items) {
    switch (sortOrder) {
      case 'Price: low to high':
        items.sort((a, b) => a.priceCents.compareTo(b.priceCents));
        break;
      case 'Price: high to low':
        items.sort((a, b) => b.priceCents.compareTo(a.priceCents));
        break;
      case 'Top rated':
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }
    return items;
  }

  void _clearFilters() {
    setState(() {
      query = '';
      category = 'All';
      sortOrder = 'Recommended';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = products.where((p) => p.store == widget.name).toList();
    final categoryCounts = <String, int>{
      for (final product in all)
        product.category: all.where((p) => p.category == product.category).length,
    };
    final categories = ['All', ...categoryCounts.keys];
    final visible = _sort(all
        .where((product) =>
            (category == 'All' || product.category == category) &&
            _matches(product, query, context))
        .toList());
    final featured = all.length < 3 || query.isNotEmpty || category != 'All'
        ? <ShopProduct>[]
        : (all.toList()..sort((a, b) => b.rating.compareTo(a.rating)))
            .take(3)
            .toList();
    final saved = ref.watch(commerceProvider).savedShops.contains(widget.name);
    final averageRating = all.isEmpty
        ? null
        : (all.map((p) => p.rating).reduce((a, b) => a + b) / all.length)
            .toStringAsFixed(1);
    final addressNumber =
        10 + products.indexWhere((p) => p.store == widget.name).clamp(0, 99);
    final sortKey = '$category-$sortOrder';

    return Scaffold(
      appBar: AppBar(title: AppText(widget.name), actions: [
        IconButton.filledTonal(
            tooltip: tr(context, saved ? 'Unsave business' : 'Save business'),
            onPressed: () {
              ref.read(commerceProvider.notifier).toggleShop(widget.name);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: AppText(saved
                      ? 'Shop removed from favourites'
                      : 'Shop saved to favourites')));
            },
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                color: Brand.green))
      ]),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _StoreHero(name: widget.name, products: all),
                  const SizedBox(height: 14),
                  LayoutBuilder(builder: (context, constraints) {
                    const gap = 9.0;
                    final columns = constraints.maxWidth >= 700 ? 5 : 2;
                    final itemWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(spacing: gap, runSpacing: gap, children: [
                      SizedBox(
                          width: itemWidth,
                          child: _StoreFact(
                              icon: Icons.location_on_outlined,
                              label: 'Demo address',
                              value: '$addressNumber Main Street, Ermelo')),
                      SizedBox(
                          width: itemWidth,
                          child: const _StoreFact(
                              icon: Icons.schedule_outlined,
                              label: 'Demo hours',
                              value: '08:00–20:00 daily')),
                      SizedBox(
                          width: itemWidth,
                          child: _StoreFact(
                              icon: Icons.delivery_dining_outlined,
                              label: 'Delivery',
                              value:
                                  '${rand(deliveryFee(widget.name))} · ${tr(context, '25–40 min')}')),
                      SizedBox(
                          width: itemWidth,
                          child: _StoreFact(
                              icon: Icons.shopping_basket_outlined,
                              label: 'Minimum items',
                              value: rand(minimumOrder(widget.name)))),
                      SizedBox(
                          width: itemWidth,
                          child: _StoreFact(
                              icon: Icons.star_outline_rounded,
                              label: 'Fictional rating',
                              value: averageRating == null
                                  ? 'New'
                                  : '★ $averageRating')),
                    ]);
                  }),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: Brand.charcoal.withValues(alpha: .09))),
                    child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Brand.green, size: 19),
                          SizedBox(width: 9),
                          Expanded(
                              child: AppText(
                                  'Sample catalogue, prices and availability. No affiliation with named brands or live merchant ordering.',
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12))),
                        ]),
                  ),
                  const SizedBox(height: 11),
                  _Local10Banner(onTap: () => context.push('/deals')),
                  const SizedBox(height: 19),
                  if (featured.isNotEmpty) ...[
                    const AppText('Popular at this shop',
                        style: TextStyle(
                            color: Brand.charcoal,
                            fontSize: 19,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 9),
                    SizedBox(
                      height: 325,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) => SizedBox(
                            width: 190,
                            child: ProductCard(
                                product: featured[index],
                                highlightQuery: query,
                                showCategory: true)),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const AppText('Shop the catalogue',
                      style: TextStyle(
                          color: Brand.charcoal,
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Search this shop'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton.filledTonal(
                              tooltip: tr(context, 'Clear search'),
                              onPressed: () => setState(() {
                                query = '';
                                _searchController.clear();
                              }),
                              icon: const Icon(Icons.close)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final itemCategory in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: AppText(
                                '${tr(context, itemCategory)} · ${itemCategory == 'All' ? all.length : categoryCounts[itemCategory]}'),
                            selected: category == itemCategory,
                            onSelected: (_) =>
                                setState(() => category = itemCategory),
                          ),
                        ),
                    ]),
                  ),
                  if (query.isNotEmpty || category != 'All') ...[
                    const SizedBox(height: 3),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      if (query.isNotEmpty)
                        Chip(
                            avatar: const Icon(Icons.search, size: 15),
                            label: Text(query)),
                      if (category != 'All')
                        Chip(label: AppText(tr(context, category))),
                      TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const AppText('Clear filters')),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: AppText(
                                '${visible.length} ${tr(context, 'demo products found')}',
                                key: ValueKey(visible.length),
                                style: const TextStyle(
                                    color: Brand.charcoal,
                                    fontWeight: FontWeight.w800)))),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 178,
                      child: DropdownButtonFormField<String>(
                        initialValue: sortOrder,
                        isExpanded: true,
                        decoration: InputDecoration(
                            labelText: tr(context, 'Sort by'),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10)),
                        items: const [
                          'Recommended',
                          'Price: low to high',
                          'Price: high to low',
                          'Top rated'
                        ]
                            .map((value) => DropdownMenuItem(
                                value: value,
                                child: AppText(tr(context, value),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (value) => setState(
                            () => sortOrder = value ?? 'Recommended'),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                  child: _StoreEmptyState(
                      isCatalogueEmpty: all.isEmpty,
                      onClear: _clearFilters),
                ),
              ),
            ),
          )
        else
          SliverLayoutBuilder(builder: (context, constraints) {
            final horizontal = math
                .max(18.0, (constraints.crossAxisExtent - 1200) / 2 + 18)
                .toDouble();
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 40),
              sliver: SliverGrid.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final product = visible[index];
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('${product.name}-$sortKey'),
                    tween: Tween(begin: 0, end: 1),
                    duration:
                        Duration(milliseconds: 220 + (index.clamp(0, 5) * 40)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                            offset: Offset(0, (1 - value) * 10), child: child)),
                    child: ProductCard(
                        product: product,
                        highlightQuery: query,
                        showCategory: true),
                  );
                },
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisExtent: 325,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12),
              ),
            );
          }),
      ]),
    );
  }
}

class _StoreHero extends StatelessWidget {
  const _StoreHero({required this.name, required this.products});
  final String name;
  final List<ShopProduct> products;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 218,
          child: Stack(fit: StackFit.expand, children: [
            if (products.isEmpty)
              Image.asset('assets/images/groceries.jpg',
                  fit: BoxFit.cover,
                  semanticLabel: tr(context, 'Illustrative local shop'))
            else
              ProductVisual(
                  product: products.first, width: double.infinity, height: 218),
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                      Color(0x08000000),
                      Color(0xB8000000)
                    ]))),
            Positioned(
                left: 17,
                top: 16,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(20)),
                    child: const AppText('LOCAL SHOP · ERMELO',
                        style: TextStyle(
                            color: Brand.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .6)))),
            Positioned(
                left: 18,
                right: 18,
                bottom: 17,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8)
                              ])),
                      const SizedBox(height: 5),
                      const AppText('Open for simulated orders · 25–40 min delivery',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 6)
                              ])),
                    ])),
          ]),
        ),
      );
}

class _StoreFact extends StatelessWidget {
  const _StoreFact(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: Icon(icon, color: Brand.green, size: 18)),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  AppText(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  AppText(value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ])),
          ]),
        ),
      );
}

class _Local10Banner extends StatelessWidget {
  const _Local10Banner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Brand.green,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.local_offer_outlined,
                      color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const AppText('LOCAL10 · 10% off',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    const AppText(
                        '10% off items, up to R 50. Apply at checkout.',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 3),
                    const AppText(
                        'Delivery and service fees are excluded.',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ])),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ]),
          ),
        ),
      );
}

class _StoreEmptyState extends StatelessWidget {
  const _StoreEmptyState(
      {required this.isCatalogueEmpty, required this.onClear});
  final bool isCatalogueEmpty;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Brand.mint)),
        child: Column(children: [
          const CircleAvatar(
              radius: 28,
              backgroundColor: Brand.mint,
              child: Icon(Icons.search_off_rounded,
                  color: Brand.green, size: 28)),
          const SizedBox(height: 11),
          AppText(
              isCatalogueEmpty ? 'No catalogue yet' : 'No matching items',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Brand.charcoal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          AppText(
              isCatalogueEmpty
                  ? 'This shop has no demo products to show yet.'
                  : 'No matching items. Try another search or category.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          if (!isCatalogueEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const AppText('Clear filters')),
          ],
        ]),
      );
}
