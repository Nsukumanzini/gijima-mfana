import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter/services.dart';
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
      child: GlassCard(
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
        appBar: AppBar(title: AppText(id), actions: [
          IconButton(
              tooltip: tr(context, 'Copy order number'),
              onPressed: () => _copyOrderNumber(context, id),
              icon: const Icon(Icons.copy_rounded)),
          const SizedBox(width: 8)
        ]),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
                    children: [
                      GlassCard(
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
                                AppText(
                                    '${tr(context, o['type'] as String)} · $id',
                                    style:
                                        const TextStyle(color: Brand.charcoal)),
                                if (created != null)
                                  AppText(
                                      '${MaterialLocalizations.of(context).formatMediumDate(created)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(created))}',
                                      style: const TextStyle(
                                          color: Colors.black54)),
                                const SizedBox(height: 14),
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                        minHeight: 6,
                                        value: cancelled ? 0 : stepProgress,
                                        backgroundColor: Colors.white,
                                        color: Brand.green,
                                        semanticsLabel:
                                            tr(context, 'Order progress'))),
                                const SizedBox(height: 7),
                                AppText(cancelled ? 'Cancelled' : steps[step],
                                    style: const TextStyle(
                                        color: Brand.green,
                                        fontWeight: FontWeight.w800)),
                              ]),
                        ),
                      ),
                      _orderSection(context, 'Delivery details',
                          Icons.location_on_outlined, [
                        if (o['scheduledFor'] != null)
                          AppText(
                              '${tr(context, 'Scheduled delivery')}: ${MaterialLocalizations.of(context).formatFullDate(DateTime.parse(o['scheduledFor'] as String).toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(DateTime.parse(o['scheduledFor'] as String).toLocal()))}')
                        else
                          const AppText('Delivery: As soon as possible'),
                        const SizedBox(height: 8),
                        AppText(addressText(address)),
                        if (o['collection'] != null) ...[
                          const Divider(height: 22),
                          AppText(
                              '${tr(context, 'Collection')}: ${o['collection']}'),
                          AppText(
                              '${tr(context, 'Reference')}: ${o['reference']}'),
                          AppText(
                              '${tr(context, 'Recipient')}: ${o['recipient']}'),
                          AppText(
                              '${tr(context, 'Collection time')}: ${o['collectionTime']}'),
                        ],
                        if ((o['note'] as String? ?? '').isNotEmpty) ...[
                          const Divider(height: 22),
                          AppText(
                              '${tr(context, 'Instructions')}: ${o['note']}'),
                        ],
                      ]),
                      _orderSection(
                          context, 'Items', Icons.shopping_basket_outlined, [
                        ...(o['items'] as List).map((raw) {
                          final item = Map<String, dynamic>.from(raw as Map);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(children: [
                              const Icon(Icons.circle,
                                  color: Brand.green, size: 8),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    AppText(
                                        '${item['quantity']} × ${item['name']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    if ((item['note'] as String? ?? '')
                                        .isNotEmpty)
                                      AppText(item['note'] as String,
                                          style: const TextStyle(
                                              color: Colors.black54)),
                                  ])),
                              AppText(
                                  rand((item['price'] as int) *
                                      (o['type'] == 'Personal shopping'
                                          ? 1
                                          : item['quantity'] as int)),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                            ]),
                          );
                        }),
                      ]),
                      _orderSection(
                          context, 'Payment summary', Icons.payments_outlined, [
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
                                final result =
                                    await showDialog<Map<String, String>>(
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
                                          basket.lines[i['name']] ==
                                          i['quantity'])) {
                                    ref.read(basketProvider.notifier).clear();
                                  }
                                }
                              },
                              child: const AppText(
                                  'Resolve / retry demo payment')),
                        if (o['type'] == 'Shop')
                          OutlinedButton.icon(
                              onPressed: () => _reorder(context, ref, o),
                              icon: const Icon(Icons.replay),
                              label: const AppText(
                                  'Add these items to basket again')),
                      ]),
                      _DeliveryTracking(
                          order: o,
                          steps: steps,
                          step: step,
                          progress: stepProgress,
                          paid: paid,
                          cancelled: cancelled,
                          onAdvance: () => _simulateTrackingUpdate(
                              context, repo, id, steps, step),
                          onContact: () => _contactDemoCourier(context)),
                      if (!cancelled && step < 2)
                        TextButton(
                            onPressed: () async {
                              final yes = await showDialog<bool>(
                                  context: context,
                                  builder: (d) => AlertDialog(
                                          title: const AppText(
                                              'Cancel this demo order?'),
                                          content: const AppText(
                                              'The order will remain in cancelled history. For a paid order, use support to request a simulated refund.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(d, false),
                                                child: const AppText(
                                                    'Keep order')),
                                            FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(d, true),
                                                child: const AppText(
                                                    'Cancel order'))
                                          ]));
                              if (yes == true) repo.cancelOrder(id);
                            },
                            child: const AppText('Cancel order')),
                      OutlinedButton.icon(
                          onPressed: () => context.push('/support?order=$id'),
                          icon: const Icon(Icons.support_agent),
                          label: const AppText(
                              'Report an issue / request a refund')),
                      if (o['requestId'] != null)
                        TextButton(
                            onPressed: () =>
                                context.push('/requests/${o['requestId']}'),
                            child: const AppText('View original request'))
                    ]))));
  }
}

