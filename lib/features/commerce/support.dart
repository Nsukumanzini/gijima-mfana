import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter/services.dart';
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
                    ...visibleFaqs.map((faq) => GlassCard(
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
                  GlassCard(
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
  final conversationScroll = ScrollController();
  @override
  void dispose() {
    reply.dispose();
    conversationScroll.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = reply.text.trim();
    if (text.isEmpty) return;
    ref.read(commerceProvider.notifier).reply(widget.id, text);
    reply.clear();
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (conversationScroll.hasClients) {
        conversationScroll.animateTo(
          conversationScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: AppText('Reply saved on this device.'),
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _advanceTicket(String status) async {
    final next = status == 'Open' ? 'Under review' : 'Resolved';
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
            next == 'Resolved' ? Icons.task_alt_rounded : Icons.manage_search),
        title: AppText(next == 'Resolved'
            ? 'Resolve this demo ticket?'
            : 'Start a demo review?'),
        content: AppText(next == 'Resolved'
            ? 'This will mark the issue resolved and add a final update to the conversation.'
            : 'This will move the ticket to Under review and add an update to the conversation.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const AppText('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: AppText('Continue'))
        ],
      ),
    );
    if (shouldContinue != true || !mounted) return;
    ref.read(commerceProvider.notifier).reviewTicket(widget.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: AppText(next == 'Resolved'
            ? 'Ticket marked resolved.'
            : 'Ticket moved to review.'),
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _reopenTicket() async {
    ref.read(commerceProvider.notifier).reopenTicket(widget.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: AppText('Ticket reopened.'),
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(commerceProvider);
    final ticket = data.tickets.cast<Record?>().firstWhere(
          (item) => item?['id'] == widget.id,
          orElse: () => null,
        );
    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Support ticket')),
        body:
            Center(child: _MissingTicket(onBack: () => context.go('/support'))),
      );
    }

    final status = ticket['status'] as String? ?? 'Open';
    final messages = (ticket['messages'] as List? ?? const []).cast<Record>();
    final originalIndex =
        messages.indexWhere((item) => item['sender'] == 'You');
    final originalReport = originalIndex < 0 ? null : messages[originalIndex];
    final threadMessages = [
      for (var i = 0; i < messages.length; i++)
        if (i != originalIndex) messages[i]
    ];
    final relatedOrder = data.orders.cast<Record?>().firstWhere(
          (item) => item?['id'] == ticket['orderId'],
          orElse: () => null,
        );
    final latestUpdate =
        messages.isEmpty ? '' : _timestampLabel(context, messages.last['time']);
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Support ticket'),
        actions: [
          IconButton(
              tooltip: tr(context, 'Copy ticket number'),
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: ticket['id'] as String? ?? widget.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const AppText('Ticket number copied.'),
                      behavior: SnackBarBehavior.floating));
                }
              },
              icon: const Icon(Icons.copy_rounded)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _StatusPill(status: status)),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(children: [
            Expanded(
              child: ListView(
                controller: conversationScroll,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                children: [
                  _TicketSummary(ticket: ticket, latestUpdate: latestUpdate),
                  const SizedBox(height: 12),
                  _TicketProgress(status: status, ticket: ticket),
                  if (ticket['kind'] == 'Refund request') ...[
                    const SizedBox(height: 12),
                    _RefundSummary(ticket: ticket, order: relatedOrder),
                  ],
                  if (originalReport != null) ...[
                    const SizedBox(height: 12),
                    _OriginalReport(message: originalReport),
                  ],
                  if (relatedOrder != null) ...[
                    const SizedBox(height: 12),
                    _RelatedOrderCard(
                      order: relatedOrder,
                      onTap: () =>
                          context.push('/orders/${relatedOrder['id']}'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SectionTitle(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Conversation',
                      subtitle:
                          'Updates stay on this device for this prototype.'),
                  const SizedBox(height: 8),
                  if (threadMessages.isEmpty)
                    const _SoftNotice(
                        icon: Icons.chat_bubble_outline_rounded,
                        text: 'Your conversation updates will appear here.'),
                  ..._messagesWithDateDividers(context, threadMessages),
                  const SizedBox(height: 12),
                  if (status != 'Resolved')
                    FilledButton.icon(
                        onPressed: () => _advanceTicket(status),
                        icon: Icon(status == 'Open'
                            ? Icons.manage_search_rounded
                            : Icons.task_alt_rounded),
                        label: AppText(status == 'Open'
                            ? 'Simulate support review'
                            : 'Simulate resolution'))
                  else
                    OutlinedButton.icon(
                        onPressed: _reopenTicket,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const AppText('Reopen demo ticket')),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                        onPressed: () => context.push(
                            '/support?order=${Uri.encodeComponent(ticket['orderId'] as String? ?? '')}'),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const AppText('Report another issue')),
                  ),
                  const SizedBox(height: 8),
                  const _SoftNotice(
                      icon: Icons.lock_outline_rounded,
                      text:
                          'This conversation stays on your device. No external ticket, message or refund is sent.'),
                ],
              ),
            ),
            if (status != 'Resolved')
              _ReplyComposer(
                  controller: reply,
                  onChanged: () => setState(() {}),
                  onSend: _sendReply),
          ]),
        ),
      ),
    );
  }
}

