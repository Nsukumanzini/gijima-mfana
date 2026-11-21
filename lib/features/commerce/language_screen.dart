// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/localization/strings.dart';
import '../../app/theme/app_theme.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageProvider);
    final selectedName = languageNames[code]!;
    return Scaffold(
      appBar: AppBar(title: const AppText('Language')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Brand.mint, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.translate_rounded, color: Brand.green)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const AppText('Choose your preferred language',
                          style: TextStyle(
                              color: Brand.charcoal,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const AppText('Your choice is saved on this device.',
                          style: TextStyle(color: Colors.black54)),
                    ])),
              ]),
            ),
            const SizedBox(height: 17),
            const AppText('Available languages',
                style: TextStyle(
                    color: Brand.charcoal,
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: code,
              onChanged: (value) {
                if (value != null) {
                  ref.read(languageProvider.notifier).state = value;
                }
              },
              child: Column(
                children: languageNames.entries.map((entry) {
                  final selected = entry.key == code;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                        color: selected ? Brand.mint : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: selected
                                ? Brand.green.withValues(alpha: .45)
                                : Brand.charcoal.withValues(alpha: .1))),
                    child: RadioListTile<String>(
                      value: entry.key,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      title: Text(entry.value,
                          style: TextStyle(
                              color: Brand.charcoal,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700)),
                      secondary: selected
                          ? const AppText('Selected',
                              style: TextStyle(
                                  color: Brand.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800))
                          : const Icon(Icons.language_outlined,
                              color: Brand.green),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: Brand.green, size: 19),
                        const SizedBox(width: 8),
                        Expanded(
                            child: AppText('Language preview',
                                style: const TextStyle(
                                    color: Brand.charcoal,
                                    fontWeight: FontWeight.w900))),
                        Text(selectedName,
                            style: const TextStyle(
                                color: Brand.green,
                                fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 9),
                      const AppText('Sample language preview',
                          style:
                              TextStyle(color: Brand.charcoal, fontSize: 16)),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