Widget _orderSection(BuildContext context, String title, IconData icon,
        List<Widget> children) =>
    GlassCard(
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
    final color = switch (status) {
      'Active' || 'Completed' => Brand.green,
      'Cancelled' => const Color(0xFFB3261E),
      'Payment pending' => const Color(0xFF9A6500),
      _ => Colors.blueGrey,
    };
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

class _DeliveryTracking extends StatelessWidget {
  const _DeliveryTracking(
      {required this.order,
      required this.steps,
      required this.step,
      required this.progress,
      required this.paid,
      required this.cancelled,
      required this.onAdvance,
      required this.onContact});
  final Record order;
  final List<String> steps;
  final int step;
  final double progress;
  final bool paid, cancelled;
  final VoidCallback onAdvance, onContact;

  @override
  Widget build(BuildContext context) {
    final history = (order['trackingHistory'] as List? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    final assignedAt = steps.indexOf('Courier assigned');
    final courierAssigned = assignedAt >= 0 && step >= assignedAt;
    final scheduledRaw = order['scheduledFor'] as String?;
    final scheduled = DateTime.tryParse(scheduledRaw ?? '')?.toLocal();
    final isScheduled = scheduled != null &&
        scheduled.isAfter(DateTime.now()) &&
        step < (assignedAt < 0 ? 1 : assignedAt);
    final delivered = !cancelled && step >= steps.length - 1;
    final nextStep = step < steps.length - 1 ? steps[step + 1] : null;
    final address = Map<String, dynamic>.from(order['address'] as Map);
    final destination =
        (address['suburb'] as String? ?? address['city'] as String? ?? 'Ermelo')
            .trim();
    final origin = order['type'] == 'Collect & deliver'
        ? '${tr(context, 'Collection point')} · Ermelo'
        : '${order['merchant']} · Ermelo';
    final sampleKm = order['type'] == 'Collect & deliver' ? 7.2 : 4.8;
    final eta = cancelled
        ? 'Cancelled'
        : delivered
            ? _deliveredAt(context, history, steps.length)
            : !paid
                ? 'After payment'
                : isScheduled
                    ? MaterialLocalizations.of(context)
                        .formatTimeOfDay(TimeOfDay.fromDateTime(scheduled))
                    : !courierAssigned
                        ? 'After courier allocation'
                        : step >= steps.length - 2
                            ? '5–15 min'
                            : '20–35 min';
    final etaTitle = cancelled
        ? 'Delivery cancelled'
        : delivered
            ? 'Delivered'
            : isScheduled
                ? 'Scheduled arrival'
                : 'Estimated arrival';
    final trackingStatus = cancelled
        ? 'Cancelled'
        : delivered
            ? 'Completed'
            : paid
                ? 'Active'
                : 'Payment pending';
    final summary =
        '${tr(context, etaTitle)}. $eta. ${tr(context, steps[step])}';

    return _orderSection(context, 'Delivery tracking', Icons.route_outlined, [
      Semantics(
          label: tr(context, 'Accessible tracking summary'),
          value: summary,
          child: _TrackingOverview(
              status: trackingStatus,
              currentStep: cancelled ? 'Cancelled' : steps[step],
              etaTitle: etaTitle,
              eta: eta,
              distance:
                  '${sampleKm.toStringAsFixed(1)} ${tr(context, 'km · illustrative')}',
              deliveredAt: delivered && history.isNotEmpty
                  ? _eventTime(context, history,
                      step: steps.length - 1, fallback: null)
                  : null)),
      const SizedBox(height: 6),
      const AppText('ETA and route distance are illustrative estimates.',
          style: TextStyle(color: Colors.black54, fontSize: 11)),
      if (scheduled != null) ...[
        const SizedBox(height: 10),
        _ScheduledTrackingCard(date: scheduled),
      ],
      const SizedBox(height: 10),
      _RouteMap(
          progress: cancelled
              ? 0
              : delivered
                  ? 1
                  : courierAssigned
                      ? progress
                      : 0,
          origin: origin,
          destination: destination,
          showCourier: courierAssigned && !cancelled && !delivered),
      const SizedBox(height: 7),
      const AppText('Illustrative local route · no GPS or mapping service',
          style: TextStyle(color: Colors.black54, fontSize: 11)),
      if (order['type'] == 'Collect & deliver') ...[
        const SizedBox(height: 10),
        _CollectionHandoffCard(order: order),
      ],
      if (courierAssigned && !cancelled && !delivered) ...[
        const SizedBox(height: 10),
        _DemoCourierCard(onContact: onContact),
      ] else if (paid && !cancelled && !delivered) ...[
        const SizedBox(height: 10),
        _TrackingHint(
            icon: Icons.hourglass_top_rounded,
            text: 'Courier allocation follows payment and preparation.'),
      ],
      if (cancelled) ...[
        const SizedBox(height: 10),
        const _TrackingHint(
            icon: Icons.info_outline_rounded,
            text:
                'This order is cancelled. Tracking updates and courier contact are unavailable.'),
      ] else if (!paid) ...[
        const SizedBox(height: 10),
        const _TrackingHint(
            icon: Icons.payments_outlined,
            text:
                'Complete the simulated payment before courier allocation can begin.'),
      ],
      const SizedBox(height: 8),
      _TrackingTimeline(
          steps: steps,
          step: step,
          cancelled: cancelled,
          history: history,
          created: order['created'] as String?),
      if (nextStep != null && paid && !cancelled)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
              onPressed: onAdvance,
              icon: Icon(nextStep == 'Delivered'
                  ? Icons.task_alt_rounded
                  : Icons.update_rounded),
              label: AppText(nextStep == 'Delivered'
                  ? 'Confirm delivered (demo)'
                  : 'Preview next delivery update')),
        ),
      if (delivered) ...[
        const SizedBox(height: 10),
        _TrackingHint(
            icon: Icons.check_circle_outline_rounded,
            text: 'Delivered to your demo address'),
      ],
    ]);
  }
}

