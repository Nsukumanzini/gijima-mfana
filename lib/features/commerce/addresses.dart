// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/commerce.dart';
import 'common.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(commerceProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Saved addresses')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text(
              'Demo delivery region: Ermelo and Wesselton. Use fictional details for this prototype.'),
          const SizedBox(height: 16),
          if (data.addresses.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child:
                    Text('No addresses saved. Add one to arrange delivery.')),
          ...data.addresses.map((a) => Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(covered(a)
                                ? Icons.location_on_outlined
                                : Icons.location_off_outlined),
                            title: Text(addressText(a)),
                            subtitle: Text(
                                '${a['default'] == true ? 'Default · ' : ''}${covered(a) ? 'Delivery available' : 'Outside our demo delivery area'}')),
                        Wrap(spacing: 8, children: [
                          TextButton(
                              onPressed: () => _edit(context, ref, a),
                              child: const Text('Edit')),
                          TextButton(
                              onPressed: () => ref
                                  .read(commerceProvider.notifier)
                                  .defaultAddress(a['id'] as String),
                              child: const Text('Set default')),
                          TextButton(
                              onPressed: () => ref
                                  .read(commerceProvider.notifier)
                                  .deleteAddress(a['id'] as String),
                              child: const Text('Delete'))
                        ])
                      ])))),
          FilledButton.icon(
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Add address'))
        ]));
  }

  void _edit(BuildContext context, WidgetRef ref, Record? a) {
    showDialog<void>(
        context: context, builder: (_) => _AddressEditor(address: a));
  }
}

class _AddressEditor extends ConsumerStatefulWidget {
  const _AddressEditor({this.address});
  final Record? address;
  @override
  ConsumerState<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends ConsumerState<_AddressEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController label, street, city, postal;
  @override
  void initState() {
    super.initState();
    final a = widget.address;
    label = TextEditingController(text: a?['label'] as String? ?? 'Home');
    street = TextEditingController(text: a?['street'] as String?);
    city = TextEditingController(text: a?['city'] as String? ?? 'Ermelo');
    postal = TextEditingController(text: a?['postal'] as String? ?? '2351');
  }

  @override
  void dispose() {
    label.dispose();
    street.dispose();
    city.dispose();
    postal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.address == null ? 'Add address' : 'Edit address'),
          content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                  child: Form(
                      key: form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        input(label, 'Label (Home, Work or Other)'),
                        input(street, 'Street and building'),
                        input(city, 'Town / area'),
                        input(postal, 'Postal code',
                            keyboard: TextInputType.number,
                            validate: (v) =>
                                RegExp(r'^\d{4}$').hasMatch(v ?? '')
                                    ? null
                                    : 'Enter a four-digit postal code'),
                        const Text(
                            'Addresses outside Ermelo/Wesselton can be saved but cannot be used for delivery.')
                      ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  ref.read(commerceProvider.notifier).saveAddress({
                    'id': widget.address?['id'],
                    'label': label.text.trim(),
                    'street': street.text.trim(),
                    'city': city.text.trim(),
                    'postal': postal.text.trim(),
                    'default': widget.address?['default'] ?? false
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'))
          ]);
}
