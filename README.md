# Gijima Mfana

Flutter customer prototype for local shopping, personal shopping, and collection/delivery in Ermelo and Wesselton. All orders, quotes, payments, courier updates, support conversations and refunds are simulated on the device. No backend, payment credentials, live GPS, external messages or merchant connections are used. KFC/McDonald’s and all catalogue prices, addresses, hours and ratings are demonstration listings; no affiliation or real availability is implied.

## Run and verify

This environment has Flutter 3.50.0 / Dart 3.14.0 under `toolchains/flutter`. Its config/cache directories are `.config` and `.pub-cache`. The wrapper configures them automatically:

```sh
scripts/flutterw pub get
toolchains/flutter/bin/dart format lib test
scripts/flutterw analyze
scripts/flutterw test
scripts/flutterw run -d chrome
scripts/publish_web.sh
```

For a normal local installation use `flutter` instead of `scripts/flutterw`. The SDK is not committed. Only Web platform scaffolding is currently included; generate Android/iOS runners with Flutter when preparing those builds. `scripts/publish_web.sh` produces `public/` for the static Vercel project `gijima-mfana-customer-app`. Flutter uses its engine-pinned official CDN renderer by default; unused local renderer files are omitted. Local demo data is scoped to the browser/device and site origin. Clearing site storage removes it; private browser settings can restrict persistence. Save failures show an in-app warning.

## Connected customer flows

1. **Orders and tracking:** checkout produces a saved order with item/address snapshots, integer-cent fees, payment state and a timeline. Orders filters cover active, completed, cancelled and request-based deliveries. Advance demo statuses from order details to move the illustrative courier map and generate notifications. No real location is used. Early orders can be cancelled; paid cancellations can request a simulated refund through support.
2. **Personal shopping:** request name, description, quantity, preferred shop, item budget, urgency, instructions and a saved address. Use the clearly labelled simulation controls to move Submitted → Under review → Quotation received. Accept or reject the itemised quote; successful simulated payment creates one linked tracked order. The quoted item amount covers the complete requested quantity and is within the supplied item budget.
3. **Collect & deliver:** enter collection business/address/town, reference, item/quantity, recipient, future collection time, handling notes and a delivery address. Review the R 45 delivery + R 5 service quotation before acceptance/payment. Item purchase cost is zero because it is an existing order/parcel. A paid request becomes a courier delivery order.
4. **Saved addresses:** add/edit/delete locations, select the default, and check demo coverage. Outside-area addresses can be saved but cannot be checked out. Existing order/request address snapshots survive later edits/deletion.
5. **Storefronts:** business address, hours, rating, availability, delivery estimate/fee, minimum order, promotion, search/category filters, product links, and saved businesses. Access from Home shop shortcuts or product details.
6. **Basket and checkout:** one shop per basket, quantity changes/removal, per-item instructions, delivery notes, saved address selection, minimums and coverage validation. `LOCAL10` discounts item subtotal by 10%, capped at R 50. Fees and final totals are shown before payment. Outcomes are Successful, Pending, Failed or Cancelled. Successful checkout clears the basket; pending/failed orders can resolve/retry payment in order details. No real payment information is collected.
7. **Notifications:** locally generated order/payment, quote/request and support updates with unread badge, mark-all-read, and direct links to their originating records.
8. **Order support:** report missing/damaged items or delivery problems, request a refund or create a general enquiry. Tickets keep local replies and simulated support review/resolution. Paid orders can receive one simulated refund; no actual money moves. Refund approval appears in the related order.

Baskets/item notes, product/business favourites, addresses/default, payment-method preference, requests/quotes, orders/payment statuses, notifications/read status and support tickets are saved locally. All save operations serialize through the preferences adapter.

## Architecture

- `lib/app`: Material 3 light theme, routes and shared branding.
- `lib/data/mock`: fictional product/category catalogue and basket/favourite providers.
- `lib/data/repositories/local_store.dart`: `LocalStore` interface, SharedPreferences adapter and memory test adapter.
- `lib/data/repositories/commerce.dart`: local commerce state and guarded domain transitions. A versioned JSON document stores linked orders, requests, addresses, notifications and tickets. Orders snapshot prices and addresses so historical totals cannot change with catalogue/address edits.
- `lib/features`: customer screens organised by feature; `commerce/` supplies address, notification, support and storefront screens plus shared form/payment controls.
- `lib/shared/components`: reusable two-colour wordmark and category shortcuts.

## Checks

Tests cover basket calculations/single merchant, catalogue category membership and filtering, discount/fee calculations, delivery coverage/default addresses, snapshot integrity, payment retries/cancellation/delivery, quotation acceptance/rejection and idempotent conversion, collection quotes, support/refund transitions, notification routing/read state, preferences restoration, and connected screens at 360px and 1280px widths. The checkout widget test follows payment through order creation and notification navigation.

## Artwork

Transparent courier PNG: `assets/brand/courier.png` / `web/logo.png`. The original supplied complete logo remains in `assets/brand/gijima-mfana.jpg` for reference. “Gijima” is black and “Mfana” emerald green via `BrandText`. Photos are bundled from Unsplash (`photo-1576485290814-1c72aa4bbb8e`, `photo-1568901346375-23c9450c58cd`, `photo-1626082927389-6cd097cdc6ec`, `photo-1542838132-92c53300491e`) and are illustrative.

## Future integration

Authentication/onboarding is deferred at the user's request. Before real service launch, replace local transition methods with authenticated server-authoritative commerce APIs; introduce immutable typed transport/domain records and migration handling; enforce pricing/stock/coverage on the server; integrate approved payment/refund processing and courier dispatch; validate genuine merchant details and legal terms. The current application intentionally has no such integrations.
