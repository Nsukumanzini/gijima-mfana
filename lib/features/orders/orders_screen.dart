import '../../app/localization/strings.dart';
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
  String statusFilter = 'All';
  String typeFilter = 'All types';
  String sortOrder = 'Newest';

  bool _done(Record order) =>
      order['step'] == stepsFor(order).length - 1 && order['cancelled'] != true;

  String _status(Record order) {
    if (order['cancelled'] == true) return 'Cancelled';
    if (_done(order)) return 'Completed';
    return 'Active';
  }

  Future<void> _refresh() async {
    ref.invalidate(commerceProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(tr(context, 'Orders refreshed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(commerceProvider).orders;
    final counts = <String, int>{
      'All': allOrders.length,
      'Active': allOrders.where((o) => _status(o) == 'Active').length,
      'Completed': allOrders.where((o) => _status(o) == 'Completed').length,
      'Cancelled': allOrders.where((o) => _status(o) == 'Cancelled').length,
    };
    final orders = allOrders.where((o) {
      return (statusFilter == 'All' || _status(o) == statusFilter) &&
          (typeFilter == 'All types' || o['type'] == typeFilter);
    }).toList();
    orders.sort((a, b) {
      if (sortOrder == 'Highest total') {
        return (b['total'] as int).compareTo(a['total'] as int);
      }
      final aDate = DateTime.tryParse(a['created'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['created'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return sortOrder == 'Oldest'
          ? aDate.compareTo(bDate)
          : bDate.compareTo(aDate);
    });

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
        children: [
          Row(children: [
            Expanded(child: heading('Your orders')),
            IconButton.filledTonal(
                tooltip: tr(context, 'Refresh orders'),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh)),
          ]),
          const AppText(
              'Shop orders, personal shopping and collection deliveries.'),
          const SizedBox(height: 16),
          _OrderSummaryCard(
              total: allOrders.length,
              active: counts['Active']!,
              completed: counts['Completed']!),
          const SizedBox(height: 18),
          const AppText('Order status',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final status in ['All', 'Active', 'Completed', 'Cancelled'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: AppText('${tr(context, status)}  ${counts[status]}'),
                    selected: statusFilter == status,
                    onSelected: (_) => setState(() => statusFilter = status),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _orderDropdown(context,
                    label: 'Type',
                    value: typeFilter,
                    values: const [
                      'All types',
                      'Shop',
                      'Personal shopping',
                      'Collect & deliver'
                    ],
                    onChanged: (value) =>
                        setState(() => typeFilter = value ?? 'All types'))),
            const SizedBox(width: 10),
            Expanded(
                child: _orderDropdown(context,
                    label: 'Sort by',
                    value: sortOrder,
                    values: const ['Newest', 'Oldest', 'Highest total'],
                    onChanged: (value) =>
                        setState(() => sortOrder = value ?? 'Newest'))),
          ]),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, .025), end: Offset.zero)
                        .animate(animation),
                    child: child)),
            child: orders.isEmpty
                ? _OrdersEmptyState(
                    key: ValueKey('$statusFilter-$typeFilter-empty'),
                    hasOrders: allOrders.isNotEmpty,
                    onClear: () => setState(() {
                          statusFilter = 'All';
                          typeFilter = 'All types';
                        }))
                : Column(
                    key: ValueKey('$statusFilter-$typeFilter-$sortOrder'),
                    children: [
                      for (var i = 0; i < orders.length; i++)
                        _OrderCard(
                            order: orders[i],
                            index: i,
                            status: _status(orders[i]),
                            onTap: () =>
                                context.push('/orders/${orders[i]['id']}'))
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

Widget _orderDropdown(BuildContext context,
        {required String label,
        required String value,
        required List<String> values,
        required ValueChanged<String?> onChanged}) =>
    DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: tr(context, label)),
      items: values
          .map((item) => DropdownMenuItem(
              value: item,
              child: AppText(tr(context, item),
                  maxLines: 1, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard(
      {required this.total, required this.active, required this.completed});
  final int total, active, completed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Brand.mint, Color(0xFFF2F8F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Expanded(
              child: _SummaryValue(
                  label: 'Total orders',
                  value: total,
                  icon: Icons.receipt_long)),
          _SummaryValue(
              label: 'Active', value: active, icon: Icons.local_shipping),
          const SizedBox(width: 16),
          _SummaryValue(
              label: 'Completed', value: completed, icon: Icons.check_circle),
        ]),
      );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue(
      {required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Brand.green, size: 19),
          const SizedBox(height: 6),
          Text('$value',
              style: const TextStyle(
                  color: Brand.charcoal,
                  fontSize: 21,
                  height: 1,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          AppText(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Brand.charcoal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState(
      {super.key, required this.hasOrders, required this.onClear});
  final bool hasOrders;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Brand.mint)),
        child: Column(children: [
          const CircleAvatar(
              radius: 30,
              backgroundColor: Brand.mint,
              child: Icon(Icons.receipt_long_outlined,
                  color: Brand.green, size: 30)),
          const SizedBox(height: 12),
          AppText(hasOrders ? 'No orders match these filters' : 'No orders yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: Brand.charcoal)),
          const SizedBox(height: 6),
          AppText(
              hasOrders
                  ? 'Try another status or order type.'
                  : 'Shop local or request a personal shop and delivery.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          if (hasOrders)
            OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const AppText('Clear filters'))
          else
            Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const AppText('Browse shops')),
                  OutlinedButton.icon(
                      onPressed: () => context.push('/request/new/personal'),
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const AppText('Make a request')),
                ])
        ]),
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(
      {required this.order,
      required this.index,
      required this.status,
      required this.onTap});
  final Record order;
  final int index;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = order['type'] as String? ?? 'Shop';
    final steps = stepsFor(order);
    final step = (order['step'] as int).clamp(0, steps.length - 1);
    final date =
        DateTime.tryParse(order['created'] as String? ?? '')?.toLocal();
    final dateText = date == null
        ? ''
        : '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    final typeIcon = type == 'Personal shopping'
        ? Icons.shopping_bag_outlined
        : type == 'Collect & deliver'
            ? Icons.swap_horiz_rounded
            : Icons.restaurant_outlined;
    final badgeColor = status == 'Active'
        ? Brand.green
        : status == 'Completed'
            ? const Color(0xFF24734F)
            : Colors.blueGrey;
    return TweenAnimationBuilder<double>(
      key: ValueKey('${order['id']}-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + (index.clamp(0, 5) * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)), child: child)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 11),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: status == 'Active' ? Brand.mint : Colors.black12)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                    radius: 24,
                    backgroundColor: Brand.mint,
                    child: Icon(typeIcon, color: Brand.green, size: 23)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      AppText(order['merchant'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Brand.charcoal,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      AppText('${tr(context, type)} · ${order['id']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ])),
                const SizedBox(width: 8),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(20)),
                    child: AppText(status,
                        style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.schedule_outlined,
                    size: 15, color: Colors.black54),
                const SizedBox(width: 5),
                Expanded(
                    child: AppText(dateText,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12))),
                AppText(rand(order['total'] as int),
                    style: const TextStyle(
                        color: Brand.charcoal,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                    order['payment'] == 'Successful'
                        ? Icons.verified_outlined
                        : Icons.pending_outlined,
                    size: 15,
                    color: order['payment'] == 'Successful'
                        ? Brand.green
                        : Colors.deepOrange),
                const SizedBox(width: 5),
                AppText(
                    '${tr(context, 'Payment')}: ${tr(context, order['payment'] as String)}',
                    style: const TextStyle(fontSize: 12)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Brand.green),
              ]),
              if (status == 'Active') ...[
                const SizedBox(height: 10),
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        minHeight: 5,
                        value: step / (steps.length - 1),
                        backgroundColor: Brand.mint,
                        color: Brand.green,
                        semanticsLabel: tr(context, 'Order progress'))),
                const SizedBox(height: 5),
                AppText(tr(context, steps[step]),
                    style: const TextStyle(
                        color: Brand.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
        ),
      ),
    );
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
          appBar: AppBar(title: const AppText('Order')),
          body:
              const Center(child: AppText('Order not found on this device.')));
    }
    final steps = stepsFor(o),
        step = (o['step'] as int).clamp(0, stepsFor(o).length - 1);
    final paid = o['payment'] == 'Successful',
        cancelled = o['cancelled'] == true;
    final created = DateTime.tryParse(o['created'] as String? ?? '')?.toLocal();
    final stepProgress = step / (steps.length - 1);
    final address = Map<String, dynamic>.from(o['address'] as Map);
    return Scaffold(
        appBar: AppBar(title: AppText(id)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
            color: Brand.mint,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.shopping_bag_outlined,
                              color: Brand.green)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: AppText(o['merchant'] as String,
                              style: const TextStyle(
                                  color: Brand.charcoal,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900))),
                      _StatusBadge(
                          status: cancelled
                              ? 'Cancelled'
                              : step == steps.length - 1
                                  ? 'Completed'
                                  : 'Active'),
                    ]),
                    const SizedBox(height: 10),
                    AppText('${tr(context, o['type'] as String)} · $id',
                        style: const TextStyle(color: Brand.charcoal)),
                    if (created != null)
                      AppText(
                          '${MaterialLocalizations.of(context).formatMediumDate(created)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(created))}',
                          style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 14),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            minHeight: 6,
                            value: cancelled ? 0 : stepProgress,
                            backgroundColor: Colors.white,
                            color: Brand.green,
                            semanticsLabel: tr(context, 'Order progress'))),
                    const SizedBox(height: 7),
                    AppText(cancelled ? 'Cancelled' : steps[step],
                        style: const TextStyle(
                            color: Brand.green, fontWeight: FontWeight.w800)),
                  ]),
            ),
          ),
          _orderSection(
              context, 'Delivery details', Icons.location_on_outlined, [
            if (o['scheduledFor'] != null)
              AppText(
                  '${tr(context, 'Scheduled delivery')}: ${MaterialLocalizations.of(context).formatFullDate(DateTime.parse(o['scheduledFor'] as String).toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(DateTime.parse(o['scheduledFor'] as String).toLocal()))}')
            else
              const AppText('Delivery: As soon as possible'),
            const SizedBox(height: 8),
            AppText(addressText(address)),
            if (o['collection'] != null) ...[
              const Divider(height: 22),
              AppText('${tr(context, 'Collection')}: ${o['collection']}'),
              AppText('${tr(context, 'Reference')}: ${o['reference']}'),
              AppText('${tr(context, 'Recipient')}: ${o['recipient']}'),
              AppText(
                  '${tr(context, 'Collection time')}: ${o['collectionTime']}'),
            ],
            if ((o['note'] as String? ?? '').isNotEmpty) ...[
              const Divider(height: 22),
              AppText('${tr(context, 'Instructions')}: ${o['note']}'),
            ],
          ]),
          _orderSection(context, 'Items', Icons.shopping_basket_outlined, [
            ...(o['items'] as List).map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  const Icon(Icons.circle, color: Brand.green, size: 8),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        AppText('${item['quantity']} × ${item['name']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        if ((item['note'] as String? ?? '').isNotEmpty)
                          AppText(item['note'] as String,
                              style: const TextStyle(color: Colors.black54)),
                      ])),
                  AppText(
                      rand((item['price'] as int) *
                          (o['type'] == 'Personal shopping'
                              ? 1
                              : item['quantity'] as int)),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              );
            }),
          ]),
          _orderSection(context, 'Payment summary', Icons.payments_outlined, [
            moneyRow('Items', o['subtotal'] as int),
            moneyRow('Delivery', o['delivery'] as int),
            moneyRow('Service fee', o['service'] as int),
            moneyRow('Discount', -(o['discount'] as int)),
            moneyRow('Total', o['total'] as int),
            AppText(
                '${tr(context, o['method'] as String)} · ${tr(context, o['payment'] as String)} (${tr(context, 'simulated')})'),
            if (o['refund'] == 'Approved')
              AppText(
                  '${tr(context, 'Simulated refund approved')}: ${rand(o['total'] as int)}'),
            if (!paid && !cancelled)
              FilledButton(
                  onPressed: () async {
                    final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (_) => const PaymentDialog());
                    if (result == null) return;
                    repo.retryPayment(id, result['outcome']!,
                        method: result['method']);
                    if (result['outcome'] == 'Successful') {
                      final basket = ref.read(basketProvider);
                      final items = o['items'] as List;
                      if (basket.lines.length == items.length &&
                          items.every((i) =>
                              basket.lines[i['name']] == i['quantity'])) {
                        ref.read(basketProvider.notifier).clear();
                      }
                    }
                  },
                  child: const AppText('Resolve / retry demo payment')),
            if (o['type'] == 'Shop')
              OutlinedButton.icon(
                  onPressed: () => _reorder(context, ref, o),
                  icon: const Icon(Icons.replay),
                  label: const AppText('Add these items to basket again')),
          ]),
          _orderSection(context, 'Delivery tracking', Icons.route_outlined, [
            const AppText(
                'Illustrative local route · no GPS or mapping service'),
            const SizedBox(height: 12),
            _RouteMap(progress: cancelled ? 0 : stepProgress),
            const SizedBox(height: 12),
            AppText(cancelled
                ? 'Delivery cancelled'
                : o['scheduledFor'] != null &&
                        DateTime.parse(o['scheduledFor'] as String)
                            .isAfter(DateTime.now()) &&
                        step < 2
                    ? 'Scheduled delivery; updates are simulated.'
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
                  label: const AppText('Contact courier (demo)')),
            for (var i = 0; i < steps.length; i++)
              ListTile(
                  minLeadingWidth: 28,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      i <= step && !cancelled
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          i <= step && !cancelled ? Brand.green : Colors.grey),
                  title: AppText(steps[i])),
            if (paid && !cancelled && step < steps.length - 1)
              FilledButton(
                  onPressed: () => repo.advanceOrder(id),
                  child: AppText(step == steps.length - 2
                      ? 'Confirm delivered (demo)'
                      : 'Simulate next delivery update')),
          ]),
          if (!cancelled && step < 2)
            TextButton(
                onPressed: () async {
                  final yes = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                              title: const AppText('Cancel this demo order?'),
                              content: const AppText(
                                  'The order will remain in cancelled history. For a paid order, use support to request a simulated refund.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(d, false),
                                    child: const AppText('Keep order')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(d, true),
                                    child: const AppText('Cancel order'))
                              ]));
                  if (yes == true) repo.cancelOrder(id);
                },
                child: const AppText('Cancel order')),
          OutlinedButton.icon(
              onPressed: () => context.push('/support?order=$id'),
              icon: const Icon(Icons.support_agent),
              label: const AppText('Report an issue / request a refund')),
          if (o['requestId'] != null)
            TextButton(
                onPressed: () => context.push('/requests/${o['requestId']}'),
                child: const AppText('View original request'))
        ]));
  }
}

