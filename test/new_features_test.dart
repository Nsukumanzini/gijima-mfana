import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gijima_mfana/app/app.dart';
import 'package:gijima_mfana/app/localization/strings.dart';
import 'package:gijima_mfana/data/mock/catalog.dart';
import 'package:gijima_mfana/data/repositories/commerce.dart';
import 'package:gijima_mfana/data/repositories/local_store.dart';

class FakePicker extends FilePicker {
  FakePicker(this.file);
  PlatformFile file;
  @override
  Future<FilePickerResult?> pickFiles(
          {String? dialogTitle,
          String? initialDirectory,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          Function(FilePickerStatus)? onFileLoading,
          bool allowCompression = false,
          int compressionQuality = 0,
          bool allowMultiple = false,
          bool withData = false,
          bool withReadStream = false,
          bool lockParentWindow = false,
          bool readSequential = false}) async =>
      FilePickerResult([file]);
}

void main() {
  test(
      'scheduled orders and request delivery times persist and reject invalid times',
      () async {
    final store = MemoryStore();
    final c = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    final repo = c.read(commerceProvider.notifier);
    final basket = BasketState({products.first.name: 2}, products.first.store);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(
        () => repo.checkout(
            basket: basket,
            addressId: 'home',
            note: '',
            code: '',
            method: 'Card',
            outcome: 'Successful',
            scheduledFor: DateTime.now().subtract(const Duration(minutes: 1))),
        throwsStateError);
    final id = repo.checkout(
        basket: basket,
        addressId: 'home',
        note: '',
        code: 'LOCAL10',
        method: 'Card',
        outcome: 'Successful',
        scheduledFor: tomorrow);
    expect(DateTime.parse(repo.find('orders', id)!['scheduledFor'] as String),
        tomorrow.toUtc());
    final pickup = DateTime.now().add(const Duration(hours: 3));
    final req = repo.submitRequest({
      'type': 'Collect & deliver',
      'name': 'Parcel',
      'description': 'Small',
      'quantity': 1,
      'budget': 0,
      'business': 'Shop',
      'collection': '1 Main St, Ermelo',
      'reference': 'Demo-1',
      'recipient': 'Demo recipient',
      'collectionTime': pickup.toIso8601String(),
      'instructions': '',
      'addressId': 'home'
    });
    repo.quoteDecision(req, true);
    expect(
        () => repo.payRequest(req, 'Card', 'Successful',
            scheduledFor: pickup.subtract(const Duration(hours: 1))),
        throwsStateError);
    expect(repo.payRequest(req, 'Card', 'Pending', scheduledFor: tomorrow),
        isNull);
    expect(
        DateTime.parse(repo.find('requests', req)!['scheduledFor'] as String),
        tomorrow.toUtc());
    final linked =
        repo.payRequest(req, 'Card', 'Successful', scheduledFor: tomorrow)!;
    await store.write('flush', {});
    c.dispose();
    final second = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(second.dispose);
    expect(
        DateTime.parse(second
            .read(commerceProvider.notifier)
            .find('orders', linked)!['scheduledFor'] as String),
        tomorrow.toUtc());
  });
  testWidgets(
      'language selector updates primary navigation and persists selection',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryStore();
    final c = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(c.dispose);
    c.read(routerProvider).go('/language');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const GijimaApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Afrikaans'));
    await tester.pumpAndSettle();
    expect(find.text('Taal'), findsOneWidget);
    c.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    expect(find.text('Tuis'), findsOneWidget);
    expect(find.text('Kategorieë'), findsOneWidget);
    c.read(routerProvider).go('/language');
    await tester.pumpAndSettle();
    await tester.tap(find.text('isiZulu'));
    await tester.pumpAndSettle();
    expect(find.text('Ulimi'), findsOneWidget);
    c.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    expect(find.text('Ekhaya'), findsOneWidget);
    expect(find.text('Izigaba'), findsOneWidget);
    expect(find.text('Izicelo'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'igrosa');
    await tester.pumpAndSettle();
    expect(find.text('Farm fresh eggs'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    c.read(basketProvider.notifier).add(products.first);
    c.read(basketProvider.notifier).add(products.first);
    c.read(routerProvider).go('/checkout');
    await tester.pumpAndSettle();
    expect(find.text('Isikhathi sokulethwa'), findsOneWidget);
    expect(find.text('Ikheli lokulethwa'), findsWidgets);
    expect(
        Localizations.localeOf(
                    tester.element(find.text('Isikhathi sokulethwa')))
                .languageCode ==
            'zu',
        isTrue);
    c.read(routerProvider).go('/request/new/shopping');
    await tester.pumpAndSettle();
    expect(find.text('Igama lomkhiqizo'), findsOneWidget);

    await store.write('flush', {});
    final restored = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    expect(restored.read(languageProvider), 'zu');
    restored.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('deal applies LOCAL10 to checkout without extra discount',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final b = c.read(basketProvider.notifier);
    b.add(products.first);
    b.add(products.first);
    c.read(routerProvider).go('/deals');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const GijimaApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply at checkout'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('R -9.19'), 350,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('R -9.19'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'personal shopping photo is validated, stored, restored and removable',
      (tester) async {
    final bytes =
        Uint8List.fromList(File('assets/images/chicken.jpg').readAsBytesSync());
    final fake = FakePicker(
        PlatformFile(name: 'demo.jpg', size: bytes.length, bytes: bytes));
    FilePicker? old;
    try {
      old = FilePicker.platform;
    } catch (_) {}
    FilePicker.platform = fake;
    addTearDown(() {
      if (old != null) FilePicker.platform = old;
    });
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryStore();
    final container = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    container.read(routerProvider).go('/request/new/shopping');
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const GijimaApp()));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'), 'Green school bag');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Description and requirements'),
        'Green fabric bag');
    await tester.enterText(
        find.widgetWithText(
            TextFormField, 'Preferred business / shopping location'),
        'Ermelo shop');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Maximum item budget (R)'), '120');
    await tester.scrollUntilVisible(
        find.text('Add reference photo (optional)'), 250,
        scrollable: find.byType(Scrollable).first);
    fake.file = PlatformFile(
        name: 'large.jpg',
        size: 1024 * 1024 + 1,
        bytes: Uint8List(1024 * 1024 + 1));
    await tester.tap(find.text('Add reference photo (optional)'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a JPEG, PNG or WebP image no larger than 1 MB.'),
        findsOneWidget);
    fake.file =
        PlatformFile(name: 'demo.jpg', size: bytes.length, bytes: bytes);
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Add reference photo (optional)'));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Submit shopping request'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Submit shopping request'));
    await tester.pumpAndSettle();
    final req = container.read(commerceProvider).requests.first;
    expect(base64Decode(req['photoBase64'] as String), bytes);
    await store.write('flush', {});
    final restored = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    expect(restored.read(commerceProvider).requests.first['photoBase64'],
        req['photoBase64']);
    restored.dispose();
    await tester.scrollUntilVisible(find.text('Remove saved photo'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Remove saved photo'));
    await tester.pumpAndSettle();
    expect(
        container
            .read(commerceProvider)
            .requests
            .first
            .containsKey('photoBase64'),
        false);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('checkout lets the customer pick a future delivery date and time',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final b = c.read(basketProvider.notifier);
    b.add(products.first);
    b.add(products.first);
    c.read(routerProvider).go('/checkout');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const GijimaApp()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Schedule delivery'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Schedule delivery'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Choose delivery date and time'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Choose delivery date and time'));
    await tester.pumpAndSettle();
    final now = DateTime.now(), tomorrow = now.add(const Duration(days: 1));
    if (now.month != tomorrow.month || now.year != tomorrow.year) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${tomorrow.day}').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.textContaining('Simulate payment ·'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.textContaining('Simulate payment ·'));
    await tester.pumpAndSettle();
    final scheduled = DateTime.parse(
            c.read(commerceProvider).orders.single['scheduledFor'] as String)
        .toLocal();
    expect(scheduled.year, tomorrow.year);
    expect(scheduled.month, tomorrow.month);
    expect(scheduled.day, tomorrow.day);
    await tester.pumpWidget(const SizedBox());
  });
}
