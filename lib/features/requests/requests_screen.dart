import 'dart:ui' as ui;
import '../../app/localization/strings.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/repositories/commerce.dart';
import '../commerce/common.dart';
import '../../data/repositories/local_store.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});
  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  String filter = 'All';

  String _group(Map<String, dynamic> request) {
    final status = request['status'];
    if (status == 'Quotation received') return 'Action needed';
    if (status == 'Delivered' || status == 'Quote rejected') return 'Complete';
    return 'In progress';
  }

  Future<void> _refresh() async {
    ref.invalidate(commerceProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(tr(context, 'Requests refreshed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRequests = ref.watch(commerceProvider).requests;
    final counts = <String, int>{
      'All': allRequests.length,
      'In progress': allRequests
          .where((request) => _group(request) == 'In progress')
          .length,
      'Action needed': allRequests
          .where((request) => _group(request) == 'Action needed')
          .length,
      'Complete':
          allRequests.where((request) => _group(request) == 'Complete').length,
    };
    final requests = allRequests
        .where((request) => filter == 'All' || _group(request) == filter)
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['created'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
              children: [
                Row(children: [
                  const Expanded(
                      child: AppText('Requests',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Brand.charcoal))),
                  IconButton.filledTonal(
                      tooltip: tr(context, 'Refresh requests'),
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, color: Brand.green)),
                ]),
                const AppText(
                    'Tell us what you need. Review all fees before accepting a quote.'),
                const SizedBox(height: 16),
                _RequestOverview(
                    total: allRequests.length,
                    active: counts['In progress']!,
                    actionNeeded: counts['Action needed']!),
                const SizedBox(height: 18),
                const AppText('Start a request',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Brand.charcoal)),
                const SizedBox(height: 9),
                _RequestStartCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Personal shopping',
                    description:
                        'Ask us to find an item that is not in the catalogue.',
                    action: 'Start shopping request',
                    onTap: () => context.push('/request/new/shopping')),
                _RequestStartCard(
                    icon: Icons.delivery_dining_outlined,
                    title: 'Collect & deliver',
                    description:
                        'Already arranged an order? Get a local collection quote.',
                    action: 'Get collection quote',
                    onTap: () => context.push('/request/new/collection')),
                const SizedBox(height: 14),
                Row(children: [
                  const Expanded(
                      child: AppText('Your requests',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Brand.charcoal))),
                  if (allRequests.isNotEmpty)
                    Text('${requests.length} ${tr(context, 'shown')}',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                ]),
                if (allRequests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final status in [
                        'All',
                        'In progress',
                        'Action needed',
                        'Complete'
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: AppText(
                                  '${tr(context, status)} · ${counts[status]}'),
                              selected: filter == status,
                              onSelected: (_) =>
                                  setState(() => filter = status)),
                        ),
                    ]),
                  ),
                ],
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                          position: Tween<Offset>(
                                  begin: const Offset(0, .02), end: Offset.zero)
                              .animate(animation),
                          child: child)),
                  child: requests.isEmpty
                      ? _RequestsEmpty(
                          key: ValueKey('$filter-empty-${allRequests.isEmpty}'),
                          hasRequests: allRequests.isNotEmpty,
                          onClear: () => setState(() => filter = 'All'))
                      : Column(
                          key: ValueKey(filter),
                          children: [
                            for (var i = 0; i < requests.length; i++)
                              _RequestCard(
                                  request: requests[i],
                                  index: i,
                                  group: _group(requests[i]),
                                  onTap: () => context
                                      .push('/requests/${requests[i]['id']}')),
                          ],
                        ),
                ),
              ]),
        ),
      ),
    );
  }
}

class _RequestOverview extends StatelessWidget {
  const _RequestOverview(
      {required this.total, required this.active, required this.actionNeeded});
  final int total, active, actionNeeded;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Brand.mint, Color(0xFFF3F8F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Expanded(
              child: _RequestMetric(
                  label: 'Total requests', count: total, icon: Icons.inbox)),
          _RequestMetric(
              label: 'In progress', count: active, icon: Icons.sync_rounded),
          const SizedBox(width: 16),
          _RequestMetric(
              label: 'Action needed',
              count: actionNeeded,
              icon: Icons.notifications_active_outlined),
        ]),
      );
}

