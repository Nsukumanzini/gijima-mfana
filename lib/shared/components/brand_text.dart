// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Keeps the two brand words consistent, including inside longer copy.
class BrandText extends StatelessWidget {
  const BrandText(this.text, {super.key, this.style, this.textAlign});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final matches =
        RegExp('Gijima Mfana', caseSensitive: false).allMatches(text);
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in matches) {
      spans.add(TextSpan(text: text.substring(end, match.start)));
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
    spans.add(TextSpan(text: text.substring(end)));
    return Text.rich(TextSpan(children: spans),
        style: style, textAlign: textAlign);
  }
}
