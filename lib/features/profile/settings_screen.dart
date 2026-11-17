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
    return Scaffold(
        appBar: AppBar(title: const AppText('Settings')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              const Center(child: BrandLogo(size: 125)),
              const AppText('Your preferences',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _link(context, Icons.translate, 'Language',
                  languageNames[ref.watch(languageProvider)]!, '/language'),
              _link(
                  context,
                  Icons.payments_outlined,
                  'Payment preferences',
                  tr(context, ref.watch(preferredPaymentProvider)),
                  '/account/Payment%20preferences'),
              _link(context, Icons.palette_outlined, 'Appearance',
                  'Light · Gijima Mfana', '/account/Appearance'),
              const SizedBox(height: 18),
              const AppText('In-app notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const AppText('Controls new in-app updates on this device.'),
              const SizedBox(height: 8),
              Card(
                  child: Column(children: [
                SwitchListTile(
                    secondary: const Icon(Icons.local_shipping_outlined,
                        color: Brand.green),
                    title: const AppText('Order updates'),
                    value: settings.orders,
                    onChanged: (v) => controller.update(orders: v)),
                SwitchListTile(
                    secondary: const Icon(Icons.shopping_bag_outlined,
                        color: Brand.green),
                    title: const AppText('Shopping request updates'),
                    value: settings.requests,
                    onChanged: (v) => controller.update(requests: v)),
                SwitchListTile(
                    secondary:
                        const Icon(Icons.support_agent, color: Brand.green),
                    title: const AppText('Support updates'),
                    value: settings.support,
                    onChanged: (v) => controller.update(support: v)),
              ])),
              const SizedBox(height: 18),
              _link(context, Icons.privacy_tip_outlined, 'Privacy & terms',
                  'Read our information', '/account/Privacy%20%26%20terms'),
              _link(context, Icons.help_outline, 'Help centre',
                  'FAQs and mock support', '/account/Help%20centre'),
            ]));
  }

  Widget _link(BuildContext context, IconData icon, String title,
          String subtitle, String route) =>
      Card(
          child: ListTile(
              leading: Icon(icon, color: Brand.green),
              title: AppText(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: AppText(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(route)));
}