class _RequestMetric extends StatelessWidget {
  const _RequestMetric(
      {required this.label, required this.count, required this.icon});
  final String label;
  final int count;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Brand.green, size: 19),
          const SizedBox(height: 6),
          Text('$count',
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

class _RequestStartCard extends StatelessWidget {
  const _RequestStartCard(
      {required this.icon,
      required this.title,
      required this.description,
      required this.action,
      required this.onTap});
  final IconData icon;
  final String title, description, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: Brand.mint, shape: BoxShape.circle),
                  child: Icon(icon, color: Brand.green, size: 24)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    AppText(title,
                        style: const TextStyle(
                            color: Brand.charcoal,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    AppText(description,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 7),
                    AppText(action,
                        style: const TextStyle(
                            color: Brand.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ])),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Brand.green),
            ]),
          ),
        ),
      );
}

class _RequestsEmpty extends StatelessWidget {
  const _RequestsEmpty(
      {super.key, required this.hasRequests, required this.onClear});
  final bool hasRequests;
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
              radius: 29,
              backgroundColor: Brand.mint,
              child: Icon(Icons.inbox_outlined, color: Brand.green, size: 29)),
          const SizedBox(height: 12),
          AppText(
              hasRequests ? 'No requests match this filter' : 'No requests yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Brand.charcoal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          AppText(
              hasRequests
                  ? 'Choose another status to see your requests.'
                  : 'Start a personal shopping or collection request above.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          if (hasRequests) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const AppText('Show all requests')),
          ],
        ]),
      );
}

List<String> _requestSteps(bool personal) => [
      'Submitted',
      'Under review',
      'Quotation received',
      'Quote accepted',
      'Payment confirmed',
      'Courier assigned',
      if (personal) 'Item purchased',
      'Delivered'
    ];

int _requestProgressIndex(Map<String, dynamic> request) {
  final steps = _requestSteps(request['type'] == 'Personal shopping');
  final index = steps.indexOf(request['status'] as String? ?? 'Submitted');
  return index < 0 ? 2 : index;
}

