# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

Flutter (Dart SDK ^3.13.2) shipping to iPhone first; Android builds from the same
codebase and inherits the iOS-first design language. iPad is not a stated target.
Confirmed by the user, not inferred from the repo (which contains both `ios/` and
`android/` runners).

## Users

Two authenticated roles share one app, separated by role-based routing after OTP login:

- **Customer** — a UAE resident who needs laundry collected from home and returned
  clean. Reaches the app on their own phone, usually one-handed, often deciding a
  pickup slot in a spare minute. Their job: get items collected, know where the
  order stands, pay the invoice, receive items back.
- **Driver** — a courier working a shift, using the app outdoors, in a vehicle, in
  sunlight, frequently with one hand while carrying bags. Their job: see today's
  pickups and deliveries, navigate to the address, reach the customer, confirm a
  pickup or delivery, collect cash when owed, and report a failure when it happens.

Staff/facility operators are explicitly **not** app users: `staffMustUsePortal`
routes them to a web Admin Portal that does not exist yet.

Primary language is **English (LTR)**, with Arabic (RTL) as a fully supported
locale chosen on first run and switchable from Account. Both locales ship complete
ARB catalogs today; no string may be hard-coded.

## Product Purpose

A laundry pickup-and-delivery service: the customer books a collection window, a
driver collects the items, the facility inspects and prices them, the customer pays,
and a driver returns the items in a delivery window. Success is an order that moves
from booked to delivered without the customer having to ask anyone where it is, and
a driver who can complete a stop without leaving the app.

## Positioning

Price is set **after** physical inspection at the facility, never estimated at
booking. The app deliberately shows no price during the order wizard, and the
`Invoice` entity only exists once the laundry has counted the items. Two service
tiers (Standard and VIP) differ by turnaround hours, which in turn filter the
delivery slots offered — the level the customer picks is a promise about time,
not about an estimate.

## Operating Context

- **Auth:** phone (UAE format `5X XXX XXXX`) + 4-digit OTP, then profile completion
  with a first pickup address. Session expiry on 401 sends the user back to login
  with an explanation.
- **Customer flow:** Home → 4-step order wizard (what to clean → service type →
  service level → pickup & delivery slots) → confirmation → tracking timeline →
  invoice → payment (bank card via external browser, or cash on delivery) → delivered.
- **Driver flow:** today's tasks split into Pickup and Delivery tabs → task detail
  with map, call/message, and navigation hand-off → confirm pickup (items are
  counted at the laundry, not on the doorstep) → hand over to laundry; or confirm
  delivery, collecting cash first when the invoice is unpaid, with an optional
  proof-of-delivery photo. Either stop can be reported as failed with a reason.
- **Order lifecycle:** `pending → driverAssigned → pickedUp → atFacility →
  awaitingPayment → processing → outForDelivery → delivered`, plus the terminal
  states `pickupFailed`, `deliveryFailed`, `cancelled`.
- **Backend:** currently a mock data layer (`core/mock/mock_database.dart`) behind
  repository interfaces, with `dio`-backed remote data sources already written.
  The facility-side transitions that a real Admin Portal and Auto-Dispatch would
  drive are simulated so the app demos end to end.

## Capabilities and Constraints

- **Architecture:** clean architecture — `domain` (entities, repositories,
  use cases) / `data` (models, data sources, repository impls) / `presentation`
  (cubits, pages, widgets), wired with `get_it`; state via `flutter_bloc` cubits;
  routing via `go_router` with a refresh listenable driven by `SessionCubit`.
- **Dependencies in play:** `dio`, `equatable`, `flutter_secure_storage`,
  `shared_preferences`, `intl`, `url_launcher`, `go_router`, `flutter_bloc`,
  `get_it`. No image, animation, or design-system package is present today.
- **Localization:** `flutter_localizations` + generated `AppLocalizations` from
  `lib/l10n/app_en.arb` / `app_ar.arb`. Every user-facing string is a key.
- **Currency:** AED, formatted through the `currencyAed` key.
- **Assets:** the project has **no** `assets/` directory, no bundled fonts, and no
  imagery. The brand mark is drawn in code (`CustomPainter`). Any new asset or font
  must be added deliberately and declared in `pubspec.yaml`.
- **Maps:** no map SDK is integrated — `map_placeholder.dart` is a stand-in and
  navigation hands off to the system Maps app via `url_launcher`.
- **Not built yet:** Admin Portal, auto-dispatch, push notifications, real payments
  (card payment opens an external browser), address geocoding.

## Brand Commitments

None binding. The user has explicitly released the incumbent identity — the ink /
teal / gold palette in `core/theme/app_colors.dart`, the painted rhombus-with-drop
logo in `core/widgets/app_logo.dart`, and the current component shapes — for
replacement. The product name in-app is the localized `appName` ("Laundry" /
"غسيل") with tagline "Wash, iron & delivery to your door"; no legal name, logo
file, or trademark asset has been supplied.

## Evidence on Hand

- Real, complete bilingual copy for every screen (`lib/l10n/app_en.arb`,
  `lib/l10n/app_ar.arb`) — use it rather than inventing labels.
- Realistic seeded content in `lib/core/mock/mock_database.dart` (service
  categories, sub-services, tiers, slots, orders, invoices, driver tasks).
- **No** real customer testimonials, ratings, photography, partner logos, press,
  pricing tables, or usage statistics exist. None may be fabricated in UI.

## Product Principles

1. **No price before inspection.** The UI never estimates, implies, or previews a
   total before the facility issues the invoice.
2. **State is always answerable.** At any moment the customer can see where the
   order is and what happens next without contacting support.
3. **The driver's screen is a working surface.** Outdoor legibility, one-handed
   reach, and unmistakable confirm actions outrank expression on every driver screen.
4. **Both locales are first-class.** Nothing may look like a translation
   afterthought in Arabic; layout is direction-agnostic by construction.
5. **Irreversible actions are guarded.** Confirming pickup, confirming delivery,
   collecting cash, and reporting a failure each state their consequence before
   they commit.

## Accessibility & Inclusion

No formal standard has been mandated by the user. Product-specific needs that are
nonetheless binding: iOS Dynamic Type must not break layouts (both roles include
older customers and drivers working in poor light); every tappable control meets
44×44 pt; Dark Mode is a first-class appearance; RTL mirroring must be complete;
and driver confirm/fail actions must be distinguishable without relying on color alone.
