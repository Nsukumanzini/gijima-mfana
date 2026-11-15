import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String method = 'Card';
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(basketProvider);
    final fee = basket.count == 0 ? 0 : 2500;
    return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Delivery address',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          const Card(
              child: ListTile(
                  leading: Icon(Icons.location_on, color: Brand.green),
                  title: Text('Home'),
                  subtitle: Text('12 Acacia Street, Ermelo'),
                  trailing: Icon(Icons.chevron_right))),
          const SizedBox(height: 18),
          const Text('Payment method',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          RadioGroup<String>(
            groupValue: method,
            onChanged: (v) => setState(() => method = v!),
            child: Column(
              children: ['Card', 'Instant EFT', 'Digital wallet']
                  .map((m) => RadioListTile<String>(
                        value: m,
                        title: Text(m),
                        subtitle: const Text(
                            'Simulation only · no credentials collected'),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
              decoration: InputDecoration(
                  labelText: 'Delivery instructions (optional)',
                  prefixIcon: Icon(Icons.edit_note))),
          const SizedBox(height: 18),
          const Text('Order summary',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ...basket.lines.entries.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.key),
              trailing: Text('× ${e.value}'))),
          _money('Subtotal', basket.subtotal),
          _money('Delivery', fee),
          const Divider(),
          _money('Total', basket.subtotal + fee, bold: true),
          const SizedBox(height: 14),
          FilledButton(
              onPressed: busy || basket.count == 0 ? null : _pay,
              child: Text(busy
                  ? 'Processing demo payment…'
                  : 'Pay R ${((basket.subtotal + fee) / 100).toStringAsFixed(2)}')),
          const SizedBox(height: 8),
          const Text('Payments and delivery are simulated locally.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54))
        ]));
  }

  Widget _money(String s, int n, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(s,
                style: TextStyle(fontWeight: bold ? FontWeight.bold : null))),
        Text('R ${(n / 100).toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null))
      ]));
  Future<void> _pay() async {
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final controller = ref.read(basketProvider.notifier);
    controller.clear();
    setState(() => busy = false);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (d) => AlertDialog(
                icon: const Icon(Icons.check_circle,
                    color: Brand.green, size: 48),
                title: const Text('Order confirmed'),
                content: Text(
                    'Demo payment via $method succeeded. Your order GM-${1000 + DateTime.now().millisecond} is on its way.'),
                actions: [
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(d);
                        context.go('/');
                      },
                      child: const Text('Done'))
                ]));
  }
}
