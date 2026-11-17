import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/categories.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesState();
}

class _CategoriesState extends State<CategoriesScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final visible = shopCategories
        .where((c) => '${c.name} ${tr(context, c.name)} ${c.description}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    return CustomScrollView(slivers: [
      const SliverAppBar(
          pinned: true,
          title: AppText('Categories',
              style: TextStyle(fontWeight: FontWeight.w800))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          sliver: SliverToBoxAdapter(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const AppText('What are you shopping for?',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const AppText(
                    'Choose a category to find your local favourites.',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 18),
                TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: tr(context, 'Search categories'))),
                const SizedBox(height: 12),
                TextButton.icon(
                    onPressed: () => context.push('/explore'),
                    icon: const Icon(Icons.grid_view_outlined),
                    label: const AppText('Browse all products')),
              ]))),
      if (visible.isEmpty)
        const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
                child:
                    AppText('No categories match. Try meals, fresh or home.')))
      else
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverGrid.builder(
              itemCount: visible.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 200,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12),
              itemBuilder: (context, i) {
                final c = visible[i];
                return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        onTap: () => context.push('/explore?category=${c.id}'),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                      backgroundColor: Brand.mint,
                                      foregroundColor: Brand.green,
                                      child: Icon(c.icon)),
                                  const SizedBox(height: 12),
                                  AppText(c.name,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  AppText(c.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54)),
                                  const Spacer(),
                                  AppText('${c.count} items  →',
                                      style: const TextStyle(
                                          color: Brand.green,
                                          fontWeight: FontWeight.w600)),
                                ]))));
              },
            )),
    ]);
  }
}
