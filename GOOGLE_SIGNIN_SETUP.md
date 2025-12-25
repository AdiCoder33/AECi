# Google Sign-In Setup Guide

## ✅ What's Already Done

1. ✅ Added `google_sign_in` package to pubspec.yaml
2. ✅ Updated AuthRepository to use native Google Sign-In
3. ✅ App will now show account picker within the app (not Chrome)

## 🔧 Required Configuration Steps

### Step 1: Get Google OAuth Credentials

#### 1.1 Go to Google Cloud Console
- Visit: https://console.cloud.google.com/
- Select your project or create a new one: **"Aravind E-Logbook"**

#### 1.2 Enable Google Sign-In API
1. Go to **APIs & Services** → **Library**
2. Search for **"Google+ API"** or **"Google Sign-In API"**
3. Click **Enable**

#### 1.3 Create OAuth 2.0 Credentials

**For Android:**
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client ID**
3. Select **Android**
4. **Package name**: `com.example.aravind_e_logbook`
5. **SHA-1 certificate fingerprint**: Get it using:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Look for **SHA-1** under `debug` variant
6. Click **Create**
7. **Save the Client ID** (you won't use it directly in code, but keep it)

**For Web (Supabase):**
1. Click **Create Credentials** → **OAuth 2.0 Client ID** again
2. Select **Web application**
3. Name: **"Aravind E-Logbook - Supabase"**
4. **Authorized JavaScript origins**: Add your Supabase project URL:
   ```
   https://<your-project-ref>.supabase.co
   ```
5. **Authorized redirect URIs**: Add:
   ```
   https://<your-project-ref>.supabase.co/auth/v1/callback
   ```
6. Click **Create**
7. **Save the Client ID and Client Secret** - you'll need these for Supabase

### Step 2: Configure Supabase

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your **AECi** project
3. Navigate to **Authentication** → **Providers** (left sidebar)
4. Find **Google** and enable it
5. Enter:
   - **Client ID**: The Web Client ID from Step 1.3
   - **Client Secret**: The Web Client Secret from Step 1.3
6. Click **Save**

### Step 3: Update Android Configuration (Optional - if you get errors)

If you see SHA-1 related errors, you may need to add the OAuth client ID to your Android app:

Create/update `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_web_client_id">YOUR_WEB_CLIENT_ID_HERE</string>
</resources>
```

Replace `YOUR_WEB_CLIENT_ID_HERE` with your **Web Client ID** from Google Cloud Console.

### Step 4: Test the App

1. Run the app:
   ```bash
   flutter run -d 10BF690L9Z000N0 --dart-define-from-file=.env.local
   ```

2. Click **"Continue with Google"**

3. You should see:
   - ✅ Google account picker **within the app** (not Chrome)
   - ✅ Shows all Google accounts on your device
   - ✅ Tap an account to sign in
   - ✅ If no profile exists → Create Profile screen
   - ✅ If profile exists → Home screen

## 🐛 Troubleshooting

### Error: "Sign in failed: 10"
**Solution**: Your SHA-1 certificate fingerprint doesn't match
- Re-run `./gradlew signingReport` in the `android` folder
- Update the SHA-1 in Google Cloud Console

### Error: "Developer Error"
**Solution**: Package name mismatch
- Verify package name is: `com.example.aravind_e_logbook`
- Update in Google Cloud Console if different

### Account picker opens in Chrome instead of in-app
**Solution**: This means native Google Sign-In isn't configured
- Make sure you created the **Android OAuth Client ID** in Google Cloud Console
- Check that SHA-1 certificate is correct

### "Invalid client" error
**Solution**: 
- Make sure you enabled Google provider in Supabase
- Verify Web Client ID and Secret are correct in Supabase

## 📝 Quick Checklist

- [ ] Created Android OAuth Client ID in Google Cloud Console
- [ ] Created Web OAuth Client ID in Google Cloud Console  
- [ ] Added SHA-1 certificate to Android OAuth Client
- [ ] Enabled Google provider in Supabase Authentication
- [ ] Added Web Client ID and Secret to Supabase
- [ ] Ran `flutter pub get`
- [ ] Tested sign-in on device

## 🎯 How It Works Now

1. User taps **"Continue with Google"**
2. Native Android account picker appears
3. User selects account
4. App gets Google ID token
5. Supabase validates token and creates/signs in user
6. App checks if profile exists:
   - **No profile** → Create Profile screen
   - **Has profile** → Home screen

No more Chrome redirects! 🎉
