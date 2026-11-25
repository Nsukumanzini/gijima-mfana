import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/local_store.dart';
import '../../shared/components/brand_logo.dart';
import '../commerce/common.dart';
import '../shared/product_visual.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<CheckoutScreen> {
  DateTime? scheduledFor;
  bool schedule = false;
  final form = GlobalKey<FormState>();
  final note = TextEditingController();
  final discount = TextEditingController();
  String? address;
  String code = '', method = 'Card', outcome = 'Successful';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    method = ref.read(preferredPaymentProvider);
    if (widget.initialCode?.toUpperCase() == 'LOCAL10') {
      code = 'LOCAL10';
      discount.text = 'LOCAL10';
    }
    address = ref.read(commerceProvider).defaultAddress?['id'] as String?;
  }

  @override
  void dispose() {
    note.dispose();
    discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(basketProvider);
    final commerce = ref.watch(commerceProvider);
    final totals = basketTotals(basket, code);
    final minimum =
        basket.merchant == null ? 0 : minimumOrder(basket.merchant!);
    final meetsMinimum = basket.count == 0 || basket.subtotal >= minimum;

    final deliveryDetails = Column(
      children: [
        _addressField(commerce),
        const SizedBox(height: 4),
        _deliveryOptions(),
        const SizedBox(height: 12),
        TextFormField(
          controller: note,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: tr(context, 'Delivery instructions (optional)'),
            hintText: tr(context, 'Gate code, unit or helpful directions'),
            prefixIcon: const Icon(Icons.sticky_note_2_outlined),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );

    final orderDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _orderItems(basket),
        const SizedBox(height: 16),
        _discountField(),
        const SizedBox(height: 12),
        _feeBreakdown(totals, minimum, basket),
      ],
    );

    final paymentDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CheckoutPayment(
          method: method,
          outcome: outcome,
          onMethod: (value) => setState(() => method = value),
          onOutcome: (value) => setState(() => outcome = value),
        ),
        const SizedBox(height: 12),
        _reviewCard(basket, commerce),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const BrandLogo(size: 34),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                AppText('Checkout',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                AppText('Your local Mzansi marketplace',
                    style: TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    _CheckoutIntro(merchant: basket.merchant),
                    const SizedBox(height: 18),
                    if (basket.count == 0) ...[
                      _emptyBasket(),
                    ] else if (wide) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                _SectionCard(
                                  title: 'Delivery details',
                                  icon: Icons.location_on_outlined,
                                  child: deliveryDetails,
                                ),
                                const SizedBox(height: 14),
                                _SectionCard(
                                  title: 'Payment',
                                  icon: Icons.account_balance_wallet_outlined,
                                  child: paymentDetails,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: _SectionCard(
                              title: 'Review your order',
                              icon: Icons.receipt_long_outlined,
                              child: orderDetails,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _SectionCard(
                        title: 'Delivery details',
                        icon: Icons.location_on_outlined,
                        child: deliveryDetails,
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Review your order',
                        icon: Icons.receipt_long_outlined,
                        child: orderDetails,
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Payment',
                        icon: Icons.account_balance_wallet_outlined,
                        child: paymentDetails,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: basket.count == 0
          ? null
          : _CheckoutFooter(
              total: totals.total,
              isBusy: busy,
              isOrderValid: meetsMinimum,
              onSubmit: () => _submit(basket),
              minimumText: meetsMinimum
                  ? null
                  : tr(context, 'Add items to reach the shop minimum'),
            ),
    );
  }

  Widget _addressField(DemoState commerce) => FormField<String>(
        initialValue: address,
        validator: (value) {
          final selected = commerce.address(value);
          if (selected == null) {
            return tr(context, 'Add and choose a delivery address');
          }
          if (!covered(selected)) {
            return tr(
                context, 'Delivery is available in Ermelo and Wesselton only');
          }
          return null;
        },
        builder: (field) {
          final selected = commerce.address(field.value);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected == null)
                _EmptyAddressCard(
                    onSelect: () => _chooseAddress(commerce, field))
              else
                _SelectedAddressCard(
                  address: selected,
                  onChange: () => _chooseAddress(commerce, field),
                ),
              if (field.errorText != null) ...[
                const SizedBox(height: 5),
                Text(field.errorText!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12)),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openAddressManager(field),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const AppText('Manage delivery addresses'),
                ),
              ),
            ],
          );
        },
      );

  Future<void> _chooseAddress(
      DemoState commerce, FormFieldState<String> field) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: AppText('Choose delivery address',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 8),
                if (commerce.addresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: AppText('No delivery addresses saved yet.'),
                  )
                else
                  ...commerce.addresses.map((item) {
                    final id = item['id'] as String;
                    final isAvailable = covered(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AddressChoice(
                        address: item,
                        selected: field.value == id,
                        available: isAvailable,
                        onTap: isAvailable
                            ? () => Navigator.pop(sheetContext, id)
                            : null,
                      ),
                    );
                  }),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, '__manage__'),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const AppText('Manage delivery addresses'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == '__manage__') {
      await context.push('/addresses');
      if (!mounted) return;
      final updated = ref.read(commerceProvider);
      final current = updated.address(address);
      final next = current != null && covered(current)
          ? address
          : updated.defaultAddress?['id'] as String?;
      setState(() => address = next);
      field.didChange(next);
      return;
    }
    setState(() => address = selected);
    field.didChange(selected);
  }

  Future<void> _openAddressManager(FormFieldState<String> field) async {
    await context.push('/addresses');
    if (!mounted) return;
    final updated = ref.read(commerceProvider);
    final current = updated.address(address);
    final next = current != null && covered(current)
        ? address
        : updated.defaultAddress?['id'] as String?;
    setState(() => address = next);
    field.didChange(next);
  }

  Widget _deliveryOptions() => FormField<DateTime?>(
        initialValue: scheduledFor,
        validator: (_) => schedule && scheduledFor == null
            ? tr(context, 'Choose a delivery date and time')
            : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<bool>(
              groupValue: schedule,
              onChanged: (value) {
                setState(() {
                  schedule = value!;
                  if (!schedule) scheduledFor = null;
                });
                field.didChange(scheduledFor);
              },
              child: Column(
                children: [
                  _DeliveryChoiceCard(
                    value: false,
                    title: 'As soon as possible',
                    subtitle: 'Estimated 25–40 minutes · Demo',
                    icon: Icons.bolt_rounded,
                    selected: !schedule,
                  ),
                  const SizedBox(height: 8),
                  _DeliveryChoiceCard(
                    value: true,
                    title: 'Schedule delivery',
                    subtitle: scheduledFor == null
                        ? 'Choose a date and time'
                        : _scheduledLabel(context, scheduledFor!),
                    icon: Icons.calendar_month_outlined,
                    selected: schedule,
                    onTrailing: _selectTime(field),
                  ),
                ],
              ),
            ),
            if (schedule)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () => _selectTime(field)(),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: AppText(scheduledFor == null
                        ? 'Choose delivery date and time'
                        : 'Change delivery time'),
                  ),
                ),
              ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(field.errorText!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12)),
              ),
          ],
        ),
      );

  VoidCallback _selectTime(FormFieldState<DateTime?> field) => () async {
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: calendarInitial(scheduledFor, now),
          firstDate: now,
          lastDate: now.add(const Duration(days: 13)),
          helpText: tr(context, 'Choose a delivery date'),
        );
        if (selected == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
              scheduledFor ?? now.add(const Duration(hours: 1))),
          helpText: tr(context, 'Choose a delivery time'),
        );
        if (time == null || !mounted) return;
        final candidate = DateTime(selected.year, selected.month, selected.day,
            time.hour, time.minute);
        if (candidate
            .isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
          message(context, 'Please choose at least 30 minutes from now');
          return;
        }
        setState(() {
          schedule = true;
          scheduledFor = candidate;
        });
        field.didChange(candidate);
      };

  String _scheduledLabel(BuildContext context, DateTime value) =>
      '${MaterialLocalizations.of(context).formatFullDate(value.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(value.toLocal()))}';

  Widget _orderItems(BasketState basket) => Column(
        children: basket.lines.entries.map((line) {
          final product = products.firstWhere((p) => p.name == line.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProductVisual(
                    product: product,
                    width: 58,
                    height: 58,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      AppText(product.store,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 11)),
                      if ((basket.notes[line.key] ?? '').trim().isNotEmpty)
                        AppText(basket.notes[line.key]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Brand.green, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(rand(product.priceCents * line.value),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    _QuantityEditor(
                      quantity: line.value,
                      onMinus: () => ref
                          .read(basketProvider.notifier)
                          .quantity(line.key, line.value - 1),
                      onPlus: () => ref
                          .read(basketProvider.notifier)
                          .quantity(line.key, line.value + 1),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );

  Widget _discountField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
              child: AppText('Discount code',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            if (code.isNotEmpty)
              const _StatusChip(label: 'LOCAL10 applied', icon: Icons.check),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discount,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText:
                        tr(context, 'Try LOCAL10: 10% off items, max R 50'),
                    prefixIcon: const Icon(Icons.sell_outlined),
                  ),
                  onSubmitted: (_) => _applyDiscount(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _applyDiscount,
                child: AppText(code.isEmpty ? 'Apply code' : 'Update code'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const AppText('Use LOCAL10 for 10% off items, up to R 50.',
              style: TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      );

  void _applyDiscount() {
    final value = discount.text.trim().toUpperCase();
    setState(() => code = value == 'LOCAL10' ? value : '');
    message(
      context,
      value.isEmpty
          ? 'Discount removed'
          : value == 'LOCAL10'
              ? 'LOCAL10 applied'
              : 'Code not recognised. Try LOCAL10.',
    );
  }

  Widget _feeBreakdown(Totals totals, int minimum, BasketState basket) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 22),
          _MoneyRow(label: 'Subtotal', cents: totals.subtotal),
          _MoneyRow(
            label: 'Delivery fee',
            cents: totals.delivery,
            detail: 'Courier delivery from your local shop.',
          ),
          _MoneyRow(
            label: 'Service fee',
            cents: totals.service,
            detail: 'Helps with order support and secure checkout.',
          ),
          _MoneyRow(
            label: 'Discount',
            cents: totals.discount,
            isDiscount: true,
          ),
          const Divider(height: 22),
          Row(children: [
            const Expanded(
              child: AppText('Total',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(rand(totals.total),
                  key: ValueKey(totals.total),
                  style: const TextStyle(
                      color: Brand.green,
                      fontSize: 19,
                      fontWeight: FontWeight.w900)),
            ),
          ]),
          if (basket.merchant != null) ...[
            const SizedBox(height: 7),
            _MinimumOrderHint(
              minimum: minimum,
              subtotal: basket.subtotal,
              merchant: basket.merchant!,
            ),
          ],
        ],
      );

  Widget _reviewCard(BasketState basket, DemoState commerce) {
    final selected = commerce.address(address);
    final addressName = selected == null
        ? tr(context, 'Choose a delivery address')
        : addressText(selected);
    final delivery = schedule
        ? scheduledFor != null
            ? _scheduledLabel(context, scheduledFor!)
            : tr(context, 'Choose a date and time')
        : tr(context, 'As soon as possible');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.mint.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.green.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Final order review',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          _ReviewLine(
              icon: Icons.storefront_outlined,
              label: basket.merchant ?? tr(context, 'Local shop')),
          _ReviewLine(icon: Icons.location_on_outlined, label: addressName),
          _ReviewLine(icon: Icons.schedule_outlined, label: delivery),
          _ReviewLine(icon: Icons.payment_outlined, label: method),
          if (!meetsAddressCoverage(commerce))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: AppText('Choose a covered Ermelo or Wesselton address.',
                  style: TextStyle(color: Colors.red, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  bool meetsAddressCoverage(DemoState commerce) {
    final selected = commerce.address(address);
    return selected != null && covered(selected);
  }

  Widget _emptyBasket() => _SectionCard(
        title: 'Your basket is empty.',
        icon: Icons.shopping_basket_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText('Add a local favourite before you check out.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.storefront_outlined),
              label: const AppText('Browse local shops'),
            ),
          ],
        ),
      );

  Future<void> _submit(BasketState basket) async {
    if (basket.count == 0) return;
    final valid = form.currentState?.validate() ?? false;
    if (!valid) {
      message(context, 'Please check the highlighted checkout details.');
      return;
    }
    final commerce = ref.read(commerceProvider);
    final selectedAddress = commerce.address(address);
    if (selectedAddress == null || !covered(selectedAddress)) {
      message(context, 'Delivery is available in Ermelo and Wesselton only');
      return;
    }
    if (basket.merchant != null &&
        basket.subtotal < minimumOrder(basket.merchant!)) {
      message(context, 'Add items to reach the shop minimum');
      return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(commerceProvider.notifier);
      final id = repo.checkout(
        basket: basket,
        addressId: address!,
        note: note.text.trim(),
        code: code,
        method: method,
        outcome: outcome,
        scheduledFor: schedule ? scheduledFor : null,
      );
      if (outcome == 'Successful') ref.read(basketProvider.notifier).clear();
      if (context.mounted) context.pushReplacement('/orders/$id');
    } catch (error) {
      if (context.mounted) message(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _CheckoutIntro extends StatelessWidget {
  const _CheckoutIntro({required this.merchant});
  final String? merchant;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: merchant == null
                      ? tr(context, 'Review and confirm')
                      : '${tr(context, 'Order from')} ',
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.w900)),
              if (merchant != null)
                TextSpan(
                    text: merchant,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 5),
          const AppText(
              'Check your delivery details, items and total before payment.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          const _CheckoutSteps(),
        ],
      );
}

class _CheckoutSteps extends StatelessWidget {
  const _CheckoutSteps();

  @override
  Widget build(BuildContext context) {
    const labels = ['Delivery details', 'Review order', 'Payment'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.green.withValues(alpha: .1)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                  child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Brand.green.withValues(alpha: .18))),
            Flexible(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                      color: Brand.mint, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Brand.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AppText(labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Brand.charcoal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => GlassCard(
        margin: EdgeInsets.zero,
        elevation: 1,
        shadowColor: Brand.charcoal.withValues(alpha: .06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Brand.green.withValues(alpha: .08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                      color: Brand.mint, shape: BoxShape.circle),
                  child: Icon(icon, color: Brand.green, size: 19),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: AppText(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}

class _SelectedAddressCard extends StatelessWidget {
  const _SelectedAddressCard({required this.address, required this.onChange});
  final Record address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final available = covered(address);
    final full = addressText(address);
    final name = address['label'] as String? ?? 'Delivery address';
    final detail =
        full.contains(' · ') ? full.split(' · ').skip(1).join(' · ') : full;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Brand.green.withValues(alpha: .17)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: const Icon(Icons.home_work_outlined,
                    color: Brand.green, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: AppText(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                      if (address['default'] == true)
                        const _StatusChip(label: 'Default', icon: Icons.check),
                    ]),
                    const SizedBox(height: 3),
                    AppText(detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 6),
                    _StatusChip(
                      label: available
                          ? 'Delivery available · Ermelo'
                          : 'Outside delivery area',
                      icon: available
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      isGood: available,
                    ),
                    if (available)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: AppText('Estimated 25–40 minutes · Demo',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 10)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onChange,
                tooltip: tr(context, 'Change delivery address'),
                icon: const Icon(Icons.edit_location_alt_outlined,
                    color: Brand.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAddressCard extends StatelessWidget {
  const _EmptyAddressCard({required this.onSelect});
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Brand.green.withValues(alpha: .15)),
        ),
        child: Row(children: [
          const Icon(Icons.location_off_outlined, color: Brand.green),
          const SizedBox(width: 9),
          const Expanded(child: AppText('No delivery address chosen.')),
          TextButton(
              onPressed: onSelect, child: const AppText('Choose address')),
        ]),
      );
}

class _AddressChoice extends StatelessWidget {
  const _AddressChoice({
    required this.address,
    required this.selected,
    required this.available,
    required this.onTap,
  });
  final Record address;
  final bool selected, available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = address['label'] as String? ?? 'Address';
    return Material(
      color: selected ? Brand.mint : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: selected
                    ? Brand.green
                    : Brand.green.withValues(alpha: .12)),
          ),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? Brand.green : Colors.black45),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  AppText(addressText(address),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 4),
                  _StatusChip(
                    label: available
                        ? 'Delivery available'
                        : 'Outside delivery area',
                    icon: available
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    isGood: available,
                  ),
                ],
              ),
            ),
            if (address['default'] == true)
              const _StatusChip(label: 'Default', icon: Icons.check),
          ]),
        ),
      ),
    );
  }
}

