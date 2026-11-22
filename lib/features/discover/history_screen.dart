import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../shared/product_visual.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final search = TextEditingController();
  String query = '';
  bool groupByShop = false;
  bool grid = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentNames = ref.watch(recentlyViewedProvider);
    final recent = recentNames
        .map((name) => products.firstWhere((p) => p.name == name))
        .where((p) => '${p.name} ${p.store} ${p.category}'
            .toLowerCase()
            .contains(query.trim().toLowerCase()))
        .toList();
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Recently viewed'),
        actions: [
          IconButton(
              tooltip: grid ? 'List view' : 'Grid view',
              onPressed:
                  recent.isEmpty ? null : () => setState(() => grid = !grid),
              icon: Icon(
                  grid ? Icons.view_list_rounded : Icons.grid_view_rounded)),
          TextButton(
              onPressed: recentNames.isEmpty ? null : _confirmClear,
              child: const AppText('Clear all')),
          const SizedBox(width: 4),
        ],
      ),
      body: recentNames.isEmpty
          ? _emptyState(context)
          : CustomScrollView(slivers: [
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  sliver: SliverList.list(children: [
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                          color: Brand.mint,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.history_rounded,
                                color: Brand.green)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const AppText('Pick up where you left off',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16)),
                              AppText(
                                  '${recentNames.length} of 12 recent products · newest first',
                                  style: const TextStyle(
                                      fontSize: 12, color: Brand.charcoal)),
                            ])),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: search,
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Brand.green),
                          hintText: tr(context, 'Search recent products'),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    search.clear();
                                    setState(() => query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded))),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      FilterChip(
                          label: const AppText('Group by shop'),
                          avatar:
                              const Icon(Icons.storefront_outlined, size: 17),
                          selected: groupByShop,
                          onSelected: (value) =>
                              setState(() => groupByShop = value)),
                      const Spacer(),
                      AppText(
                          '${recent.length} ${recent.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                              color: Brand.green, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                  ])),
              if (recent.isEmpty)
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(children: [
                          const Icon(Icons.search_off_rounded,
                              size: 42, color: Brand.green),
                          const SizedBox(height: 10),
                          const AppText('No recent products match your search',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          TextButton(
                              onPressed: () {
                                search.clear();
                                setState(() => query = '');
                              },
                              child: const AppText('Clear search')),
                        ])))
              else if (groupByShop)
                ..._groupedSlivers(recent, grid, favorites)
              else if (grid)
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                    sliver: SliverGrid.builder(
                      itemCount: recent.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: .67),
                      itemBuilder: (context, index) => _RecentCard(
                          product: recent[index],
                          compact: true,
                          isSaved: favorites.contains(recent[index].name),
                          onRemove: () => ref
                              .read(recentlyViewedProvider.notifier)
                              .remove(recent[index].name),
                          onSave: () =>
                              _toggleFavorite(recent[index].name, favorites),
                          onAdd: () => _addToBasket(recent[index])),
                    ))
              else
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                    sliver: SliverList.separated(
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) => _RecentCard(
                          product: recent[index],
                          isSaved: favorites.contains(recent[index].name),
                          onRemove: () => ref
                              .read(recentlyViewedProvider.notifier)
                              .remove(recent[index].name),
                          onSave: () =>
                              _toggleFavorite(recent[index].name, favorites),
                          onAdd: () => _addToBasket(recent[index])),
                    )),
              const SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(22, 0, 22, 20),
                      child: AppText(
                          'Prices and availability can change. Sample marketplace content.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                          textAlign: TextAlign.center))),
            ]),
    );
  }

  List<Widget> _groupedSlivers(
      List<ShopProduct> recent, bool grid, Set<String> favorites) {
    final shops = recent.map((p) => p.store).toSet().toList();
    return [
      for (final shop in shops) ...[
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                child: Row(children: [
                  const Icon(Icons.storefront_outlined,
                      size: 18, color: Brand.green),
                  const SizedBox(width: 7),
                  Expanded(
                      child: AppText(shop,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900))),
                  AppText(
                      '${recent.where((p) => p.store == shop).length} items',
                      style: const TextStyle(
                          color: Brand.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))
                ]))),
        if (grid)
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              sliver: SliverGrid.builder(
                itemCount: recent.where((p) => p.store == shop).length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .67),
                itemBuilder: (context, index) {
                  final p =
                      recent.where((p) => p.store == shop).elementAt(index);
                  return _RecentCard(
                      product: p,
                      compact: true,
                      isSaved: favorites.contains(p.name),
                      onRemove: () => ref
                          .read(recentlyViewedProvider.notifier)
                          .remove(p.name),
                      onSave: () => _toggleFavorite(p.name, favorites),
                      onAdd: () => _addToBasket(p));
                },
              ))
        else
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              sliver: SliverList.separated(
                itemCount: recent.where((p) => p.store == shop).length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final p =
                      recent.where((p) => p.store == shop).elementAt(index);
                  return _RecentCard(
                      product: p,
                      isSaved: favorites.contains(p.name),
                      onRemove: () => ref
                          .read(recentlyViewedProvider.notifier)
                          .remove(p.name),
                      onSave: () => _toggleFavorite(p.name, favorites),
                      onAdd: () => _addToBasket(p));
                },
              )),
      ]
    ];
  }

  Widget _emptyState(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: const Icon(Icons.history_rounded,
                    color: Brand.green, size: 42)),
            const SizedBox(height: 18),
            const AppText('Your next favourite is out there',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const AppText(
                'Products you view will appear here, ready when you are.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.explore_outlined),
                label: const AppText('Explore local finds')),
          ])));

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              icon: const Icon(Icons.delete_sweep_outlined, color: Brand.green),
              title: const AppText('Clear recent products?'),
              content: const AppText(
                  'This removes all products from your recently viewed list.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const AppText('Keep history')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: const AppText('Clear history'))
              ],
            ));
    if (clear == true && mounted) {
      ref.read(recentlyViewedProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: AppText('Recently viewed products cleared')));
    }
  }

  void _toggleFavorite(String name, Set<String> favorites) {
    ref.read(favoritesProvider.notifier).state = favorites.contains(name)
        ? ({...favorites}..remove(name))
        : {...favorites, name};
  }

  Future<void> _addToBasket(ShopProduct product) async {
    final basket = ref.read(basketProvider.notifier);
    if (!basket.add(product)) {
      final replace = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const AppText('One shop per order'),
                content: AppText(
                    'Your basket contains items from ${ref.read(basketProvider).merchant}. Start a new basket for ${product.store}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const AppText('Keep basket')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const AppText('Start new basket'))
                ],
              ));
      if (replace != true || !mounted) return;
      basket.clear();
      basket.add(product);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: AppText('${product.name} added to basket'),
          action: SnackBarAction(
              label: 'Checkout', onPressed: () => context.push('/checkout'))));
    }
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard(
      {required this.product,
      required this.isSaved,
      required this.onRemove,
      required this.onSave,
      required this.onAdd,
      this.compact = false});
  final ShopProduct product;
  final bool isSaved;
  final VoidCallback onRemove, onSave, onAdd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Card(
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Stack(fit: StackFit.expand, children: [
              InkWell(
                  onTap: () => context
                      .push('/product/${Uri.encodeComponent(product.name)}'),
                  child: ProductVisual(product: product)),
              Positioned(
                  right: 3,
                  top: 3,
                  child: _action(onRemove, 'Remove from recent history',
                      Icons.close_rounded)),
              Positioned(
                  left: 3,
                  top: 3,
                  child: _action(
                      onSave,
                      isSaved ? 'Remove from favourites' : 'Save to favourites',
                      isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded)),
            ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                child: AppText(product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, height: 1.15))),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AppText('${product.store} · ${rand(product.priceCents)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black54))),
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 1, 8, 7),
                child: Row(children: [
                  Text('★ ${product.rating}',
                      style: const TextStyle(
                          color: Brand.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      tooltip: 'Add to basket',
                      visualDensity: VisualDensity.compact,
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_shopping_cart_rounded,
                          size: 19, color: Brand.green))
                ])),
          ]));
    }
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              context.push('/product/${Uri.encodeComponent(product.name)}'),
          child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child:
                        ProductVisual(product: product, width: 78, height: 78)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      AppText(product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      AppText(product.store,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Row(children: [
                        AppText(rand(product.priceCents),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Text('★ ${product.rating}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Brand.green,
                                fontWeight: FontWeight.w700))
                      ]),
                      AppText(
                          '${tr(context, product.category)} · Illustrative availability',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54)),
                    ])),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _action(
                      onSave,
                      isSaved ? 'Remove from favourites' : 'Save to favourites',
                      isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded),
                  _action(
                      onAdd, 'Add to basket', Icons.add_shopping_cart_rounded),
                  _action(onRemove, 'Remove from recent history',
                      Icons.close_rounded),
                ]),
              ])),
        ));
  }

  Widget _action(VoidCallback action, String label, IconData icon) =>
      IconButton(
          tooltip: label,
          visualDensity: VisualDensity.compact,
          onPressed: action,
          icon: Icon(icon,
              size: 19,
              color: label == 'Remove from recent history'
                  ? Colors.black54
                  : Brand.green));
}
