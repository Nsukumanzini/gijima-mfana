import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/commerce.dart';
import 'common.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key, this.orderId});
  final String? orderId;
  @override
  ConsumerState<SupportScreen> createState() => _SupportState();
}

class _SupportState extends ConsumerState<SupportScreen> {
  final form = GlobalKey<FormState>();
  final description = TextEditingController();
  String? order;
  String kind = 'Missing item';
  @override
  void initState() {
    super.initState();
    order = widget.orderId;
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(commerceProvider);
    return Scaffold(
        appBar: AppBar(title: const AppText('Help & support')),
        body: Form(
            key: form,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              heading('How can we help?'),
              const ExpansionTile(
                  title: AppText('Where do you deliver?'),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(16),
                        child: AppText(
                            'The demo service covers Ermelo and Wesselton. All tracking, payments and refunds are simulated.'))
                  ]),
              const ExpansionTile(
                  title: AppText('How do requests work?'),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(16),
                        child: AppText(
                            'Submit your requirements, review a quotation, accept it, and simulate online payment. Your request then becomes a tracked delivery order.'))
                  ]),
              heading('Report an order issue'),
              DropdownButtonFormField<String>(
                  initialValue: order,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: tr(context, 'Related order (optional)')),
                  items: [
                    const DropdownMenuItem<String>(
                        value: '', child: AppText('General enquiry')),
                    ...data.orders.map((o) => DropdownMenuItem<String>(
                        value: o['id'] as String,
                        child: AppText('${o['merchant']} · ${o['id']}',
                            overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: (v) => setState(() => order = v)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration:
                      InputDecoration(labelText: tr(context, 'Issue type')),
                  items: [
                    'Missing item',
                    'Damaged item',
                    'Refund request',
                    'Delivery problem',
                    'Other'
                  ]
                      .map((k) => DropdownMenuItem(value: k, child: AppText(k)))
                      .toList(),
                  onChanged: (v) => setState(() => kind = v!)),
              const SizedBox(height: 12),
              input(description, 'What happened?',
                  lines: 3,
                  validate: (v) => (v ?? '').trim().length >= 5
                      ? null
                      : 'Add at least five characters'),
              FilledButton(
                  onPressed: () {
                    if (!form.currentState!.validate()) return;
                    if (kind != 'Other' && (order == null || order!.isEmpty)) {
                      message(
                          context, 'Select the related order for this issue');
                      return;
                    }
                    try {
                      final id = ref
                          .read(commerceProvider.notifier)
                          .support(order ?? '', kind, description.text.trim());
                      context.push('/support/$id');
                      description.clear();
                    } catch (e) {
                      message(context, e);
                    }
                  },
                  child: const AppText('Create demo support ticket')),
              heading('Your tickets'),
              if (data.tickets.isEmpty)
                const AppText('No support tickets yet.'),
              ...data.tickets.map((t) => Card(
                  child: ListTile(
                      title: AppText('${t['kind']} · ${t['status']}'),
                      subtitle: AppText('${t['id']}\n${t['orderId']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/support/${t['id']}'))))
            ])));
  }
}

class TicketDetail extends ConsumerStatefulWidget {
  const TicketDetail({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TicketDetail> createState() => _TicketState();
}

class _TicketState extends ConsumerState<TicketDetail> {
  final reply = TextEditingController();
  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(commerceProvider);
    final repo = ref.read(commerceProvider.notifier),
        t = repo.find('tickets', widget.id);
    if (t == null) {
      return Scaffold(
          appBar: AppBar(title: const AppText('Support ticket')),
          body: const Center(child: AppText('Ticket not found.')));
    }
    return Scaffold(
        appBar: AppBar(title: AppText(t['id'] as String)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          heading('${t['kind']} · ${t['status']}'),
          if (t['kind'] == 'Refund request')
            AppText('Refund: ${t['refund']} · Demo only'),
          if ((t['orderId'] as String).isNotEmpty)
            TextButton(
                onPressed: () => context.push('/orders/${t['orderId']}'),
                child: const AppText('View related order')),
          ...(t['messages'] as List).map((m) => Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppText('${m['sender']}\n${m['text']}')))),
          if (t['status'] != 'Resolved') ...[
            TextField(
                controller: reply,
                maxLines: 2,
                decoration:
                    InputDecoration(labelText: tr(context, 'Add a reply'))),
            TextButton(
                onPressed: () {
                  repo.reply(widget.id, reply.text.trim());
                  reply.clear();
                },
                child: const AppText('Send local reply')),
            FilledButton(
                onPressed: () => repo.reviewTicket(widget.id),
                child: AppText(t['status'] == 'Open'
                    ? 'Simulate support review'
                    : 'Simulate resolution'))
          ],
          const AppText(
              'This conversation stays on your device. No external ticket, message or refund is sent.')
        ]));
  }
}