class _DeliveryChoiceCard extends StatelessWidget {
  const _DeliveryChoiceCard({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    this.onTrailing,
  });
  final bool value, selected;
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? Brand.mint.withValues(alpha: .6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  selected ? Brand.green : Brand.green.withValues(alpha: .12)),
        ),
        child: RadioListTile<bool>(
          value: value,
          activeColor: Brand.green,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          secondary: onTrailing == null
              ? Icon(icon, color: Brand.green, size: 20)
              : IconButton(
                  tooltip: tr(context, 'Choose a delivery date and time'),
                  onPressed: onTrailing,
                  icon: const Icon(Icons.calendar_month_outlined,
                      color: Brand.green),
                ),
          title: AppText(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: AppText(subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          toggleable: false,
        ),
      );
}

class _QuantityEditor extends StatelessWidget {
  const _QuantityEditor(
      {required this.quantity, required this.onMinus, required this.onPlus});
  final int quantity;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        _QuantityButton(icon: Icons.remove, onTap: onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Text('$quantity',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        _QuantityButton(icon: Icons.add, onTap: onPlus),
      ]);
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 25,
        height: 25,
        child: IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          iconSize: 17,
          color: Brand.green,
          tooltip: tr(context,
              icon == Icons.add ? 'Increase quantity' : 'Decrease quantity'),
          icon: Icon(icon),
        ),
      );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(
      {required this.label,
      required this.cents,
      this.detail,
      this.isDiscount = false});
  final String label;
  final int cents;
  final String? detail;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: AppText(label)),
                  if (detail != null) ...[
                    const SizedBox(width: 3),
                    Tooltip(
                      message: tr(context, detail!),
                      child: const Icon(Icons.info_outline,
                          size: 14, color: Colors.black45),
                    ),
                  ],
                ]),
                if (detail != null)
                  AppText(detail!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
          AppText(isDiscount ? '−${rand(cents)}' : rand(cents),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDiscount && cents > 0 ? Brand.green : null)),
        ]),
      );
}

