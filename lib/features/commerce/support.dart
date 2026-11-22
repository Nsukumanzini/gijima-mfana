import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
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
  final faqSearch = TextEditingController();
  String? order;
  String kind = 'Missing item';
  String ticketFilter = 'All';

  @override
  void initState() {
    super.initState();
    order = widget.orderId;
  }

  @override
  void dispose() {
    description.dispose();
    faqSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(commerceProvider);
    final selectedOrder = data.orders.cast<Record?>().firstWhere(
          (item) => item?['id'] == order,
          orElse: () => null,
        );
    final faqItems = <(String, String, IconData)>[
      (
        'Where do you deliver?',
        'The demo service covers Ermelo and Wesselton. All tracking, payments and refunds are simulated.',
        Icons.location_on_outlined
      ),
      (
        'How do requests work?',
        'Submit your requirements, review a quotation, accept it, and simulate online payment. Your request then becomes a tracked delivery order.',
        Icons.shopping_bag_outlined
      ),
    ];
    final faqQuery = faqSearch.text.trim().toLowerCase();
    final visibleFaqs = faqItems
        .where((faq) =>
            faqQuery.isEmpty ||
            tr(context, faq.$1).toLowerCase().contains(faqQuery) ||
            tr(context, faq.$2).toLowerCase().contains(faqQuery))
        .toList();
    final tickets = data.tickets
        .where((ticket) =>
            ticketFilter == 'All' || ticket['status'] == ticketFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const AppText('Help & support')),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SupportHero(onOrders: () => context.push('/orders')),
                  const SizedBox(height: 20),
                  _SectionTitle(
                      icon: Icons.help_outline_rounded,
                      title: 'Frequently asked questions',
                      subtitle:
                          'Find quick answers about local delivery and requests.'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: faqSearch,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: tr(context, 'Search help topics'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: faqSearch.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: tr(context, 'Clear search'),
                              onPressed: () {
                                faqSearch.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (visibleFaqs.isEmpty)
                    _SoftNotice(
                        icon: Icons.search_off_rounded,
                        text: 'No help topics match your search.')
                  else
                    ...visibleFaqs.map((faq) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            leading: _IconBubble(icon: faq.$3),
                            title: AppText(faq.$1,
                                style: const TextStyle(
                                    color: Brand.charcoal,
                                    fontWeight: FontWeight.w800)),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 18),
                            children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: AppText(faq.$2,
                                      style: const TextStyle(
                                          color: Colors.black54, height: 1.45)))
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),
                  _SectionTitle(
                      icon: Icons.support_agent_rounded,
                      title: 'Report an order issue',
                      subtitle:
                          'Tell us what happened and we’ll create a local demo ticket.'),
                  const SizedBox(height: 10),
                  _DemoCoverageNote(),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                  'order-${order ?? 'none'}-${data.orders.length}'),
                              initialValue:
                                  data.orders.any((o) => o['id'] == order)
                                      ? order
                                      : '',
                              isExpanded: true,
                              decoration: InputDecoration(
                                  labelText: tr(context, 'Related order'),
                                  helperText: tr(context,
                                      'Choose an order for item, delivery or refund issues.'),
                                  prefixIcon:
                                      const Icon(Icons.receipt_long_outlined)),
                              items: [
                                const DropdownMenuItem<String>(
                                    value: '',
                                    child: AppText('General enquiry')),
                                ...data.orders.map((o) =>
                                    DropdownMenuItem<String>(
                                        value: o['id'] as String,
                                        child: AppText(
                                            '${o['merchant']} · ${o['id']}',
                                            overflow: TextOverflow.ellipsis)))
                              ],
                              onChanged: (value) =>
                                  setState(() => order = value),
                            ),
                            if (selectedOrder != null) ...[
                              const SizedBox(height: 9),
                              _SelectedOrderSummary(order: selectedOrder),
                            ],
                            const SizedBox(height: 18),
                            AppText('Issue type',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final item in _issueKinds)
                                  ChoiceChip(
                                    avatar: Icon(item.$2, size: 17),
                                    label: AppText(item.$1),
                                    selected: kind == item.$1,
                                    onSelected: (_) =>
                                        setState(() => kind = item.$1),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: description,
                              minLines: 3,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                  labelText: tr(context, 'What happened?'),
                                  alignLabelWithHint: true,
                                  helperText: tr(context,
                                      'Add at least five characters. Please do not include payment details.'),
                                  prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 48),
                                      child: Icon(Icons.edit_note_rounded))),
                              validator: (value) => (value ?? '')
                                          .trim()
                                          .length >=
                                      5
                                  ? null
                                  : tr(context, 'Add at least five characters'),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: () {
                                if (!form.currentState!.validate()) return;
                                if (kind != 'Other' &&
                                    (order == null || order!.isEmpty)) {
                                  message(context,
                                      'Select the related order for this issue');
                                  return;
                                }
                                try {
                                  final id = ref
                                      .read(commerceProvider.notifier)
                                      .support(order ?? '', kind,
                                          description.text.trim());
                                  description.clear();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Row(children: [
                                    Expanded(
                                        child:
                                            AppText('Support ticket received')),
                                    Text(id,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800))
                                  ])));
                                  context.push('/support/$id');
                                } catch (error) {
                                  message(context, error);
                                }
                              },
                              icon: const Icon(Icons.add_comment_outlined),
                              label:
                                  const AppText('Create demo support ticket'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                      icon: Icons.forum_outlined,
                      title: 'Your tickets',
                      subtitle:
                          '${data.tickets.length} ${tr(context, 'support tickets')}',
                      trailing: TextButton.icon(
                          onPressed: () => context.push('/orders'),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const AppText('Orders'))),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final filter in _ticketFilters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: AppText(filter),
                            selected: ticketFilter == filter,
                            onSelected: (_) =>
                                setState(() => ticketFilter = filter),
                          ),
                        )
                    ]),
                  ),
                  const SizedBox(height: 6),
                  if (tickets.isEmpty)
                    _TicketEmptyState(
                        hasAnyTickets: data.tickets.isNotEmpty,
                        onReset: () => setState(() => ticketFilter = 'All'))
                  else
                    ...tickets.map((ticket) => _TicketListCard(
                          ticket: ticket,
                          onTap: () => context.push('/support/${ticket['id']}'),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _issueKinds = <(String, IconData)>[
  ('Missing item', Icons.remove_shopping_cart_outlined),
  ('Damaged item', Icons.broken_image_outlined),
  ('Refund request', Icons.currency_exchange_rounded),
  ('Delivery problem', Icons.delivery_dining_outlined),
  ('Other', Icons.more_horiz_rounded),
];
const _ticketFilters = ['All', 'Open', 'Under review', 'Resolved'];

class TicketDetail extends ConsumerStatefulWidget {
  const TicketDetail({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TicketDetail> createState() => _TicketState();
}

class _TicketState extends ConsumerState<TicketDetail> {
  final reply = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(commerceProvider);
    final repo = ref.read(commerceProvider.notifier);
    final ticket = data.tickets.cast<Record?>().firstWhere(
          (item) => item?['id'] == widget.id,
          orElse: () => null,
        );
    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Support ticket')),
        body: Center(
            child: _TicketEmptyState(
                hasAnyTickets: false, onReset: () => context.pop())),
      );
    }

    final status = ticket['status'] as String? ?? 'Open';
    final messages = (ticket['messages'] as List? ?? const []).cast<Record>();
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Support ticket'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _StatusPill(status: status)),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const _IconBubble(icon: Icons.support_agent_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                            child: AppText(ticket['kind'] as String? ?? 'Other',
                                style: const TextStyle(
                                    fontSize: 19,
                                    color: Brand.charcoal,
                                    fontWeight: FontWeight.w900))),
                      ]),
                      const SizedBox(height: 14),
                      _DetailLine(
                          label: 'Ticket number',
                          value: ticket['id'] as String? ?? widget.id),
                      if ((ticket['orderId'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 9),
                        _DetailLine(
                            label: 'Related order',
                            value: ticket['orderId'] as String),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                              onPressed: () =>
                                  context.push('/orders/${ticket['orderId']}'),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const AppText('View related order')),
                        ),
                      ],
                      if (ticket['kind'] == 'Refund request')
                        _DetailLine(
                            label: 'Refund status',
                            value: '${ticket['refund']} · Demo only'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Conversation',
                  subtitle: 'Updates stay on this device for this prototype.'),
              const SizedBox(height: 8),
              for (final item in messages) _MessageBubble(message: item),
              if (status != 'Resolved') ...[
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: reply,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                                labelText: tr(context, 'Add a reply'),
                                alignLabelWithHint: true),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? tr(context, 'Please enter a reply')
                                : null,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                              onPressed: () {
                                if (!form.currentState!.validate()) return;
                                repo.reply(widget.id, reply.text.trim());
                                reply.clear();
                                FocusScope.of(context).unfocus();
                              },
                              icon: const Icon(Icons.send_rounded),
                              label: const AppText('Send local reply')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                    onPressed: () => repo.reviewTicket(widget.id),
                    icon: Icon(status == 'Open'
                        ? Icons.manage_search_rounded
                        : Icons.task_alt_rounded),
                    label: AppText(status == 'Open'
                        ? 'Simulate support review'
                        : 'Simulate resolution')),
              ],
              const SizedBox(height: 14),
              const _SoftNotice(
                  icon: Icons.lock_outline_rounded,
                  text:
                      'This conversation stays on your device. No external ticket, message or refund is sent.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportHero extends StatelessWidget {
  const _SupportHero({required this.onOrders});
  final VoidCallback onOrders;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Brand.green, Color(0xFF075C43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 30)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const AppText('We’re here to help',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const AppText('Local support for Ermelo and Wesselton.',
                    style: TextStyle(color: Colors.white70, height: 1.3)),
                const SizedBox(height: 6),
                const AppText('DEMO SUPPORT · NO LIVE AGENT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: .7,
                        fontWeight: FontWeight.w900)),
              ])),
          const SizedBox(width: 8),
          IconButton.filledTonal(
              tooltip: tr(context, 'View orders'),
              onPressed: onOrders,
              style: IconButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Brand.green),
              icon: const Icon(Icons.receipt_long_outlined)),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing});
  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: icon),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                AppText(title,
                    style: const TextStyle(
                        color: Brand.charcoal,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                AppText(subtitle,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 12, height: 1.3))
              ])),
          if (trailing != null) trailing!,
        ],
      );
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
      width: 38,
      height: 38,
      decoration:
          const BoxDecoration(color: Brand.mint, shape: BoxShape.circle),
      child: Icon(icon, color: Brand.green, size: 20));
}

