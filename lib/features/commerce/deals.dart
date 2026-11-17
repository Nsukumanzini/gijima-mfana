import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_visual.dart';
import 'common.dart';

class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final featured = products.where((p) => p.category == 'Restaurants').take(4);
    return Scaffold(
        appBar: AppBar(title: const AppText('Deals & offers')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: Brand.green, borderRadius: BorderRadius.circular(24)),
              child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_offer_outlined,
                        color: Colors.white, size: 32),
                    SizedBox(height: 12),
                    AppText('10% off your items',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    AppText(
                        'Use LOCAL10 at checkout. Up to R 50 off the item subtotal.',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 6),
                    AppText(
                        'Demo offer · Shop orders only · One code per order · Delivery and service fees excluded',
                        style: TextStyle(color: Colors.white70, fontSize: 12))
                  ])),
          const SizedBox(height: 12),
          Wrap(spacing: 10, children: [
            FilledButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(
                        const ClipboardData(text: 'LOCAL10'));
                    if (context.mounted) message(context, 'LOCAL10 copied');
                  } catch (_) {
                    if (context.mounted) {
                      message(context, 'Use code LOCAL10 at checkout');
                    }
                  }
                },
                icon: const Icon(Icons.copy),
                label: const AppText('Copy LOCAL10')),
            OutlinedButton(
                onPressed: () => context.push(
                    basket.count > 0 ? '/checkout?code=LOCAL10' : '/explore'),
                child: AppText(
                    basket.count > 0 ? 'Apply at checkout' : 'Browse products'))
          ]),
          const SizedBox(height: 24),
          const AppText('Local favourites',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const AppText(
              'Sample prices and photos · no live merchant promotions'),
          const SizedBox(height: 8),
          ...featured.map((p) => Card(
              child: ListTile(
                  leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ProductVisual(product: p, width: 56, height: 56)),
                  title: AppText(p.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: AppText(
                      '${p.store} · R ${(p.priceCents / 100).toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/product/${Uri.encodeComponent(p.name)}'))))
        ]));
  }
}
