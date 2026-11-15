import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            sliver: SliverToBoxAdapter(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Brand.green,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.directions_run,
                            color: Colors.white)),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('DELIVERING TO',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.3,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                          Text('Ermelo · Home',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold))
                        ])),
                    IconButton(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('You’re all caught up'))),
                        icon: const Icon(Icons.notifications_none))
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'What are you looking for?')),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Brand.green,
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Your town, at your door.',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            const Text('Shop local in Ermelo',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Local shops are ready to explore'))),
                              style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Brand.green),
                              child: const Text('Explore shops'),
                            ),
                          ])),
                      const Text('🛍️', style: TextStyle(fontSize: 58)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('How can we help?',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _service(context, 'Shop', 'Browse local stores',
                        Icons.storefront_outlined),
                    const SizedBox(width: 10),
                    _service(context, 'Personal shop',
                        'Find something specific', Icons.shopping_bag_outlined),
                    const SizedBox(width: 10),
                    _service(context, 'Collect & deliver',
                        'Send an order or parcel', Icons.delivery_dining)
                  ]),
                  const SizedBox(height: 22),
                  const Row(children: [
                    Expanded(
                        child: Text('Popular near you',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800))),
                    Text('See all →',
                        style: TextStyle(
                            color: Brand.green, fontWeight: FontWeight.bold))
                  ]),
                ]))),
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            sliver: SliverLayoutBuilder(builder: (context, c) {
              final wide = c.crossAxisExtent > 700;
              return SliverGrid.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) =>
                      ProductCard(product: products[i]),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: wide ? 4 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 0.82 : 0.72));
            }))
      ]);
  Widget _service(BuildContext c, String title, String sub, IconData icon) =>
      Expanded(
          child: InkWell(
              onTap: () => ScaffoldMessenger.of(c)
                  .showSnackBar(SnackBar(content: Text('$title coming up'))),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Brand.mint,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: Brand.green),
                        const Spacer(),
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54))
                      ]))));
}
