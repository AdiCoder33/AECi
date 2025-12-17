# Aravind E-Logbook (Phase 1B)

Flutter + Supabase app with Google Auth, session restore, mandatory professional profile onboarding, and profile edit.

## Features
- Google OAuth (PKCE) + email/password login/signup (Supabase Auth)
- Mandatory profile capture after first login; enforced routing
- Profile view/edit stored in Supabase `profiles` table
- Session restoration on restart; Riverpod state; GoRouter navigation
- Dark UI with Auth, Create Profile, Profile, and Home screens

## Supabase setup
1) Enable providers: Google and Email/Password (Authentication → Providers).
2) Redirect URLs: add `io.supabase.flutter://login-callback` (Authentication → URL Configuration).
3) Apply schema/RLS: run `supabase/profile_schema.sql` in the SQL editor.

## Mobile redirect configuration
- **Android**: intent-filter for `io.supabase.flutter://login-callback` already in `android/app/src/main/AndroidManifest.xml`. If you change the scheme/host, also update `_redirectUrl` in `lib/features/auth/data/auth_repository.dart`.
- **iOS**: URL scheme `io.supabase.flutter` already in `ios/Runner/Info.plist`. Keep it in sync with your redirect URL.

## Run
```bash
flutter pub get
# Option A: use local env file (preferred, Flutter 3.35+)
flutter run --dart-define-from-file=.env.local

# Option B: inline defines
flutter run --dart-define=SUPABASE_URL=https://zivtybyisftechheizwe.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## App flow
1) Launch → restores Supabase session if present.
2) If not logged in → Auth screen (Google or email/password login/signup).
3) If logged in and no profile → forced Create Profile (cannot back out) → Save upserts to Supabase.
4) If profile exists → Home shows name, designation, centre; navigate to Profile to view/edit.
5) Logout available on Home/Profile/Create screens.
