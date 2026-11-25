import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/catalog.dart';
import '../../app/theme/app_theme.dart';
import 'product_visual.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard(
      {super.key,
      required this.product,
      this.showDeliveryEstimate = false,
      this.highlightQuery = '',
      this.showCategory = false});
  final ShopProduct product;
  final bool showDeliveryEstimate;
  final String highlightQuery;
  final bool showCategory;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final saved = favorites.contains(product.name);
    return InkWell(
        onTap: () =>
            context.push('/product/${Uri.encodeComponent(product.name)}'),
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
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
                        tooltip: tr(
                            context,
                            saved
                                ? 'Remove from favourites'
                                : 'Save to favourites'),
                        onPressed: () =>
                            ref.read(favoritesProvider.notifier).state = saved
                                ? ({...favorites}..remove(product.name))
                                : ({...favorites, product.name}),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                              saved ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(saved),
                              color: saved ? Brand.green : null),
                        )))
              ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HighlightedProductName(
                            name: tr(context, product.name),
                            query: highlightQuery),
                        AppText(product.store,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                        if (showCategory)
                          AppText(tr(context, product.category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Brand.green,
                                  fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Row(children: [
                          Expanded(
                              child: AppText(
                                  'R ${(product.priceCents / 100).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800))),
                          AppText('★ ${product.rating}',
                              style: const TextStyle(fontSize: 11))
                        ]),
                        if (showDeliveryEstimate) ...[
                          const SizedBox(height: 5),
                          Row(children: [
                            const Icon(Icons.schedule_outlined,
                                size: 13, color: Brand.green),
                            const SizedBox(width: 4),
                            Expanded(
                              child: AppText(
                                  product.category == 'Restaurants'
                                      ? '25–35 min · Demo'
                                      : '35–45 min · Demo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Brand.green, fontSize: 11)),
                            ),
                          ])
                        ]
                      ]))
            ])));
  }
}

class _HighlightedProductName extends StatelessWidget {
  const _HighlightedProductName({required this.name, required this.query});
  final String name;
  final String query;

  @override
  Widget build(BuildContext context) {
    final match = query.trim();
    final start =
        match.isEmpty ? -1 : name.toLowerCase().indexOf(match.toLowerCase());
    if (start < 0) {
      return AppText(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold));
    }
    final end = start + match.length;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: name.substring(0, start)),
        TextSpan(
            text: name.substring(start, end),
            style: const TextStyle(
                color: Brand.green, backgroundColor: Brand.mint)),
        TextSpan(text: name.substring(end)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
