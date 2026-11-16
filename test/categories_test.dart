// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gijima_mfana/features/explore/explore_screen.dart';
import 'package:gijima_mfana/data/mock/categories.dart';
import 'package:gijima_mfana/data/mock/catalog.dart';

void main() {
  test('every product belongs to a category with a stable unique ID', () {
    expect(shopCategories.map((c) => c.id).toSet().length, shopCategories.length);
    for (final p in products) {
      expect(shopCategories.where((c) => c.name == p.category).length, 1);
    }
  });
  testWidgets('category selection filters results and search can be reset', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: ExploreScreen(initialCategory: 'Restaurants')))));
    expect(find.text('Streetwise chicken meal'), findsOneWidget);
    expect(find.text('Farm fresh eggs'), findsNothing);
    await tester.enterText(find.byType(TextField), 'no matching meal');
    await tester.pumpAndSettle();
    expect(find.text('No items match your search in this category.'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Explore categories'), findsOneWidget);
    expect(find.text('${products.length} results'), findsOneWidget);
  });
}
