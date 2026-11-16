// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/catalog.dart';
import '../shared/product_visual.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentlyViewedProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Recently viewed'), actions: [
          TextButton(
              onPressed: recent.isEmpty
                  ? null
                  : () => ref.read(recentlyViewedProvider.notifier).clear(),
              child: const Text('Clear'))
        ]),
        body: recent.isEmpty
            ? const Center(child: Text('Products you view will appear here.'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: recent.map((name) {
                  final p = products.firstWhere((p) => p.name == name);
                  return Card(
                      child: ListTile(
                          leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: ProductVisual(
                                  product: p, width: 56, height: 56)),
                          title: Text(p.name),
                          subtitle: Text(
                              '${p.store} · R ${(p.priceCents / 100).toStringAsFixed(2)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                              '/product/${Uri.encodeComponent(p.name)}')));
                }).toList()));
  }
}
