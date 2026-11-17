import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../data/mock/catalog.dart';
import '../../data/mock/categories.dart';
import '../shared/product_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialCategory = 'All'});
  final String initialCategory;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String category = 'All';
  String query = '';
  final searchController = TextEditingController();
  final categories = ['All', ...shopCategories.map((c) => c.name)];
  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = products
        .where((p) =>
            (category == 'All' || p.category == category) &&
            ('${p.name} ${p.store} ${p.category} ${tr(context, p.category)}'
                .toLowerCase()
                .contains(query.toLowerCase())))
        .toList();
    return CustomScrollView(slivers: [
      SliverAppBar(
          pinned: true,
          title: AppText(category == 'All' ? 'Explore categories' : category,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(74),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: TextField(
                      controller: searchController,
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: tr(
                              context, 'Search products and local shops')))))),
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
                              label: AppText(
                                  '${tr(context, c)} (${c == 'All' ? products.length : products.where((p) => p.category == c).length})'),
                              selected: category == c,
                              onSelected: (_) => setState(() => category = c))))
                      .toList()))),
      SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: AppText(
                  '${visible.length} results${category == 'All' ? '' : ' in $category'}',
                  style: const TextStyle(fontWeight: FontWeight.w700)))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 105),
          sliver: visible.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.search_off, size: 42),
                  const SizedBox(height: 12),
                  const AppText('No items match your search in this category.'),
                  TextButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          query = '';
                          category = 'All';
                        });
                      },
                      child: const AppText('Clear filters'))
                ])))
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
