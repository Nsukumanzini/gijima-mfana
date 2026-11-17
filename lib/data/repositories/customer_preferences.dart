import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_store.dart';

final customerNameProvider = StateProvider<String>((ref) {
  final saved =
      ref.read(localStoreProvider).read('customer-profile.v1')?['name'];
  // ignore: deprecated_member_use
  ref.listenSelf(
      (previous, next) => persist(ref, 'customer-profile.v1', {'name': next}));
  return saved is String && saved.trim().isNotEmpty ? saved : 'Sihle Mokoena';
});

class CustomerSettings {
  const CustomerSettings(
      {this.orders = true, this.requests = true, this.support = true});
  final bool orders, requests, support;
  CustomerSettings copyWith({bool? orders, bool? requests, bool? support}) =>
      CustomerSettings(
          orders: orders ?? this.orders,
          requests: requests ?? this.requests,
          support: support ?? this.support);
  Map<String, dynamic> toJson() =>
      {'orders': orders, 'requests': requests, 'support': support};
  bool allows(String route) => route.startsWith('/orders/')
      ? orders
      : route.startsWith('/requests/')
          ? requests
          : route.startsWith('/support/')
              ? support
              : true;
}

final customerSettingsProvider =
    NotifierProvider<CustomerSettingsController, CustomerSettings>(
        CustomerSettingsController.new);

class CustomerSettingsController extends Notifier<CustomerSettings> {
  @override
  CustomerSettings build() {
    final saved =
        ref.read(localStoreProvider).read('customer-settings.v1') ?? {};
    return CustomerSettings(
        orders: saved['orders'] != false,
        requests: saved['requests'] != false,
        support: saved['support'] != false);
  }

  void update({bool? orders, bool? requests, bool? support}) {
    state =
        state.copyWith(orders: orders, requests: requests, support: support);
    persist(ref, 'customer-settings.v1', state.toJson());
  }
}
