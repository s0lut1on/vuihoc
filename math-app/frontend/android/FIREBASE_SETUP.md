# Android Firebase / Google Sign-In Setup

The app uses `firebase_core`, `firebase_auth`, and `google_sign_in`. On Android these require a Firebase project and `google-services.json`.

## 1. Create / open Firebase project

Go to https://console.firebase.google.com/ and create a project (or use an existing one).

## 2. Register Android app

In Project settings → Your apps → Add app → Android:
- **Android package name**: `com.sekklings.hocvui`
- **App nickname**: `HocVui`
- **SHA-1**: get it from the release keystore:
  ```bash
  cd math-app/frontend/android
  keytool -list -v -keystore release.keystore -alias mathapp | grep SHA1
  ```
  (keystore password: `mathapp2025`)

If you don't have a keystore yet, generate one:
```bash
keytool -genkey -v -keystore release.keystore -alias mathapp \
  -keyalg RSA -keysize 2048 -validity 10000
```

## 3. Download `google-services.json`

After registering the app, download `google-services.json` and place it at:

```
math-app/frontend/android/app/google-services.json
```

## 4. Enable Google Sign-In provider

In Firebase Console → Authentication → Sign-in method → **Google** → Enable → select support email.

## 5. Get web client ID

The backend verifies the Google `idToken`. For that, you need the **Web client ID** from Firebase/Google Cloud:

- Firebase Console → Project settings → Your apps → Web app
- Or Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs

Copy the web client ID (looks like `123456789-abcdef.apps.googleusercontent.com`).

## 6. Build with the web client ID

```bash
cd math-app/frontend
flutter build apk --release \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID \
  --dart-define=APP_VERSION=$(git rev-parse --short HEAD)
```

## 7. Apply the Google Services plugin

Uncomment this line in `android/app/build.gradle`:

```gradle
id "com.google.gms.google-services"
```

Then rebuild.

## Notes

- `google_sign_in` on Android reads the Android client ID from `google-services.json` automatically.
- The `serverClientId` in `auth_service.dart` is set from the `GOOGLE_CLIENT_ID` dart-define so the plugin returns an `idToken` usable by the backend.
- If testing on Waydroid, make sure the container has internet (`sudo ufw disable` if needed).