class _MinimumOrderHint extends StatelessWidget {
  const _MinimumOrderHint(
      {required this.minimum, required this.subtotal, required this.merchant});
  final int minimum, subtotal;
  final String merchant;

  @override
  Widget build(BuildContext context) {
    final remaining = (minimum - subtotal).clamp(0, minimum);
    final reached = remaining == 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: reached ? Brand.mint : const Color(0xFFFFF4DE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(reached ? Icons.check_circle_outline : Icons.info_outline,
            color: reached ? Brand.green : const Color(0xFF9A6800), size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: AppText(
            reached
                ? '${tr(context, 'Shop minimum reached for')} $merchant.'
                : '${tr(context, 'Add')} ${rand(remaining)} ${tr(context, 'to reach the minimum for')} $merchant.',
            style: TextStyle(
                fontSize: 11,
                color: reached ? Brand.green : const Color(0xFF805500),
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: Brand.green),
          const SizedBox(width: 7),
          Expanded(
            child: AppText(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11)),
          ),
        ]),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.label, required this.icon, this.isGood = true});
  final String label;
  final IconData icon;
  final bool isGood;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
            color: isGood ? Brand.mint : const Color(0xFFFFF4DE),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 12, color: isGood ? Brand.green : const Color(0xFF9A6800)),
          const SizedBox(width: 3),
          AppText(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isGood ? Brand.green : const Color(0xFF805500))),
        ]),
      );
}

