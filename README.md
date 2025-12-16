# Aravind E-Logbook (Phase 1A - Auth MVP)

Minimal Flutter + Supabase app that supports Google sign-in, session restore on restart, and logout with a dark UI.

## Features
- Google OAuth via Supabase Auth (PKCE)
- Session restoration on app launch
- Riverpod state + GoRouter navigation
- Clean dark UI with Auth and Home screens

## Prerequisites
1) Supabase project with Google provider enabled (Authentication → Providers → Google).
2) Add `io.supabase.flutter://login-callback` to **Authentication → URL Configuration → Redirect URLs**.
3) Grab your project URL and anon key (Project Settings → API).

## Mobile redirect configuration
- **Android**: `android/app/src/main/AndroidManifest.xml` already contains an intent-filter for `io.supabase.flutter://login-callback`. If you change the scheme/host, update both the manifest and `AuthRepository._redirectUrl`.
- **iOS**: `ios/Runner/Info.plist` includes the `io.supabase.flutter` URL scheme. Match this to your redirect URL if you customize it.

## Run
```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=your-url \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Flow
1) Launch app → restores existing Supabase session (if any) and routes to Home.
2) Auth screen → tap **Continue with Google** → Supabase OAuth → redirects back to app → Home.
3) Home shows signed-in email + user id; **Logout** signs out and returns to Auth.
