# 🔐 Google Sign-In Setup Guide

## ✅ Implementation Complete!

Google Sign-In has been fully implemented for both **Worker** and **User** sides with Firebase integration!

---

## 🎯 What's Implemented

### ✅ Features:
- **Google Sign-In Button** on both Login and Signup screens
- **Role-based authentication** - Saves correct role (worker/user) to Firestore
- **Automatic user document creation** - Creates user profile on first login
- **Session management** - Handles existing users properly
- **Firebase integration** - Saves FCM tokens for notifications
- **Navigation** - Routes to correct dashboard based on role

---

## 📱 Setup Steps

### Step 1: Enable Google Sign-In in Firebase Console (5 minutes)

1. **Go to Firebase Console:**
   https://console.firebase.google.com/project/skilllink-fd388

2. **Enable Google Authentication:**
   - Click **"Authentication"** in left menu
   - Click **"Sign-in method"** tab
   - Find **"Google"** in the list
   - Click to enable it
   - Enter your project support email
   - Click **"Save"**

3. **Enable it:**
   - Toggle **"Enable"** switch to ON
   - Click **"Save"**

---

### Step 2: Get SHA-1 Fingerprint (Android)

#### For Windows:
```bash
cd android
gradlew signingReport
```

#### For Mac/Linux:
```bash
cd android
./gradlew signingReport
```

#### Copy SHA-1:
Look for output like:
```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy the **SHA-1** value (the long string of hex numbers).

---

### Step 3: Add SHA-1 to Firebase Project

1. **Go to Project Settings:**
   - Firebase Console → Project Settings (gear icon)
   - Scroll to **"Your apps"** section
   - Click on your Android app

2. **Add SHA-1:**
   - Click **"Add fingerprint"**
   - Paste your SHA-1 value
   - Click **"Save"**

3. **Download Updated Config:**
   - Download the updated `google-services.json`
   - Replace the file in `android/app/`

---

### Step 4: Configure OAuth Consent Screen (If Needed)

1. **Go to Google Cloud Console:**
   https://console.cloud.google.com/

2. **Select your project:**
   - Select "skilllink-fd388" or your project name

3. **OAuth Consent Screen:**
   - Go to **APIs & Services** → **OAuth consent screen**
   - Configure if not already done
   - Add test users if in testing mode

---

### Step 5: Enable Google Sign-In API

1. **In Google Cloud Console:**
   - Go to **APIs & Services** → **Library**
   - Search for **"Google Sign-In API"**
   - Make sure it's **enabled**

---

## 🧪 Testing Google Sign-In

### Test Flow:

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Navigate to Login/Signup:**
   - Choose role (Worker or User)
   - Go to Login or Signup screen

3. **Tap "Continue with Google":**
   - Google sign-in popup appears
   - Select your Google account
   - Grant permissions

4. **Verify:**
   - ✅ App navigates to correct dashboard (Worker/User)
   - ✅ User document created in Firestore `users/` collection
   - ✅ Role is saved correctly (`worker` or `user`)
   - ✅ FCM token saved for notifications

---

## 🔍 Verify in Firebase Console

### Check Authentication:
1. Go to **Firebase Console** → **Authentication** → **Users**
2. You should see your Google account listed
3. Provider should show "google.com"

### Check Firestore:
1. Go to **Firestore Database** → `users` collection
2. Find your user document
3. Verify fields:
   ```json
   {
     "uid": "user-id-here",
     "name": "Your Name",
     "email": "your-email@gmail.com",
     "role": "worker" or "user",
     "photoURL": "profile-image-url",
     "createdAt": timestamp,
     "updatedAt": timestamp
   }
   ```

---

## 📱 How It Works

### First Time Google Sign-In:

```
User taps "Continue with Google"
        ↓
Google Sign-In popup appears
        ↓
User selects Google account
        ↓
Firebase creates authentication account
        ↓
App checks if user document exists in Firestore
        ↓
