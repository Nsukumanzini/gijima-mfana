import '../../app/localization/strings.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../../shared/components/glass_surface.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../../data/mock/categories.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesState();
}

class _CategoriesState extends State<CategoriesScreen> {
  final _searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final visible = shopCategories.where((category) {
      final localizedName = tr(context, category.name);
      final localizedDescription = tr(context, category.description);
      final previewNames = products
          .where((product) => product.category == category.name)
          .map((product) => '${product.name} ${product.store}')
          .join(' ');
      return '$localizedName ${category.name} $localizedDescription ${category.description} $previewNames'
          .toLowerCase()
          .contains(normalizedQuery);
    }).toList();
    final suggestions =
        normalizedQuery.isEmpty ? <ShopCategory>[] : visible.take(4).toList();

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: AppText('Categories',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('What are you shopping for?',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const AppText(
                    'Choose a category to find your local favourites.',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Brand.green),
                    hintText: tr(context, 'Search categories'),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: tr(context, 'Clear search'),
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: suggestions
                        .map((category) => ActionChip(
                              avatar: Icon(category.icon,
                                  size: 17, color: Brand.green),
                              label: AppText(category.name),
                              onPressed: () => _chooseSuggestion(category),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: Brand.green.withValues(alpha: .18)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/explore'),
                    icon: const Icon(Icons.grid_view_rounded, size: 19),
                    label: const AppText('Browse all products'),
                    style: TextButton.styleFrom(
                        foregroundColor: Brand.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoCategories(onClear: _clearSearch),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1000
                    ? 4
                    : width >= 680
                        ? 3
                        : width >= 360
                            ? 2
                            : 1;
                return SliverGrid.builder(
                  itemCount: visible.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: width < 360 ? 246 : 258,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final category = visible[index];
                    return _CategoryEntrance(
                      key: ValueKey(category.id),
                      index: index,
                      child: _CategoryCard(
                        category: category,
                        onTap: () =>
                            context.push('/explore?category=${category.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _clearSearch() {
    setState(() {
      query = '';
      _searchController.clear();
    });
  }

  void _chooseSuggestion(ShopCategory category) {
    setState(() {
      query = category.name;
      _searchController.text = category.name;
    });
  }
}

class _CategoryEntrance extends StatefulWidget {
  const _CategoryEntrance(
      {super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_CategoryEntrance> createState() => _CategoryEntranceState();
}

class _CategoryEntranceState extends State<_CategoryEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(Duration(milliseconds: widget.index * 36), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _offset, child: widget.child),
      );
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category, required this.onTap});
  final ShopCategory category;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final samples = products
        .where((product) => product.category == category.name)
        .take(1)
        .toList();
    final count = category.count;

    return AnimatedScale(
      scale: _selected ? .975 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: GlassCard(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: _selected ? 4 : 1,
        shadowColor: Brand.green.withValues(alpha: .14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: BorderSide(
            color: _selected
                ? Brand.green.withValues(alpha: .35)
                : Brand.green.withValues(alpha: .07),
          ),
        ),
        child: InkWell(
          onTap: () async {
            setState(() => _selected = true);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            if (!mounted) return;
            widget.onTap();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryArtwork(category: category),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        category.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        category.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54),
                      ),
                      const Spacer(),
                      if (samples.isNotEmpty)
                        Row(
                          children: [
                            Text(samples.first.emoji,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: AppText(
                                samples.first.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Brand.charcoal,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$count ${tr(context, count == 1 ? 'item' : 'items')}',
                              style: const TextStyle(
                                  color: Brand.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                                color: Brand.mint, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_rounded,
                                size: 15, color: Brand.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryArtwork extends StatelessWidget {
  const _CategoryArtwork({required this.category});
  final ShopCategory category;

  @override
  Widget build(BuildContext context) {
    final imageAsset = category.imageAsset;
    return SizedBox(
      height: 94,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageAsset != null)
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _illustration(),
            )
          else
            _illustration(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .30),
                  Colors.transparent
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 9,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .94),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, size: 19, color: Brand.green),
            ),
          ),
          if (category.isPopular || category.isNew)
            Positioned(
              top: 9,
              right: 9,
              child: _Badge(
                label: category.isPopular ? 'Popular' : 'New',
                icon: category.isPopular
                    ? Icons.local_fire_department_rounded
                    : Icons.auto_awesome_rounded,
              ),
            ),
          if (category.id == 'restaurants')
            Positioned(
              left: 10,
              bottom: 8,
              right: 8,
              child: Text(
                'KFC  ·  McDonald’s  ·  Spur  ·  Steers',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _illustration() => ColoredBox(
        color: Brand.mint,
        child: Center(
          child:
              Text(category.illustration, style: const TextStyle(fontSize: 42)),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: Brand.green),
            const SizedBox(width: 3),
            AppText(label,
                style: const TextStyle(
                    color: Brand.charcoal,
                    fontSize: 9,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class _NoCategories extends StatelessWidget {
  const _NoCategories({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                    color: Brand.mint, shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded,
                    size: 34, color: Brand.green),
              ),
              const SizedBox(height: 14),
              const AppText('No categories match your search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 6),
              const AppText('Try another search or clear it to see everything.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const AppText('Clear search'),
              ),
            ],
          ),
        ),
      );
}