class _RequestCard extends StatelessWidget {
  const _RequestCard(
      {required this.request,
      required this.index,
      required this.group,
      required this.onTap});
  final Map<String, dynamic> request;
  final int index;
  final String group;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final type = request['type'] as String? ?? 'Personal shopping';
    final steps = _requestSteps(type == 'Personal shopping');
    final progress = _requestProgressIndex(request);
    final date =
        DateTime.tryParse(request['created'] as String? ?? '')?.toLocal();
    final dateLabel = date == null
        ? ''
        : '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    final color = group == 'Action needed'
        ? const Color(0xFF9A5B00)
        : group == 'Complete'
            ? const Color(0xFF42685A)
            : Brand.green;
    final typeIcon = type == 'Collect & deliver'
        ? Icons.delivery_dining_outlined
        : Icons.shopping_bag_outlined;
    return TweenAnimationBuilder<double>(
      key: ValueKey('${request['id']}-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + index.clamp(0, 5) * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)), child: child)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                              color: Brand.mint, shape: BoxShape.circle),
                          child: Icon(typeIcon, color: Brand.green)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            AppText(request['name'] as String? ?? 'Request',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Brand.charcoal,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            AppText('${tr(context, type)} · ${request['id']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                          ])),
                      const SizedBox(width: 8),
                      _RequestStatusBadge(
                          status: request['status'] as String? ?? group,
                          color: color),
                    ]),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      Row(children: [
                        const Icon(Icons.schedule_outlined,
                            size: 15, color: Colors.black54),
                        const SizedBox(width: 5),
                        AppText(dateLabel,
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                      ]),
                    ],
                    const SizedBox(height: 11),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: progress / (steps.length - 1),
                            minHeight: 5,
                            backgroundColor: Brand.mint,
                            color: color,
                            semanticsLabel: tr(context, 'Request progress'))),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                          child: AppText(
                              tr(context, request['status'] as String),
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12))),
                      const Icon(Icons.chevron_right, color: Brand.green),
                    ]),
                  ])),
        ),
      ),
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status, required this.color});
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18)),
        child: AppText(status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w900)),
      );
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
  Uint8List? referencePhoto;
  String urgency = 'Today';
  DateTime when = DateTime.now().add(const Duration(hours: 1));
  @override
  void initState() {
    super.initState();
    address = ref.read(commerceProvider).defaultAddress?['id'] as String?;
    fields['quantity']!.text = '1';
    fields['collectionCity']!.text = 'Ermelo';
    for (final controller in fields.values) {
      controller.addListener(() {
        if (mounted) setState(() {});
      });
    }
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

  int get _completedRequiredFields {
    final requiredKeys = widget.collection
        ? [
            'name',
            'description',
            'quantity',
            'business',
            'collection',
            'collectionCity',
            'reference',
            'recipient'
          ]
        : ['name', 'description', 'quantity', 'business', 'budget'];
    var completed =
        requiredKeys.where((key) => fields[key]!.text.trim().isNotEmpty).length;
    if (positive(fields['quantity']!.text) != null) completed--;
    if (!widget.collection && budget(fields['budget']!.text) != null) {
      completed--;
    }
    if (widget.collection &&
        !['ermelo', 'wesselton']
            .contains(fields['collectionCity']!.text.trim().toLowerCase())) {
      completed--;
    }
    if (address != null) completed++;
    return completed.clamp(0, requiredKeys.length + 1);
  }

  int get _requiredFieldCount => (widget.collection ? 8 : 5) + 1;

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final completed = _completedRequiredFields;
    final dateLabel =
        MaterialLocalizations.of(context).formatMediumDate(when.toLocal());
    final timeLabel = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(when.toLocal()));
    return Scaffold(
        appBar: AppBar(
            title: AppText(
                collection ? 'Collect & deliver' : 'Personal shopping')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Form(
              key: form,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    _FormProgressCard(
                        completed: completed,
                        total: _requiredFieldCount,
                        progress: completed / _requiredFieldCount),
                    const SizedBox(height: 12),
                    Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E5),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Row(children: [
                          Icon(Icons.info_outline, color: Color(0xFF8C5700)),
                          SizedBox(width: 10),
                          Expanded(
                              child: AppText(
                                  'Use fictional demo details. No courier will be dispatched.',
                                  style: TextStyle(color: Color(0xFF61420D)))),
                        ])),
                    const SizedBox(height: 14),
                    _RequestFormSection(
                        icon: Icons.inventory_2_outlined,
                        title: 'Request details',
                        subtitle: collection
                            ? 'Tell us what needs to be collected and delivered.'
                            : 'Describe the item and where you would like us to look.',
                        children: [
                          input(
                              fields['name']!,
                              collection
                                  ? 'Item / parcel name'
                                  : 'Product name'),
                          input(fields['description']!,
                              'Description and requirements',
                              lines: 3),
                          input(fields['quantity']!, 'Quantity',
                              keyboard: TextInputType.number,
                              validate: positive),
                          input(
                              fields['business']!,
                              collection
                                  ? 'Business or sender name'
                                  : 'Preferred business / shopping location'),
                          if (!collection)
                            input(fields['budget']!, 'Maximum item budget (R)',
                                keyboard: const TextInputType.numberWithOptions(
                                    decimal: true),
                                validate: budget),
                          if (!collection)
                            DropdownButtonFormField<String>(
                                initialValue: urgency,
                                decoration: InputDecoration(
                                    labelText: tr(context, 'Urgency')),
                                items: ['Today', 'Tomorrow', 'Whenever works']
                                    .map((v) => DropdownMenuItem(
                                        value: v, child: AppText(v)))
                                    .toList(),
                                onChanged: (v) => setState(() => urgency = v!)),
                        ]),
                    if (!collection) ...[
                      const SizedBox(height: 12),
                      _RequestFormSection(
                          icon: Icons.add_photo_alternate_outlined,
                          title: 'Reference photo',
                          subtitle:
                              'A photo can help identify the item you need.',
                          children: [
                            if (referencePhoto != null)
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(referencePhoto!,
                                      height: 180,
                                      fit: BoxFit.contain,
                                      semanticLabel: tr(context,
                                          'Selected reference photo'))),
                            Wrap(spacing: 8, runSpacing: 4, children: [
                              OutlinedButton.icon(
                                  onPressed: _pickPhoto,
                                  icon: const Icon(
                                      Icons.add_photo_alternate_outlined),
                                  label: AppText(referencePhoto == null
                                      ? 'Add reference photo (optional)'
                                      : 'Change reference photo')),
                              if (referencePhoto != null)
                                TextButton(
                                    onPressed: () =>
                                        setState(() => referencePhoto = null),
                                    child: const AppText('Remove photo'))
                            ]),
                            const AppText(
                                'JPEG, PNG or WebP, up to 1 MB. Photos stay on this device.',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                          ]),
                    ],
                    if (collection) ...[
                      const SizedBox(height: 12),
                      _RequestFormSection(
                          icon: Icons.store_mall_directory_outlined,
                          title: 'Collection details',
                          subtitle:
                              'Add the pickup location and handover details.',
                          children: [
                            input(fields['collection']!,
                                'Collection street and building'),
                            input(fields['collectionCity']!, 'Collection town',
                                validate: (v) => ['ermelo', 'wesselton']
                                        .contains(
                                            (v ?? '').trim().toLowerCase())
                                    ? null
                                    : 'Collections cover Ermelo and Wesselton'),
                            input(fields['reference']!,
                                'Order reference / collection code'),
                            input(fields['recipient']!,
                                'Recipient name / demo contact'),
                            Card(
                                color: Brand.mint,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                    minTileHeight: 64,
                                    leading: const Icon(
                                        Icons.event_available_outlined,
                                        color: Brand.green),
                                    title: const AppText(
                                        'Preferred collection time',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    subtitle:
                                        AppText('$dateLabel · $timeLabel'),
                                    trailing: const Icon(
                                        Icons.edit_calendar_outlined,
                                        color: Brand.green),
                                    onTap: _time)),
                          ]),
                    ],
                    const SizedBox(height: 12),
                    _RequestFormSection(
                        icon: Icons.location_on_outlined,
                        title: 'Delivery details',
                        subtitle:
                            'Choose a covered Ermelo or Wesselton address.',
                        children: [
                          addressPicker(context, ref, address,
                              (v) => setState(() => address = v)),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                  onPressed: () => context.push('/addresses'),
                                  icon: const Icon(
                                      Icons.edit_location_alt_outlined),
                                  label: const AppText('Manage addresses'))),
                          input(fields['instructions']!,
                              'Additional / handling instructions (optional)',
                              lines: 2, validate: (_) => null),
                        ]),
                  ]),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                        top: BorderSide(
                            color: Brand.charcoal.withValues(alpha: .1)))),
                child: FilledButton.icon(
                    onPressed: _submitRequest,
                    icon: const Icon(Icons.send_rounded),
                    label: AppText(collection
                        ? 'Get delivery quotation'
                        : 'Submit shopping request')),
              ),
            ),
          ),
        ));
  }

  void _submitRequest() {
    if (!form.currentState!.validate()) return;
    try {
      final collection = widget.collection;
      final budgetText = fields['budget']!.text.trim();
      final parts = budgetText.split('.');
      final cents = collection
          ? 0
          : int.parse(parts[0]) * 100 +
              (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
      final id = ref.read(commerceProvider.notifier).submitRequest({
        'type': collection ? 'Collect & deliver' : 'Personal shopping',
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
        'addressId': address,
        if (referencePhoto != null)
          'photoBase64': base64Encode(referencePhoto!),
      });
      context.pushReplacement('/requests/$id');
    } catch (e) {
      message(context, e);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final selected = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
          withData: true,
          allowMultiple: false);
      if (!mounted || selected == null) return;
      final file = selected.files.single, bytes = file.bytes;
      if (file.size > 1024 * 1024 ||
          bytes == null ||
          bytes.isEmpty ||
          bytes.length > 1024 * 1024) {
        message(
            context, 'Choose a JPEG, PNG or WebP image no larger than 1 MB.');
        return;
      }
      final jpeg = bytes.length > 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff;
      final png = bytes.length > 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47;
      final webp = bytes.length > 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
      if (!jpeg && !png && !webp) {
        message(context, 'Please choose a valid JPEG, PNG or WebP image.');
        return;
      }
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        frame.image.dispose();
        codec.dispose();
      } catch (_) {
        if (mounted) {
          message(context, 'Please choose a valid JPEG, PNG or WebP image.');
        }
        return;
      }
      if (!mounted) return;
      setState(() => referencePhoto = bytes);
    } catch (_) {
      if (mounted) {
        message(context, 'Could not open the photo picker. Please try again.');
      }
    }
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

