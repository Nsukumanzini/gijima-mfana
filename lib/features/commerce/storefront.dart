// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../shared/product_card.dart';
import '../shared/product_visual.dart';
import 'common.dart';

class Storefront extends ConsumerStatefulWidget {
  const Storefront({super.key, required this.name});
  final String name;
  @override
  ConsumerState<Storefront> createState() => _StoreState();
}

class _StoreState extends ConsumerState<Storefront> {
  String query = '', category = 'All';
  @override
  Widget build(BuildContext context) {
    final all = products.where((p) => p.store == widget.name).toList(),
        categories = ['All', ...all.map((p) => p.category).toSet()];
    final visible = all
        .where((p) =>
            (category == 'All' || p.category == category) &&
            p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final saved = ref.watch(commerceProvider).savedShops.contains(widget.name);
    return Scaffold(
        appBar: AppBar(title: Text(widget.name), actions: [
          IconButton(
              tooltip: saved ? 'Unsave business' : 'Save business',
              onPressed: () =>
                  ref.read(commerceProvider.notifier).toggleShop(widget.name),
              icon: Icon(saved ? Icons.favorite : Icons.favorite_border))
        ]),
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: all.isEmpty
                                ? Image.asset('assets/images/groceries.jpg',
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover)
                                : ProductVisual(
                                    product: all.first,
                                    height: 200,
                                    width: double.infinity)),
                        heading(widget.name),
                        Text(all.isEmpty
                            ? 'No catalogue yet'
                            : '${all.first.category} · Locally selected demo catalogue'),
                        const SizedBox(height: 8),
                        Text(
                            'Demo address: ${10 + products.indexWhere((p) => p.store == widget.name).clamp(0, 99)} Main Street, Ermelo\nDemo hours: 08:00–20:00 daily\nOpen for simulated orders · 25–40 min delivery\n★ ${all.isEmpty ? 'New' : (all.map((p) => p.rating).reduce((a, b) => a + b) / all.length).toStringAsFixed(1)} customer rating (fictional)\nDelivery ${rand(deliveryFee(widget.name))} · Minimum items ${rand(minimumOrder(widget.name))}'),
                        const SizedBox(height: 12),
                        const Text(
                            'Sample catalogue, prices and availability. No affiliation with named brands or live merchant ordering.'),
                        const SizedBox(height: 12),
                        const Card(
                            child: ListTile(
                                leading: Icon(Icons.local_offer_outlined),
                                title: Text('LOCAL10'),
                                subtitle: Text(
                                    '10% off items, up to R 50. Apply at checkout.'))),
                        const SizedBox(height: 12),
                        TextField(
                            onChanged: (v) => setState(() => query = v),
                            decoration: const InputDecoration(
                                labelText: 'Search this shop',
                                prefixIcon: Icon(Icons.search))),
                        const SizedBox(height: 12),
                        Wrap(
                            spacing: 8,
                            children: categories
                                .map((c) => ChoiceChip(
                                    label: Text(c),
                                    selected: category == c,
                                    onSelected: (_) =>
                                        setState(() => category = c)))
                                .toList()),
                        const SizedBox(height: 12),
                        Text('${visible.length} available demo products')
                      ]))),
          if (visible.isEmpty)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'No matching items. Try another search or category.')))
          else
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                sliver: SliverGrid.builder(
                    itemCount: visible.length,
                    itemBuilder: (c, i) => ProductCard(product: visible[i]),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisExtent: 300,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12)))
        ]));
  }
}
