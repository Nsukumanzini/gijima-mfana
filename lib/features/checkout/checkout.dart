// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/local_store.dart';
import '../commerce/common.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  final note = TextEditingController(), discount = TextEditingController();
  String? address;
  String code = '', method = 'Card', outcome = 'Successful';
  bool busy = false;
  @override
  void initState() {
    super.initState();
    method = ref.read(preferredPaymentProvider);
    address = ref.read(commerceProvider).defaultAddress?['id'] as String?;
  }

  @override
  void dispose() {
    note.dispose();
    discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(basketProvider), t = basketTotals(basket, code);
    return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Form(
            key: form,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (basket.count == 0) const Text('Your basket is empty.'),
              heading('Delivery address'),
              addressPicker(ref, address, (v) => setState(() => address = v)),
              TextButton(
                  onPressed: () => context.push('/addresses'),
                  child: const Text('Manage delivery addresses')),
              input(note, 'Delivery instructions (optional)',
                  lines: 2, validate: (_) => null),
              heading('Order from ${basket.merchant ?? 'your local shop'}'),
              const Text('Estimated delivery: 25–40 minutes · Demo only'),
              for (final e in basket.lines.entries)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${e.value} × ${e.key}'),
                    subtitle: Text(basket.notes[e.key] ?? ''),
                    trailing: Text(rand(
                        products.firstWhere((p) => p.name == e.key).priceCents *
                            e.value))),
              const SizedBox(height: 12),
              TextField(
                  controller: discount,
                  decoration: const InputDecoration(
                      labelText: 'Discount code',
                      hintText: 'Try LOCAL10: 10% off items, max R 50')),
              TextButton(
                  onPressed: () {
                    final v = discount.text.trim().toUpperCase();
                    setState(() => code = v == 'LOCAL10' ? v : '');
                    message(
                        context,
                        v.isEmpty
                            ? 'Discount removed'
                            : v == 'LOCAL10'
                                ? 'LOCAL10 applied'
                                : 'Code not recognised. Try LOCAL10.');
                  },
                  child: const Text('Apply code')),
              moneyRow('Subtotal', t.subtotal),
              moneyRow('Delivery', t.delivery),
              moneyRow('Service fee', t.service),
              moneyRow('Discount', -t.discount),
              const Divider(),
              moneyRow('Total', t.total),
              if (basket.merchant != null)
                Text(
                    'Minimum items subtotal: ${rand(minimumOrder(basket.merchant!))}'),
              heading('Online payment'),
              DemoPayment(
                  method: method,
                  outcome: outcome,
                  onMethod: (v) => setState(() => method = v),
                  onOutcome: (v) => setState(() => outcome = v)),
              FilledButton(
                  onPressed: busy || basket.count == 0
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          setState(() => busy = true);
                          try {
                            final repo = ref.read(commerceProvider.notifier);
                            final id = repo.checkout(
                                basket: basket,
                                addressId: address!,
                                note: note.text.trim(),
                                code: code,
                                method: method,
                                outcome: outcome);
                            if (outcome == 'Successful') {
                              ref.read(basketProvider.notifier).clear();
                            }
                            if (context.mounted) {
                              context.pushReplacement('/orders/$id');
                            }
                          } catch (e) {
                            if (context.mounted) message(context, e);
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  child: Text('Simulate payment · ${rand(t.total)}'))
            ])));
  }
}
