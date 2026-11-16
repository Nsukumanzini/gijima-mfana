// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/commerce.dart';
import '../../data/mock/catalog.dart';
import '../commerce/common.dart';
import '../../app/theme/app_theme.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersState();
}

class _OrdersState extends ConsumerState<OrdersScreen> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(commerceProvider).orders.where((o) {
      final done = o['step'] == stepsFor(o).length - 1;
      return filter == 'All' ||
          filter == 'Active' && o['cancelled'] != true && !done ||
          filter == 'Completed' && done && o['cancelled'] != true ||
          filter == 'Cancelled' && o['cancelled'] == true ||
          o['type'] == filter;
    }).toList();
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          heading('Your orders'),
          const Text(
              'Shop orders, personal shopping and collection deliveries.'),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              children: [
                'All',
                'Active',
                'Completed',
                'Cancelled',
                'Personal shopping',
                'Collect & deliver'
              ]
                  .map((f) => ChoiceChip(
                      label: Text(f),
                      selected: filter == f,
                      onSelected: (_) => setState(() => filter = f)))
                  .toList()),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'No orders here yet. Shop local or submit a request to get started.'))),
          ...orders.map((o) => Card(
              child: ListTile(
                  leading: const Icon(Icons.local_shipping_outlined,
                      color: Brand.green),
                  title: Text(o['merchant'] as String),
                  subtitle: Text(
                      '${o['id']}\n${o['type']} · ${o['cancelled'] == true ? 'Cancelled' : stepsFor(o)[o['step'] as int]}\nPayment: ${o['payment']} · ${rand(o['total'] as int)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/orders/${o['id']}'))))
        ]);
  }
}

class OrderDetail extends ConsumerWidget {
  const OrderDetail({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(commerceProvider);
    final repo = ref.read(commerceProvider.notifier),
        o = repo.find('orders', id);
    if (o == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Order')),
          body: const Center(child: Text('Order not found on this device.')));
    }
    final steps = stepsFor(o), step = o['step'] as int;
    final paid = o['payment'] == 'Successful',
        cancelled = o['cancelled'] == true;
    return Scaffold(
        appBar: AppBar(title: Text(id)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          heading(o['merchant'] as String),
          Text('${o['type']} · ${o['created']}'),
          Text(cancelled ? 'Cancelled' : steps[step],
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Brand.green)),
          const SizedBox(height: 12),
          Text(
              'Delivery: ${addressText(Map<String, dynamic>.from(o['address'] as Map))}'),
          if (o['collection'] != null)
            Text(
                'Collection: ${o['collection']}\nReference: ${o['reference']}\nRecipient: ${o['recipient']}\nCollection time: ${o['collectionTime']}'),
          if ((o['note'] as String? ?? '').isNotEmpty)
            Text('Instructions: ${o['note']}'),
          heading('Items'),
          ...(o['items'] as List).map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${item['quantity']} × ${item['name']}'),
                subtitle: Text(item['note'] as String? ?? ''),
                trailing: Text(rand((item['price'] as int) *
                    (o['type'] == 'Personal shopping'
                        ? 1
                        : item['quantity'] as int))));
          }),
          heading('Payment summary'),
          moneyRow('Items', o['subtotal'] as int),
          moneyRow('Delivery', o['delivery'] as int),
          moneyRow('Service fee', o['service'] as int),
          moneyRow('Discount', -(o['discount'] as int)),
          moneyRow('Total', o['total'] as int),
          Text('${o['method']} · ${o['payment']} (simulated)'),
          if (o['refund'] == 'Approved')
            Text('Simulated refund approved: ${rand(o['total'] as int)}'),
          if (!paid && !cancelled)
            FilledButton(
                onPressed: () async {
                  final result = await showDialog<Map<String, String>>(
                      context: context, builder: (_) => const PaymentDialog());
                  if (result == null) return;
                  repo.retryPayment(id, result['outcome']!,
                      method: result['method']);
                  if (result['outcome'] == 'Successful') {
                    final basket = ref.read(basketProvider);
                    final items = o['items'] as List;
                    if (basket.lines.length == items.length &&
                        items.every(
                            (i) => basket.lines[i['name']] == i['quantity'])) {
                      ref.read(basketProvider.notifier).clear();
                    }
                  }
                },
                child: const Text('Resolve / retry demo payment')),
          heading('Delivery tracking'),
          const Text('Illustrative local route · no GPS or mapping service'),
          const SizedBox(height: 12),
          _RouteMap(progress: cancelled ? 0 : step / (steps.length - 1)),
          const SizedBox(height: 12),
          Text(cancelled
              ? 'Delivery cancelled'
              : step == steps.length - 1
                  ? 'Delivered to your demo address'
                  : step >= 2
                      ? 'Courier Sipho Dlamini · ETA ${step >= steps.length - 2 ? '5–15' : '20–35'} min (simulated)'
                      : 'Courier allocation follows payment and preparation.'),
          if (paid && !cancelled)
            TextButton.icon(
                onPressed: () => message(context,
                    'Demo contact: Sipho has received your request. No call or message was sent.'),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Contact courier (demo)')),
          for (var i = 0; i < steps.length; i++)
            ListTile(
                leading: Icon(
                    i <= step && !cancelled
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: i <= step && !cancelled ? Brand.green : Colors.grey),
                title: Text(steps[i])),
          if (paid && !cancelled && step < steps.length - 1)
            FilledButton(
                onPressed: () => repo.advanceOrder(id),
                child: Text(step == steps.length - 2
                    ? 'Confirm delivered (demo)'
                    : 'Simulate next delivery update')),
          if (!cancelled && step < 2)
            TextButton(
                onPressed: () async {
                  final yes = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                              title: const Text('Cancel this demo order?'),
                              content: const Text(
                                  'The order will remain in cancelled history. For a paid order, use support to request a simulated refund.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(d, false),
                                    child: const Text('Keep order')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(d, true),
                                    child: const Text('Cancel order'))
                              ]));
                  if (yes == true) repo.cancelOrder(id);
                },
                child: const Text('Cancel order')),
          const SizedBox(height: 18),
          OutlinedButton.icon(
              onPressed: () => context.push('/support?order=$id'),
              icon: const Icon(Icons.support_agent),
              label: const Text('Report an issue / request a refund')),
          if (o['requestId'] != null)
            TextButton(
                onPressed: () => context.push('/requests/${o['requestId']}'),
                child: const Text('View original request'))
        ]));
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) => Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: Brand.mint, borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder(
          builder: (c, s) => Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                const Positioned(
                    left: 15, bottom: 15, child: Text('Collection · Ermelo')),
                const Positioned(
                    right: 15, top: 15, child: Text('Your address')),
                AnimatedPositioned(
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 700),
                    left: 20 + (s.maxWidth - 70) * progress,
                    top: 130 - 95 * progress,
                    child: const Icon(Icons.delivery_dining,
                        size: 38, color: Brand.green))
              ])));
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = 12;
    for (double x = 35; x < s.width; x += 65) {
      c.drawLine(Offset(x, 0), Offset(x - 30, s.height), street);
    }
    for (double y = 35; y < s.height; y += 55) {
      c.drawLine(Offset(0, y), Offset(s.width, y + 15), street);
    }
    c.drawLine(
        Offset(30, s.height - 45),
        Offset(s.width - 35, 40),
        Paint()
          ..color = Brand.green.withValues(alpha: .35)
          ..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