Widget _orderSection(BuildContext context, String title, IconData icon,
        List<Widget> children) =>
    Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: Brand.green, size: 21),
            const SizedBox(width: 9),
            Expanded(
                child: AppText(title,
                    style: const TextStyle(
                        color: Brand.charcoal,
                        fontSize: 17,
                        fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = status == 'Active' ? Brand.green : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(18)),
      child: AppText(status,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

Future<void> _reorder(BuildContext context, WidgetRef ref, Record order) async {
  final items = order['items'] as List;
  final available = <({ShopProduct product, int quantity, String note})>[];
  for (final raw in items) {
    final match = products
        .where((p) => p.name == raw['name'] && p.store == order['merchant'])
        .toList();
    if (match.isNotEmpty &&
        raw['quantity'] is int &&
        (raw['quantity'] as int) > 0) {
      available.add((
        product: match.first,
        quantity: (raw['quantity'] as int).clamp(1, 99),
        note: raw['note'] as String? ?? ''
      ));
    }
  }
  if (available.isEmpty) {
    if (context.mounted) {
      message(context, 'These items are no longer in the demo catalogue.');
    }
    return;
  }
  if (available.length != items.length) {
    if (context.mounted) {
      message(
          context, 'Some items are no longer available in the demo catalogue.');
    }
  }
  final basket = ref.read(basketProvider.notifier);
  if (ref.read(basketProvider).merchant != null &&
      ref.read(basketProvider).merchant != order['merchant']) {
    final replace = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
                title: const AppText('Start a new basket?'),
                content: AppText(
                    'Your basket has items from ${ref.read(basketProvider).merchant}. Replace them with items from ${order['merchant']}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const AppText('Keep basket')),
                  FilledButton(
                      onPressed: () => Navigator.pop(d, true),
                      child: const AppText('Replace basket'))
                ]));
    if (replace != true || !context.mounted) return;
    basket.clear();
  }
  for (final item in available) {
    basket.addQuantity(item.product, item.quantity, instructions: item.note);
  }
  if (context.mounted) {
    message(context,
        'Items added at current demo prices. Review your basket before checkout.');
    context.go('/');
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
                    left: 15,
                    bottom: 15,
                    child: AppText('Collection · Ermelo')),
                const Positioned(
                    right: 15, top: 15, child: AppText('Your address')),
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
