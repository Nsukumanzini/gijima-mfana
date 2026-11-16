import '../features/explore/explore_screen.dart';
import '../data/mock/categories.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import '../features/shell/shell.dart';
import '../features/checkout/checkout.dart';
import '../features/product/product_detail.dart';
import '../data/mock/catalog.dart';
import '../features/profile/account_pages.dart';

final routerProvider =
    Provider<GoRouter>((ref) => GoRouter(initialLocation: '/', routes: [
          GoRoute(
              path: '/account/:page',
              builder: (context, state) =>
                  AccountPage(title: state.pathParameters['page']!)),
          GoRoute(
              path: '/explore',
              builder: (context, state) => Scaffold(
                  body: SafeArea(
                      child: ExploreScreen(
                          initialCategory: categoryById(
                                      state.uri.queryParameters['category'])
                                  ?.name ??
                              'All')))),
          GoRoute(path: '/', builder: (context, state) => const AppShell()),
          GoRoute(
              path: '/checkout',
              builder: (context, state) => const CheckoutScreen()),
          GoRoute(
              path: '/product/:name',
              builder: (context, state) {
                final name = Uri.decodeComponent(state.pathParameters['name']!);
                return ProductDetail(
                    product: products.firstWhere((p) => p.name == name));
              }),
        ]));

class GijimaApp extends ConsumerWidget {
  const GijimaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
      title: 'Gijima Mfana',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider));
}
