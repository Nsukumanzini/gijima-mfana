import '../../app/localization/strings.dart';
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
    final favorites = ref.watch(favoritesProvider);
    final saved = favorites.contains(product.name);
    final related = products
        .where((p) => p.name != product.name && p.category == product.category)
        .take(6)
        .toList();
    final ratingCount = 18 + product.name.length * 7;
    return Scaffold(
      appBar: AppBar(
        title: AppText(product.store,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: saved ? 'Remove from favourites' : 'Save to favourites',
            onPressed: () => ref.read(favoritesProvider.notifier).state = saved
                ? ({...favorites}..remove(product.name))
                : {...favorites, product.name},
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(saved ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(saved), color: saved ? Brand.green : null),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          sliver: SliverList.list(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(children: [
                Hero(
                  tag: product.name,
                  child: AspectRatio(
                    aspectRatio: 1.18,
                    child: ProductVisual(product: product),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child:
                      _Pill(icon: Icons.place_outlined, text: 'Ermelo local'),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child:
                      _Pill(icon: Icons.photo_outlined, text: 'Product image'),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Pill(
                  icon: Icons.category_outlined,
                  text: tr(context, product.category)),
              const _Pill(
                  icon: Icons.check_circle_outline,
                  text: 'Available today · Demo'),
            ]),
            const SizedBox(height: 12),
            AppText(product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 27, height: 1.12)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.star_rounded,
                  size: 20, color: Color(0xFFE39A18)),
              const SizedBox(width: 4),
              AppText(
                  '${product.rating.toStringAsFixed(1)}  ·  $ratingCount demo ratings',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.schedule_outlined, size: 17, color: Brand.green),
              const SizedBox(width: 4),
              const AppText('25–40 min',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Brand.green)),
            ]),
            const SizedBox(height: 17),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                  child: AppText(rand(product.priceCents),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Brand.charcoal))),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: AppText('Price shown is illustrative',
                    style: TextStyle(fontSize: 11, color: Colors.black54)),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: Brand.mint, borderRadius: BorderRadius.circular(18)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.local_mall_outlined, color: Brand.green),
                const SizedBox(width: 10),
                Expanded(
                    child: AppText(
                        '${product.name} from ${product.store}. Product details, photos, availability and prices are sample marketplace content.',
                        style: const TextStyle(height: 1.45))),
              ]),
            ),
            const SizedBox(height: 14),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    context.push('/shop/${Uri.encodeComponent(product.store)}'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const CircleAvatar(
                        backgroundColor: Brand.mint,
                        child: Icon(Icons.storefront_outlined,
                            color: Brand.green)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          AppText(product.store,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          AppText(
                              'Ermelo · Demo delivery ${rand(deliveryFee(product.store))}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ])),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Brand.green),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(
                  child: AppText('Choose quantity',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17))),
              _QuantityControl(
                  quantity: quantity,
                  onChanged: (value) => setState(() => quantity = value)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: instructions,
              maxLength: 200,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: tr(context, 'Special instructions (optional)'),
                hintText: tr(context, 'Add a note for the shop'),
                prefixIcon:
                    const Icon(Icons.edit_note_rounded, color: Brand.green),
                alignLabelWithHint: true,
              ),
            ),
            if (related.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(children: [
                const Expanded(
                    child: AppText('You may also like',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 20))),
                AppText('${related.length} picks',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Brand.green,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                height: 188,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = related[index];
                    return SizedBox(
                      width: 150,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push(
                              '/product/${Uri.encodeComponent(item.name)}'),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: SizedBox(
                                        width: double.infinity,
                                        child: ProductVisual(product: item))),
                                Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText(item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          AppText(
                                              '${rand(item.priceCents)} · ★ ${item.rating}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Brand.green)),
                                        ])),
                              ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Center(
                child: AppText(
                    'Illustrative demo marketplace · No live merchant affiliation',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                    textAlign: TextAlign.center)),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 18,
                    offset: const Offset(0, -5))
              ]),
          child: Row(children: [
            Expanded(
                child: OutlinedButton.icon(
              onPressed: () => _add(true),
              icon: const Icon(Icons.bolt_rounded),
              label: const AppText('Buy now'),
            )),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _add(false),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: AppText(
                      'Add to basket · ${rand(product.priceCents * quantity)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                )),
          ]),
        ),
      ),
    );
  }

  Future<void> _add(bool checkout) async {
    final basket = ref.read(basketProvider.notifier);
    final product = widget.product;
    if (!basket.addQuantity(product, quantity,
        instructions: instructions.text)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const AppText('One shop per order'),
          content: AppText(
              'Your basket contains items from ${ref.read(basketProvider).merchant}. Start a new basket for ${product.store}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const AppText('Keep basket')),
            FilledButton(
                onPressed: () => Navigator.pop(d, true),
                child: const AppText('Start new basket')),
          ],
        ),
      );
      if (replace != true || !mounted) return;
      basket.clear();
      basket.addQuantity(product, quantity, instructions: instructions.text);
    }
    if (!mounted) return;
    if (checkout) {
      context.push('/checkout');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: AppText('$quantity × ${product.name} added to your basket'),
        action: SnackBarAction(
            label: 'Checkout', onPressed: () => context.push('/checkout')),
      ));
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .95),
            borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: Brand.green),
          const SizedBox(width: 5),
          AppText(text,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.quantity, required this.onChanged});
  final int quantity;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Brand.mint, borderRadius: BorderRadius.circular(15)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              tooltip: 'Decrease quantity',
              visualDensity: VisualDensity.compact,
              onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
              icon: const Icon(Icons.remove_rounded)),
          SizedBox(
              width: 24,
              child: Center(
                  child: AppText('$quantity',
                      style: const TextStyle(fontWeight: FontWeight.w800)))),
          IconButton(
              tooltip: 'Increase quantity',
              visualDensity: VisualDensity.compact,
              onPressed: quantity < 99 ? () => onChanged(quantity + 1) : null,
              icon: const Icon(Icons.add_circle_outline)),
        ]),
      );
}