If NOT exists → Creates new user document with:
  - Name (from Google)
  - Email (from Google)
  - Photo URL (from Google)
  - Role (worker/user - from selection)
  - Created timestamp
        ↓
Saves FCM token for notifications
        ↓
Navigates to appropriate dashboard
```

### Existing User Sign-In:

```
User taps "Continue with Google"
        ↓
Google Sign-In popup appears
        ↓
User selects Google account
        ↓
Firebase authenticates
        ↓
App checks Firestore user document
        ↓
Document EXISTS → Uses existing role
        ↓
Updates last login time
        ↓
Navigates to appropriate dashboard
```

---

## 🎯 Code Implementation Details

### AuthService (`lib/services/auth_service.dart`):

**Method:** `signInWithGoogle({required String role})`

**What it does:**
1. Triggers Google Sign-In flow
2. Gets Google authentication credentials
3. Signs into Firebase with Google credential
4. Checks if user document exists in Firestore
5. Creates/updates user document with role
6. Returns UserCredential

**Key Features:**
- Handles user cancellation gracefully
- Preserves existing role for returning users
- Updates role if user doesn't have one
- Saves all Google profile data (name, email, photo)

---

### Login Screen (`lib/screens/auth/login_screen.dart`):

**Method:** `_handleGoogleSignIn()`

**What it does:**
1. Shows loading indicator
2. Calls `AuthService.signInWithGoogle()` with current role
3. Saves FCM token for notifications
4. Navigates to Worker/User dashboard
5. Handles errors gracefully

---

### Signup Screen (`lib/screens/auth/signup_screen.dart`):

**Method:** `_handleGoogleSignIn()`

**Same functionality as Login screen:**
- Works for both new and existing users
- Creates account or signs in existing user
- Routes to correct dashboard

---

## 🔧 Troubleshooting

### Issue: "Sign in failed"

**Solution:**
1. Make sure Google Sign-In is enabled in Firebase Console
2. Verify SHA-1 fingerprint is added
3. Check if Google Sign-In API is enabled
4. Make sure `google-services.json` is updated

### Issue: "User canceled"

**Solution:**
- This is normal if user closes the Google sign-in popup
- App handles this gracefully
- No error shown to user

### Issue: "Role not saved"

**Solution:**
1. Check Firestore rules allow writes to `users/` collection
2. Verify user document is being created
3. Check console logs for errors

### Issue: "App crashes on Google Sign-In"

**Solution:**
1. Run `flutter clean` then `flutter pub get`
2. Rebuild the app
3. Make sure `google_sign_in` package is in `pubspec.yaml`
4. Verify SHA-1 is correct

---

## ✅ Checklist

Before testing, ensure:

- [ ] Google Sign-In enabled in Firebase Console
- [ ] SHA-1 fingerprint added to Firebase project
- [ ] `google-services.json` updated
- [ ] Google Sign-In API enabled in Google Cloud
- [ ] OAuth consent screen configured
- [ ] Firestore rules allow user creation
- [ ] App rebuilt after adding SHA-1

---

## 🎉 Success Indicators

You'll know it's working when:

✅ Google sign-in popup appears  
✅ You can select Google account  
✅ App navigates to dashboard  
✅ User appears in Firebase Authentication  
✅ User document created in Firestore  
✅ Role saved correctly  
✅ Profile photo appears (if available)  

---

## 📚 Additional Resources

- [Firebase Google Auth Docs](https://firebase.google.com/docs/auth/android/google-signin)
- [Flutter Google Sign-In Package](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication Guide](https://firebase.google.com/docs/auth/flutter/start)

---

## 🚀 Ready to Test!

Once you've completed the setup steps above, run your app and try signing in with Google! 

The implementation is complete and ready to use! 🎉

---

**Note:** For iOS, additional setup may be required:
- Add GoogleService-Info.plist to iOS project
- Configure URL schemes in Info.plist
- But Android should work with the above setup!