class _TicketSummary extends StatelessWidget {
  const _TicketSummary({required this.ticket, required this.latestUpdate});
  final Record ticket;
  final String latestUpdate;
  @override
  Widget build(BuildContext context) => GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _IconBubble(
                  icon: _issueIcon(ticket['kind'] as String? ?? 'Other')),
              const SizedBox(width: 12),
              Expanded(
                  child: AppText(ticket['kind'] as String? ?? 'Other',
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontSize: 18,
                          fontWeight: FontWeight.w900))),
              _StatusPill(status: ticket['status'] as String? ?? 'Open'),
            ]),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(
                  child: _DetailLine(
                      label: 'Ticket number',
                      value: ticket['id'] as String? ?? '')),
              if (latestUpdate.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                    child:
                        _DetailLine(label: 'Last updated', value: latestUpdate))
              ]
            ]),
          ]),
        ),
      );
}

class _TicketProgress extends StatelessWidget {
  const _TicketProgress({required this.status, required this.ticket});
  final String status;
  final Record ticket;
  @override
  Widget build(BuildContext context) {
    final messages = (ticket['messages'] as List? ?? const []).cast<Record>();
    final reviewMessage = messages.where((message) {
      final text = (message['text'] as String? ?? '').toLowerCase();
      return message['sender'] == 'Support' && text.contains('reviewing');
    }).lastOrNull;
    final resolvedMessage = messages.where((message) {
      final text = (message['text'] as String? ?? '').toLowerCase();
      return message['sender'] == 'Support' && text.contains('resolved');
    }).lastOrNull;
    final stages = ['Open', 'Under review', 'Resolved'];
    final current = stages.indexOf(status).clamp(0, stages.length - 1);
    final timeByStage = [
      ticket['created'],
      reviewMessage?['time'],
      resolvedMessage?['time']
    ];
    final a11y = '${tr(context, 'Ticket progress')}: ${tr(context, status)}';
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.timeline_rounded, color: Brand.green, size: 19),
            const SizedBox(width: 8),
            Expanded(
                child: AppText('Ticket progress',
                    style: const TextStyle(
                        color: Brand.charcoal, fontWeight: FontWeight.w900))),
            AppText(tr(context, status),
                style: const TextStyle(
                    color: Brand.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          Semantics(
            label: a11y,
            child: Row(children: [
              for (var i = 0; i < stages.length; i++) ...[
                Expanded(
                    flex: 2,
                    child: _ProgressDot(
                        complete: i < current,
                        active: i == current,
                        label: stages[i],
                        time: timeByStage[i])),
                if (i < stages.length - 1)
                  Expanded(
                      child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 34),
                          color: i < current ? Brand.green : Brand.mint)),
              ]
            ]),
          )
        ]),
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot(
      {required this.complete,
      required this.active,
      required this.label,
      required this.time});
  final bool complete, active;
  final String label;
  final dynamic time;
  @override
  Widget build(BuildContext context) {
    final date = _dateLabel(context, time);
    final color = complete || active ? Brand.green : Colors.black26;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: active ? 27 : 23,
        height: active ? 27 : 23,
        decoration: BoxDecoration(
            color: complete || active ? Brand.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: active ? 3 : 2)),
        child: Icon(complete ? Icons.check : _stageIcon(label),
            size: 13,
            color: complete || active ? Colors.white : Colors.black38),
      ),
      const SizedBox(height: 6),
      AppText(label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
              color: active || complete ? Brand.charcoal : Colors.black45,
              fontSize: 10,
              height: 1.15,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700)),
      if (date.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black45, fontSize: 9))
      ]
    ]);
  }
}

class _OriginalReport extends StatelessWidget {
  const _OriginalReport({required this.message});
  final Record message;
  @override
  Widget build(BuildContext context) {
    final date = _timestampLabel(context, message['time']);
    return GlassCard(
      color: Brand.mint,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.description_outlined,
                color: Brand.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: AppText('Issue summary',
                    style: const TextStyle(
                        color: Brand.charcoal, fontWeight: FontWeight.w900))),
            if (date.isNotEmpty)
              Text(date,
                  style: const TextStyle(color: Colors.black54, fontSize: 10))
          ]),
          const SizedBox(height: 8),
          AppText(message['text'] as String? ?? '',
              style: const TextStyle(color: Brand.charcoal, height: 1.4)),
        ]),
      ),
    );
  }
}

