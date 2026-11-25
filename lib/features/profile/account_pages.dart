import '../../app/localization/strings.dart';
import '../../app/theme/app_theme.dart';
import '../../data/repositories/local_store.dart';
import '../commerce/addresses.dart';
import '../commerce/notifications.dart';
import '../commerce/support.dart';
import '../commerce/storefront.dart';
import '../../data/repositories/commerce.dart';
import 'package:go_router/go_router.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_card.dart';
import '../requests/requests_screen.dart';
import '../explore/explore_screen.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key, required this.title});
  final String title;
  @override
  ConsumerState<AccountPage> createState() => _AccountState();
}

class _AccountState extends ConsumerState<AccountPage> {
  final message = TextEditingController();
  final messages = <String>[];
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    if (title == 'Personal shopping') {
      return const RequestForm(collection: false);
    }
    if (title == 'Collect & deliver') {
      return const RequestForm(collection: true);
    }
    if (title == 'Saved addresses') return const AddressesScreen();
    if (title == 'Notifications') return const NotificationsScreen();
    if (title == 'Help centre') return const SupportScreen();
    if (![
      'Shop local',
      'Restaurants',
      'Groceries',
      'Favourites',
      'Appearance',
      'Privacy & terms',
      'Payment preferences',
      'Sign out'
    ].contains(title)) {
      return Storefront(name: title);
    }
    return Scaffold(appBar: AppBar(title: AppText(title)), body: _body(title));
  }

  Widget _body(String title) {
    if (title == 'Personal shopping') {
      return const RequestForm(collection: false);
    }
    if (title == 'Collect & deliver') {
      return const RequestForm(collection: true);
    }
    if (title == 'Saved addresses') return const AddressesScreen();
    if (title == 'Notifications') return const NotificationsScreen();
    if (title == 'Help centre') return const SupportScreen();
    if (['Shop local', 'Restaurants', 'Groceries'].contains(title)) {
      return ExploreScreen(
          initialCategory: title == 'Shop local' ? 'All' : title);
    }
    if (title == 'Favourites') {
      final saved = ref.watch(favoritesProvider),
          shops = ref.watch(commerceProvider).savedShops;
      return ListView(padding: const EdgeInsets.all(20), children: [
        const AppText('Saved businesses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (shops.isEmpty)
          const AppText('Save a business from its storefront.'),
        ...shops.map((s) => ListTile(
            title: AppText(s),
            trailing: IconButton(
                onPressed: () =>
                    ref.read(commerceProvider.notifier).toggleShop(s),
                icon: const Icon(Icons.favorite)),
            onTap: () => context.push('/shop/${Uri.encodeComponent(s)}'))),
        const AppText('Saved products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (saved.isEmpty) const AppText('Tap a product heart to save it.'),
        ...products
            .where((p) => saved.contains(p.name))
            .map((p) => SizedBox(height: 290, child: ProductCard(product: p))),
      ]);
    }
    if (title == 'Appearance') {
      return const _AppearancePreview();
    }
    if (title == 'Privacy & terms') {
      return const _PrivacyOverview();
    }
    if (title == 'Payment preferences') {
      final selected = ref.watch(preferredPaymentProvider);
      return _PaymentPreferenceOptions(
          selected: selected,
          onChanged: (value) =>
              ref.read(preferredPaymentProvider.notifier).state = value);
    }
    if (title == 'Sign out') {
      return Center(
          child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText('Continue browsing as a guest')));
    }
    return Storefront(name: title);
  }
}

