// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/catalog.dart';
import '../../app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class ProductDetail extends ConsumerWidget {
  const ProductDetail({super.key, required this.product});
  final ShopProduct product;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: Text(product.store)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
            height: 260,
            decoration: BoxDecoration(
                color: Color(product.color),
                borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Hero(
                tag: product.name,
                child: Image.asset(productImage(product), fit: BoxFit.cover))),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: Text(product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 25))),
          IconButton(
              onPressed: () => ref
                  .read(favoritesProvider.notifier)
                  .update((s) => ({...s, product.name})),
              icon: const Icon(Icons.favorite_border))
        ]),
        TextButton(
            onPressed: () =>
                context.push('/shop/${Uri.encodeComponent(product.store)}'),
            child: const Text('Visit business storefront')),
        Text('${product.store} · Ermelo',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        Text('★ ${product.rating}  ·  Available today',
            style: const TextStyle(
                color: Brand.green, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Text('R ${(product.priceCents / 100).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 23)),
        const SizedBox(height: 12),
        Text(
            'A carefully selected local favourite, available from ${product.store}. Add a note for the shop at checkout.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5)),
        const SizedBox(height: 18),
        FilledButton.icon(
            onPressed: () {
              final ok = ref.read(basketProvider.notifier).add(product);
              if (!ok) {
                showDialog(
                    context: context,
                    builder: (d) => AlertDialog(
                            title: const Text('One shop per order'),
                            content: Text(
                                'Your basket has items from ${ref.read(basketProvider).merchant}. Clear your basket before shopping with ${product.store}.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(d),
                                  child: const Text('Keep browsing')),
                              TextButton(
                                  onPressed: () {
                                    ref.read(basketProvider.notifier).clear();
                                    ref
                                        .read(basketProvider.notifier)
                                        .add(product);
                                    Navigator.pop(d);
                                  },
                                  child: const Text('Start new basket'))
                            ]));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to your basket')));
              }
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to basket'))
      ]));
}