class _RelatedOrderCard extends StatelessWidget {
  const _RelatedOrderCard({required this.order, required this.onTap});
  final Record order;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              const _IconBubble(icon: Icons.receipt_long_outlined),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    AppText(order['merchant'] as String? ?? 'Local order',
                        style: const TextStyle(
                            color: Brand.charcoal,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    AppText(
                        '${order['id']} · ${tr(context, _orderStatus(order))}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextButton.icon(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            alignment: Alignment.centerLeft),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const AppText('View related order')),
                  ])),
              if (order['total'] is int)
                AppText(rand(order['total'] as int),
                    style: const TextStyle(
                        color: Brand.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      );
}

class _RefundSummary extends StatelessWidget {
  const _RefundSummary({required this.ticket, required this.order});
  final Record ticket;
  final Record? order;
  @override
  Widget build(BuildContext context) {
    final total = order?['total'];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Brand.mint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Brand.green.withValues(alpha: .14))),
      child: Row(children: [
        const _IconBubble(icon: Icons.currency_exchange_rounded),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppText('Refund details',
              style: TextStyle(
                  color: Brand.charcoal, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          AppText(
              '${tr(context, 'Refund status')}: ${ticket['refund'] ?? 'Not reviewed'}',
              style: const TextStyle(color: Brand.charcoal, fontSize: 12)),
          if (total is int)
            AppText('${tr(context, 'Demo refund amount')}: ${rand(total)}',
                style: const TextStyle(
                    color: Brand.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800))
        ])),
        const Icon(Icons.info_outline_rounded, color: Brand.green, size: 19),
      ]),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer(
      {required this.controller,
      required this.onChanged,
      required this.onSend});
  final TextEditingController controller;
  final VoidCallback onChanged, onSend;
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                  child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                    labelText: tr(context, 'Add a reply'),
                    hintText: tr(context, 'Write a helpful reply…'),
                    counterText: '${controller.text.length}/500',
                    contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 5)),
              )),
              const SizedBox(width: 8),
              Semantics(
                label: tr(context, 'Send local reply'),
                button: true,
                enabled: controller.text.trim().isNotEmpty,
                child: IconButton.filled(
                    tooltip: tr(context, 'Send local reply'),
                    onPressed: controller.text.trim().isEmpty ? null : onSend,
                    icon: const Icon(Icons.send_rounded)),
              )
            ]),
          ),
        ),
      );
}

class _MissingTicket extends StatelessWidget {
  const _MissingTicket({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Brand.mint)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const _IconBubble(icon: Icons.search_off_rounded),
            const SizedBox(height: 12),
            const AppText('Ticket not found.',
                style: TextStyle(
                    color: Brand.charcoal,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const AppText('This ticket may have been removed from this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            FilledButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.support_agent_rounded),
                label: const AppText('Back to support'))
          ]),
        ),
      );
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          const Expanded(child: Divider(color: Brand.mint)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700))),
          const Expanded(child: Divider(color: Brand.mint))
        ]),
      );
}

List<Widget> _messagesWithDateDividers(
    BuildContext context, List<Record> messages) {
  final children = <Widget>[];
  DateTime? lastDay;
  for (var index = 0; index < messages.length; index++) {
    final item = messages[index];
    final time = DateTime.tryParse(item['time'] as String? ?? '')?.toLocal();
    if (time != null) {
      final day = DateUtils.dateOnly(time);
      if (lastDay == null || !DateUtils.isSameDay(lastDay, day)) {
        children.add(_DateDivider(
            label: MaterialLocalizations.of(context).formatFullDate(time)));
      }
      lastDay = day;
    }
    children.add(TweenAnimationBuilder<double>(
      key: ValueKey('${item['time'] ?? 'message'}-$index'),
      tween: Tween(begin: .88, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, (1 - value) * 8), child: child)),
      child: _MessageBubble(message: item),
    ));
  }
  return children;
}

String _dateLabel(BuildContext context, dynamic value) {
  if (value is! String) return '';
  final date = DateTime.tryParse(value)?.toLocal();
  return date == null
      ? ''
      : MaterialLocalizations.of(context).formatShortDate(date);
}

IconData _stageIcon(String stage) => switch (stage) {
      'Open' => Icons.mark_email_unread_outlined,
      'Under review' => Icons.manage_search_rounded,
      _ => Icons.task_alt_rounded,
    };

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
    return GlassCard(
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
