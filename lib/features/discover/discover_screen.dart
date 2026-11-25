import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../shared/product_visual.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverState();
}

class _DiscoverState extends ConsumerState<DiscoverScreen> {
  final search = TextEditingController();
  String query = '';
  String category = 'All';
  String sort = 'Popular';
  bool savedOnly = false;
  bool grid = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(commerceProvider).savedShops;
    final shops = products.map((p) => p.store).toSet().toList();
    final categories = ['All', ...products.map((p) => p.category).toSet()];
    bool matchesCategory(String shop) =>
        category == 'All' ||
        products.any((p) => p.store == shop && p.category == category);
    final visible = shops.where((shop) {
      final items = products.where((p) => p.store == shop).toList();
      final searchText =
          '$shop ${items.map((p) => '${p.category} ${tr(context, p.category)} ${p.name}').join(' ')}'
              .toLowerCase();
      return (!savedOnly || saved.contains(shop)) &&
          matchesCategory(shop) &&
          searchText.contains(query.trim().toLowerCase());
    }).toList();
    visible.sort((a, b) {
      switch (sort) {
        case 'A–Z':
          return a.compareTo(b);
        case 'Delivery fee':
          return deliveryFee(a).compareTo(deliveryFee(b));
        default:
          double rating(String shop) {
            final list = products.where((p) => p.store == shop).toList();
            return list.fold<double>(0, (total, p) => total + p.rating) /
                list.length;
          }
          return rating(b).compareTo(rating(a));
      }
    });
    final featured = shops.take(4).toList();
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Discover local shops'),
        actions: [
          IconButton(
              tooltip: grid ? 'List view' : 'Grid view',
              onPressed: () => setState(() => grid = !grid),
              icon: Icon(
                  grid ? Icons.view_list_rounded : Icons.grid_view_rounded)),
          const SizedBox(width: 6),
        ],
      ),
      body: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          sliver: SliverList.list(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Brand.green, Color(0xFF075E48)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: AppText('Close to home.\nFull of good finds.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900))),
                      Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 28)),
                    ]),
                    const SizedBox(height: 10),
                    const AppText(
                        'Browse Ermelo favourites and local essentials.',
                        style: TextStyle(color: Colors.white, height: 1.35)),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Icon(Icons.place_outlined, color: Colors.white, size: 17),
                      SizedBox(width: 5),
                      AppText('Ermelo, Mpumalanga · Demo marketplace',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12))
                    ]),
                  ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: search,
              onChanged: (value) => setState(() => query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Brand.green),
                hintText: tr(context, 'Search shops or categories'),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          search.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close_rounded)),
              ),
            ),
            const SizedBox(height: 15),
            Row(children: [
              const Expanded(
                  child: AppText('Shop by category',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900))),
              TextButton.icon(
                  onPressed: () => context.push('/explore'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const AppText('All categories')),
            ]),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = categories[index];
                  return ChoiceChip(
                      label: AppText(item == 'All' ? 'All' : tr(context, item)),
                      selected: category == item,
                      onSelected: (_) => setState(() => category = item));
                },
              ),
            ),
            const SizedBox(height: 15),
            if (query.isEmpty && category == 'All' && !savedOnly) ...[
              Row(children: [
                const Expanded(
                    child: AppText('Local favourites',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900))),
                const AppText('Popular demo shops',
                    style: TextStyle(
                        fontSize: 11,
                        color: Brand.green,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                height: 146,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final shop = featured[index];
                    final item = products.firstWhere((p) => p.store == shop);
                    return SizedBox(
                        width: 128,
                        child: GlassCard(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                              onTap: () => context
                                  .push('/shop/${Uri.encodeComponent(shop)}'),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: SizedBox(
                                            width: double.infinity,
                                            child:
                                                ProductVisual(product: item))),
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 7, 10, 9),
                                        child: AppText(shop,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12))),
                                  ])),
                        ));
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(children: [
              FilterChip(
                  label: const AppText('Saved shops'),
                  avatar: const Icon(Icons.favorite_outline_rounded, size: 17),
                  selected: savedOnly,
                  onSelected: (value) => setState(() => savedOnly = value)),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Sort shops',
                initialValue: sort,
                onSelected: (value) => setState(() => sort = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Popular', child: Text('Popular')),
                  PopupMenuItem(value: 'A–Z', child: Text('Name A–Z')),
                  PopupMenuItem(
                      value: 'Delivery fee', child: Text('Lowest delivery fee'))
                ],
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.sort_rounded,
                          size: 18, color: Brand.green),
                      const SizedBox(width: 5),
                      AppText(sort,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      const Icon(Icons.expand_more_rounded, size: 18)
                    ])),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: AppText(
                      '${visible.length} ${visible.length == 1 ? 'shop' : 'shops'}',
                      style: const TextStyle(
                          color: Brand.green, fontWeight: FontWeight.w800))),
              if (visible.isNotEmpty)
                AppText('Delivery estimates are illustrative',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 50),
                  child: Column(children: [
                    const Icon(Icons.store_mall_directory_outlined,
                        size: 48, color: Brand.green),
                    const SizedBox(height: 12),
                    const AppText('No shops match those filters',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 6),
                    const AppText(
                        'Try another search, category, or saved-shop setting.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                        onPressed: () {
                          search.clear();
                          setState(() {
                            query = '';
                            category = 'All';
                            savedOnly = false;
                          });
                        },
                        child: const AppText('Clear filters')),
                  ])))
        else if (grid)
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverGrid.builder(
                itemCount: visible.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .78),
                itemBuilder: (context, index) => _ShopCard(
                    shop: visible[index],
                    saved: saved.contains(visible[index]),
                    compact: true,
                    onSave: () => ref
                        .read(commerceProvider.notifier)
                        .toggleShop(visible[index])),
              ))
        else
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _ShopCard(
                    shop: visible[index],
                    saved: saved.contains(visible[index]),
                    onSave: () => ref
                        .read(commerceProvider.notifier)
                        .toggleShop(visible[index])),
              )),
        const SliverToBoxAdapter(
            child: Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, 25),
                child: AppText(
                    'Sample shops, prices and delivery estimates are illustrative. No live merchant availability or affiliation is implied.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                    textAlign: TextAlign.center))),
      ]),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard(
      {required this.shop,
      required this.saved,
      required this.onSave,
      this.compact = false});
  final String shop;
  final bool saved;
  final VoidCallback onSave;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final items = products.where((p) => p.store == shop).toList();
    final rating =
        items.fold<double>(0, (sum, p) => sum + p.rating) / items.length;
    final categories =
        items.map((p) => tr(context, p.category)).toSet().join(' · ');
    if (compact) {
      return GlassCard(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/shop/${Uri.encodeComponent(shop)}'),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Stack(fit: StackFit.expand, children: [
                ProductVisual(product: items.first),
                Positioned(right: 5, top: 5, child: _saveButton())
              ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(shop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        AppText(
                            '★ ${rating.toStringAsFixed(1)} · ${items.length} items',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Brand.green,
                                fontWeight: FontWeight.w700)),
                        AppText('Delivery ${rand(deliveryFee(shop))}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54)),
                      ])),
            ]),
          ));
    }
    return GlassCard(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/shop/${Uri.encodeComponent(shop)}'),
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: ProductVisual(
                        product: items.first, width: 86, height: 86)),
                const SizedBox(width: 13),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      AppText(shop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      AppText(categories,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 10, runSpacing: 3, children: [
                        Text('★ ${rating.toStringAsFixed(1)} demo',
                            style: const TextStyle(
                                color: Brand.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        Text('${items.length} items',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 11)),
                      ]),
                      const SizedBox(height: 3),
                      AppText(
                          'Ermelo · Demo delivery ${rand(deliveryFee(shop))}',
                          style: const TextStyle(
                              fontSize: 11, color: Brand.charcoal)),
                    ])),
                _saveButton(),
              ])),
        ));
  }

  Widget _saveButton() => IconButton(
        tooltip: saved ? 'Remove saved shop' : 'Save shop',
        onPressed: onSave,
        icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(saved),
                color: Brand.green)),
      );
}
