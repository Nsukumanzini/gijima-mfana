import 'customer_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_store.dart';
import '../mock/catalog.dart';

typedef Record = Map<String, dynamic>;
String rand(int cents) => 'R ${(cents / 100).toStringAsFixed(2)}';
const orderSteps = [
  'Order placed',
  'Payment confirmed',
  'Merchant preparing order',
  'Courier assigned',
  'Courier collecting order',
  'Out for delivery',
  'Delivered'
];
const shoppingSteps = [
  'Order placed',
  'Payment confirmed',
  'Courier assigned',
  'Item purchased',
  'Out for delivery',
  'Delivered'
];
const collectionSteps = [
  'Order placed',
  'Payment confirmed',
  'Courier assigned',
  'Courier collecting order',
  'Out for delivery',
  'Delivered'
];
List<String> stepsFor(Record o) => o['type'] == 'Personal shopping'
    ? shoppingSteps
    : o['type'] == 'Collect & deliver'
        ? collectionSteps
        : orderSteps;
bool covered(Record a) => ['ermelo', 'wesselton']
    .contains((a['city'] as String? ?? '').trim().toLowerCase());
String addressText(Record a) {
  final street = [
    a['unit'],
    a['building'],
    a['street'],
  ]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(', ');
  final area = [
    a['suburb'],
    a['city'],
    a['province'],
  ]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(', ');
  final postal = (a['postal'] as String? ?? '').trim();
  final location = [area, postal].where((part) => part.isNotEmpty).join(' ');
  return '${a['label']} · ${[
    street,
    location
  ].where((part) => part.isNotEmpty).join(', ')}';
}

int deliveryFee(String merchant) =>
    merchant == 'KFC' || merchant == 'McDonald’s' ? 2990 : 2500;
int minimumOrder(String merchant) =>
    merchant == 'KFC' || merchant == 'McDonald’s' ? 5000 : 3000;

class Totals {
  Totals(this.subtotal, this.delivery, this.service, this.discount);
  final int subtotal, delivery, service, discount;
  int get total => subtotal + delivery + service - discount;
}

Totals basketTotals(BasketState basket, String code) => Totals(
    basket.subtotal,
    basket.count == 0 ? 0 : deliveryFee(basket.merchant!),
    basket.count == 0 ? 0 : 500,
    code.trim().toUpperCase() == 'LOCAL10'
        ? (basket.subtotal * 10 ~/ 100).clamp(0, 5000)
        : 0);

