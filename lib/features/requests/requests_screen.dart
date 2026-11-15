import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});
  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final requestKey = GlobalKey<FormState>();
  final item = TextEditingController();
  final description = TextEditingController();
  final budget = TextEditingController();
  final address = TextEditingController(text: '12 Acacia Street, Ermelo');
  String urgency = 'Whenever works';
  String? submitted;
  @override
  void dispose() {
    item.dispose();
    description.dispose();
    budget.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 110), children: [
        const Text('Requests',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
            'Need something special, or have an order ready to collect? We’ll help.'),
        const SizedBox(height: 18),
        if (submitted != null)
          Card(
              child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Brand.green),
                  title: Text('Request $submitted submitted'),
                  subtitle: const Text('Status: under review · mock workflow'),
                  trailing: TextButton(
                      onPressed: () => setState(() => submitted = null),
                      child: const Text('New')))),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                    key: requestKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personal shopping',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text(
                              'Tell us what you’re looking for and we’ll find a local option.'),
                          const SizedBox(height: 16),
                          _field(item, 'Product name'),
                          const SizedBox(height: 10),
                          _field(
                              description, 'Description and preferred details',
                              lines: 3),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                                child: _field(budget, 'Budget (R)',
                                    keyboard: TextInputType.number)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: DropdownButtonFormField(
                                    initialValue: urgency,
                                    decoration: const InputDecoration(
                                        labelText: 'When'),
                                    items: ['Whenever works', 'Today', 'Urgent']
                                        .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e,
                                                overflow:
                                                    TextOverflow.ellipsis)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => urgency = v!)))
                          ]),
                          const SizedBox(height: 10),
                          _field(address, 'Delivery address'),
                          const SizedBox(height: 14),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                  onPressed: () => _submit(context),
                                  icon: const Icon(Icons.send),
                                  label: const Text('Submit mock request')))
                        ])))),
        const SizedBox(height: 16),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Collect & deliver',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                          'Already bought something? Get a local courier to bring it to you.'),
                      const SizedBox(height: 14),
                      FilledButton.tonalIcon(
                          onPressed: () => _delivery(context),
                          icon: const Icon(Icons.delivery_dining),
                          label: const Text('Get a delivery quote'))
                    ]))),
      ]);
  Widget _field(TextEditingController ctl, String label,
          {int lines = 1, TextInputType? keyboard}) =>
      TextFormField(
          controller: ctl,
          maxLines: lines,
          keyboardType: keyboard,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Please add $label' : null,
          decoration: InputDecoration(labelText: label));
  void _submit(BuildContext context) {
    if (!requestKey.currentState!.validate()) return;
    setState(() => submitted = 'GM-${1000 + DateTime.now().millisecond}');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Demo only: your request was saved on this device.')));
  }

  void _delivery(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (c) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.viewInsetsOf(c).bottom + 20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Collect & deliver',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                      'Collection: Main Street business, Ermelo\nDelivery: 12 Acacia Street\nEstimated quote: R 45.00\n\nThis is a simulated quote.'),
                  const SizedBox(height: 14),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: () {
                            Navigator.pop(c);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Mock delivery request confirmed.')));
                          },
                          child: const Text('Confirm demo request')))
                ])));
  }
}
