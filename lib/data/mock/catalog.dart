import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShopProduct {
  const ShopProduct(this.name, this.store, this.priceCents, this.category,
      this.emoji, this.color, this.rating);
  final String name, store, category, emoji;
  final int priceCents;
  final int color;
  final double rating;
}

const products = <ShopProduct>[
  ShopProduct('Farm fresh eggs', 'Highveld Farm Store', 4599, 'Groceries', '🥚',
      0xFFFFF2D8, 4.9),
  ShopProduct('Sourdough loaf', 'The Daily Crumb', 3899, 'Bakery', '🍞',
      0xFFF8E5CF, 4.8),
  ShopProduct('Market fruit box', 'Ermelo Fresh Market', 8999, 'Fresh produce',
      '🍊', 0xFFFFE6D9, 4.7),
  ShopProduct('Streetwise chicken meal', 'KFC', 12900, 'Restaurants', '🍗',
      0xFFFFE5D5, 4.9),
  ShopProduct('Burger & chips', 'McDonald’s', 8990, 'Restaurants', '🍔',
      0xFFE5E9F3, 4.6),
  ShopProduct(
      'Hand cream set', 'Bloom Beauty', 15900, 'Beauty', '🧴', 0xFFF4E3EF, 4.8),
  ShopProduct('Household starter kit', 'Corner Basket', 7499, 'Household', '🧺',
      0xFFE4F0E9, 4.5),
  ShopProduct('Local honey 500g', 'Highveld Farm Store', 6999, 'Groceries',
      '🍯', 0xFFFFE9B8, 4.9),
  ShopProduct('USB-C charging cable', 'Tech Corner Ermelo', 7990, 'Electronics',
      '🔌', 0xFFE5E9F3, 4.6),
  ShopProduct('Plain cotton T-shirt', 'Highveld Clothing', 14999, 'Fashion',
      '👕', 0xFFE4F0E9, 4.7),
  ShopProduct('A4 exercise books · 5 pack', 'Ermelo Paper & Pen', 5999,
      'Stationery', '📚', 0xFFFFF2D8, 4.8),
  ShopProduct('Chips & cooldrink combo', 'Corner Basket', 3599, 'Convenience',
      '🥤', 0xFFFFE6D9, 4.6),
];

class BasketLine {
  const BasketLine(this.product, this.quantity);
  final ShopProduct product;
  final int quantity;
}

class BasketState {
  const BasketState(this.lines, this.merchant);
  final Map<String, int> lines;
  final String? merchant;
  int get count => lines.values.fold(0, (a, b) => a + b);
  int get subtotal => lines.entries.fold(
      0,
      (a, e) =>
          a + products.firstWhere((p) => p.name == e.key).priceCents * e.value);
}

class BasketController extends Notifier<BasketState> {
  @override
  BasketState build() => const BasketState({}, null);
  bool add(ShopProduct p) {
    if (state.merchant != null && state.merchant != p.store) return false;
    final next = Map<String, int>.from(state.lines)
      ..update(p.name, (n) => n + 1, ifAbsent: () => 1);
    state = BasketState(next, p.store);
    return true;
  }

  void quantity(String name, int n) {
    final next = Map<String, int>.from(state.lines);
    if (n <= 0) {
      next.remove(name);
    } else {
      next[name] = n;
    }
    state = BasketState(next, next.isEmpty ? null : state.merchant);
  }

  void clear() => state = const BasketState({}, null);
}

final basketProvider =
    NotifierProvider<BasketController, BasketState>(BasketController.new);
final favoritesProvider = StateProvider<Set<String>>((ref) => <String>{});

String productImage(ShopProduct p) => p.store == 'KFC'
    ? 'assets/images/chicken.jpg'
    : p.store == 'McDonald’s'
        ? 'assets/images/burger.jpg'
        : 'assets/images/groceries.jpg';
