// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'catalog.dart';

class ShopCategory {
  const ShopCategory(this.id, this.name, this.icon, this.description);
  final String id, name, description;
  final IconData icon;
  int get count => products.where((p) => p.category == name).length;
}

const shopCategories = [
  ShopCategory('groceries', 'Groceries', Icons.shopping_basket_outlined,
      'Everyday pantry favourites'),
  ShopCategory('restaurants', 'Restaurants', Icons.restaurant_outlined,
      'Meals, burgers & chicken'),
  ShopCategory('fresh-produce', 'Fresh produce', Icons.eco_outlined,
      'Fruit & vegetables'),
  ShopCategory('bakery', 'Bakery', Icons.bakery_dining_outlined,
      'Fresh bread & baked treats'),
  ShopCategory('convenience', 'Convenience',
      Icons.local_convenience_store_outlined, 'Quick snacks & essentials'),
  ShopCategory('electronics', 'Electronics', Icons.headphones_outlined,
      'Useful tech & accessories'),
  ShopCategory(
      'fashion', 'Fashion', Icons.checkroom_outlined, 'Everyday clothing'),
  ShopCategory(
      'beauty', 'Beauty', Icons.spa_outlined, 'Personal care favourites'),
  ShopCategory('household', 'Household', Icons.chair_outlined,
      'Essentials for your home'),
  ShopCategory('stationery', 'Stationery', Icons.edit_note_outlined,
      'School & office supplies'),
];

ShopCategory? categoryById(String? id) {
  for (final c in shopCategories) {
    if (c.id == id) return c;
  }
  return null;
}
