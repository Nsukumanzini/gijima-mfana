import '../../shared/components/brand_text.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 110), children: [
        Image.asset('assets/brand/courier.png',
            height: 120,
            fit: BoxFit.contain,
            semanticLabel: 'Gijima Mfana courier symbol'),
        const Center(
            child: BrandText('Gijima Mfana', style: TextStyle(fontSize: 26))),
        const SizedBox(height: 16),
        const Text('Profile',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Card(
            child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Brand.mint,
                    child: Icon(Icons.person, color: Brand.green)),
                title: const Text('Sihle Mokoena',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Demo account · Ermelo'),
                trailing: IconButton(
                    onPressed: () =>
                        _toast(context, 'Profile editing is simulated'),
                    icon: const Icon(Icons.edit_outlined)))),
        const SizedBox(height: 14),
        const Text('YOUR ACCOUNT',
            style: TextStyle(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.black54)),
        const SizedBox(height: 8),
        _item(context, Icons.location_on_outlined, 'Saved addresses',
            'Home · 12 Acacia Street'),
        _item(context, Icons.favorite_border, 'Favourites',
            'Your saved shops and products'),
        _item(context, Icons.notifications_none, 'Notifications',
            'Order and offer updates'),
        _item(context, Icons.payments_outlined, 'Payment preferences',
            'Demo payment options only'),
        const SizedBox(height: 14),
        const Text('PREFERENCES & HELP',
            style: TextStyle(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.black54)),
        const SizedBox(height: 8),
        _item(context, Icons.palette_outlined, 'Appearance',
            'Light · Gijima Mfana'),
        _item(context, Icons.help_outline, 'Help centre',
            'FAQs and mock support'),
        _item(context, Icons.privacy_tip_outlined, 'Privacy & terms',
            'Read our information'),
        _item(context, Icons.logout, 'Sign out', 'Demo session'),
      ]);
  Widget _item(BuildContext c, IconData icon, String title, String sub) => Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(
          leading: Icon(icon, color: Brand.green),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: BrandText(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => c.push('/account/${Uri.encodeComponent(title)}')));
  static void _toast(BuildContext c, String s) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));
}
