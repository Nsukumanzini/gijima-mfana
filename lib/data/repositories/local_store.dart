import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStore {
  Map<String, dynamic>? read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
}

class MemoryStore implements LocalStore {
  final Map<String, String> values = {};
  @override
  Map<String, dynamic>? read(String key) => values[key] == null
      ? null
      : jsonDecode(values[key]!) as Map<String, dynamic>;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    values[key] = jsonEncode(value);
  }
}

class PreferencesStore implements LocalStore {
  PreferencesStore(this.preferences);
  final SharedPreferences preferences;
  Future<void> _pending = Future.value();
  @override
  Map<String, dynamic>? read(String key) {
    try {
      final raw = preferences.getString(key);
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) {
    final encoded = jsonEncode(value);
    _pending = _pending.catchError((Object _) {}).then((_) async {
      if (!await preferences.setString(key, encoded)) {
        throw StateError('Could not save this device’s demo data');
      }
    });
    return _pending;
  }
}

final localStoreProvider = Provider<LocalStore>((ref) => MemoryStore());
final saveErrorProvider = StateProvider<String?>((ref) => null);
void persist(Ref ref, String key, Map<String, dynamic> value) {
  var active = true;
  ref.onDispose(() => active = false);
  ref.read(localStoreProvider).write(key, value).then((_) {
    if (!active) return;
    ref.read(saveErrorProvider.notifier).state = null;
  }).catchError((Object _) {
    if (!active) return;
    ref.read(saveErrorProvider.notifier).state =
        'Changes are in memory, but device storage is unavailable. Keep this page open.';
  });
}

final preferredPaymentProvider = StateProvider<String>((ref) {
  final saved = ref
      .read(localStoreProvider)
      .read('payment-preference.v1')?['method'] as String?;
  // ignore: deprecated_member_use
  ref.listenSelf((previous, next) =>
      persist(ref, 'payment-preference.v1', {'method': next}));
  return ['Card', 'Instant EFT', 'Digital wallet'].contains(saved)
      ? saved!
      : 'Card';
});
