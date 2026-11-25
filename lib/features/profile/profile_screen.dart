// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/localization/strings.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/customer_preferences.dart';
import '../../shared/components/brand_logo.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commerce = ref.watch(commerceProvider);
    final address = commerce.defaultAddress;
    final name = ref.watch(customerNameProvider);
    final savedProducts = ref.watch(favoritesProvider).length;
    final savedShops = commerce.savedShops.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            Row(children: [
              const Expanded(
                  child: AppText('Profile',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Brand.charcoal))),
              IconButton.filledTonal(
                  tooltip: tr(context, 'Settings'),
                  onPressed: () => context.push('/settings'),
                  icon:
                      const Icon(Icons.settings_outlined, color: Brand.green)),
            ]),
            _ProfileEntrance(
              index: 0,
              child: _ProfileHero(name: name),
            ),
            const SizedBox(height: 14),
            _ProfileEntrance(
              index: 1,
              child: _ProfileStats(
                  orders: commerce.orders.length,
                  shops: savedShops,
                  products: savedProducts),
            ),
            const SizedBox(height: 22),
            _ProfileSectionTitle(title: 'Shopping & account'),
            _ProfileEntrance(
                index: 2,
                child: _ProfileLink(
                    icon: Icons.receipt_long_outlined,
                    title: 'Your orders',
                    subtitle: 'View your order history',
                    route: '/order-history')),
            _ProfileEntrance(
                index: 3, child: _DeliveryAddressCard(address: address)),
            _ProfileEntrance(
                index: 4,
                child: _ProfileLink(
                    icon: Icons.favorite_border,
                    title: 'Favourites',
                    subtitle: 'Your saved shops and products',
                    route: '/account/Favourites')),
            _ProfileEntrance(
                index: 5,
                child: _ProfileLink(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    subtitle: 'View your in-app updates',
                    route: '/notifications')),
            const SizedBox(height: 12),
            _ProfileSectionTitle(title: 'Help & support'),
            _ProfileEntrance(
                index: 6,
                child: _ProfileLink(
                    icon: Icons.help_outline,
                    title: 'Help centre',
                    subtitle: 'FAQs and mock support',
                    route: '/account/Help%20centre')),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name});
  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final values = parts.take(2).map((p) => p.characters.first.toUpperCase());
    return values.join().isEmpty ? 'U' : values.join();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Brand.mint, Color(0xFFF4F9F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Brand.green.withValues(alpha: .12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const BrandLogo(size: 56),
            ),
            const SizedBox(width: 12),
            const Expanded(
                child: AppText('Gijima Mfana',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Brand.charcoal,
                        fontSize: 17,
                        fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 17),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child)),
              child: CircleAvatar(
                  key: ValueKey(name),
                  radius: 28,
                  backgroundColor: Brand.green,
                  child: Text(_initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  const AppText('Demo profile · saved on this device',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ])),
          ]),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const AppText('Edit profile')),
          ),
        ]),
      );
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats(
      {required this.orders, required this.shops, required this.products});
  final int orders, shops, products;

  @override
  Widget build(BuildContext context) => GlassCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(children: [
            Expanded(
                child: _ProfileStat(
                    label: 'Orders',
                    count: orders,
                    icon: Icons.receipt_long_outlined,
                    route: '/order-history')),
            const _StatDivider(),
            Expanded(
                child: _ProfileStat(
                    label: 'Saved shops',
                    count: shops,
                    icon: Icons.storefront_outlined,
                    route: '/account/Favourites')),
            const _StatDivider(),
            Expanded(
                child: _ProfileStat(
                    label: 'Saved products',
                    count: products,
                    icon: Icons.favorite_border,
                    route: '/account/Favourites')),
          ]),
        ),
      );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 42, color: Brand.charcoal.withValues(alpha: .12));
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat(
      {required this.label,
      required this.count,
      required this.icon,
      required this.route});
  final String label;
  final int count;
  final IconData icon;
  final String route;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${tr(context, label)}: $count',
        onTap: () => context.push(route),
        excludeSemantics: true,
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(children: [
              Icon(icon, color: Brand.green, size: 20),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text('$count',
                      key: ValueKey(count),
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontWeight: FontWeight.w900,
                          fontSize: 18))),
              AppText(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Brand.charcoal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({required this.address});
  final Map<String, dynamic>? address;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/addresses'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child:
                    const Icon(Icons.location_on_outlined, color: Brand.green)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const AppText('Saved addresses',
                      style: TextStyle(
                          color: Brand.charcoal, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  if (hasAddress)
                    AppText(addressText(address!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12))
                  else
                    const AppText('No delivery address saved',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                ])),
            const SizedBox(width: 8),
            if (hasAddress)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Icon(Icons.check_circle, color: Brand.green, size: 18),
                const SizedBox(height: 4),
                AppText('Default',
                    style: TextStyle(
                        color: Brand.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ])
            else
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color: Brand.green,
                      borderRadius: BorderRadius.circular(20)),
                  child: const AppText('Add address',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800))),
          ]),
        ),
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: AppText(title,
            style: const TextStyle(
                color: Brand.charcoal,
                fontWeight: FontWeight.w900,
                fontSize: 17)),
      );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.route});
  final IconData icon;
  final String title, subtitle, route;
  @override
  Widget build(BuildContext context) => GlassCard(
        margin: const EdgeInsets.only(bottom: 9),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
            minTileHeight: 76,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            leading: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: Icon(icon, color: Brand.green, size: 21)),
            title: AppText(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Brand.charcoal)),
            subtitle: AppText(subtitle,
                style: const TextStyle(color: Colors.black54)),
            trailing: const Icon(Icons.chevron_right, color: Brand.green),
            onTap: () => context.push(route)),
      );
}

class _ProfileEntrance extends StatelessWidget {
  const _ProfileEntrance({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(index),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + index * 45),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, (1 - value) * 12), child: child)),
        child: child,
      );
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: ref.read(customerNameProvider));
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const AppText('Edit profile')),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Center(child: BrandLogo(size: 145)),
            const SizedBox(height: 12),
            const AppText('Make it yours',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const AppText('Your demo profile is saved on this device.'),
            const SizedBox(height: 24),
            TextFormField(
                controller: name,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                    labelText: tr(context, 'Display name'),
                    prefixIcon: const Icon(Icons.person_outline)),
                validator: (value) => value == null || value.trim().isEmpty
                    ? tr(context, 'Please enter a display name')
                    : null),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    ref.read(customerNameProvider.notifier).state =
                        name.text.trim();
                    context.pop();
                  }
                },
                child: const AppText('Save')),
          ])));
}
