# laundry_app

The Flutter app for customers and drivers. Product context is in `../PRODUCT.md`,
and the backend is `../laundry_admin`.

## Run

```bash
flutter run                                    # in-memory mock backend (default)
flutter run --dart-define=USE_MOCK_API=false \
            --dart-define=API_BASE_URL=http://10.0.2.2:3000   # against laundry_admin
```

## Tests

```bash
flutter test                                              # offline suite
LAUNDRY_API_URL=http://localhost:3000 flutter test test/api_live   # live API
```

## Push notifications (Firebase)

Push stays off until Firebase is configured, and the app runs normally without it.
To turn it on:

1. Create a Firebase project. Then add the apps, with `dart pub global activate flutterfire_cli`
   and `flutterfire configure` from this folder. This adds
   `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`, and applies the
   Google Services Gradle plugin.
2. **iOS:**
   - Upload an APNs authentication key in Firebase console → Project settings → Cloud Messaging.
   - In Xcode, add the **Push Notifications** capability to the Runner target.
   - `UIBackgroundModes` → `remote-notification` is already set in `Info.plist`.
3. **Server:** give `laundry_admin` the service-account key as `FIREBASE_SERVICE_ACCOUNT_JSON`.
   See its `.env.example`.

How it works:

- After sign-in, the app registers its token with `POST /api/me/devices`, and removes it on sign-out.
- Customers follow their laundry's `vendor-<id>` topic, so price edits refresh the open shop.
- The code is in `lib/core/push/push_service.dart` and `lib/core/sync/refresh_bus.dart`.
