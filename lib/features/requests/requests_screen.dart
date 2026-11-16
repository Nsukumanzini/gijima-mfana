// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/commerce.dart';
import '../commerce/common.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(commerceProvider).requests;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          heading('Requests'),
          const Text(
              'Tell us what you need. Review all fees before accepting a quote.'),
          const SizedBox(height: 18),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Personal shopping'),
                  subtitle: const Text(
                      'Ask us to find an item that is not in the catalogue.'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => context.push('/request/new/shopping'))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.delivery_dining),
                  title: const Text('Collect & deliver'),
                  subtitle: const Text(
                      'Already arranged an order? Get a local collection quote.'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => context.push('/request/new/collection'))),
          heading('Your requests'),
          if (requests.isEmpty)
            const Text('Your saved requests and quotations will appear here.'),
          ...requests.map((r) => Card(
              child: ListTile(
                  title: Text(r['name'] as String),
                  subtitle: Text('${r['type']} · ${r['status']}\n${r['id']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/requests/${r['id']}'))))
        ]);
  }
}

class RequestForm extends ConsumerStatefulWidget {
  const RequestForm({super.key, required this.collection});
  final bool collection;
  @override
  ConsumerState<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<RequestForm> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final k in [
      'name',
      'description',
      'quantity',
      'budget',
      'business',
      'collection',
      'collectionCity',
      'reference',
      'recipient',
      'instructions'
    ])
      k: TextEditingController()
  };
  String? address;
  String urgency = 'Today';
  DateTime when = DateTime.now().add(const Duration(hours: 1));
  @override
  void initState() {
    super.initState();
    address = ref.read(commerceProvider).defaultAddress?['id'] as String?;
    fields['quantity']!.text = '1';
    fields['collectionCity']!.text = 'Ermelo';
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? positive(String? v) {
    final n = int.tryParse(v ?? '');
    return n != null && n > 0 && n <= 100
        ? null
        : 'Enter a whole quantity from 1 to 100';
  }

  String? budget(String? v) => RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v ?? '') &&
          (double.tryParse(v ?? '') ?? 0) > 0 &&
          (double.tryParse(v ?? '') ?? 0) <= 100000
      ? null
      : 'Enter a budget from R 0.01 to R 100,000';
  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    return Scaffold(
        appBar: AppBar(
            title:
                Text(collection ? 'Collect & deliver' : 'Personal shopping')),
        body: Form(
            key: form,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const Text(
                  'Use fictional demo details. No courier will be dispatched.'),
              heading(collection
                  ? 'Collection details'
                  : 'What can we find for you?'),
              input(fields['name']!,
                  collection ? 'Item / parcel name' : 'Product name'),
              input(fields['description']!, 'Description and requirements',
                  lines: 3),
              input(fields['quantity']!, 'Quantity',
                  keyboard: TextInputType.number, validate: positive),
              input(
                  fields['business']!,
                  collection
                      ? 'Business or sender name'
                      : 'Preferred business / shopping location'),
              if (!collection)
                input(fields['budget']!, 'Maximum item budget (R)',
                    keyboard:
                        const TextInputType.numberWithOptions(decimal: true),
                    validate: budget),
              if (collection) ...[
                input(fields['collection']!, 'Collection street and building'),
                input(fields['collectionCity']!, 'Collection town',
                    validate: (v) => ['ermelo', 'wesselton']
                            .contains((v ?? '').trim().toLowerCase())
                        ? null
                        : 'Collections cover Ermelo and Wesselton'),
                input(
                    fields['reference']!, 'Order reference / collection code'),
                input(fields['recipient']!, 'Recipient name / demo contact'),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Preferred collection time'),
                    subtitle: Text(when.toLocal().toString().substring(0, 16)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _time())
              ],
              if (!collection)
                DropdownButtonFormField<String>(
                    initialValue: urgency,
                    decoration: const InputDecoration(labelText: 'Urgency'),
                    items: ['Today', 'Tomorrow', 'Whenever works']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => urgency = v!)),
              heading('Delivery'),
              addressPicker(ref, address, (v) => setState(() => address = v)),
              TextButton(
                  onPressed: () => context.push('/addresses'),
                  child: const Text('Manage addresses')),
              input(fields['instructions']!,
                  'Additional / handling instructions (optional)',
                  lines: 2, validate: (_) => null),
              FilledButton(
                  onPressed: () {
                    if (!form.currentState!.validate()) return;
                    try {
                      final budgetText = fields['budget']!.text.trim();
                      final parts = budgetText.split('.');
                      final cents = collection
                          ? 0
                          : int.parse(parts[0]) * 100 +
                              (parts.length == 2
                                  ? int.parse(parts[1].padRight(2, '0'))
                                  : 0);
                      final id =
                          ref.read(commerceProvider.notifier).submitRequest({
                        'type': collection
                            ? 'Collect & deliver'
                            : 'Personal shopping',
                        'name': fields['name']!.text.trim(),
                        'description': fields['description']!.text.trim(),
                        'quantity': int.parse(fields['quantity']!.text),
                        'budget': cents,
                        'business': fields['business']!.text.trim(),
                        'collection': collection
                            ? '${fields['collection']!.text.trim()}, ${fields['collectionCity']!.text.trim()}'
                            : null,
                        'reference': fields['reference']!.text.trim(),
                        'recipient': fields['recipient']!.text.trim(),
                        'collectionTime': when.toIso8601String(),
                        'urgency': urgency,
                        'instructions': fields['instructions']!.text.trim(),
                        'addressId': address
                      });
                      context.pushReplacement('/requests/$id');
                    } catch (e) {
                      message(context, e);
                    }
                  },
                  child: Text(collection
                      ? 'Get delivery quotation'
                      : 'Submit shopping request'))
            ])));
  }

  Future<void> _time() async {
    final day = await showDatePicker(
        context: context,
        initialDate: when,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 14)));
    if (day == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(when));
    if (time == null || !mounted) return;
    final selected =
        DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (selected.isBefore(DateTime.now())) {
      message(context, 'Please choose a future collection time');
      return;
    }
    setState(() => when = selected);
  }
}

