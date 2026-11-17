import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/catalog.dart';
import '../../app/theme/app_theme.dart';
import 'product_visual.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});
  final ShopProduct product;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final saved = favorites.contains(product.name);
    return InkWell(
        onTap: () =>
            context.push('/product/${Uri.encodeComponent(product.name)}'),
        borderRadius: BorderRadius.circular(20),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Stack(fit: StackFit.expand, children: [
                Hero(tag: product.name, child: ProductVisual(product: product)),
                Positioned(
                    right: 7,
                    top: 7,
                    child: IconButton.filledTonal(
                        onPressed: () =>
                            ref.read(favoritesProvider.notifier).state = saved
                                ? ({...favorites}..remove(product.name))
                                : ({...favorites, product.name}),
                        icon: Icon(
                            saved ? Icons.favorite : Icons.favorite_border,
                            color: saved ? Brand.green : null)))
              ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        AppText(product.store,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                        const SizedBox(height: 5),
                        Row(children: [
                          Expanded(
                              child: AppText(
                                  'R ${(product.priceCents / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800))),
                          AppText('★ ${product.rating}',
                              style: const TextStyle(fontSize: 11))
                        ])
                      ]))
            ])));
  }
}
