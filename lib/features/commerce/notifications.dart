import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/repositories/commerce.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commerce = ref.watch(commerceProvider);
    final notes = commerce.notifications;
    final unreadCount = notes.where((note) => note['read'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const AppText('Notifications'),
          if (unreadCount > 0) ...[
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Brand.mint, borderRadius: BorderRadius.circular(20)),
              child: Text('$unreadCount',
                  style: const TextStyle(
                      color: Brand.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ]),
        actions: [
          IconButton(
            tooltip: tr(context, 'Refresh updates'),
            onPressed: () => _refresh(context, ref),
            icon: const Icon(Icons.refresh),
          ),
          if (unreadCount > 0)
            TextButton(
                onPressed: () {
                  ref.read(commerceProvider.notifier).readAll();
                  _toast(context, 'All updates marked as read');
                },
                child: const AppText('Mark all read')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: notes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * .68,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                              color: Brand.mint,
                              borderRadius: BorderRadius.circular(28)),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Brand.green,
                                  size: 42),
                            ),
                            const SizedBox(height: 18),
                            const AppText('You’re all caught up',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Brand.charcoal,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            const AppText(
                                'No updates yet. Order and request updates appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                                onPressed: () => context.push('/order-history'),
                                icon: const Icon(Icons.receipt_long_outlined),
                                label: const AppText('View orders')),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _NotificationCard(
                  note: notes[index],
                  index: index,
                  onTap: () {
                    final note = notes[index];
                    if (note['read'] != true) {
                      ref
                          .read(commerceProvider.notifier)
                          .readNotification(note['id'] as String);
                      _toast(context, 'Notification marked as read');
                    }
                    final route = note['route'] as String?;
                    context.push(route != null && route.startsWith('/')
                        ? route
                        : '/order-history');
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    ref.invalidate(commerceProvider);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (context.mounted) _toast(context, 'Updates refreshed');
  }

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: AppText(text)));
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard(
      {required this.note, required this.index, required this.onTap});

  final Map<String, dynamic> note;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = note['read'] != true;
    final color = _notificationColor(note['route'] as String? ?? '');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + (index % 8) * 35),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)), child: child),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
            color: unread ? Brand.mint : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: unread
                    ? Brand.green.withValues(alpha: .32)
                    : Colors.transparent,
                width: unread ? 1 : 0)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  backgroundColor: unread ? Colors.white : Brand.canvas,
                  child: Icon(
                      unread
                          ? _notificationIcon(note['route'] as String? ?? '')
                          : Icons.mark_email_read_outlined,
                      color: unread ? color : Brand.charcoal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                            _localizedNotificationText(context,
                                note['text'] as String? ?? 'App update'),
                            style: TextStyle(
                                color: Brand.charcoal,
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w500)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.schedule_outlined,
                              size: 14,
                              color: unread ? Brand.green : Colors.black45),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(_relativeTime(
                                  context, note['time'] as String? ?? ''))),
                        ]),
                      ]),
                ),
                if (unread) ...[
                  const SizedBox(width: 8),
                  Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                          color: Brand.green, shape: BoxShape.circle)),
                ] else
                  const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.chevron_right, color: Colors.black45)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _notificationIcon(String route) {
  if (route.startsWith('/orders')) return Icons.receipt_long_outlined;
  if (route.startsWith('/requests')) return Icons.shopping_bag_outlined;
  if (route.startsWith('/support')) return Icons.support_agent_outlined;
  if (route.startsWith('/deals')) return Icons.local_offer_outlined;
  return Icons.notifications_active_outlined;
}

Color _notificationColor(String route) {
  if (route.startsWith('/deals')) return const Color(0xffbe7c00);
  if (route.startsWith('/support')) return const Color(0xff5365a9);
  return Brand.green;
}

String _relativeTime(BuildContext context, String raw) {
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) return raw;
  final age = DateTime.now().difference(date);
  if (age.isNegative || age.inMinutes < 1) return tr(context, 'Just now');

  final language = Localizations.localeOf(context).languageCode;
  if (age.inMinutes < 60) {
    final count = age.inMinutes;
    if (language == 'af') return '$count min gelede';
    if (language == 'zu') return 'Emizuzwini engu-$count edlule';
    return '$count ${count == 1 ? 'minute' : 'minutes'} ago';
  }
  if (age.inHours < 24) {
    final count = age.inHours;
    if (language == 'af') return '$count ${count == 1 ? 'uur' : 'ure'} gelede';
    if (language == 'zu') return 'Emahoreni angu-$count edlule';
    return '$count ${count == 1 ? 'hour' : 'hours'} ago';
  }
  if (age.inDays < 7) {
    final count = age.inDays;
    if (language == 'af') return '$count ${count == 1 ? 'dag' : 'dae'} gelede';
    if (language == 'zu') return 'Ezinsukwini ezingu-$count ezedlule';
    return '$count ${count == 1 ? 'day' : 'days'} ago';
  }
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String _localizedNotificationText(BuildContext context, String raw) {
  final orderPayment = RegExp(r'^Order (.+) · Payment (.+)$').firstMatch(raw);
  if (orderPayment != null) {
    return '${tr(context, 'Order')} ${orderPayment.group(1)} · '
        '${tr(context, 'Payment')} ${tr(context, orderPayment.group(2)!)}';
  }

  final payment = RegExp(r'^Payment (.+) · (.+)$').firstMatch(raw);
  if (payment != null) {
    return '${tr(context, 'Payment')} ${tr(context, payment.group(1)!)} · '
        '${payment.group(2)}';
  }

  const cancelled = 'Order cancelled · ';
  const paidNote = '. Any paid demo amount can be reviewed through support.';
  if (raw.startsWith(cancelled) && raw.endsWith(paidNote)) {
    final id = raw.substring(cancelled.length, raw.length - paidNote.length);
    return '${tr(context, 'Order cancelled')} · $id. '
        '${tr(context, 'Any paid demo amount can be reviewed through support.')}';
  }

  final separator = raw.lastIndexOf(' · ');
  if (separator > 0) {
    final prefix = raw.substring(0, separator);
    final suffix = raw.substring(separator + 3);
    if (prefix.startsWith('Request payment ')) {
      final outcome = prefix.substring('Request payment '.length);
      return '${tr(context, 'Request payment')} ${tr(context, outcome)} · $suffix';
    }
    if (prefix == 'Payment confirmed · Courier allocation pending') {
      return '${tr(context, 'Payment confirmed')} · '
          '${tr(context, 'Courier allocation pending')} · $suffix';
    }
    if (prefix == 'Support resolved' || prefix == 'Support under review') {
      return '${tr(context, prefix)} · $suffix';
    }
    return '${tr(context, prefix)} · $suffix';
  }
  return tr(context, raw);
}