class _FormProgressCard extends StatelessWidget {
  const _FormProgressCard(
      {required this.completed, required this.total, required this.progress});
  final int completed, total;
  final double progress;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.checklist_rounded, color: Brand.green),
              const SizedBox(width: 9),
              Expanded(
                  child: AppText('Request details',
                      style: const TextStyle(
                          color: Brand.charcoal, fontWeight: FontWeight.w900))),
              Text('$completed / $total',
                  style: const TextStyle(
                      color: Brand.green, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: Brand.green,
                    backgroundColor: Brand.mint,
                    semanticsLabel: tr(context, 'Required details complete'))),
            const SizedBox(height: 6),
            const AppText('Complete the required details to send your request.',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ),
      );
}

class _RequestFormSection extends StatelessWidget {
  const _RequestFormSection(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.children});
  final IconData icon;
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: Brand.green),
              const SizedBox(width: 9),
              Expanded(
                  child: AppText(title,
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontSize: 17,
                          fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 4),
            AppText(subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      );
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
          appBar: AppBar(title: const AppText('Request')),
          body: const Center(
              child: AppText('Request not found on this device.')));
    }
    final status = r['status'] as String;
    final personal = r['type'] == 'Personal shopping';
    final steps = _requestSteps(personal);
    final currentStep = _requestProgressIndex(r);
    final created = DateTime.tryParse(r['created'] as String? ?? '')?.toLocal();
    final quoteTotal = (r['itemPrice'] as int) +
        (r['delivery'] as int) +
        (r['service'] as int);
    return Scaffold(
        appBar: AppBar(title: AppText(id)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(padding: const EdgeInsets.all(18), children: [
              if (ref.watch(saveErrorProvider) != null)
                Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AppText(ref.watch(saveErrorProvider)!))),
              Card(
                color: Brand.mint,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Icon(
                                  personal
                                      ? Icons.shopping_bag_outlined
                                      : Icons.delivery_dining_outlined,
                                  color: Brand.green)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: AppText(r['name'] as String,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: Brand.charcoal,
                                      fontWeight: FontWeight.w900))),
                          _RequestStatusBadge(
                              status: status, color: _statusColor(status)),
                        ]),
                        const SizedBox(height: 8),
                        AppText('${tr(context, r['type'] as String)} · $id',
                            style: const TextStyle(color: Brand.charcoal)),
                        if (created != null)
                          AppText(
                              '${tr(context, 'Submitted')}: ${MaterialLocalizations.of(context).formatMediumDate(created)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(created))}',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                      ]),
                ),
              ),
              _RequestDetailSection(
                  title: 'Request details',
                  icon: Icons.description_outlined,
                  children: [
                    _RequestDetailRow(
                        label: 'Quantity', value: '${r['quantity']}'),
                    _RequestDetailRow(
                        label: 'Description',
                        value: r['description'] as String? ?? ''),
                    _RequestDetailRow(
                        label: 'Business',
                        value: r['business'] as String? ?? ''),
                    if (personal)
                      _RequestDetailRow(
                          label: 'Item budget',
                          value:
                              '${rand(r['budget'] as int)} · ${tr(context, r['urgency'] as String)}'),
                    _RequestDetailRow(
                        label: 'Delivery address',
                        value: addressText(
                            Map<String, dynamic>.from(r['address'] as Map))),
                    if ((r['instructions'] as String? ?? '').isNotEmpty)
                      _RequestDetailRow(
                          label: 'Instructions',
                          value: r['instructions'] as String),
                  ]),
              if (!personal)
                _RequestDetailSection(
                    title: 'Collection details',
                    icon: Icons.store_mall_directory_outlined,
                    children: [
                      _RequestDetailRow(
                          label: 'Collection',
                          value: r['collection'] as String? ?? ''),
                      _RequestDetailRow(
                          label: 'Reference',
                          value: r['reference'] as String? ?? ''),
                      _RequestDetailRow(
                          label: 'Recipient',
                          value: r['recipient'] as String? ?? ''),
                      _RequestDetailRow(
                          label: 'Collection time',
                          value: _localizedDateTime(
                              context, r['collectionTime'] as String? ?? '')),
                    ]),
              if (r['photoBase64'] is String)
                _RequestDetailSection(
                    title: 'Reference photo',
                    icon: Icons.photo_outlined,
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                              base64Decode(r['photoBase64'] as String),
                              height: 220,
                              fit: BoxFit.contain,
                              semanticLabel:
                                  tr(context, 'Saved reference photo'),
                              errorBuilder: (c, e, stack) => const AppText(
                                  'Reference photo could not be displayed.'))),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                              onPressed: () => repo.removeRequestPhoto(id),
                              icon: const Icon(Icons.delete_outline),
                              label: const AppText('Remove saved photo'))),
                    ]),
              _RequestDetailSection(
                  title: 'Request progress',
                  icon: Icons.route_outlined,
                  children: [
                    _RequestTimeline(
                        steps: steps, currentStep: currentStep, status: status),
                    if (status == 'Submitted' || status == 'Under review')
                      FilledButton.icon(
                          onPressed: () => repo.review(id),
                          icon: const Icon(Icons.play_circle_outline),
                          label: AppText(status == 'Submitted'
                              ? 'Simulate request review'
                              : 'Simulate quotation received')),
                  ]),
              if (status == 'Quotation received' ||
                  status == 'Quote accepted' ||
                  r['orderId'] != null)
                _RequestQuoteSection(
                    personal: personal,
                    request: r,
                    total: quoteTotal,
                    status: status,
                    onAccept: () => repo.quoteDecision(id, true),
                    onReject: () => repo.quoteDecision(id, false),
                    onPayment: () async {
                      final result = await showDialog<Map<String, String>>(
                          context: context,
                          builder: (_) => PaymentDialog(
                              allowSchedule: true,
                              initialScheduled: r['scheduledFor'] == null
                                  ? null
                                  : DateTime.tryParse(
                                      r['scheduledFor'] as String)));
                      if (result == null) return;
                      try {
                        final oid = repo.payRequest(
                            id, result['method']!, result['outcome']!,
                            scheduledFor: result['scheduledFor'] == null
                                ? null
                                : DateTime.parse(result['scheduledFor']!));
                        if (!context.mounted) return;
                        if (oid != null) {
                          context.push('/orders/$oid');
                        } else {
                          message(context,
                              'Payment ${result['outcome']}. You can retry from this quotation.');
                        }
                      } catch (e) {
                        if (context.mounted) message(context, e);
                      }
                    }),
              if (status == 'Quote rejected')
                Card(
                    color: const Color(0xFFFFF5E5),
                    child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: AppText(
                            'You rejected this quotation. No payment was taken. Submit a new request to change requirements.'))),
              if (r['orderId'] != null)
                Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/orders/${r['orderId']}'),
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const AppText('Track delivery order'))),
            ]),
          ),
        ));
  }
}

