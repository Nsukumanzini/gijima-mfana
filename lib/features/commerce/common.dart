// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/local_store.dart';

Widget heading(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)));
Widget moneyRow(String label, int cents) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label)),
      Text(rand(cents), style: const TextStyle(fontWeight: FontWeight.w700))
    ]));
void message(BuildContext context, Object text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text.toString().replaceFirst('Bad state: ', ''))));
String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Please complete this field' : null;
Widget input(TextEditingController controller, String label,
        {int lines = 1,
        TextInputType? keyboard,
        String? Function(String?)? validate}) =>
    Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
            controller: controller,
            maxLines: lines,
            keyboardType: keyboard,
            validator: validate ?? requiredText,
            decoration: InputDecoration(labelText: label)));
Widget addressPicker(
    WidgetRef ref, String? value, ValueChanged<String?> onChange) {
  final data = ref.watch(commerceProvider);
  return DropdownButtonFormField<String>(
      key: ValueKey('$value-${data.addresses.length}'),
      initialValue: data.addresses.any((a) => a['id'] == value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Delivery address'),
      items: data.addresses
          .map((a) => DropdownMenuItem<String>(
              value: a['id'] as String,
              child: Text(
                  '${addressText(a)}${covered(a) ? '' : ' · Outside coverage'}',
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChange,
      validator: (v) => v == null
          ? 'Add and choose a delivery address'
          : covered(data.address(v)!)
              ? null
              : 'Delivery is available in Ermelo and Wesselton only');
}

class DemoPayment extends StatelessWidget {
  const DemoPayment(
      {super.key,
      required this.method,
      required this.outcome,
      required this.onMethod,
      required this.onOutcome});
  final String method, outcome;
  final ValueChanged<String> onMethod, onOutcome;
  @override
  Widget build(BuildContext context) => Column(children: [
        DropdownButtonFormField<String>(
            initialValue: method,
            decoration:
                const InputDecoration(labelText: 'Online payment method'),
            items: ['Card', 'Instant EFT', 'Digital wallet']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => onMethod(v!)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            initialValue: outcome,
            decoration:
                const InputDecoration(labelText: 'Simulated payment outcome'),
            items: ['Successful', 'Pending', 'Failed', 'Cancelled']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => onOutcome(v!)),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
                'Demo payments only. No card numbers, bank details or real money.'))
      ]);
}

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({super.key});
  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String method = 'Card', outcome = 'Successful';
  @override
  void initState() {
    super.initState();
    method = ref.read(preferredPaymentProvider);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Simulate online payment'),
          content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                  child: DemoPayment(
                      method: method,
                      outcome: outcome,
                      onMethod: (v) => setState(() => method = v),
                      onOutcome: (v) => setState(() => outcome = v)))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back')),
            FilledButton(
                onPressed: () => Navigator.pop(
                    context, {'method': method, 'outcome': outcome}),
                child: const Text('Simulate payment'))
          ]);
}
