// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String category = 'All';
  String query = '';
  final categories = [
    'All',
    'Groceries',
    'Restaurants',
    'Fresh produce',
    'Electronics',
    'Beauty',
    'Household'
  ];
  @override
  Widget build(BuildContext context) {
    final visible = products
        .where((p) =>
            (category == 'All' || p.category == category) &&
            ('${p.name} ${p.store}'
                .toLowerCase()
                .contains(query.toLowerCase())))
        .toList();
    return CustomScrollView(slivers: [
      SliverAppBar(
          pinned: true,
          title: const Text('Explore',
              style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(74),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search products and local shops'))))),
      SliverToBoxAdapter(
          child: SizedBox(
              height: 50,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: categories
                      .map((c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                              label: Text(c),
                              selected: category == c,
                              onSelected: (_) => setState(() => category = c))))
                      .toList()))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 105),
          sliver: visible.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                      child: Text('No matches yet. Try another search.')))
              : SliverGrid.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, i) => ProductCard(product: visible[i]),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
                      childAspectRatio: .72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12)))
    ]);
  }
}
