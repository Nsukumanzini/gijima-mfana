import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../data/mock/catalog.dart';

class ProductVisual extends StatelessWidget {
  const ProductVisual(
      {super.key, required this.product, this.width, this.height});
  final ShopProduct product;
  final double? width, height;
  @override
  Widget build(BuildContext context) {
    final hasPhoto = [
      'Restaurants',
      'Groceries',
      'Fresh produce',
      'Bakery',
      'Convenience'
    ].contains(product.category);
    return SizedBox(
        width: width,
        height: height,
        child: hasPhoto
            ? Image.asset(productImage(product),
                fit: BoxFit.cover, semanticLabel: product.name)
            : ColoredBox(
                color: Color(product.color),
                child: Center(
                    child: AppText(product.emoji,
                        semanticsLabel: product.name,
                        style: const TextStyle(fontSize: 52)))));
  }
}