Color _statusColor(String status) => status == 'Quotation received'
    ? const Color(0xFF925900)
    : status == 'Delivered'
        ? const Color(0xFF32664E)
        : status == 'Quote rejected'
            ? const Color(0xFF9D3F35)
            : Brand.green;

String _localizedDateTime(BuildContext context, String raw) {
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) return raw;
  return '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
}

class _RequestDetailSection extends StatelessWidget {
  const _RequestDetailSection(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(top: 14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      );
}

class _RequestDetailRow extends StatelessWidget {
  const _RequestDetailRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppText(label,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          AppText(value,
              style: const TextStyle(
                  color: Brand.charcoal, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _RequestTimeline extends StatelessWidget {
  const _RequestTimeline(
      {required this.steps, required this.currentStep, required this.status});
  final List<String> steps;
  final int currentStep;
  final String status;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Semantics(
              label:
                  '${tr(context, steps[i])}, ${tr(context, i < currentStep ? 'Complete' : i == currentStep ? 'Current step' : 'Upcoming')}',
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 30,
                  child: Column(children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                          color: i < currentStep
                              ? Brand.green
                              : i == currentStep
                                  ? _statusColor(status).withValues(alpha: .15)
                                  : Colors.black12,
                          shape: BoxShape.circle),
                      child: Icon(
                          i < currentStep
                              ? Icons.check
                              : i == currentStep && status == 'Quote rejected'
                                  ? Icons.close
                                  : i == currentStep
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                          size: i < currentStep ? 16 : 12,
                          color: i < currentStep
                              ? Colors.white
                              : i == currentStep
                                  ? _statusColor(status)
                                  : Colors.black38),
                    ),
                    if (i < steps.length - 1)
                      Container(
                          width: 2,
                          height: 26,
                          color:
                              i < currentStep ? Brand.green : Colors.black12),
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 19),
                  child: Row(children: [
                    Expanded(
                        child: AppText(steps[i],
                            style: TextStyle(
                                color: i <= currentStep
                                    ? Brand.charcoal
                                    : Colors.black54,
                                fontWeight: i == currentStep
                                    ? FontWeight.w900
                                    : FontWeight.w600))),
                    if (i == currentStep)
                      AppText(
                          status == 'Quote rejected'
                              ? 'Closed'
                              : 'Current step',
                          style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                  ]),
                )),
              ]),
            ),
        ],
      );
}