class _TrackingOverview extends StatelessWidget {
  const _TrackingOverview(
      {required this.status,
      required this.currentStep,
      required this.etaTitle,
      required this.eta,
      required this.distance,
      this.deliveredAt});
  final String status, currentStep, etaTitle, eta, distance;
  final String? deliveredAt;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Brand.mint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Brand.green.withValues(alpha: .12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_shipping_outlined,
                color: Brand.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: AppText(tr(context, currentStep),
                        key: ValueKey(currentStep),
                        maxLines: 2,
                        style: const TextStyle(
                            color: Brand.charcoal,
                            fontWeight: FontWeight.w900)))),
            _StatusBadge(status: status)
          ]),
          const SizedBox(height: 13),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  AppText(etaTitle,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 11)),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: AppText(eta,
                          key: ValueKey(eta),
                          style: const TextStyle(
                              color: Brand.green,
                              fontSize: 21,
                              fontWeight: FontWeight.w900))),
                  if (deliveredAt != null && deliveredAt!.isNotEmpty)
                    AppText('${tr(context, 'Delivered at')}: $deliveredAt',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 11))
                ])),
            const SizedBox(width: 12),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.straighten_rounded,
                      size: 16, color: Brand.green),
                  const SizedBox(width: 5),
                  AppText(distance,
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800))
                ]))
          ]),
        ]),
      );
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline(
      {required this.steps,
      required this.step,
      required this.cancelled,
      required this.history,
      required this.created});
  final List<String> steps;
  final int step;
  final bool cancelled;
  final List<Record> history;
  final String? created;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Delivery updates',
              style: TextStyle(
                  color: Brand.charcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          for (var i = 0; i < steps.length; i++)
            _TrackingTimelineRow(
                title: steps[i],
                current: i == step && !cancelled,
                complete: cancelled ? i <= step : i < step,
                isLast: i == steps.length - 1 && !cancelled,
                time: _eventTime(context, history,
                    step: i, fallback: i == 0 ? created : null)),
          if (cancelled)
            _TrackingTimelineRow(
                title: 'Cancelled',
                current: true,
                complete: false,
                isLast: true,
                time: _eventTime(context, history,
                    status: 'Cancelled', fallback: null)),
        ],
      );
}