class DemoState {
  DemoState(
      {required this.addresses,
      required this.orders,
      required this.requests,
      required this.notifications,
      required this.tickets,
      required this.savedShops});
  final List<Record> addresses, orders, requests, notifications, tickets;
  final List<String> savedShops;
  factory DemoState.fromJson(Record j) => DemoState(
      addresses: _records(j['addresses']),
      orders: _records(j['orders']),
      requests: _records(j['requests']),
      notifications: _records(j['notifications']),
      tickets: _records(j['tickets']),
      savedShops: List<String>.from(j['savedShops'] ?? []));
  Record toJson() => {
        'addresses': addresses,
        'orders': orders,
        'requests': requests,
        'notifications': notifications,
        'tickets': tickets,
        'savedShops': savedShops
      };
  static List<Record> _records(dynamic raw) => (raw as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  Record? address(String? id) {
    for (final a in addresses) {
      if (a['id'] == id) return a;
    }
    return null;
  }

  Record? get defaultAddress {
    for (final a in addresses) {
      if (a['default'] == true) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }
}

class CommerceController extends Notifier<DemoState> {
  @override
  DemoState build() =>
      DemoState.fromJson(ref.read(localStoreProvider).read('commerce.v1') ??
          {
            'addresses': [
              {
                'id': 'home',
                'label': 'Home',
                'street': '12 Acacia Street',
                'building': 'Acacia Place',
                'suburb': 'Central Ermelo',
                'city': 'Ermelo',
                'province': 'Mpumalanga',
                'postal': '2351',
                'pinLabel': 'Town centre',
                'default': true
              },
              {
                'id': 'work',
                'label': 'Work',
                'street': '8 Church Street',
                'building': 'Church Office Park',
                'suburb': 'Ermelo CBD',
                'city': 'Ermelo',
                'province': 'Mpumalanga',
                'postal': '2351',
                'pinLabel': 'Near my street',
                'default': false
              },
            ]
          });
  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  void _commit(Record j) {
    state = DemoState.fromJson(j);
    persist(ref, 'commerce.v1', j);
  }

  void _list(String key, List<Record> records) {
    _commit({...state.toJson(), key: records});
  }

  Record? find(String list, String id) {
    for (final r in state.toJson()[list] as List) {
      if (r['id'] == id) return Map<String, dynamic>.from(r);
    }
    return null;
  }

  void _patch(String list, String id, Record patch) {
    _list(list, [
      for (final r in state.toJson()[list] as List)
        r['id'] == id ? {...r, ...patch} : Map<String, dynamic>.from(r)
    ]);
  }

  void notify(String text, String route) {
    if (!ref.read(customerSettingsProvider).allows(route)) return;
    _list('notifications', [
      {
        'id': _id('N'),
        'text': text,
        'route': route,
        'read': false,
        'time': DateTime.now().toIso8601String()
      },
      ...state.notifications
    ]);
  }

  void readNotification(String id) =>
      _patch('notifications', id, {'read': true});
  void readAll() => _list('notifications', [
        for (final n in state.notifications) {...n, 'read': true}
      ]);
  void saveAddress(Record a) {
    if ((a['street'] as String? ?? '').trim().isEmpty) {
      throw StateError('A street address is required');
    }
    final id = a['id'] ?? _id('A');
    final isDefault = a['default'] == true || state.addresses.isEmpty;
    _list('addresses', [
      for (final old in state.addresses)
        if (old['id'] != id) {...old, if (isDefault) 'default': false},
      {...a, 'id': id, 'default': isDefault}
    ]);
  }

  void deleteAddress(String id) {
    final remaining =
        state.addresses.where((a) => a['id'] != id).map((a) => {...a}).toList();
    if (remaining.isNotEmpty && !remaining.any((a) => a['default'] == true)) {
      remaining.first['default'] = true;
    }
    _list('addresses', remaining);
  }

  void defaultAddress(String id) => _list('addresses', [
        for (final a in state.addresses) {...a, 'default': a['id'] == id}
      ]);
  void toggleShop(String shop) {
    final next = [...state.savedShops];
    next.contains(shop) ? next.remove(shop) : next.add(shop);
    _commit({...state.toJson(), 'savedShops': next});
  }

  String checkout(
      {required BasketState basket,
      required String addressId,
      required String note,
      required String code,
      required String method,
      required String outcome,
      DateTime? scheduledFor}) {
    if (scheduledFor != null &&
        (scheduledFor
                .isBefore(DateTime.now().add(const Duration(minutes: 30))) ||
            scheduledFor
                .isAfter(DateTime.now().add(const Duration(days: 14))))) {
      throw StateError('Please choose a time 30 minutes to 14 days from now');
    }
    if (basket.count == 0) throw StateError('Your basket is empty');
    final address = state.address(addressId);
    if (address == null || !covered(address)) {
      throw StateError('Choose an address in Ermelo or Wesselton');
    }
    if (basket.subtotal < minimumOrder(basket.merchant!)) {
      throw StateError(
          'Minimum order is ${rand(minimumOrder(basket.merchant!))}');
    }
    final t = basketTotals(basket, code);
    final id = _id('GM');
    final order = {
      'id': id,
      'type': 'Shop',
      'merchant': basket.merchant,
      'address': {...address},
      'note': note,
      'scheduledFor': scheduledFor?.toUtc().toIso8601String(),
      'items': [
        for (final e in basket.lines.entries)
          {
            'name': e.key,
            'quantity': e.value,
            'price': products.firstWhere((p) => p.name == e.key).priceCents,
            'note': basket.notes[e.key] ?? ''
          }
      ],
      'subtotal': t.subtotal,
      'delivery': t.delivery,
      'service': t.service,
      'discount': t.discount,
      'total': t.total,
      'method': method,
      'payment': outcome,
      'step': outcome == 'Successful' ? 1 : 0,
      'cancelled': outcome == 'Cancelled',
      'created': DateTime.now().toIso8601String()
    };
    _list('orders', [order, ...state.orders]);
    notify('Order $id · Payment $outcome', '/orders/$id');
    return id;
  }

  void retryPayment(String id, String outcome, {String? method}) {
    final o = find('orders', id);
    if (o == null || o['payment'] == 'Successful' || o['cancelled'] == true) {
      return;
    }
    _patch('orders', id, {
      'payment': outcome,
      if (method != null) 'method': method,
      'step': outcome == 'Successful' ? 1 : 0,
      'cancelled': outcome == 'Cancelled'
    });
    notify('Payment $outcome · $id', '/orders/$id');
  }

  void advanceOrder(String id) {
    final o = find('orders', id);
    if (o == null || o['cancelled'] == true || o['payment'] != 'Successful') {
      return;
    }
    final steps = stepsFor(o);
    final next = (o['step'] as int) + 1;
    if (next >= steps.length) return;
    _patch('orders', id, {'step': next});
    notify('${steps[next]} · $id', '/orders/$id');
    if (o['requestId'] != null) {
      _patch('requests', o['requestId'] as String, {'status': steps[next]});
    }
  }

  void cancelOrder(String id) {
    final o = find('orders', id);
    if (o == null || (o['step'] as int) >= 2 || o['cancelled'] == true) return;
    _patch('orders', id, {'cancelled': true});
    if (o['requestId'] != null) {
      _patch('requests', o['requestId'] as String, {'status': 'Cancelled'});
    }
    notify(
        'Order cancelled · $id. Any paid demo amount can be reviewed through support.',
        '/orders/$id');
  }

  String submitRequest(Record fields) {
    final qty = fields['quantity'];
    if (qty is! int || qty < 1 || qty > 100) {
      throw StateError('Quantity must be from 1 to 100');
    }
    if ((fields['name'] as String? ?? '').trim().isEmpty ||
        (fields['business'] as String? ?? '').trim().isEmpty) {
      throw StateError('Item and business details are required');
    }
    if (fields['type'] == 'Personal shopping' &&
        (fields['budget'] is! int || (fields['budget'] as int) < 1)) {
      throw StateError('An item budget is required');
    }
    if (fields['type'] == 'Collect & deliver') {
      if ((fields['collection'] as String? ?? '').trim().isEmpty ||
          (fields['reference'] as String? ?? '').trim().isEmpty ||
          (fields['recipient'] as String? ?? '').trim().isEmpty) {
        throw StateError(
            'Collection, reference and recipient details are required');
      }
      final when = DateTime.tryParse(fields['collectionTime'] as String? ?? '');
      if (when == null || when.isBefore(DateTime.now())) {
        throw StateError('Choose a future collection time');
      }
    }

    final address = state.address(fields['addressId'] as String?);
    if (address == null || !covered(address)) {
      throw StateError('Choose a covered delivery address');
    }
    final id = _id('REQ');
    final collection = fields['type'] == 'Collect & deliver';
    _list('requests', [
      {
        ...fields,
        'id': id,
        'address': {...address},
        'status': collection ? 'Quotation received' : 'Submitted',
        'itemPrice': collection ? 0 : 0,
        'delivery': collection ? 4500 : 2990,
        'service': collection ? 500 : 1000,
        'payment': 'Not paid',
        'created': DateTime.now().toIso8601String()
      },
      ...state.requests
    ]);
    notify(
        collection
            ? 'Delivery quotation ready · $id'
            : 'Personal shopping request received · $id',
        '/requests/$id');
    return id;
  }

  void removeRequestPhoto(String id) {
    final r = find('requests', id);
    if (r == null) return;
    _list('requests', [
      for (final item in state.requests)
        if (item['id'] == id)
          (Map<String, dynamic>.from(item)..remove('photoBase64'))
        else
          item
    ]);
  }

  void review(String id) {
    final r = find('requests', id);
    if (r == null) return;
    if (r['status'] == 'Submitted') {
      _patch('requests', id, {'status': 'Under review'});
      notify('Request under review · $id', '/requests/$id');
    } else if (r['status'] == 'Under review') {
      _patch('requests', id, {
        'status': 'Quotation received',
        'itemPrice': ((r['budget'] as int) * 9 ~/ 10).clamp(1, 10000000)
      });
      notify('Quotation ready · $id', '/requests/$id');
    }
  }

  void quoteDecision(String id, bool accept) {
    final r = find('requests', id);
    if (r == null || r['status'] != 'Quotation received') return;
    _patch('requests', id,
        {'status': accept ? 'Quote accepted' : 'Quote rejected'});
    notify('Quote ${accept ? 'accepted' : 'rejected'} · $id', '/requests/$id');
  }

  String? payRequest(String id, String method, String outcome,
      {DateTime? scheduledFor}) {
    final r = find('requests', id);
    if (r == null || r['orderId'] != null || r['status'] != 'Quote accepted') {
      return r?['orderId'] as String?;
    }
    if (scheduledFor != null) {
      final now = DateTime.now();
      if (scheduledFor.isBefore(now.add(const Duration(minutes: 30))) ||
          scheduledFor.isAfter(now.add(const Duration(days: 14)))) {
        throw StateError('Please choose a time 30 minutes to 14 days from now');
      }
      if (r['type'] == 'Collect & deliver' &&
          r['collectionTime'] is String &&
          scheduledFor
              .isBefore(DateTime.parse(r['collectionTime'] as String))) {
        throw StateError(
            'Delivery must be after the preferred collection time');
      }
    }
    _patch('requests', id, {
      'payment': outcome,
      'scheduledFor': scheduledFor?.toUtc().toIso8601String()
    });
    if (outcome != 'Successful') {
      notify('Request payment $outcome · $id', '/requests/$id');
      return null;
    }
    final oid = _id('GM');
    final total = (r['itemPrice'] as int) +
        (r['delivery'] as int) +
        (r['service'] as int);
    _list('orders', [
      {
        'id': oid,
        'requestId': id,
        'type': r['type'],
        'merchant': r['business'],
        'address': r['address'],
        'collection': r['collection'],
        'reference': r['reference'],
        'recipient': r['recipient'],
        'collectionTime': r['collectionTime'],
        'scheduledFor': scheduledFor?.toUtc().toIso8601String(),
        'note': r['instructions'],
        'items': [
          {
            'name': r['name'],
            'quantity': r['quantity'],
            'price': r['itemPrice'],
            'note': r['description']
          }
        ],
        'subtotal': r['itemPrice'],
        'delivery': r['delivery'],
        'service': r['service'],
        'discount': 0,
        'total': total,
        'method': method,
        'payment': 'Successful',
        'step': 1,
        'cancelled': false,
        'created': DateTime.now().toIso8601String()
      },
      ...state.orders
    ]);
    _patch('requests', id, {'status': 'Payment confirmed', 'orderId': oid});
    notify('Payment confirmed · Courier allocation pending · $oid',
        '/orders/$oid');
    return oid;
  }

  String support(String orderId, String kind, String description) {
    if (description.trim().length < 5) {
      throw StateError('Please describe the issue');
    }
    if (orderId.isNotEmpty && find('orders', orderId) == null) {
      throw StateError('Order not found');
    }
    if (kind == 'Refund request') {
      final order = find('orders', orderId);
      if (order == null || order['payment'] != 'Successful') {
        throw StateError('Only successfully paid demo orders can be refunded');
      }
      if (order['refund'] == 'Approved' ||
          state.tickets.any((t) =>
              t['orderId'] == orderId &&
              t['kind'] == 'Refund request' &&
              t['status'] != 'Resolved')) {
        throw StateError(
            'A refund has already been requested or approved for this order');
      }
    }
    final id = _id('T');
    _list('tickets', [
      {
        'id': id,
        'orderId': orderId,
        'kind': kind,
        'status': 'Open',
        'refund': 'Not reviewed',
        'messages': [
          {'sender': 'You', 'text': description},
          {
            'sender': 'Support',
            'text':
                'Thanks. Your demo ticket has been received. Use the simulation below to review it.'
          }
        ]
      },
      ...state.tickets
    ]);
    notify('Support ticket received · $id', '/support/$id');
    return id;
  }

  void reply(String id, String text) {
    final t = find('tickets', id);
    if (t == null || text.trim().isEmpty || t['status'] == 'Resolved') return;
    _patch('tickets', id, {
      'messages': [
        ...t['messages'] as List,
        {'sender': 'You', 'text': text}
      ]
    });
  }

  void reviewTicket(String id) {
    final t = find('tickets', id);
    if (t == null || t['status'] == 'Resolved') return;
    final resolved = t['status'] == 'Under review';
    if (resolved && t['kind'] == 'Refund request') {
      _patch('orders', t['orderId'] as String, {'refund': 'Approved'});
    }
    _patch('tickets', id, {
      'status': resolved ? 'Resolved' : 'Under review',
      'refund': t['kind'] == 'Refund request'
          ? (resolved ? 'Simulated refund approved' : 'Under review')
          : 'Not applicable',
      'messages': [
        ...t['messages'] as List,
        {
          'sender': 'Support',
          'text': resolved
              ? 'Your demo issue is resolved.${t['kind'] == 'Refund request' ? ' A simulated refund has been approved; no money moves.' : ''}'
              : 'We are reviewing your order and issue.'
        }
      ]
    });
    notify('Support ${resolved ? 'resolved' : 'under review'} · $id',
        '/support/$id');
  }
}

final commerceProvider =
    NotifierProvider<CommerceController, DemoState>(CommerceController.new);
