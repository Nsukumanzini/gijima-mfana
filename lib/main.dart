// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositories/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocalStore store;
  try {
    store = PreferencesStore(await SharedPreferences.getInstance());
  } catch (_) {
    store = MemoryStore();
  }
  runApp(ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const GijimaApp()));
}