class _TrackingTimelineRow extends StatelessWidget {
  const _TrackingTimelineRow(
      {required this.title,
      required this.current,
      required this.complete,
      required this.isLast,
      required this.time});
  final String title;
  final bool current, complete, isLast;
  final String? time;
  @override
  Widget build(BuildContext context) {
    final active = current || complete;
    final label = current
        ? 'Current update'
        : complete
            ? 'Completed'
            : 'Up next';
    return Semantics(
      label:
          '${tr(context, title)} · ${tr(context, label)}${time == null ? '' : ' · $time'}',
      child: SizedBox(
        height: isLast ? 58 : 68,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 30,
              child: Column(children: [
                AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: current ? 24 : 20,
                    height: current ? 24 : 20,
                    decoration: BoxDecoration(
                        color: active ? Brand.green : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: active ? Brand.green : Colors.black26,
                            width: current ? 3 : 2)),
                    child: current
                        ? const Icon(Icons.local_shipping_outlined,
                            size: 13, color: Colors.white)
                        : complete
                            ? const Icon(Icons.check,
                                size: 13, color: Colors.white)
                            : null),
                if (!isLast)
                  Container(
                      width: 2,
                      height: 42,
                      color: complete ? Brand.green : Brand.mint)
              ])),
          const SizedBox(width: 9),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AppText(title,
                      style: TextStyle(
                          color: active ? Brand.charcoal : Colors.black45,
                          fontWeight:
                              current ? FontWeight.w900 : FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(children: [
                    AppText(label,
                        style: TextStyle(
                            color: current ? Brand.green : Colors.black45,
                            fontSize: 10,
                            fontWeight: current ? FontWeight.w800 : null)),
                    if (time != null && time!.isNotEmpty) ...[
                      const SizedBox(width: 7),
                      Flexible(
                          child: Text(time!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 10)))
                    ]
                  ])
                ]),
          )),
        ]),
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap(
      {required this.progress,
      required this.origin,
      required this.destination,
      required this.showCourier});
  final double progress;
  final String origin, destination;
  final bool showCourier;
  @override
  Widget build(BuildContext context) => Semantics(
        label: tr(context, 'Illustrative route map'),
        value:
            '${tr(context, 'From')} $origin. ${tr(context, 'To')} $destination. ${showCourier ? tr(context, 'Demo courier en route') : ''}',
        child: ExcludeSemantics(
          child: Container(
              height: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: Brand.mint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Brand.green.withValues(alpha: .1))),
              child: LayoutBuilder(builder: (context, bounds) {
                final size = Size(bounds.maxWidth, 190);
                final route = _routePath(size);
                final metric = route.computeMetrics().first;
                final marker = metric
                    .getTangentForOffset(metric.length * progress.clamp(0, 1))!
                    .position;
                return Stack(children: [
                  Positioned.fill(
                      child: CustomPaint(
                          painter: _MapPainter(progress: progress))),
                  Positioned(
                      left: 10,
                      top: 10,
                      child: _MapLabel(
                          icon: Icons.storefront_outlined,
                          text: origin,
                          alignEnd: false)),
                  Positioned(
                      right: 10,
                      bottom: 10,
                      child: _MapLabel(
                          icon: Icons.location_on_outlined,
                          text: destination,
                          alignEnd: true)),
                  Positioned(
                      left: 13,
                      top: size.height * .75 - 13,
                      child:
                          const _MapPin(icon: Icons.storefront, start: true)),
                  Positioned(
                      left: size.width * .85 - 12,
                      top: size.height * .2 - 13,
                      child: const _MapPin(
                          icon: Icons.location_on_rounded, start: false)),
                  if (showCourier)
                    AnimatedPositioned(
                        duration: MediaQuery.of(context).disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 650),
                        curve: Curves.easeInOutCubic,
                        left: marker.dx - 17,
                        top: marker.dy - 17,
                        child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Brand.green, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 7,
                                      offset: Offset(0, 2))
                                ]),
                            child: const Icon(Icons.delivery_dining_rounded,
                                color: Brand.green, size: 22)))
                ]);
              })),
        ),
      );
}

