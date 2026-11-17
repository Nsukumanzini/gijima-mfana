import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
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
  String query = '';
  bool savedOnly = false;
  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(commerceProvider).savedShops;
    final shops = products.map((p) => p.store).toSet().toList()..sort();
    final visible = shops
        .where((s) =>
            (!savedOnly || saved.contains(s)) &&
            ('$s ${products.where((p) => p.store == s).map((p) => '${p.category} ${tr(context, p.category)}').join(' ')}'
                .toLowerCase()
                .contains(query.toLowerCase())))
        .toList();
    return Scaffold(
        appBar: AppBar(title: const AppText('Discover local shops')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              const AppText('A little closer to home.',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const AppText(
                  'Browse our illustrative Ermelo marketplace and find your next favourite.'),
              const SizedBox(height: 18),
              TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: tr(context, 'Search shops or categories'))),
              const SizedBox(height: 10),
              FilterChip(
                  label: const AppText('Saved shops'),
                  selected: savedOnly,
                  onSelected: (v) => setState(() => savedOnly = v)),
              const SizedBox(height: 10),
              AppText(
                  '${visible.length} ${visible.length == 1 ? 'shop' : 'shops'}',
                  style: const TextStyle(
                      color: Brand.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (visible.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: AppText(
                        'No shops found. Try another search or remove the saved filter.')),
              ...visible.map((s) {
                final shopItems = products.where((p) => p.store == s).toList();
                return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        onTap: () =>
                            context.push('/shop/${Uri.encodeComponent(s)}'),
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: ProductVisual(
                                      product: shopItems.first,
                                      width: 76,
                                      height: 76)),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    AppText(s,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16)),
                                    AppText(
                                        shopItems
                                            .map((p) => p.category)
                                            .toSet()
                                            .join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    AppText(
                                        '${shopItems.length} items · Delivery ${rand(deliveryFee(s))}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54))
                                  ])),
                              IconButton(
                                  tooltip: saved.contains(s)
                                      ? 'Remove saved shop'
                                      : 'Save shop',
                                  onPressed: () => ref
                                      .read(commerceProvider.notifier)
                                      .toggleShop(s),
                                  icon: Icon(
                                      saved.contains(s)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Brand.green))
                            ]))));
              }),
              const SizedBox(height: 12),
              const AppText(
                  'Demo shops and prices are illustrative; no live merchant availability or affiliation is implied.',
                  style: TextStyle(fontSize: 12, color: Colors.black54))
            ]));
  }
}
