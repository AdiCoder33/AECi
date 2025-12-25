# Account Creation & Email Confirmation Guide

## Overview of Changes

I've fixed the account creation process to properly handle email confirmations and added the missing gender field. Here's what was updated:

## ✅ What's Fixed

### 1. **Email Confirmation Handling**
- **Before**: Sign-up didn't show proper feedback about email confirmation
- **After**: 
  - Clear success message: "✅ Account created! Check your email to confirm your account and then sign in."
  - Automatically switches back to sign-in mode after successful registration
  - Proper email redirect URL configured for confirmation links

### 2. **Gender Field Added**
- **Location**: [create_profile_screen.dart](lib/features/profile/presentation/create_profile_screen.dart)
- **Options**: Male, Female, Other
- Now saved to the profile database

### 3. **Email Redirect Configuration**
- Added `emailRedirectTo` parameter in sign-up process
- Uses the same redirect URL as OAuth: `io.supabase.flutter://login-callback`
- This ensures email confirmation links work correctly with the app

## 📋 Complete Profile Fields

When creating a new account, users must provide:

### Required Fields:
1. **Email** - User's email address (from sign-up)
2. **Name** - Full name
3. **Age** - Between 18-80
4. **Designation** - Choose from:
   - Fellow
   - Resident
   - Consultant
5. **Centre** - Choose from:
   - Madurai
   - Chennai
   - Coimbatore
   - Tirunelveli
   - Salem
   - Tirupati
   - Pondicherry
6. **Gender** - Choose from:
   - Male
   - Female
   - Other
7. **Employee ID** - Aravind employee ID
8. **Phone Number** - 10-digit phone number
9. **Date of Birth** - Must be 18-80 years old
10. **Hospital** - Auto-filled as "Aravind Eye Hospital"

## 🔄 New Account Creation Flow

### Step 1: Sign Up
1. User opens the app → sees login screen
2. Clicks "Create one" to switch to sign-up mode
3. Enters email and password
4. Clicks "Create account"

### Step 2: Email Confirmation (if enabled in Supabase)
**Two scenarios:**

#### Scenario A: Auto-Confirm Enabled in Supabase
- User is signed in immediately
- Redirected to Create Profile screen

#### Scenario B: Email Confirmation Required
- User sees: "✅ Account created! Check your email to confirm your account and then sign in."
- Screen automatically switches back to sign-in mode
- User checks email and clicks confirmation link
- Confirmation link opens app (via deep link)
- User signs in with email/password
- Redirected to Create Profile screen

### Step 3: Complete Profile
1. User fills in all required fields
2. Clicks "Save Profile"
3. Profile is created in database
4. User is redirected to home screen

## 🔧 Supabase Configuration

### To Enable Email Confirmation:
1. Go to Supabase Dashboard → Authentication → Settings
2. **Enable email confirmations**: ON
3. **Email Templates** → Confirm signup
4. Make sure the confirmation URL is set to: `io.supabase.flutter://login-callback`

### To Disable Email Confirmation (Auto-Confirm):
1. Go to Supabase Dashboard → Authentication → Settings
2. **Enable email confirmations**: OFF
3. Users will be auto-confirmed on sign-up

## 🐛 Troubleshooting

### Email Confirmation Not Sending?
**Check:**
1. Supabase Dashboard → Authentication → Settings → Email Confirmations is **enabled**
2. SMTP settings are configured (or using Supabase's default email service)
3. Check spam/junk folder

### Confirmation Link Not Working?
**Check:**
1. Deep link is configured in:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/Info.plist`
2. Redirect URL in Supabase matches: `io.supabase.flutter://login-callback`
3. App is installed on the device (deep links won't work in browser for mobile apps)

### Still Having Issues?
**Option 1: Disable Email Confirmation**
- Go to Supabase Dashboard → Authentication → Settings
- Turn OFF "Enable email confirmations"
- Users will be auto-confirmed

**Option 2: Manual Confirmation**
- Go to Supabase Dashboard → Authentication → Users
- Find the user and click "Confirm email" manually

## 📱 Deep Link Configuration

### Android Setup
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.flutter" />
</intent-filter>
```

### iOS Setup
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.flutter</string>
        </array>
    </dict>
</array>
```

## 🎯 Testing the Fix

1. **Test Sign-Up with Email Confirmation OFF**:
   - Create account → should be logged in immediately
   - Should redirect to Create Profile screen
   
2. **Test Sign-Up with Email Confirmation ON**:
   - Create account → should see success message
   - Check email → click confirmation link
   - Sign in → should redirect to Create Profile screen
   
3. **Test Profile Creation**:
   - Fill all fields including gender
   - Submit → should redirect to home screen
   - Check profile → gender should be saved

## 📄 Files Modified

1. [create_profile_screen.dart](lib/features/profile/presentation/create_profile_screen.dart) - Added gender field
2. [auth_repository.dart](lib/features/auth/data/auth_repository.dart) - Added email redirect URL
3. [auth_controller.dart](lib/features/auth/application/auth_controller.dart) - Improved sign-up messaging
4. [auth_screen.dart](lib/features/auth/presentation/auth_screen.dart) - Auto-switch to sign-in after sign-up

All changes are backward compatible and won't break existing user accounts.
