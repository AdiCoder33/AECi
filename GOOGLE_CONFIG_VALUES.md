# Google Sign-In Configuration Details

## 📋 Your Project Information

### Package Name
```
com.example.aravind_e_logbook
```

### SHA-1 Fingerprints

#### Debug Build (For Testing)
```
SHA-1: 0E:78:4E:D6:AB:93:34:89:97:8A:1D:67:31:5C:09:94:1A:C3:D0:24
SHA-256: 2B:F6:CD:5D:38:51:20:9B:8B:04:27:11:02:91:46:C8:C7:A2:99:5A:81:EE:C2:F0:E8:BC:59:99:C2:D5:9A:21
```

#### Production Build (For Release)
**Note**: Currently using debug keystore. For production, you'll need to:
1. Generate a release keystore
2. Configure it in `android/app/build.gradle.kts`
3. Run `./gradlew signingReport` again to get production SHA-1

---

## 🔧 Step-by-Step Configuration

### Step 1: Create Google Cloud Project

1. Go to: https://console.cloud.google.com/
2. Click **Select a project** → **NEW PROJECT**
3. Project name: `Aravind E-Logbook`
4. Click **CREATE**

### Step 2: Enable Google Sign-In API

1. In your Google Cloud project, go to **APIs & Services** → **Library**
2. Search for: `Google Sign-In API` or `Google+ API`
3. Click **ENABLE**

### Step 3: Create Android OAuth Client ID

1. Go to **APIs & Services** → **Credentials**
2. Click **CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
3. Click **CONFIGURE CONSENT SCREEN** (if prompted)
   - Select **External**
   - Click **CREATE**
   - Fill in:
     - App name: `Aravind E-Logbook`
     - User support email: Your email
     - Developer contact: Your email
   - Click **SAVE AND CONTINUE** (skip optional fields)
4. Now create the Android credential:
   - Application type: **Android**
   - Name: `Aravind E-Logbook - Android`
   - Package name: `com.example.aravind_e_logbook`
   - SHA-1 certificate fingerprint: `0E:78:4E:D6:AB:93:34:89:97:8A:1D:67:31:5C:09:94:1A:C3:D0:24`
5. Click **CREATE**
6. You'll see a dialog - click **OK** (no need to download)

### Step 4: Create Web OAuth Client ID (for Supabase)

1. Still in **Credentials**, click **CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
2. Application type: **Web application**
3. Name: `Aravind E-Logbook - Web (Supabase)`
4. **Authorized JavaScript origins**: Add your Supabase URL:
   ```
   https://YOUR_PROJECT_ID.supabase.co
   ```
   (Replace YOUR_PROJECT_ID with your actual Supabase project ID)

5. **Authorized redirect URIs**: Add:
   ```
   https://YOUR_PROJECT_ID.supabase.co/auth/v1/callback
   ```

6. Click **CREATE**
7. **COPY AND SAVE**:
   - ✅ **Client ID** (looks like: 123456789-abcdef.apps.googleusercontent.com)
   - ✅ **Client Secret** (looks like: GOCSPX-xxxxxxxxxxxxx)

### Step 5: Configure Supabase

1. Go to: https://supabase.com/dashboard
2. Select your **AECi** project
3. Navigate to: **Authentication** → **Providers**
4. Find **Google** and click to expand
5. Toggle **Enable Sign in with Google** to ON
6. Fill in:
   - **Client ID (for OAuth)**: Paste the Web Client ID from Step 4
   - **Client Secret (for OAuth)**: Paste the Web Client Secret from Step 4
7. Click **Save**

### Step 6: Update Supabase Redirect URLs

1. In Supabase, go to: **Authentication** → **URL Configuration**
2. Make sure you have:
   - **Site URL**: `io.supabase.flutter://login-callback`
   - **Redirect URLs**:
     ```
     io.supabase.flutter://login-callback
     io.supabase.flutter://reset-callback
     io.supabase.flutter://**
     ```

---

## ✅ Verification Checklist

- [ ] Created Google Cloud Project
- [ ] Enabled Google Sign-In API
- [ ] Created Android OAuth Client ID with correct SHA-1
- [ ] Created Web OAuth Client ID
- [ ] Configured Supabase with Web Client ID and Secret
- [ ] Updated Supabase redirect URLs

---

## 🎯 Test It!

Run your app:
```bash
flutter run -d 10BF690L9Z000N0 --dart-define-from-file=.env.local
```

1. Tap **"Continue with Google"**
2. You should see Google account picker **in the app** (not Chrome)
3. Select an account
4. Sign in!

---

## 🐛 Troubleshooting

### "Error 10: Developer Error"
- SHA-1 fingerprint doesn't match
- Package name doesn't match
- Wait 5-10 minutes after creating credentials (Google's cache)

### "Sign in failed" or blank screen
- Web Client ID/Secret incorrect in Supabase
- Google provider not enabled in Supabase

### Opens in Chrome instead of in-app
- Android OAuth Client not created
- SHA-1 fingerprint incorrect
- Package name mismatch

---

## 📝 For Production Release

When you're ready to publish your app:

1. Generate a release keystore:
   ```bash
   keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Get the SHA-1:
   ```bash
   keytool -list -v -keystore release.keystore -alias release
   ```

3. Add the production SHA-1 to your Android OAuth Client in Google Cloud Console

4. Configure signing in `android/app/build.gradle.kts`

---

## 📞 Need Help?

If you get stuck:
1. Double-check all values match exactly (no extra spaces)
2. Wait 5-10 minutes after creating credentials
3. Try clearing app data and reinstalling
4. Check Supabase logs for error messages