class _MapLabel extends StatelessWidget {
  const _MapLabel(
      {required this.icon, required this.text, required this.alignEnd});
  final IconData icon;
  final String text;
  final bool alignEnd;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 5)
            ]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Brand.green, size: 15),
          const SizedBox(width: 5),
          Flexible(
              child: AppText(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                  style: const TextStyle(
                      color: Brand.charcoal,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)))
        ]),
      );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.start});
  final IconData icon;
  final bool start;
  @override
  Widget build(BuildContext context) => Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
            color: start ? Colors.white : Brand.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 5)
            ]),
        child: Icon(icon, size: 14, color: start ? Brand.green : Colors.white),
      );
}

class _TrackingHint extends StatelessWidget {
  const _TrackingHint({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Brand.mint, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Brand.green),
          const SizedBox(width: 8),
          Expanded(
              child: AppText(text,
                  style: const TextStyle(
                      color: Brand.charcoal, fontSize: 12, height: 1.35)))
        ]),
      );
}

class _DemoCourierCard extends StatelessWidget {
  const _DemoCourierCard({required this.onContact});
  final VoidCallback onContact;
  @override
  Widget build(BuildContext context) {
    const identity = Row(children: [
      CircleAvatar(
          backgroundColor: Brand.mint,
          child: Icon(Icons.delivery_dining, color: Brand.green)),
      SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppText('Courier',
              style: TextStyle(
                  color: Brand.charcoal, fontWeight: FontWeight.w800)),
          Text(' · Sipho Dlamini',
              style:
                  TextStyle(color: Brand.charcoal, fontWeight: FontWeight.w800))
        ]),
        SizedBox(height: 2),
        AppText('Demo bicycle · unit GM-01',
            style: TextStyle(color: Colors.black54, fontSize: 11))
      ]))
    ]);
    final contactButton = OutlinedButton.icon(
        onPressed: onContact,
        icon: const Icon(Icons.chat_outlined, size: 17),
        label: const AppText('Contact courier'));
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 440) {
            return Column(children: [
              identity,
              Align(alignment: Alignment.centerRight, child: contactButton)
            ]);
          }
          return Row(children: [
            const Expanded(child: identity),
            const SizedBox(width: 8),
            contactButton
          ]);
        }),
      ),
    );
  }
}

class _ScheduledTrackingCard extends StatelessWidget {
  const _ScheduledTrackingCard({required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    final fullDate = MaterialLocalizations.of(context).formatFullDate(date);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF5DF),
          borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        const Icon(Icons.event_available_outlined, color: Brand.green),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppText('Scheduled delivery',
              style: TextStyle(
                  color: Brand.charcoal, fontWeight: FontWeight.w900)),
          AppText('$fullDate · $time',
              style: const TextStyle(color: Brand.charcoal, fontSize: 12)),
          const AppText('Tracking updates are simulated.',
              style: TextStyle(color: Colors.black54, fontSize: 10))
        ]))
      ]),
    );
  }
}

