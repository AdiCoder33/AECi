# Complete Google Sign-In Setup for Production

## ✅ What I've Done

1. ✅ Created production keystore: `android/app/upload-keystore.jks`
2. ✅ Created `android/key.properties` with signing credentials
3. ✅ Updated `android/app/build.gradle.kts` to use production signing
4. ✅ Added keystore files to `.gitignore` (NEVER commit these!)

## 🔑 Your SHA-1 Keys

### Debug SHA-1 (for development/testing)
```
0E:78:4E:D6:AB:93:34:89:97:8A:1D:67:31:5C:09:94:1A:C3:D0:24
```

### Production SHA-1 (for release builds)
```
17:DC:49:75:D6:17:DF:55:8A:BE:F7:7A:86:8E:25:3B:32:BB:B8:A5
```

## 🔧 Step 1: Configure Google Cloud Console

### Go to Google Cloud Console
https://console.cloud.google.com/apis/credentials?project=precise-bank-480516-k8

### Add BOTH SHA-1 Keys to Your Android OAuth Client

1. Find your **Android** OAuth 2.0 Client (or create one)
2. Click on it to edit
3. Add **Package name**: `com.example.aravind_e_logbook`
4. Add **BOTH SHA-1 fingerprints**:
   - Debug: `0E:78:4E:D6:AB:93:34:89:97:8A:1D:67:31:5C:09:94:1A:C3:D0:24`
   - Production: `17:DC:49:75:D6:17:DF:55:8A:BE:F7:7A:86:8E:25:3B:32:BB:B8:A5`
5. Click **SAVE**

### Configure Web OAuth Client (for Chrome/localhost)

1. Find or create **Web application** OAuth 2.0 Client
2. Client ID should be: `362737514668-ejdc1dvss4j3r9l7negebv1dfn7gto64.apps.googleusercontent.com`
3. Add **Authorized JavaScript origins**:
   ```
   http://localhost
   http://localhost:64824
   https://zivtybyisftechheizwe.supabase.co
   ```
4. Add **Authorized redirect URIs**:
   ```
   http://localhost/auth
   https://zivtybyisftechheizwe.supabase.co/auth/v1/callback
   ```
5. Click **SAVE**

### Important: Wait 5-10 Minutes
Google needs time to propagate these changes across their servers.

## 🔧 Step 2: Configure Supabase

### Go to Supabase Dashboard
https://supabase.com/dashboard/project/zivtybyisftechheizwe/auth/providers

1. Find **Google** provider
2. Enable it
3. Enter:
   - **Client ID**: `362737514668-ejdc1dvss4j3r9l7negebv1dfn7gto64.apps.googleusercontent.com`
   - **Client Secret**: (Get from Google Cloud Console - Web OAuth client)
4. Click **Save**

## 📱 Step 3: Test Your Setup

### For Chrome/Web (Development)
```powershell
$env:PATH="$env:USERPROFILE\dev\flutter\bin;$env:PATH"
cd "C:\Users\vijay\Desktop\AECi"
flutter run -d chrome --dart-define-from-file=.env.local
```

### For Android Device (Development)
```powershell
$env:PATH="$env:USERPROFILE\dev\flutter\bin;$env:PATH"
cd "C:\Users\vijay\Desktop\AECi"
flutter run -d 10BF690L9Z000N0 --dart-define-from-file=.env.local
```

### For Android Release Build (Production)
```powershell
$env:PATH="$env:USERPROFILE\dev\flutter\bin;$env:PATH"
cd "C:\Users\vijay\Desktop\AECi"
flutter build apk --release --dart-define-from-file=.env.local
```

The signed APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## 🔐 Important Security Notes

### NEVER Commit These Files:
- ❌ `android/key.properties`
- ❌ `android/app/upload-keystore.jks`
- ❌ `.env.local`

These are already in `.gitignore`, but double-check!

### Keystore Credentials (SAVE THESE SECURELY)
```
Store Password: aravind123
Key Password: aravind123
Key Alias: upload
Keystore File: android/app/upload-keystore.jks
```

⚠️ **IMPORTANT**: If you lose the keystore file, you cannot update your app on Play Store!

## 🐛 Troubleshooting

### Issue 1: "Sign in failed" on Android
**Solution**: 
1. Verify you added BOTH SHA-1 keys to Google Cloud Console
2. Wait 5-10 minutes after adding them
3. Uninstall and reinstall the app
4. Try again

### Issue 2: "ClientID not set" on Web/Chrome
**Solution**:
1. Check `web/index.html` has the meta tag:
   ```html
   <meta name="google-signin-client_id" content="362737514668-ejdc1dvss4j3r9l7negebv1dfn7gto64.apps.googleusercontent.com">
   ```
2. Verify localhost is in Google Cloud Console authorized origins
3. Clear browser cache and reload

### Issue 3: Different SHA-1 error
**Solution**: 
Run this to get current SHA-1:
```powershell
cd "C:\Users\vijay\Desktop\AECi\android"
.\gradlew signingReport
```
Then add that SHA-1 to Google Cloud Console.

## ✅ Final Checklist

Before deploying to production:

- [ ] Added both Debug and Production SHA-1 to Google Cloud Console Android OAuth
- [ ] Configured Web OAuth client with localhost for development
- [ ] Configured Supabase Google provider with correct Client ID and Secret
- [ ] Tested Google Sign-In on Android device
- [ ] Tested Google Sign-In on Chrome/Web
- [ ] Backed up `upload-keystore.jks` securely (external drive, password manager, etc.)
- [ ] Verified `.gitignore` includes keystore files
- [ ] Never committed sensitive files to git

## 📦 Building for Production

When ready to publish:

```powershell
# Build release APK
flutter build apk --release --dart-define-from-file=.env.local

# Or build App Bundle for Play Store
flutter build appbundle --release --dart-define-from-file=.env.local
```

Your signed app will be ready for distribution!
