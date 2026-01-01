# Fix Google Sign-In for Web (Chrome/localhost)

## ✅ Code Changes Applied

I've updated the following files:
1. **web/index.html** - Added Google Sign-In meta tag
2. **lib/features/auth/data/auth_repository.dart** - Added clientId parameter

## 🔧 Google Cloud Console Configuration Required

You **MUST** complete these steps in Google Cloud Console:

### Step 1: Go to Google Cloud Console
Visit: https://console.cloud.google.com/apis/credentials?project=precise-bank-480516-k8

### Step 2: Check/Create Web OAuth Client

1. Look for a **Web application** OAuth 2.0 Client ID
   - If you already have one, click on it to edit
   - If not, click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"** → Select **"Web application"**

2. Configure the Web OAuth Client:
   
   **Name**: `Aravind E-Logbook Web`
   
   **Authorized JavaScript origins**: Add these URLs:
   ```
   http://localhost:64824
   http://localhost
   https://zivtybyisftechheizwe.supabase.co
   ```
   
   **Authorized redirect URIs**: Add these URLs:
   ```
   http://localhost:64824/auth
   https://zivtybyisftechheizwe.supabase.co/auth/v1/callback
   ```

3. Click **SAVE**

4. **Important**: Copy the **Client ID** (it should match: `362737514668-ejdc1dvss4j3r9l7negebv1dfn7gto64.apps.googleusercontent.com`)

### Step 3: Configure Supabase Google Provider

1. Go to: https://supabase.com/dashboard/project/zivtybyisftechheizwe/auth/providers

2. Find **Google** provider and enable it

3. Enter:
   - **Client ID**: `362737514668-ejdc1dvss4j3r9l7negebv1dfn7gto64.apps.googleusercontent.com`
   - **Client Secret**: (Get this from Google Cloud Console - same OAuth client)

4. Click **Save**

### Step 4: Test

1. The app should now be running in Chrome
2. Click "Continue with Google"
3. You should see the Google account picker
4. Sign in should work!

## 🐛 If Still Not Working

### Check 1: Verify the Client ID matches everywhere
- `.env.local` file
- `web/index.html` meta tag
- Google Cloud Console Web OAuth Client
- Supabase Google Provider settings

### Check 2: Clear browser cache
1. Press `Ctrl + Shift + Delete` in Chrome
2. Select "Cached images and files"
3. Click "Clear data"
4. Reload the app

### Check 3: Check browser console
1. Press `F12` in Chrome
2. Go to "Console" tab
3. Look for any Google Sign-In errors
4. Share the errors if needed

## 📝 Current Configuration

**Client ID**: `362737514668-ejdc1dvss4j3r9l7negebv1dfn7gto64.apps.googleusercontent.com`
**Supabase URL**: `https://zivtybyisftechheizwe.supabase.co`
**App Port**: Usually `64824` or similar (changes each run)

## ⚠️ Important Notes

1. **Localhost ports change**: Every time you run the app, the port might be different (64824, 51234, etc.)
   - Add common ports to Google Cloud Console OR
   - Use just `http://localhost` (without port) which covers all ports

2. **Wait 5 minutes**: After changing Google Cloud Console settings, wait 5-10 minutes for changes to propagate

3. **Web Client ID ≠ Android Client ID**: Make sure you're using the **Web** OAuth client, not the Android one
