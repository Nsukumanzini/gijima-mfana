import '../../app/localization/strings.dart';
import '../../app/theme/app_theme.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/commerce.dart';
import 'common.dart';

enum _AddressAction { edit, makeDefault, delete }

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  final _coverageController = TextEditingController();
  bool? _coverageResult;
  String _checkedLocation = '';

  @override
  void dispose() {
    _coverageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(commerceProvider).addresses;

    return Scaffold(
      appBar: AppBar(title: const AppText('Saved addresses')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 760;
              final cardWidth = twoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const AppText(
                    'Your places',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const AppText(
                    'Manage delivery locations and choose where your demo order goes.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  _CoverageChecker(
                    controller: _coverageController,
                    result: _coverageResult,
                    checkedLocation: _checkedLocation,
                    onChanged: (_) {
                      if (_coverageResult != null) {
                        setState(() => _coverageResult = null);
                      }
                    },
                    onCheck: _checkCoverage,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: AppText(
                          'Saved places',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                      _CountPill(count: addresses.length),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (addresses.isEmpty)
                    _EmptyAddresses(onAdd: () => _edit(context, null))
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: addresses
                          .map((address) => SizedBox(
                                width: cardWidth,
                                child: _AddressCard(
                                  address: address,
                                  onAction: (action) =>
                                      _handleAction(address, action),
                                ),
                              ))
                          .toList(),
                    ),
                  if (addresses.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _edit(context, null),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const AppText('Add delivery address'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _checkCoverage() {
    final location = _coverageController.text.trim();
    if (location.isEmpty) return;
    final normalized = location.toLowerCase();
    setState(() {
      _checkedLocation = location;
      _coverageResult =
          RegExp(r'\b(ermelo|wesselton|2351)\b').hasMatch(normalized);
    });
  }

  Future<void> _handleAction(Record address, _AddressAction action) async {
    final controller = ref.read(commerceProvider.notifier);
    switch (action) {
      case _AddressAction.edit:
        await _edit(context, address);
        break;
      case _AddressAction.makeDefault:
        controller.defaultAddress(address['id'] as String);
        _toast('Default address updated.');
        break;
      case _AddressAction.delete:
        final confirmed = await _confirmDelete(address);
        if (confirmed != true || !mounted) return;
        controller.deleteAddress(address['id'] as String);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const AppText('Address removed.'),
          action: SnackBarAction(
            label: tr(context, 'Undo'),
            onPressed: () => ref
                .read(commerceProvider.notifier)
                .saveAddress(Map<String, dynamic>.from(address)),
          ),
        ));
        break;
    }
  }

  Future<bool?> _confirmDelete(Record address) => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.location_off_outlined, color: Brand.green),
          title: const AppText('Remove this address?'),
          content: const AppText(
              'You can add it again later. Existing orders keep their saved address.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const AppText('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const AppText('Remove address'),
            ),
          ],
        ),
      );

  void _toast(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: AppText(text)));
  }

  Future<void> _edit(BuildContext context, Record? address) async {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= 700) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 650,
            height: size.height * .88,
            child: _AddressEditor(address: address),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .96,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _AddressEditor(address: address),
        ),
      ),
    );
  }
}

class _CoverageChecker extends StatelessWidget {
  const _CoverageChecker({
    required this.controller,
    required this.result,
    required this.checkedLocation,
    required this.onChanged,
    required this.onCheck,
  });

  final TextEditingController controller;
  final bool? result;
  final String checkedLocation;
  final ValueChanged<String> onChanged;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final statusColor = result == true
        ? Brand.green
        : result == false
            ? const Color(0xFF9A5A00)
            : Brand.charcoal;

