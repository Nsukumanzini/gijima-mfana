// ignore: deprecated_member_use
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 100});
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/brand/gijima-mfana.jpg',
          width: size,
          height: size,
          fit: BoxFit.contain,
          semanticLabel: 'Gijima Mfana official logo');
}