class _CheckoutPayment extends StatelessWidget {
  const _CheckoutPayment(
      {required this.method,
      required this.outcome,
      required this.onMethod,
      required this.onOutcome});
  final String method, outcome;
  final ValueChanged<String> onMethod, onOutcome;

  @override
  Widget build(BuildContext context) {
    const methods = <(String, IconData)>[
      ('Card', Icons.credit_card_outlined),
      ('Instant EFT', Icons.account_balance_outlined),
      ('Digital wallet', Icons.account_balance_wallet_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Choose a payment method',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: methods.map((item) {
            final selected = method == item.$1;
            return ChoiceChip(
              selected: selected,
              showCheckmark: false,
              avatar: Icon(item.$2,
                  size: 17, color: selected ? Brand.green : Brand.charcoal),
              label: AppText(item.$1),
              onSelected: (_) => onMethod(item.$1),
              backgroundColor: Colors.white,
              selectedColor: Brand.mint,
              side: BorderSide(
                  color: selected
                      ? Brand.green
                      : Brand.green.withValues(alpha: .16)),
              labelStyle: TextStyle(
                  color: selected ? Brand.green : Brand.charcoal,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          shape: RoundedRectangleBorder(
              side: BorderSide(color: Brand.green.withValues(alpha: .12)),
              borderRadius: BorderRadius.circular(14)),
          collapsedShape: RoundedRectangleBorder(
              side: BorderSide(color: Brand.green.withValues(alpha: .12)),
              borderRadius: BorderRadius.circular(14)),
          leading:
              const Icon(Icons.science_outlined, color: Brand.green, size: 19),
          title: const AppText('Demo payment options',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: const AppText('Preview only · no real payment',
              style: TextStyle(color: Colors.black54, fontSize: 10)),
          children: [
            DropdownButtonFormField<String>(
              initialValue: outcome,
              decoration: InputDecoration(
                  labelText: tr(context, 'Simulated payment outcome')),
              items: ['Successful', 'Pending', 'Failed', 'Cancelled']
                  .map((value) =>
                      DropdownMenuItem(value: value, child: AppText(value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onOutcome(value);
              },
            ),
            const SizedBox(height: 8),
            const AppText(
                'Demo payments only. No card numbers, bank details or real money.',
                style: TextStyle(color: Colors.black54, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter({
    required this.total,
    required this.isBusy,
    required this.isOrderValid,
    required this.onSubmit,
    required this.minimumText,
  });
  final int total;
  final bool isBusy, isOrderValid;
  final VoidCallback onSubmit;
  final String? minimumText;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
                top: BorderSide(color: Brand.green.withValues(alpha: .12))),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 14,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  final totalWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppText('Total to pay',
                          style:
                              TextStyle(color: Colors.black54, fontSize: 11)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(rand(total),
                            key: ValueKey(total),
                            style: const TextStyle(
                                color: Brand.charcoal,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  );
                  final paymentButton = FilledButton.icon(
                    onPressed: isBusy || !isOrderValid ? null : onSubmit,
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.lock_outline_rounded, size: 18),
                    label: isBusy
                        ? const AppText('Processing…')
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            const AppText('Confirm demo payment'),
                            const SizedBox(width: 5),
                            Text('· ${rand(total)}'),
                          ]),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 18)),
                  );

                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    if (minimumText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppText(minimumText!,
                              style: const TextStyle(
                                  color: Color(0xFF805500),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (compact) ...[
                      Align(
                          alignment: Alignment.centerLeft, child: totalWidget),
                      const SizedBox(height: 7),
                      SizedBox(width: double.infinity, child: paymentButton),
                    ] else
                      Row(children: [
                        Expanded(child: totalWidget),
                        const SizedBox(width: 12),
                        paymentButton,
                      ]),
                  ]);
                },
              ),
            ),
          ),
        ),
      );
}
