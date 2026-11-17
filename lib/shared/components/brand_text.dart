// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../app/localization/strings.dart';

/// Keeps the two brand words consistent, including inside longer copy.
class BrandText extends StatelessWidget {
  const BrandText(this.text, {super.key, this.style, this.textAlign});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final translated = tr(context, text);
    final matches =
        RegExp('Gijima Mfana', caseSensitive: false).allMatches(translated);
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in matches) {
      spans.add(TextSpan(text: translated.substring(end, match.start)));
      final words = match.group(0)!.split(' ');
      spans.add(TextSpan(
          text: words.first,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w800)));
      spans.add(TextSpan(
          text: ' ${words.last}',
          style: const TextStyle(
              color: Brand.green, fontWeight: FontWeight.w800)));
      end = match.end;
    }
    spans.add(TextSpan(text: translated.substring(end)));
    return Text.rich(TextSpan(children: spans),
        style: style, textAlign: textAlign);
  }
}