class _CollectionHandoffCard extends StatelessWidget {
  const _CollectionHandoffCard({required this.order});
  final Record order;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Brand.mint)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppText('Collection hand-off',
              style: TextStyle(
                  color: Brand.charcoal, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _TrackingDetailRow(label: 'Collection', value: order['collection']),
          _TrackingDetailRow(label: 'Recipient', value: order['recipient']),
          _TrackingDetailRow(label: 'Reference', value: order['reference']),
          _TrackingDetailRow(
              label: 'Collection time', value: order['collectionTime']),
        ]),
      );
}

class _TrackingDetailRow extends StatelessWidget {
  const _TrackingDetailRow({required this.label, required this.value});
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 105,
              child: AppText(label,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700))),
          Expanded(
              child: AppText(_trackingDetailValue(context, label, value),
                  style: const TextStyle(color: Brand.charcoal, fontSize: 11)))
        ]),
      );
}

String _trackingDetailValue(BuildContext context, String label, dynamic value) {
  if (label == 'Collection time' && value is String) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date != null) {
      final day = MaterialLocalizations.of(context).formatShortDate(date);
      final time = MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(date));
      return '$day · $time';
    }
  }
  return value?.toString() ?? '—';
}

class _MapPainter extends CustomPainter {
  const _MapPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final street = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    for (double x = 35; x < size.width; x += 65) {
      canvas.drawLine(Offset(x, 0), Offset(x - 30, size.height), street);
    }
    for (double y = 35; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 15), street);
    }
    final path = _routePath(size);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
        path,
        Paint()
          ..color = Brand.charcoal.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        metric.extractPath(0, metric.length * progress.clamp(0, 1)),
        Paint()
          ..color = Brand.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

Path _routePath(Size size) => Path()
  ..moveTo(26, size.height * .75)
  ..cubicTo(size.width * .28, size.height * .56, size.width * .47,
      size.height * .83, size.width * .85, size.height * .2);

String? _eventTime(BuildContext context, List<Record> history,
    {int? step, String? status, String? fallback}) {
  final event = history.where((entry) =>
      status != null ? entry['status'] == status : entry['step'] == step);
  final value = event.isEmpty ? fallback : event.last['time'] as String?;
  final parsed = DateTime.tryParse(value ?? '')?.toLocal();
  if (parsed == null) return null;
  final date = MaterialLocalizations.of(context).formatShortDate(parsed);
  final time = MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(parsed));
  return '$date · $time';
}

String _deliveredAt(BuildContext context, List<Record> history, int count) {
  return _eventTime(context, history, step: count - 1, fallback: null) ??
      tr(context, 'Delivery complete');
}

Future<void> _copyOrderNumber(BuildContext context, String id) async {
  await Clipboard.setData(ClipboardData(text: id));
  if (context.mounted) {
    message(context, 'Order number copied.');
  }
}

Future<void> _simulateTrackingUpdate(BuildContext context,
    CommerceController repo, String id, List<String> steps, int step) async {
  final next = steps[step + 1];
  final delivered = next == 'Delivered';
  final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
            icon: Icon(delivered
                ? Icons.task_alt_rounded
                : Icons.local_shipping_outlined),
            title: AppText(delivered
                ? 'Confirm demo delivery?'
                : 'Preview next tracking update'),
            content: AppText(delivered
                ? 'This will mark the order as delivered to your demo address. No courier is dispatched.'
                : '${tr(context, 'Next simulated update')}: ${tr(context, next)}. No live courier or location is involved.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const AppText('Keep order')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const AppText('Continue'))
            ],
          ));
  if (confirm == true && context.mounted) {
    repo.advanceOrder(id);
    message(context, 'Tracking update saved.');
  }
}

Future<void> _contactDemoCourier(BuildContext context) async {
  final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.chat_outlined, color: Brand.green),
            title: const AppText('Contact courier (demo)'),
            content: const AppText(
                'This prototype does not send calls or messages. You can record a simulated contact request on this device.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const AppText('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const AppText('Record demo request'))
            ],
          ));
  if (confirm == true && context.mounted) {
    message(
        context, 'Demo contact request recorded. No call or message was sent.');
  }
}
