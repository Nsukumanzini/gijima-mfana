// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/localization/strings.dart';
import '../../app/theme/app_theme.dart';
import '../../data/repositories/customer_preferences.dart';
import '../../data/repositories/local_store.dart';
import '../../shared/components/brand_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(customerSettingsProvider);
    final controller = ref.read(customerSettingsProvider.notifier);
    final language = ref.watch(languageProvider);
    final payment = ref.watch(preferredPaymentProvider);
    final enabledCount = [settings.orders, settings.requests, settings.support]
        .where((enabled) => enabled)
        .length;
    final updateSummary = enabledCount == 3
        ? 'All on'
        : enabledCount == 0
            ? 'Off'
            : 'Some on';

    return Scaffold(
      appBar: AppBar(title: const AppText('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _SettingsEntrance(index: 0, child: const _SettingsBrandHeader()),
              const SizedBox(height: 16),
              _SettingsEntrance(
                  index: 1,
                  child: _SettingsOverview(
                      language: languageNames[language]!,
                      payment: payment,
                      updates: updateSummary)),
              const SizedBox(height: 22),
              const _SettingsSectionTitle(title: 'Preferences'),
              _SettingsEntrance(
                  index: 2,
                  child: _SettingsLink(
                      icon: Icons.translate_rounded,
                      title: 'Language',
                      subtitle: languageNames[language]!,
                      route: '/language')),
              _SettingsEntrance(
                  index: 3,
                  child: _SettingsLink(
                      icon: Icons.payments_outlined,
                      title: 'Payment preferences',
                      subtitle: tr(context, payment),
                      route: '/account/Payment%20preferences')),
              _SettingsEntrance(
                  index: 4,
                  child: _SettingsLink(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Light · Gijima Mfana',
                      route: '/account/Appearance')),
              const SizedBox(height: 14),
              const _SettingsSectionTitle(title: 'Notifications'),
              Card(
                margin: EdgeInsets.zero,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 4),
                    child: Row(children: [
                      const Icon(Icons.notifications_active_outlined,
                          color: Brand.green),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const AppText('In-app notifications',
                                style: TextStyle(
                                    color: Brand.charcoal,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            const AppText(
                                'Controls new in-app updates on this device.',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                          ])),
                      _EnabledPill(status: updateSummary),
                    ]),
                  ),
                  const Divider(height: 16, indent: 16, endIndent: 16),
                  _NotificationPreference(
                      icon: Icons.local_shipping_outlined,
                      title: 'Order updates',
                      description: 'Delivery and order status changes.',
                      value: settings.orders,
                      onChanged: (v) => controller.update(orders: v)),
                  _NotificationPreference(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Shopping request updates',
                      description: 'Request reviews, quotations and progress.',
                      value: settings.requests,
                      onChanged: (v) => controller.update(requests: v)),
                  _NotificationPreference(
                      icon: Icons.support_agent_outlined,
                      title: 'Support updates',
                      description: 'Replies and changes to support tickets.',
                      value: settings.support,
                      onChanged: (v) => controller.update(support: v)),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 15),
                      child: Row(children: [
                        const Icon(Icons.phone_android_outlined,
                            size: 17, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                            child: AppText(
                                'These controls affect in-app updates on this device.',
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 12))),
                      ])),
                ]),
              ),
              const SizedBox(height: 22),
              const _SettingsSectionTitle(title: 'Help & privacy'),
              _SettingsEntrance(
                  index: 5,
                  child: _SettingsLink(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy & terms',
                      subtitle: 'Read our information',
                      route: '/account/Privacy%20%26%20terms')),
              _SettingsEntrance(
                  index: 6,
                  child: _SettingsLink(
                      icon: Icons.help_outline_rounded,
                      title: 'Help centre',
                      subtitle: 'FAQs and mock support',
                      route: '/account/Help%20centre')),
              const SizedBox(height: 12),
              const _SettingsFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBrandHeader extends StatelessWidget {
  const _SettingsBrandHeader();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Brand.mint, Color(0xFFF4F9F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Brand.green.withValues(alpha: .12))),
        child: Row(children: [
          Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const BrandLogo(size: 54)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const AppText('Gijima Mfana',
                    style: TextStyle(
                        color: Brand.charcoal,
                        fontSize: 19,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                const AppText('Your preferences',
                    style: TextStyle(
                        color: Brand.charcoal, fontWeight: FontWeight.w700)),
              ])),
        ]),
      );
}

class _SettingsOverview extends StatelessWidget {
  const _SettingsOverview(
      {required this.language, required this.payment, required this.updates});
  final String language, payment, updates;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AppText('Settings at a glance',
                style: TextStyle(
                    color: Brand.charcoal,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 11),
            Row(children: [
              Expanded(
                  child: _OverviewValue(
                      icon: Icons.translate_rounded,
                      label: 'Language',
                      value: language)),
              const _OverviewDivider(),
              Expanded(
                  child: _OverviewValue(
                      icon: Icons.payments_outlined,
                      label: 'Payment',
                      value: payment)),
              const _OverviewDivider(),
              Expanded(
                  child: _OverviewValue(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      value: updates)),
            ]),
          ]),
        ),
      );
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Brand.green),
          const SizedBox(height: 5),
          AppText(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 11)),
          const SizedBox(height: 3),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: AppText(value,
                  key: ValueKey(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Brand.charcoal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800))),
        ],
      );
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();
  @override
  Widget build(BuildContext context) => Container(
      height: 45,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 9),
      color: Brand.charcoal.withValues(alpha: .12));
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: AppText(title,
            style: const TextStyle(
                color: Brand.charcoal,
                fontSize: 17,
                fontWeight: FontWeight.w900)),
      );
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.route});
  final IconData icon;
  final String title, subtitle, route;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
            minTileHeight: 74,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            leading: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: Icon(icon, color: Brand.green)),
            title: AppText(title,
                style: const TextStyle(
                    color: Brand.charcoal, fontWeight: FontWeight.w800)),
            subtitle: AppText(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54)),
            trailing: const Icon(Icons.chevron_right, color: Brand.green),
            onTap: () => context.push(route)),
      );
}

class _EnabledPill extends StatelessWidget {
  const _EnabledPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: Brand.mint, borderRadius: BorderRadius.circular(20)),
        child: AppText(status,
            style: const TextStyle(
                color: Brand.green, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _NotificationPreference extends StatelessWidget {
  const _NotificationPreference(
      {required this.icon,
      required this.title,
      required this.description,
      required this.value,
      required this.onChanged});
  final IconData icon;
  final String title, description;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: Icon(icon, color: Brand.green),
        title: AppText(title,
            style: const TextStyle(
                color: Brand.charcoal, fontWeight: FontWeight.w800)),
        subtitle: AppText(description,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
        value: value,
        onChanged: onChanged,
      );
}

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: Brand.charcoal.withValues(alpha: .12)))),
        child: Wrap(
            spacing: 7,
            runSpacing: 5,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.local_mall_outlined,
                  color: Brand.green, size: 17),
              const AppText('Gijima Mfana',
                  style: TextStyle(
                      color: Brand.charcoal, fontWeight: FontWeight.w900)),
              AppText('Prototype · demo data only',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
      );
}

class _SettingsEntrance extends StatelessWidget {
  const _SettingsEntrance({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(index),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 240 + index * 40),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, (1 - value) * 10), child: child)),
        child: child,
      );
}
