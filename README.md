# Gijima Mfana

Customer facing Flutter prototype for local Ermelo shopping, personal shopping requests and collection/delivery. All data and payment/delivery interactions are local demonstrations; there are no backend connections, real messages, live GPS, or payment credentials.

## Run

Flutter 3.50.0 (Dart 3.14.0) is installed for this environment at `toolchains/flutter`. Its writable configuration and package cache are in `.config/` and `.pub-cache/`. `scripts/flutterw` runs this SDK with the workspace cache settings. Run:

```sh
scripts/flutterw pub get
dart format .
scripts/flutterw analyze
scripts/flutterw test
scripts/flutterw run -d chrome
scripts/flutterw build web
```

`dart format lib test`, `scripts/flutterw analyze`, `scripts/flutterw test`, and `scripts/publish_web.sh` pass in this environment. The analyzer's workspace scan excludes the bundled SDK and generated build output.

To prepare Vercel's static output, run `scripts/publish_web.sh`; this builds the release Web app and copies it to `public/`. It omits unused local CanvasKit copies because Flutter's loader fetches the engine-revision-pinned renderer from the official Flutter CDN by default. Vercel settings are in `vercel.json`. The Vercel project `gijima-mfana-customer-app` has been created.

## Architecture

- `lib/app`: app entry, GoRouter and Material 3 theme.
- `lib/data/mock`: fictional catalog and local Riverpod basket/favourites state.
- `lib/features`: home, explore, requests, orders, profile, product detail and checkout views.
- `lib/features/shared`: reusable product presentation.

Repository boundaries should be introduced around the current in-memory providers as backend work begins. Keep UI models independent of future transport/database models. No Supabase, Firebase, REST, external payments or location services are included.

## Current prototype coverage

Includes responsive product grids, local category/search filters, favourites, a single-merchant basket with integer-cent totals and confirmation, simulated checkout, request submission and quote confirmation, demo order status/tracking illustration, and profile/help placeholders. Several items in the full product brief remain roadmap work: onboarding/auth flows, full storefronts, quotes and multi-step order persistence, notification centre, address editing, support conversations, richer mock data, and bundled official logo/product photography.

The official logo was supplied as a chat image but was not present as a workspace file. Add the original unmodified artwork under `assets/brand/` and register it in `pubspec.yaml` before shipping. The web scaffold's default Flutter icon assets were removed rather than used as Gijima branding.

## Roadmap

1. Add typed mock repository interfaces, local persistence, full request/quotation and order lifecycle models.
2. Complete onboarding and simulated authentication, notification centre, address management, storefronts and support flows.
3. Add approved local image assets and official logo/splash/icon artwork.
4. Add widget, workflow, accessibility, responsive and navigation tests; verify Android/iOS/Web builds on a Flutter SDK.
5. Replace repository implementations behind the existing UI contracts only after backend requirements and privacy/payment decisions are approved.

## South African visual refresh

The UI now stays in light mode and includes a timed promotional carousel, animated tab changes, Hero product image transitions, bundled South Africa/food/grocery photography, and KFC/McDonald’s demonstration storefronts. Brand-name listings, photos and prices are illustrative and do not indicate affiliation or live availability. Images are bundled from Unsplash (`photo-1576485290814-1c72aa4bbb8e`, `photo-1568901346375-23c9450c58cd`, `photo-1626082927389-6cd097cdc6ec`, `photo-1542838132-92c53300491e`).

Profile routes now open saved addresses (add/delete), favourites, notifications (mark all read), payment preferences, appearance information, privacy information and a local support ticket form. Address and support changes remain in memory for the current screen session. The official logo source file still needs to be supplied; the header uses the app name until it can be bundled unmodified. Full authentication/onboarding and the full original feature list remain roadmap work.

## Official brand artwork

The user-supplied official logo is bundled unchanged at `assets/brand/gijima-mfana.jpg` and `web/logo.jpg`. It appears on Home, Profile, the web loading screen and browser icon. The complete supplied square artwork is preserved with contain sizing. This supersedes earlier notes about the logo being unavailable.