class RequestDetail extends ConsumerWidget {
  const RequestDetail({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(commerceProvider);
    final repo = ref.read(commerceProvider.notifier),
        r = repo.find('requests', id);
    if (r == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Request')),
          body: const Center(child: Text('Request not found on this device.')));
    }
    final status = r['status'] as String;
    return Scaffold(
        appBar: AppBar(title: Text(id)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          heading(r['name'] as String),
          Text('${r['type']} · $status',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
              '${r['quantity']} requested · ${r['description']}\nBusiness: ${r['business']}\nDelivery: ${addressText(Map<String, dynamic>.from(r['address'] as Map))}\nInstructions: ${r['instructions']}'),
          if (r['type'] == 'Personal shopping')
            Text('Item budget: ${rand(r['budget'] as int)} · ${r['urgency']}')
          else
            Text(
                'Collection: ${r['collection']}\nReference: ${r['reference']}\nRecipient: ${r['recipient']}\nTime: ${r['collectionTime']}'),
          heading('Request progress'),
          for (final step in [
            'Submitted',
            'Under review',
            'Quotation received',
            'Quote accepted',
            'Payment confirmed',
            'Courier assigned',
            if (r['type'] == 'Personal shopping') 'Item purchased',
            'Delivered'
          ])
            ListTile(
                dense: true,
                leading: Icon(status == step
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(step)),
          if (status == 'Submitted' || status == 'Under review')
            FilledButton(
                onPressed: () => repo.review(id),
                child: Text(status == 'Submitted'
                    ? 'Simulate request review'
                    : 'Simulate quotation received')),
          if (status == 'Quotation received' ||
              status == 'Quote accepted' ||
              r['orderId'] != null) ...[
            heading('Your quotation'),
            if (r['type'] == 'Personal shopping')
              const Text(
                  'Quoted item price covers the full requested quantity.'),
            moneyRow('Item price', r['itemPrice'] as int),
            moneyRow('Delivery fee', r['delivery'] as int),
            moneyRow('Service fee', r['service'] as int),
            moneyRow(
                'Total',
                (r['itemPrice'] as int) +
                    (r['delivery'] as int) +
                    (r['service'] as int)),
            const Text(
                'Illustrative local quote. No real merchant was contacted.')
          ],
          if (status == 'Quotation received')
            Wrap(spacing: 12, children: [
              FilledButton(
                  onPressed: () => repo.quoteDecision(id, true),
                  child: const Text('Accept quotation')),
              OutlinedButton(
                  onPressed: () => repo.quoteDecision(id, false),
                  child: const Text('Reject quotation'))
            ]),
          if (status == 'Quote rejected')
            const Text(
                'You rejected this quotation. No payment was taken. Submit a new request to change requirements.'),
          if (status == 'Quote accepted') ...[
            Text('Payment: ${r['payment']}'),
            FilledButton(
                onPressed: () async {
                  final result = await showDialog<Map<String, String>>(
                      context: context, builder: (_) => const PaymentDialog());
                  if (result == null) return;
                  final oid = repo.payRequest(
                      id, result['method']!, result['outcome']!);
                  if (context.mounted) {
                    if (oid != null) {
                      context.push('/orders/$oid');
                    } else {
                      message(context,
                          'Payment ${result['outcome']}. You can retry from this quotation.');
                    }
                  }
                },
                child: const Text('Continue to simulated payment'))
          ],
          if (r['orderId'] != null)
            FilledButton(
                onPressed: () => context.push('/orders/${r['orderId']}'),
                child: const Text('Track delivery order'))
        ]));
  }
}
