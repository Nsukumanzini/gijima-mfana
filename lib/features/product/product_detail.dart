// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../../app/theme/app_theme.dart';
import '../shared/product_visual.dart';

class ProductDetail extends ConsumerStatefulWidget {
  const ProductDetail({super.key, required this.product});
  final ShopProduct product;
  @override
  ConsumerState<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends ConsumerState<ProductDetail> {
  int quantity = 1;
  final instructions = TextEditingController();
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(recentlyViewedProvider.notifier).record(widget.product.name);
      }
    });
  }

  @override
  void dispose() {
    instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final favorites = ref.watch(favoritesProvider),
        saved = favorites.contains(product.name);
    final related = products
        .where((p) => p.name != product.name && p.category == product.category)
        .take(4)
        .toList();
    return Scaffold(
        appBar: AppBar(title: Text(product.store)),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                  height: 270,
                  decoration: BoxDecoration(
                      color: Color(product.color),
                      borderRadius: BorderRadius.circular(24)),
                  clipBehavior: Clip.antiAlias,
                  child: Hero(
                      tag: product.name,
                      child: ProductVisual(product: product))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: Text(product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 26))),
                IconButton.filledTonal(
                    tooltip:
                        saved ? 'Remove from favourites' : 'Save to favourites',
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).state = saved
                            ? ({...favorites}..remove(product.name))
                            : {...favorites, product.name},
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                        color: Brand.green))
              ]),
              const SizedBox(height: 8),
              Text('★ ${product.rating}   ·   Available today   ·   25–40 min',
                  style: const TextStyle(
                      color: Brand.green, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text(rand(product.priceCents),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                  'A local favourite from ${product.store}. Product photos, availability and prices are illustrative.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5)),
              Card(
                  child: ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: Brand.mint,
                          child: Icon(Icons.storefront_outlined,
                              color: Brand.green)),
                      title: Text(product.store,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Ermelo · Delivery ${rand(deliveryFee(product.store))}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                          '/shop/${Uri.encodeComponent(product.store)}'))),
              const SizedBox(height: 16),
              const Text('Quantity',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Row(children: [
                IconButton(
                    onPressed:
                        quantity > 1 ? () => setState(() => quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline)),
                Text('$quantity',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed:
                        quantity < 99 ? () => setState(() => quantity++) : null,
                    icon: const Icon(Icons.add_circle_outline))
              ]),
              TextField(
                  controller: instructions,
                  maxLength: 200,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Special instructions (optional)',
                      hintText: 'Add a note for the shop')),
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: () => _add(false),
                  icon: const Icon(Icons.shopping_basket_outlined),
                  label: Text(
                      'Add to basket · ${rand(product.priceCents * quantity)}')),
              OutlinedButton(
                  onPressed: () => _add(true), child: const Text('Buy now')),
              if (related.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('You may also like',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 8),
                ...related.map((p) => Card(
                    child: ListTile(
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ProductVisual(
                                product: p, width: 52, height: 52)),
                        title: Text(p.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${p.store} · ${rand(p.priceCents)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context
                            .push('/product/${Uri.encodeComponent(p.name)}'))))
              ]
            ]));
  }

  Future<void> _add(bool checkout) async {
    final basket = ref.read(basketProvider.notifier), product = widget.product;
    if (!basket.addQuantity(product, quantity,
        instructions: instructions.text)) {
      final replace = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
                  title: const Text('One shop per order'),
                  content: Text(
                      'Your basket contains items from ${ref.read(basketProvider).merchant}. Start a new basket for ${product.store}?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Keep basket')),
                    FilledButton(
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Start new basket'))
                  ]));
      if (replace != true || !mounted) return;
      basket.clear();
      basket.addQuantity(product, quantity, instructions: instructions.text);
    }
    if (!mounted) return;
    if (checkout) {
      context.push('/checkout');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$quantity × ${product.name} added to your basket')));
    }
  }
}
