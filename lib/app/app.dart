import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import 'localization/strings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../features/commerce/language_screen.dart';
import '../features/commerce/deals.dart';
import '../features/discover/discover_screen.dart';
import '../features/discover/history_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/requests/requests_screen.dart';
import '../features/commerce/addresses.dart';
import '../features/commerce/notifications.dart';
import '../features/commerce/support.dart';
import '../features/commerce/storefront.dart';
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

final routerProvider = Provider<GoRouter>((ref) =>
    GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      GoRoute(
          path: '/profile/edit', builder: (c, s) => const EditProfileScreen()),
      GoRoute(
          path: '/order-history',
          builder: (c, s) => Scaffold(
              appBar: AppBar(title: const AppText('Your orders')),
              body: const SafeArea(child: OrdersScreen()))),
      GoRoute(path: '/language', builder: (c, s) => const LanguageScreen()),
      GoRoute(path: '/deals', builder: (c, s) => const DealsScreen()),
      GoRoute(path: '/discover', builder: (c, s) => const DiscoverScreen()),
      GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
      GoRoute(
          path: '/orders/:id',
          builder: (c, s) => OrderDetail(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/request/new/:type',
          builder: (c, s) => RequestForm(
              collection: s.pathParameters['type'] == 'collection')),
      GoRoute(
          path: '/requests/:id',
          builder: (c, s) => RequestDetail(id: s.pathParameters['id']!)),
      GoRoute(path: '/addresses', builder: (c, s) => const AddressesScreen()),
      GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsScreen()),
      GoRoute(
          path: '/support',
          builder: (c, s) =>
              SupportScreen(orderId: s.uri.queryParameters['order'])),
      GoRoute(
          path: '/support/:id',
          builder: (c, s) => TicketDetail(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/shop/:name',
          builder: (c, s) => Storefront(name: s.pathParameters['name']!)),
      GoRoute(
          path: '/account/:page',
          builder: (context, state) =>
              AccountPage(title: state.pathParameters['page']!)),
      GoRoute(
          path: '/explore',
          builder: (context, state) => Scaffold(
              body: SafeArea(
                  child: ExploreScreen(
                      initialCategory:
                          categoryById(state.uri.queryParameters['category'])
                                  ?.name ??
                              'All')))),
      GoRoute(path: '/', builder: (context, state) => const AppShell()),
      GoRoute(
          path: '/checkout',
          builder: (context, state) =>
              CheckoutScreen(initialCode: state.uri.queryParameters['code'])),
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
      locale: Locale(ref.watch(languageProvider)),
      supportedLocales: const [
        Locale('en', 'ZA'),
        Locale('af', 'ZA'),
        Locale('zu', 'ZA')
      ],
      localizationsDelegates: const [
        // ignore: deprecated_member_use
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // ignore: deprecated_member_use
        GlobalCupertinoLocalizations.delegate
      ],
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider));
}
