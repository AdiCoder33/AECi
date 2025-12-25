# Production Setup for Google Sign-In

## 🔴 Current Issue - Error 12500

**Problem**: Android OAuth Client not configured or SHA-1 mismatch

## ✅ Quick Fix for Development

### Step 1: Verify Android OAuth Client Exists

1. Go to: https://console.cloud.google.com/apis/credentials?project=precise-bank-480516-k8
2. Check if you have an **Android** OAuth client (NOT "Installed" type)
3. If not, create one:
   - Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
   - Select: **"Android"**
   - Package name: `com.example.aravind_e_logbook`
   - SHA-1: `0E:78:4E:D6:AB:93:34:89:97:8A:1D:67:31:5C:09:94:1A:C3:D0:24`
   - Click **CREATE**

### Step 2: Wait 5-10 Minutes
Google's servers need time to propagate the changes.

### Step 3: Clear App Data and Reinstall
```bash
flutter clean
flutter run -d 10BF690L9Z000N0 --dart-define-from-file=.env.local
```

---

## 🚀 Production Setup (For App Release)

### Step 1: Generate Production Keystore

Run this command in your project root:

```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Enter details when prompted:
# - Password: [SAVE THIS - YOU'LL NEED IT]
# - Name, Organization, etc.
```

**⚠️ IMPORTANT**: Save the keystore password in a secure place!

### Step 2: Get Production SHA-1

```powershell
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

Copy the **SHA-1** fingerprint from the output.

### Step 3: Create Production Android OAuth Client

1. Go to Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=precise-bank-480516-k8
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. Select: **"Android"**
4. Fill in:
   - Name: `Aravind E-Logbook Android - Production`
   - Package name: `com.example.aravind_e_logbook`
   - SHA-1: [YOUR PRODUCTION SHA-1 FROM STEP 2]
5. Click **CREATE**

### Step 4: Configure Signing in Android

Create file: `android/key.properties`

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**⚠️ Add to .gitignore:**
```
android/key.properties
android/app/upload-keystore.jks
```

### Step 5: Update android/app/build.gradle.kts

Add this configuration:

```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Step 6: Build Production APK

```powershell
flutter build apk --release --dart-define-from-file=.env.local
```

---

## 📋 Summary - What You Need

### For Development (Debug):
- ✅ Android OAuth Client with **debug** SHA-1: `0E:78:4E:D6:AB:93:34:89:97:8A:1D:67:31:5C:09:94:1A:C3:D0:24`
- ✅ Package name: `com.example.aravind_e_logbook`

### For Production (Release):
- ✅ Production keystore generated
- ✅ Android OAuth Client with **production** SHA-1 (from your production keystore)
- ✅ Same package name: `com.example.aravind_e_logbook`
- ✅ Signing configured in build.gradle.kts

### For Both (Supabase):
- ✅ Web OAuth Client configured in Supabase

---

## 🔍 Verify Setup

### Check if Android OAuth Client Exists:
1. Go to: https://console.cloud.google.com/apis/credentials?project=precise-bank-480516-k8
2. Look for:
   - ✅ OAuth 2.0 Client ID with type: **Android**
   - ✅ Package name: `com.example.aravind_e_logbook`
   - ✅ SHA-1: `0E:78:4E:D6:AB:93:34:89:97:8A:1D:67:31:5C:09:94:1A:C3:D0:24`

If missing, create it following Step 1 above.

---

## 🐛 Common Issues

### Error 12500
- **Cause**: No Android OAuth client OR SHA-1 mismatch
- **Fix**: Create Android OAuth client with correct SHA-1

### Error 10
- **Cause**: Package name mismatch
- **Fix**: Verify package name is exactly `com.example.aravind_e_logbook`

### Still opens Chrome
- **Cause**: Only Web OAuth exists, no Android OAuth
- **Fix**: Create Android OAuth client

---

## ✅ Final Checklist

- [ ] Android OAuth Client created for DEBUG (SHA-1: 0E:78...)
- [ ] Web OAuth Client created for Supabase
- [ ] Web Client ID/Secret configured in Supabase
- [ ] Waited 5-10 minutes after creating credentials
- [ ] App rebuilt and reinstalled
- [ ] Google Sign-In shows account picker in-app

For production:
- [ ] Production keystore generated
- [ ] Production SHA-1 added to new Android OAuth Client
- [ ] Signing configured in build.gradle.kts
- [ ] key.properties added to .gitignore