class _DemoCoverageNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _SoftNotice(
      icon: Icons.location_on_outlined,
      text:
          'Demo delivery coverage: Ermelo and Wesselton. Orders, reviews and refunds here are simulated.');
}

class _SoftNotice extends StatelessWidget {
  const _SoftNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Brand.mint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Brand.green.withValues(alpha: .12))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Brand.green, size: 19),
          const SizedBox(width: 9),
          Expanded(
              child: AppText(text,
                  style: const TextStyle(
                      color: Brand.charcoal, fontSize: 12, height: 1.4)))
        ]),
      );
}

class _SelectedOrderSummary extends StatelessWidget {
  const _SelectedOrderSummary({required this.order});
  final Record order;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Brand.mint, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.receipt_outlined, color: Brand.green, size: 19),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                AppText(order['merchant'] as String? ?? 'Local order',
                    style: const TextStyle(
                        color: Brand.charcoal,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
                AppText('${order['id']} · ${tr(context, _orderStatus(order))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 11))
              ])),
          const Icon(Icons.check_circle, color: Brand.green, size: 18)
        ]),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final Color tint = switch (status) {
      'Resolved' => Brand.green,
      'Under review' => const Color(0xFF9A6500),
      _ => Brand.charcoal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: tint.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(30)),
      child: AppText(status,
          style: TextStyle(
              color: tint, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _TicketListCard extends StatelessWidget {
  const _TicketListCard({required this.ticket, required this.onTap});
  final Record ticket;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final status = ticket['status'] as String? ?? 'Open';
    final created = _timestampLabel(context, ticket['created']);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            _IconBubble(icon: _issueIcon(ticket['kind'] as String? ?? 'Other')),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  AppText(ticket['kind'] as String? ?? 'Other',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Brand.charcoal, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  AppText(
                      (ticket['orderId'] as String? ?? '').isEmpty
                          ? '${ticket['id']}'
                          : '${ticket['id']} · ${ticket['orderId']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 11)),
                  if (created.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    AppText(created,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 10))
                  ]
                ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _StatusPill(status: status),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right, color: Brand.green, size: 20)
            ])
          ]),
        ),
      ),
    );
  }
}