    return GlassCard(
      color: Brand.mint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: Brand.green),
                SizedBox(width: 10),
                Expanded(
                  child: AppText(
                    'Check delivery coverage',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const AppText(
              'Enter a town or four-digit postal code to check the demo area.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final field = TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onCheck(),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    labelText: tr(context, 'Town or postal code'),
                    hintText: tr(context, 'e.g. Ermelo or 2351'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
                final button = FilledButton.icon(
                  onPressed: onCheck,
                  icon: const Icon(Icons.radar),
                  label: const AppText('Check coverage'),
                );
                if (constraints.maxWidth < 500) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [field, const SizedBox(height: 8), button],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 10),
                    button,
                  ],
                );
              },
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      result == true ? Colors.white : const Color(0xFFFFF3DF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      result == true
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        result == true
                            ? 'Coverage is available for this demo.'
                            : 'This location is outside the demo area. You can still save it.',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  children: [
                    const AppText(
                      'Checked location:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      checkedLocation,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: AppText(
                  'Demo area: Ermelo and Wesselton · postal code 2351.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: AppText(
                  'Demo area: Ermelo and Wesselton · postal code 2351.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onAction});

  final Record address;
  final ValueChanged<_AddressAction> onAction;

  @override
  Widget build(BuildContext context) {
    final isCovered = covered(address);
    final isDefault = address['default'] == true;
    final label = (address['label'] as String? ?? '').trim();
    final pinLabel = address['pinLabel'] as String? ?? 'Town centre';

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Brand.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      color: Brand.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          label.isEmpty ? 'Saved address' : label,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        if (isDefault)
                          const _StatusPill(
                            label: 'Default address',
                            icon: Icons.check_circle,
                            positive: true,
                          ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<_AddressAction>(
                  tooltip: tr(context, 'Address actions'),
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _AddressAction.edit,
                      child: _MenuLabel(
                          icon: Icons.edit_outlined, label: 'Edit address'),
                    ),
                    if (!isDefault)
                      PopupMenuItem(
                        value: _AddressAction.makeDefault,
                        child: _MenuLabel(
                            icon: Icons.check_circle_outline,
                            label: 'Make default'),
                      ),
                    PopupMenuItem(
                      value: _AddressAction.delete,
                      child: _MenuLabel(
                          icon: Icons.delete_outline, label: 'Remove address'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: AppText(
                _formatAddress(address),
                style: const TextStyle(height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusPill(
                    label:
                        isCovered ? 'Delivery available' : 'Outside demo area',
                    icon: isCovered
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    positive: isCovered,
                  ),
                  _StatusPill(
                    label: isCovered
                        ? 'Estimate · 25–40 min'
                        : 'Estimate unavailable',
                    icon: Icons.schedule_outlined,
                    positive: isCovered,
                  ),
                ],
              ),
            ),
            if (isCovered) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Wrap(
                  spacing: 4,
                  children: [
                    const AppText(
                      'Demo delivery fee varies by shop',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      rand(2500) + '–' + rand(2990),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 16, color: Brand.green),
                  const SizedBox(width: 5),
                  const AppText(
                    'Demo pin',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const Text(' · ',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  AppText(
                    pinLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.positive,
  });

  final String label;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? Brand.green : const Color(0xFF8A5700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: positive ? Brand.mint : const Color(0xFFFFF3DF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          AppText(
            label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 10),
          AppText(label),
        ],
      );
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Brand.mint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                  color: Brand.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
            const SizedBox(width: 4),
            AppText(
              count == 1 ? 'address' : 'addresses',
              style: const TextStyle(
                  color: Brand.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
          ],
        ),
      );
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: const Icon(Icons.location_on_outlined,
                    color: Brand.green, size: 38),
              ),
              const SizedBox(height: 14),
              const AppText(
                'No delivery addresses yet',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const AppText(
                'Add a place to make checkout quicker. This prototype uses local demo details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const AppText('Add your first address'),
              ),
            ],
          ),
        ),
      );
}

String _formatAddress(Record address) {
  final firstLine = [
    address['unit'],
    address['building'],
    address['street'],
  ]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(', ');
  final area = [
    address['suburb'],
    address['city'],
    address['province'],
  ]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(', ');
  final postal = (address['postal'] as String? ?? '').trim();
  return [
    firstLine,
    [area, postal].where((part) => part.isNotEmpty).join(' ')
  ].where((part) => part.isNotEmpty).join('\n');
}

class _AddressEditor extends ConsumerStatefulWidget {
  const _AddressEditor({this.address});
  final Record? address;

  @override
  ConsumerState<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends ConsumerState<_AddressEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController label;
  late final TextEditingController unit;
  late final TextEditingController building;
  late final TextEditingController street;
  late final TextEditingController suburb;
  late final TextEditingController city;
  late final TextEditingController province;
  late final TextEditingController postal;
  late final TextEditingController instructions;
  late String pinLabel;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    label = TextEditingController(text: address?['label'] as String? ?? 'Home');
    unit = TextEditingController(text: address?['unit'] as String? ?? '');
    building =
        TextEditingController(text: address?['building'] as String? ?? '');
    street = TextEditingController(text: address?['street'] as String? ?? '');
    suburb = TextEditingController(text: address?['suburb'] as String? ?? '');
    city = TextEditingController(text: address?['city'] as String? ?? 'Ermelo');
    province = TextEditingController(
        text: address?['province'] as String? ?? 'Mpumalanga');
    postal =
        TextEditingController(text: address?['postal'] as String? ?? '2351');
    instructions =
        TextEditingController(text: address?['instructions'] as String? ?? '');
    pinLabel = address?['pinLabel'] as String? ?? 'Town centre';
  }

  @override
  void dispose() {
    for (final controller in [
      label,
      unit,
      building,
      street,
      suburb,
      city,
      province,
      postal,
      instructions,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isCovered {
    final town = city.text.trim().toLowerCase();
    return town == 'ermelo' || town == 'wesselton';
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    widget.address == null
                        ? 'Add delivery address'
                        : 'Edit delivery address',
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: tr(context, 'Close'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                children: [
                  const AppText(
                    'Address details',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const AppText(
                    'Local example only: 12 Acacia Street, Ermelo, Mpumalanga 2351.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: label,
                    label: 'Address label',
                    hint: 'e.g. Home or Work',
                    icon: Icons.bookmark_border,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? tr(context, 'Enter a label such as Home or Work.')
                        : null,
                  ),
                  _field(
                    controller: unit,
                    label: 'Unit or apartment number',
                    hint: 'e.g. Flat 4',
                    icon: Icons.door_front_door_outlined,
                    required: false,
                  ),
                  _field(
                    controller: building,
                    label: 'Building or complex name (optional)',
                    hint: 'e.g. Acacia Court',
                    icon: Icons.apartment_outlined,
                    required: false,
                  ),
                  _field(
                    controller: street,
                    label: 'Street address',
                    hint: 'e.g. 12 Acacia Street',
                    icon: Icons.signpost_outlined,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? tr(context, 'Enter a street address.')
                        : null,
                  ),
                  _field(
                    controller: suburb,
                    label: 'Suburb (optional)',
                    hint: 'e.g. Ermelo Central',
                    icon: Icons.location_city_outlined,
                    required: false,
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final townField = _field(
                        controller: city,
                        label: 'Town / city',
                        hint: 'e.g. Ermelo',
                        icon: Icons.location_on_outlined,
                        onChanged: (_) => setState(() {}),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? tr(context, 'Enter a town or city.')
                                : null,
                      );
                      final postalField = _field(
                        controller: postal,
                        label: 'Postal code',
                        hint: '2351',
                        icon: Icons.markunread_mailbox_outlined,
                        keyboard: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (value) => RegExp(r'^\d{4}$')
                                .hasMatch(value?.trim() ?? '')
                            ? null
                            : tr(context,
                                'Enter a four-digit South African postal code.'),
                      );
                      if (constraints.maxWidth < 430) {
                        return Column(
                          children: [townField, postalField],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: townField),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: postalField),
                        ],
                      );
                    },
                  ),
                  _field(
                    controller: province,
                    label: 'Province',
                    hint: 'e.g. Mpumalanga',
                    icon: Icons.map_outlined,
                  ),
                  _formCoverage(isCovered: _isCovered),
                  const SizedBox(height: 16),
                  const AppText(
                    'Illustrative map pin',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  _DemoMapPin(pinLabel: pinLabel),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _choosePin,
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppText('Choose demo pin'),
                        const Text(' · '),
                        AppText(pinLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const AppText(
                    'This demo pin uses the town only; it does not use live location.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  const AppText(
                    'Delivery instructions',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    controller: instructions,
                    label: 'Directions for driver (optional)',
                    hint: 'Gate code, landmark or where to leave the order',
                    icon: Icons.notes_outlined,
                    required: false,
                    lines: 3,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const AppText('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const AppText('Save address'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    bool required = true,
    int lines = 1,
    ValueChanged<String>? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: lines,
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
          validator: required
              ? validator ??
                  (value) => value == null || value.trim().isEmpty
                      ? tr(context, 'Please complete this field.')
                      : null
              : validator,
          decoration: InputDecoration(
            labelText: tr(context, label),
            hintText: tr(context, hint),
            prefixIcon: Icon(icon),
          ),
        ),
      );

  Widget _formCoverage({required bool isCovered}) => Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCovered ? Brand.mint : const Color(0xFFFFF3DF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isCovered ? Icons.check_circle_outline : Icons.info_outline,
              color: isCovered ? Brand.green : const Color(0xFF8A5700),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppText(
                isCovered
                    ? 'Delivery available for this demo address.'
                    : 'Outside the demo area. You can save this address for later.',
                style: TextStyle(
                  color: isCovered ? Brand.green : const Color(0xFF8A5700),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _choosePin() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                'Choose a demo pin location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final option in ['Town centre', 'Near my street'])
                ListTile(
                  leading: Icon(
                    pinLabel == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Brand.green,
                  ),
                  title: AppText(option),
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => pinLabel = selected);
  }

  void _save() {
    if (!form.currentState!.validate()) return;
    ref.read(commerceProvider.notifier).saveAddress({
      'id': widget.address?['id'],
      'label': label.text.trim(),
      'unit': unit.text.trim(),
      'building': building.text.trim(),
      'street': street.text.trim(),
      'suburb': suburb.text.trim(),
      'city': city.text.trim(),
      'province': province.text.trim(),
      'postal': postal.text.trim(),
      'instructions': instructions.text.trim(),
      'pinLabel': pinLabel,
      'default': widget.address?['default'] ?? false,
    });
    Navigator.pop(context);
  }
}

class _DemoMapPin extends StatelessWidget {
  const _DemoMapPin({required this.pinLabel});
  final String pinLabel;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 128,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFFE8F2EC)),
              CustomPaint(painter: _DemoRoadPainter()),
              const Center(
                child: Icon(Icons.location_on, color: Brand.green, size: 38),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppText(
                    tr(context, pinLabel),
                    style: const TextStyle(
                        color: Brand.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Positioned(
                right: 10,
                bottom: 8,
                child: AppText(
                  'Illustrative demo map',
                  style: TextStyle(fontSize: 10, color: Brand.charcoal),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DemoRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final localRoad = Paint()
      ..color = const Color(0xFFC7DDD0)
      ..strokeWidth = 2;

    canvas.drawLine(Offset(-10, size.height * .24),
        Offset(size.width + 12, size.height * .42), road);
    canvas.drawLine(Offset(size.width * .18, -12),
        Offset(size.width * .48, size.height + 12), road);
    canvas.drawLine(Offset(size.width * .69, -12),
        Offset(size.width * .51, size.height + 10), road);
    canvas.drawLine(Offset(-10, size.height * .74),
        Offset(size.width + 12, size.height * .58), road);
    canvas.drawLine(Offset(size.width * .04, size.height * .52),
        Offset(size.width * .96, size.height * .28), localRoad);
    canvas.drawLine(Offset(size.width * .76, size.height * .05),
        Offset(size.width * .88, size.height * .95), localRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
