import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/commerce.dart';
import '../../data/repositories/local_store.dart';

DateTime calendarInitial(DateTime? preferred, DateTime now) {
  if (preferred == null) return now;
  final day = DateUtils.dateOnly(preferred);
  final first = DateUtils.dateOnly(now);
  final last = DateUtils.dateOnly(now.add(const Duration(days: 13)));
  return day.isBefore(first) || day.isAfter(last) ? now : preferred;
}

Widget heading(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: AppText(text,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)));
Widget moneyRow(String label, int cents) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: AppText(label)),
      AppText(rand(cents), style: const TextStyle(fontWeight: FontWeight.w700))
    ]));
void message(BuildContext context, Object text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: AppText(text.toString().replaceFirst('Bad state: ', ''))));
String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Please complete this field' : null;
Widget input(TextEditingController controller, String label,
        {int lines = 1,
        TextInputType? keyboard,
        String? Function(String?)? validate}) =>
    Builder(
        builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
                controller: controller,
                maxLines: lines,
                keyboardType: keyboard,
                validator: (v) {
                  final error = (validate ?? requiredText)(v);
                  return error == null ? null : tr(context, error);
                },
                decoration: InputDecoration(labelText: tr(context, label)))));
Widget addressPicker(BuildContext context, WidgetRef ref, String? value,
    ValueChanged<String?> onChange) {
  final data = ref.watch(commerceProvider);
  return DropdownButtonFormField<String>(
      key: ValueKey('$value-${data.addresses.length}'),
      initialValue: data.addresses.any((a) => a['id'] == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: tr(context, 'Delivery address')),
      items: data.addresses
          .map((a) => DropdownMenuItem<String>(
              value: a['id'] as String,
              child: AppText(
                  '${addressText(a)}${covered(a) ? '' : ' · Outside coverage'}',
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChange,
      validator: (v) => v == null
          ? tr(context, 'Add and choose a delivery address')
          : covered(data.address(v)!)
              ? null
              : tr(context,
                  'Delivery is available in Ermelo and Wesselton only'));
}

class DemoPayment extends StatelessWidget {
  const DemoPayment(
      {super.key,
      required this.method,
      required this.outcome,
      required this.onMethod,
      required this.onOutcome});
  final String method, outcome;
  final ValueChanged<String> onMethod, onOutcome;
  @override
  Widget build(BuildContext context) => Column(children: [
        DropdownButtonFormField<String>(
            initialValue: method,
            decoration: InputDecoration(
                labelText: tr(context, 'Online payment method')),
            items: ['Card', 'Instant EFT', 'Digital wallet']
                .map((m) => DropdownMenuItem(value: m, child: AppText(m)))
                .toList(),
            onChanged: (v) => onMethod(v!)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            initialValue: outcome,
            decoration: InputDecoration(
                labelText: tr(context, 'Simulated payment outcome')),
            items: ['Successful', 'Pending', 'Failed', 'Cancelled']
                .map((m) => DropdownMenuItem(value: m, child: AppText(m)))
                .toList(),
            onChanged: (v) => onOutcome(v!)),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: AppText(
                'Demo payments only. No card numbers, bank details or real money.'))
      ]);
}

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog(
      {super.key, this.allowSchedule = false, this.initialScheduled});
  final bool allowSchedule;
  final DateTime? initialScheduled;
  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String method = 'Card', outcome = 'Successful';
  bool scheduled = false;
  DateTime? scheduledFor;
  @override
  void initState() {
    super.initState();
    method = ref.read(preferredPaymentProvider);
    scheduledFor = widget.initialScheduled?.toLocal();
    scheduled = scheduledFor != null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const AppText('Simulate online payment'),
          content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                DemoPayment(
                    method: method,
                    outcome: outcome,
                    onMethod: (v) => setState(() => method = v),
                    onOutcome: (v) => setState(() => outcome = v)),
                if (widget.allowSchedule) ...[
                  SwitchListTile(
                      value: scheduled,
                      onChanged: (v) => setState(() => scheduled = v),
                      title: const AppText('Schedule delivery')),
                  if (scheduled)
                    TextButton.icon(
                        onPressed: _pickScheduledTime,
                        icon: const Icon(Icons.schedule),
                        label: AppText(scheduledFor == null
                            ? 'Choose delivery date and time'
                            : '${MaterialLocalizations.of(context).formatFullDate(scheduledFor!)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(scheduledFor!))}')),
                ],
              ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const AppText('Back')),
            FilledButton(
                onPressed: () {
                  if (scheduled && scheduledFor == null) {
                    message(context, 'Please choose a delivery date and time');
                    return;
                  }
                  Navigator.pop(context, {
                    'method': method,
                    'outcome': outcome,
                    if (scheduled && scheduledFor != null)
                      'scheduledFor': scheduledFor!.toIso8601String()
                  });
                },
                child: const AppText('Simulate payment'))
          ]);
  Future<void> _pickScheduledTime() async {
    final now = DateTime.now();
    final day = await showDatePicker(
        context: context,
        initialDate: calendarInitial(scheduledFor, now),
        firstDate: now,
        lastDate: now.add(const Duration(days: 13)));
    if (day == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            scheduledFor ?? now.add(const Duration(hours: 1))));
    if (time == null || !mounted) return;
    final chosen =
        DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (chosen.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      message(context, 'Please choose at least 30 minutes from now');
      return;
    }
    setState(() => scheduledFor = chosen);
  }
}