class _TicketEmptyState extends StatelessWidget {
  const _TicketEmptyState({required this.hasAnyTickets, required this.onReset});
  final bool hasAnyTickets;
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Brand.mint)),
        child: Column(children: [
          const _IconBubble(icon: Icons.forum_outlined),
          const SizedBox(height: 10),
          AppText(
              hasAnyTickets
                  ? 'No tickets in this status'
                  : 'No support tickets yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Brand.charcoal, fontWeight: FontWeight.w800)),
          if (hasAnyTickets)
            TextButton(
                onPressed: onReset, child: const AppText('Show all tickets'))
        ]),
      );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: AppText(label,
                style: const TextStyle(color: Colors.black54, fontSize: 12))),
        const SizedBox(width: 12),
        Flexible(
            child: AppText(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: Brand.charcoal,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)))
      ]);
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final Record message;
  @override
  Widget build(BuildContext context) {
    final fromCustomer = message['sender'] == 'You';
    final timestamp = _timestampLabel(context, message['time']);
    final bubbleColor = fromCustomer ? Brand.mint : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: fromCustomer ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width > 800 ? 560 : 310),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(17),
                  topRight: const Radius.circular(17),
                  bottomLeft: Radius.circular(fromCustomer ? 17 : 5),
                  bottomRight: Radius.circular(fromCustomer ? 5 : 17),
                ),
                border: Border.all(color: Brand.green.withValues(alpha: .12))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    fromCustomer
                        ? Icons.person_outline_rounded
                        : Icons.support_agent_rounded,
                    size: 15,
                    color: Brand.green),
                const SizedBox(width: 5),
                AppText(message['sender'] as String? ?? 'Support',
                    style: const TextStyle(
                        color: Brand.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
                if (timestamp.isNotEmpty) ...[
                  const SizedBox(width: 7),
                  AppText(timestamp,
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 10))
                ]
              ]),
              const SizedBox(height: 5),
              AppText(message['text'] as String? ?? '',
                  style: const TextStyle(color: Brand.charcoal, height: 1.4))
            ]),
          ),
        ),
      ),
    );
  }
}

IconData _issueIcon(String kind) => switch (kind) {
      'Missing item' => Icons.remove_shopping_cart_outlined,
      'Damaged item' => Icons.broken_image_outlined,
      'Refund request' => Icons.currency_exchange_rounded,
      'Delivery problem' => Icons.delivery_dining_outlined,
      _ => Icons.support_agent_rounded,
    };

String _timestampLabel(BuildContext context, dynamic raw) {
  if (raw is! String) return '';
  final time = DateTime.tryParse(raw)?.toLocal();
  if (time == null) return '';
  final date = MaterialLocalizations.of(context).formatShortDate(time);
  final hour = MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(time));
  return '$date · $hour';
}

String _orderStatus(Record order) {
  final steps = stepsFor(order);
  final step = order['step'] is int ? order['step'] as int : 0;
  return steps[step.clamp(0, steps.length - 1)];
}
