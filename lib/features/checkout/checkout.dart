import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/catalog.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/local_store.dart';
import '../commerce/common.dart';

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
  final note = TextEditingController(), discount = TextEditingController();
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
    final basket = ref.watch(basketProvider), t = basketTotals(basket, code);
    return Scaffold(
        appBar: AppBar(title: const AppText('Checkout')),
        body: Form(
            key: form,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (basket.count == 0) const AppText('Your basket is empty.'),
              heading('Delivery address'),
              addressPicker(
                  context, ref, address, (v) => setState(() => address = v)),
              TextButton(
                  onPressed: () => context.push('/addresses'),
                  child: const AppText('Manage delivery addresses')),
              input(note, 'Delivery instructions (optional)',
                  lines: 2, validate: (_) => null),
              heading('Order from ${basket.merchant ?? 'your local shop'}'),
              heading('Delivery time'),
              RadioGroup<bool>(
                  groupValue: schedule,
                  onChanged: (v) => setState(() => schedule = v!),
                  child: Column(children: [
                    const RadioListTile<bool>(
                        value: false,
                        title: AppText('As soon as possible'),
                        subtitle: AppText('Estimated 25–40 minutes · Demo')),
                    RadioListTile<bool>(
                        value: true,
                        title: const AppText('Schedule delivery'),
                        subtitle: AppText(scheduledFor == null
                            ? 'Choose a date and time'
                            : '${MaterialLocalizations.of(context).formatFullDate(scheduledFor!.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(scheduledFor!.toLocal()))}'),
                        secondary: IconButton(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.calendar_month_outlined),
                            tooltip: 'Choose date and time')),
                  ])),
              if (schedule)
                TextButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.schedule),
                    label: const AppText('Choose delivery date and time')),
              for (final e in basket.lines.entries)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: AppText('${e.value} × ${e.key}'),
                    subtitle: AppText(basket.notes[e.key] ?? ''),
                    trailing: AppText(rand(
                        products.firstWhere((p) => p.name == e.key).priceCents *
                            e.value))),
              const SizedBox(height: 12),
              TextField(
                  controller: discount,
                  decoration: InputDecoration(
                      labelText: tr(context, 'Discount code'),
                      hintText:
                          tr(context, 'Try LOCAL10: 10% off items, max R 50'))),
              TextButton(
                  onPressed: () {
                    final v = discount.text.trim().toUpperCase();
                    setState(() => code = v == 'LOCAL10' ? v : '');
                    message(
                        context,
                        v.isEmpty
                            ? 'Discount removed'
                            : v == 'LOCAL10'
                                ? 'LOCAL10 applied'
                                : 'Code not recognised. Try LOCAL10.');
                  },
                  child: const AppText('Apply code')),
              moneyRow('Subtotal', t.subtotal),
              moneyRow('Delivery', t.delivery),
              moneyRow('Service fee', t.service),
              moneyRow('Discount', -t.discount),
              const Divider(),
              moneyRow('Total', t.total),
              if (basket.merchant != null)
                AppText(
                    'Minimum items subtotal: ${rand(minimumOrder(basket.merchant!))}'),
              heading('Online payment'),
              DemoPayment(
                  method: method,
                  outcome: outcome,
                  onMethod: (v) => setState(() => method = v),
                  onOutcome: (v) => setState(() => outcome = v)),
              FilledButton(
                  onPressed: busy || basket.count == 0
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          if (schedule && scheduledFor == null) {
                            message(context,
                                'Please choose a delivery date and time');
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
                                scheduledFor: schedule ? scheduledFor : null);
                            if (outcome == 'Successful') {
                              ref.read(basketProvider.notifier).clear();
                            }
                            if (context.mounted) {
                              context.pushReplacement('/orders/$id');
                            }
                          } catch (e) {
                            if (context.mounted) message(context, e);
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  child: AppText(
                      '${tr(context, 'Simulate payment')} · ${rand(t.total)}'))
            ])));
  }

  Future<void> _selectTime() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
        context: context,
        initialDate: calendarInitial(scheduledFor, now),
        firstDate: now,
        lastDate: now.add(const Duration(days: 13)));
    if (selected == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            scheduledFor ?? now.add(const Duration(hours: 1))));
    if (time == null || !mounted) return;
    final candidate = DateTime(
        selected.year, selected.month, selected.day, time.hour, time.minute);
    if (candidate.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      message(context, 'Please choose at least 30 minutes from now');
      return;
    }
    setState(() {
      schedule = true;
      scheduledFor = candidate;
    });
  }
}
