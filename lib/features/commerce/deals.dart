import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_visual.dart';
import 'common.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  String category = 'All deals';
  String query = '';
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(basketProvider);
    final featured = products;
    final visible = featured.where((p) {
      final matchesCategory = category == 'All deals' ||
          (category == 'Restaurants' && p.category == 'Restaurants') ||
          (category == 'Groceries' &&
              (p.category == 'Groceries' || p.category == 'Fresh produce')) ||
          (category == 'Personal shopping' &&
              p.category != 'Restaurants' &&
              p.category != 'Groceries' &&
              p.category != 'Fresh produce');
      final terms = '${p.name} ${p.store} ${p.category}';
      return matchesCategory &&
          terms.toLowerCase().contains(query.toLowerCase());
    }).toList();
    final savings = (basket.subtotal * 10 ~/ 100).clamp(0, 5000);
    final progress = (basket.subtotal / 50000).clamp(0.0, 1.0);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 4
        : width >= 740
            ? 3
            : width >= 520
                ? 2
                : 1;

    return Scaffold(
      appBar: AppBar(title: const AppText('Deals & offers')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _OfferHero(
                savings: savings,
                progress: progress,
                basketCount: basket.count,
                onCopy: _copyCode,
                onCheckout: () => context.push(
                    basket.count > 0 ? '/checkout?code=LOCAL10' : '/explore'),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    onChanged: (value) => setState(() => query = value.trim()),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: tr(context, 'Search deals, shops or food'),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: tr(context, 'Clear search'),
                              onPressed: () {
                                search.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final filter in [
                      'All deals',
                      'Restaurants',
                      'Groceries',
                      'Personal shopping'
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: AppText(filter),
                          selected: category == filter,
                          selectedColor: Brand.mint,
                          onSelected: (_) => setState(() => category = filter),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                    child: AppText('Local shop offers',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800))),
                AppText('${visible.length} ${tr(context, 'offers')}',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              const SizedBox(height: 4),
              const AppText('Sample promotions · no live merchant promotions',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: visible.isEmpty
                    ? _EmptyDeals(
                        key: ValueKey('$category:$query'),
                        onClear: () {
                          search.clear();
                          setState(() {
                            query = '';
                            category = 'All deals';
                          });
                        })
                    : GridView.builder(
                        key: ValueKey('$category:$query'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 316,
                        ),
                        itemBuilder: (context, index) => _DealCard(
                          product: visible[index],
                          index: index,
                          basketMerchant: basket.merchant,
                          onCopy: _copyCode,
                          onAdd: () {
                            final added = ref
                                .read(basketProvider.notifier)
                                .add(visible[index]);
                            if (!added) {
                              message(context,
                                  'Your basket has items from another shop. Finish or clear that basket first.');
                            } else {
                              message(context, 'Added to basket');
                            }
                          },
                          onOpen: () => context.push(
                              '/product/${Uri.encodeComponent(visible[index].name)}'),
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Brand.mint, borderRadius: BorderRadius.circular(18)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Brand.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: AppText(
                          'Demo offers use sample data and prices. LOCAL10 is the working checkout code; it takes 10% off items up to R 50. Delivery and service fees are excluded.'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyCode() async {
    try {
      await Clipboard.setData(const ClipboardData(text: 'LOCAL10'));
      if (mounted) message(context, 'LOCAL10 copied');
    } catch (_) {
      if (mounted) message(context, 'Use code LOCAL10 at checkout');
    }
  }
}

class _OfferHero extends StatelessWidget {
  const _OfferHero({
    required this.savings,
    required this.progress,
    required this.basketCount,
    required this.onCopy,
    required this.onCheckout,
  });
  final int savings, basketCount;
  final double progress;
  final VoidCallback onCopy, onCheckout;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Brand.green, Color(0xff075f49)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Brand.green.withValues(alpha: .16),
                blurRadius: 22,
                offset: const Offset(0, 9))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_offer_outlined,
                color: Colors.white, size: 28),
            const SizedBox(width: 9),
            const Expanded(
                child: AppText('10% off your items',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900))),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(30)),
                child: const AppText('Ends 30 Nov 2026',
                    style: TextStyle(color: Colors.white, fontSize: 11)))
          ]),
          const SizedBox(height: 8),
          const AppText(
              'Use LOCAL10 at checkout. Up to R 50 off the item subtotal.',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Row(children: [
            const Expanded(
                child: AppText('Your estimated savings',
                    style: TextStyle(color: Colors.white70))),
            AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Text('R ${(savings / 100).toStringAsFixed(2)}',
                    key: ValueKey(savings),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17))),
          ]),
          const SizedBox(height: 7),
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white))),
          const SizedBox(height: 5),
          AppText(
              basketCount == 0
                  ? 'Add items to see your savings. Maximum R 50 at R 500 in items.'
                  : 'Savings progress · maximum R 50 at R 500 in items.',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 8, children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Brand.green),
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              label: const AppText('Copy LOCAL10'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70)),
              onPressed: onCheckout,
              child: AppText(
                  basketCount > 0 ? 'Apply at checkout' : 'Browse products'),
            ),
          ]),
          const SizedBox(height: 4),
          const AppText(
              'Demo offer · Shop orders only · One code per order · Delivery and service fees excluded',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 3),
          const AppText(
              'Shop minimums vary by store and still apply at checkout.',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      );
}

class _DealCard extends StatelessWidget {
  const _DealCard({
    required this.product,
    required this.index,
    required this.basketMerchant,
    required this.onCopy,
    required this.onAdd,
    required this.onOpen,
  });
  final ShopProduct product;
  final int index;
  final String? basketMerchant;
  final VoidCallback onCopy, onAdd, onOpen;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 280 + index * 55),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)), child: child),
        ),
        child: GlassCard(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                GestureDetector(
                    onTap: onOpen, child: ProductVisual(product: product)),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: Brand.green,
                        borderRadius: BorderRadius.circular(20)),
                    child: const AppText('LOCAL10 · 10% off',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(product.store,
                        style: const TextStyle(
                            color: Brand.green, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    AppText(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: Text(
                            'R ${(product.priceCents / 100).toStringAsFixed(2)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const Icon(Icons.star,
                          size: 15, color: Color(0xffd18a00)),
                      Text(product.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(children: [
                IconButton(
                    tooltip: tr(context, 'Copy LOCAL10'),
                    onPressed: onCopy,
                    color: Brand.green,
                    icon: const Icon(Icons.copy_outlined)),
                Expanded(
                    child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: AppText(
                      basketMerchant != null && basketMerchant != product.store
                          ? 'Different shop'
                          : 'Add to basket'),
                )),
              ]),
            )
          ]),
        ),
      );
}

class _EmptyDeals extends StatelessWidget {
  const _EmptyDeals({super.key, required this.onClear});
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          const Icon(Icons.search_off, size: 42, color: Brand.green),
          const SizedBox(height: 10),
          const AppText('No deals match your search.'),
          TextButton(onPressed: onClear, child: const AppText('Clear filters')),
        ]),
      );
}
