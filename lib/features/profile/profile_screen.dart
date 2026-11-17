// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/localization/strings.dart';
import '../../app/theme/app_theme.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/customer_preferences.dart';
import '../../shared/components/brand_logo.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(commerceProvider).defaultAddress;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          Row(children: [
            const Expanded(
                child: AppText('Profile',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
            IconButton(
                tooltip: tr(context, 'Settings'),
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined, color: Brand.green))
          ]),
          const Center(child: BrandLogo(size: 160)),
          Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: Brand.mint,
                          child: Icon(Icons.person, color: Brand.green)),
                      title: Text(ref.watch(customerNameProvider),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          const AppText('Demo profile · saved on this device'),
                      trailing: IconButton(
                          tooltip: tr(context, 'Edit profile'),
                          onPressed: () => context.push('/profile/edit'),
                          icon: const Icon(Icons.edit_outlined,
                              color: Brand.green))))),
          const SizedBox(height: 18),
          const AppText('YOUR ACCOUNT',
              style: TextStyle(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          _item(context, Icons.receipt_long_outlined, 'Your orders',
              'View your order history', '/order-history'),
          _item(
              context,
              Icons.location_on_outlined,
              'Saved addresses',
              address == null ? 'Add a delivery address' : addressText(address),
              '/addresses'),
          _item(context, Icons.favorite_border, 'Favourites',
              'Your saved shops and products', '/account/Favourites'),
          _item(context, Icons.notifications_none, 'Notifications',
              'View your in-app updates', '/notifications'),
          _item(context, Icons.help_outline, 'Help centre',
              'FAQs and mock support', '/account/Help%20centre'),
          const SizedBox(height: 14),
          _item(context, Icons.settings_outlined, 'Settings',
              'Language, payments and notifications', '/settings'),
        ]);
  }

  Widget _item(BuildContext c, IconData icon, String title, String sub,
          String route) =>
      Card(
          margin: const EdgeInsets.only(bottom: 7),
          child: ListTile(
              leading: Icon(icon, color: Brand.green),
              title: AppText(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: AppText(sub),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => c.push(route)));
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