class _PaymentPreferenceOptions extends StatelessWidget {
  const _PaymentPreferenceOptions(
      {required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                  color: Brand.mint, borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.payments_outlined, color: Brand.green)),
                SizedBox(width: 12),
                Expanded(
                    child: AppText('Choose your preferred payment method',
                        style: TextStyle(
                            color: Brand.charcoal,
                            fontSize: 17,
                            fontWeight: FontWeight.w900))),
              ]),
            ),
            const SizedBox(height: 10),
            const AppText(
                'Choose the default online method for demo payments. No payment credentials are stored.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              child: Column(children: [
                for (final method in ['Card', 'Instant EFT', 'Digital wallet'])
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                        color: selected == method ? Brand.mint : Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                            color: selected == method
                                ? Brand.green.withValues(alpha: .4)
                                : Brand.charcoal.withValues(alpha: .1))),
                    child: RadioListTile<String>(
                        value: method,
                        selected: selected == method,
                        activeColor: Brand.green,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 3),
                        title: AppText(method,
                            style: const TextStyle(
                                color: Brand.charcoal,
                                fontWeight: FontWeight.w800)),
                        subtitle: AppText(_paymentMethodDescription(method),
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                        secondary: Icon(_paymentMethodIcon(method),
                            color: Brand.green)),
                  ),
              ]),
            ),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Icon(Icons.verified_user_outlined, color: Brand.green),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: AppText('Selected payment method',
                          style: TextStyle(
                              color: Brand.charcoal,
                              fontWeight: FontWeight.w700))),
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: AppText(tr(context, selected),
                          key: ValueKey(selected),
                          style: const TextStyle(
                              color: Brand.green,
                              fontWeight: FontWeight.w900))),
                ]),
              ),
            ),
          ]),
        ),
      );

  String _paymentMethodDescription(String method) => switch (method) {
        'Card' => 'Card payment simulation at checkout.',
        'Instant EFT' => 'Bank transfer simulation at checkout.',
        _ => 'Wallet payment simulation at checkout.',
      };

  IconData _paymentMethodIcon(String method) => switch (method) {
        'Card' => Icons.credit_card_outlined,
        'Instant EFT' => Icons.account_balance_outlined,
        _ => Icons.account_balance_wallet_outlined,
      };
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview();
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Brand.mint, Color(0xFFF4F9F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.wb_sunny_outlined,
                              color: Brand.green)),
                      const SizedBox(width: 11),
                      const Expanded(
                          child: AppText('Light mode is on',
                              style: TextStyle(
                                  color: Brand.charcoal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900))),
                      AppText('Active',
                          style: TextStyle(
                              color: Brand.green, fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 10),
                    const AppText(
                        'The Gijima Mfana light theme keeps the app bright and uses emerald green and charcoal throughout.',
                        style: TextStyle(color: Colors.black54)),
                  ]),
            ),
            const SizedBox(height: 16),
            const _AccountInfoSection(
                icon: Icons.palette_outlined,
                title: 'Brand colours',
                description:
                    'Emerald green for actions, charcoal for headings, and a soft mint surface for highlights.'),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  _ColorSwatch(color: Brand.green, label: 'Emerald'),
                  const SizedBox(width: 12),
                  _ColorSwatch(color: Brand.charcoal, label: 'Charcoal'),
                  const SizedBox(width: 12),
                  _ColorSwatch(color: Brand.mint, label: 'Mint'),
                ]),
              ),
            ),
            const GlassCard(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.shopping_bag_outlined, color: Brand.green),
                  SizedBox(width: 10),
                  Expanded(
                      child: AppText('Gijima Mfana · local shopping',
                          style: TextStyle(
                              color: Brand.charcoal,
                              fontWeight: FontWeight.w800))),
                  Icon(Icons.arrow_forward_rounded, color: Brand.green),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12))),
          const SizedBox(height: 6),
          AppText(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Brand.charcoal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _PrivacyOverview extends StatelessWidget {
  const _PrivacyOverview();
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                    color: Brand.mint, borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  CircleAvatar(
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.privacy_tip_outlined, color: Brand.green)),
                  SizedBox(width: 12),
                  Expanded(
                      child: AppText('Privacy & terms',
                          style: TextStyle(
                              color: Brand.charcoal,
                              fontSize: 19,
                              fontWeight: FontWeight.w900))),
                ])),
            const SizedBox(height: 10),
            const AppText(
                'This customer app is a prototype. The information below explains the demo behaviour.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            const _AccountInfoSection(
                icon: Icons.storage_outlined,
                title: 'Prototype & demo data',
                description:
                    'Profile details, preferences, requests and orders use sample data and may be saved on this device.'),
            const _AccountInfoSection(
                icon: Icons.payments_outlined,
                title: 'Demo payments',
                description:
                    'Payment choices and outcomes are simulated. The app does not collect or store real card or bank credentials.'),
            const _AccountInfoSection(
                icon: Icons.storefront_outlined,
                title: 'Shops and images',
                description:
                    'KFC and McDonald’s are illustrative demo listings. No partnership or availability is implied; photography is illustrative.'),
            const _AccountInfoSection(
                icon: Icons.description_outlined,
                title: 'Service terms',
                description:
                    'Full service terms will be supplied before launch.'),
          ]),
        ),
      );
}

class _AccountInfoSection extends StatelessWidget {
  const _AccountInfoSection(
      {required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => GlassCard(
        margin: const EdgeInsets.only(bottom: 9),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: Icon(icon, color: Brand.green, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  AppText(title,
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  AppText(description,
                      style: const TextStyle(color: Colors.black54)),
                ])),
          ]),
        ),
      );
}
