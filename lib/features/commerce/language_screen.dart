// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/localization/strings.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageProvider);
    return Scaffold(
        appBar: AppBar(title: AppText('Language')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          AppText('Choose your preferred language'),
          const SizedBox(height: 12),
          RadioGroup<String>(
              groupValue: code,
              onChanged: (v) {
                if (v != null) ref.read(languageProvider.notifier).state = v;
              },
              child: Column(
                  children: languageNames.entries
                      .map((e) => RadioListTile<String>(
                          value: e.key, title: Text(e.value)))
                      .toList())),
          const SizedBox(height: 12),
          AppText('Your choice is saved on this device.')
        ]));
  }
}
