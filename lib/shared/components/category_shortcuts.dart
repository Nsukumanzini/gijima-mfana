// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/categories.dart';
import '../../app/theme/app_theme.dart';

class CategoryShortcuts extends StatelessWidget {
  const CategoryShortcuts({super.key});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('Shop by category',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
          TextButton(
              onPressed: () => context.push('/explore'),
              child: const Text('See all'))
        ]),
        const Text(
            'Find exactly what you need, from meals to everyday essentials.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        LayoutBuilder(
            builder: (context, constraints) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: shopCategories
                    .map((c) => SizedBox(
                          width: (constraints.maxWidth -
                                  (constraints.maxWidth > 700 ? 40 : 20)) /
                              (constraints.maxWidth > 700 ? 5 : 3),
                          child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () =>
                                      context.push('/explore?category=${c.id}'),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 5),
                                      child: Column(children: [
                                        CircleAvatar(
                                            backgroundColor: Brand.mint,
                                            foregroundColor: Brand.green,
                                            radius: 24,
                                            child: Icon(c.icon)),
                                        const SizedBox(height: 9),
                                        Text(c.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12),
                                            textAlign: TextAlign.center),
                                        Text('${c.count} items',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54)),
                                      ])))),
                        ))
                    .toList())),
        const SizedBox(height: 26),
      ]);
}