class _RequestQuoteSection extends StatelessWidget {
  const _RequestQuoteSection(
      {required this.personal,
      required this.request,
      required this.total,
      required this.status,
      required this.onAccept,
      required this.onReject,
      required this.onPayment});
  final bool personal;
  final Record request;
  final int total;
  final String status;
  final VoidCallback onAccept, onReject;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) => _RequestDetailSection(
        title: 'Your quotation',
        icon: Icons.receipt_long_outlined,
        children: [
          if (personal)
            const AppText(
                'Quoted item price covers the full requested quantity.',
                style: TextStyle(color: Colors.black54)),
          moneyRow('Item price', request['itemPrice'] as int),
          moneyRow('Delivery fee', request['delivery'] as int),
          moneyRow('Service fee', request['service'] as int),
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: Brand.mint, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Expanded(
                  child: AppText('Total',
                      style: TextStyle(
                          color: Brand.charcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.w900))),
              AppText(rand(total),
                  style: const TextStyle(
                      color: Brand.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ]),
          ),
          const AppText(
              'Illustrative local quote. No real merchant was contacted.',
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          if (status == 'Quotation received') ...[
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const AppText('Accept quotation'))),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const AppText('Reject quotation'))),
          ],
          if (status == 'Quote accepted') ...[
            const SizedBox(height: 10),
            AppText(
                '${tr(context, 'Payment')}: ${tr(context, request['payment'] as String)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: onPayment,
                    icon: const Icon(Icons.payments_outlined),
                    label: const AppText('Continue to simulated payment'))),
          ],
        ],
      );
}
