// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 100), children: [
        const Text('Your orders',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Follow your latest local deliveries.'),
        const SizedBox(height: 16),
        _order(context, 'GM-24081', 'Mahlasedi Kitchen',
            'Courier assigned · arriving in 25–35 min', '🍗', true),
        _order(context, 'GM-23964', 'Highveld Farm Store',
            'Delivered · Yesterday', '🥚', false),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery progress',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 12),
                      Container(
                          height: 170,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Brand.mint,
                              borderRadius: BorderRadius.circular(16)),
                          child: Stack(alignment: Alignment.center, children: [
                            const Icon(Icons.route,
                                size: 100, color: Brand.green),
                            Positioned(
                                left: 24,
                                bottom: 22,
                                child: const Text('Mahlasedi Kitchen')),
                            Positioned(
                                right: 20,
                                top: 20,
                                child: const Icon(Icons.delivery_dining,
                                    size: 36, color: Brand.charcoal))
                          ])),
                      const SizedBox(height: 12),
                      const Text('Courier Sipho · demo tracking only'),
                      const SizedBox(height: 8),
                      const Text(
                          '● Order placed   ━   ● Preparing   ━   ● Courier assigned',
                          style: TextStyle(fontSize: 12))
                    ]))),
      ]);
  Widget _order(BuildContext context, String id, String merchant, String status,
          String emoji, bool active) =>
      Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: Brand.mint,
                  child: Text(emoji, style: const TextStyle(fontSize: 22))),
              title: Text(merchant,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$id · $status'),
              trailing: Icon(
                  active ? Icons.chevron_right : Icons.check_circle_outline,
                  color: active ? Brand.green : null),
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$id · $status')))));
}
