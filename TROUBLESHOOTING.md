# 🔧 SkillLink - Troubleshooting Guide

## Common Build & Runtime Issues

---

### ✅ FIXED: flutter_local_notifications Build Error

**Error:**
```
error: reference to bigLargeIcon is ambiguous
```

**Solution:**
✅ Downgraded to `flutter_local_notifications: ^15.1.0`  
✅ Enabled core library desugaring in `android/app/build.gradle.kts`  
✅ Added desugaring dependency

**If Error Persists:**
```bash
rm -rf pubspec.lock
flutter clean
flutter pub cache repair
flutter pub get
flutter run
```

---

### 🔥 Firebase Issues

#### Issue 1: "No Firebase App"
**Error:** `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution:**
```bash
# Make sure you've run:
flutterfire configure

# Check firebase_options.dart exists:
ls lib/firebase_options.dart

# Verify main.dart has:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

#### Issue 2: "google-services.json not found"
**Error:** `File google-services.json is missing`

**Solution:**
1. Download from Firebase Console
2. Place in: `android/app/google-services.json`
3. ✅ Already in your project!

#### Issue 3: Firebase not initialized
**Error:** Various Firebase errors

**Solution:**
```bash
# Run configuration:
firebase login
flutterfire configure

# Select: skilllink-fd388
# Select platforms: Android, iOS, Web

# This generates firebase_options.dart automatically
```

---

### 📱 Android Build Issues

#### Issue 1: minSdk version
**Error:** `Manifest merger failed : uses-sdk:minSdkVersion`

**Solution:**
✅ Already set to 21 in `android/app/build.gradle.kts`

#### Issue 2: Multidex error
**Error:** `Cannot fit requested classes in a single dex file`

**Solution:**
✅ Already enabled: `multiDexEnabled = true`

#### Issue 3: Google Services plugin
**Error:** `Plugin with id 'com.google.gms.google-services' not found`

**Solution:**
✅ Already added to build.gradle.kts

---

### 🍎 iOS Build Issues

#### Issue 1: CocoaPods not installed
**Error:** `CocoaPods not installed`

**Solution:**
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter run
```

#### Issue 2: GoogleService-Info.plist missing
**Error:** `GoogleService-Info.plist not found`

**Solution:**
1. Download from Firebase Console
2. Place in: `ios/Runner/GoogleService-Info.plist`
3. ✅ Already in your project!

#### Issue 3: Permissions for notifications
Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

---

### 🔔 Notification Issues

#### Issue 1: Notifications not appearing
**Checklist:**
- [ ] Firebase Cloud Messaging enabled in console
- [ ] Permissions granted on device
- [ ] FCM token saved to Firestore
- [ ] Test on **physical device** (not emulator)

**Debug:**
```dart
// Add to any screen:
print('FCM Token: ${await NotificationService().getToken()}');
```

#### Issue 2: Background notifications not working
**Solution:**
- iOS: Add background modes to Info.plist
- Android: Service already configured ✅
- Test on physical device

---

### 💬 Chat Issues

#### Issue 1: Messages not appearing
**Checklist:**
- [ ] Internet connection
- [ ] Firestore rules allow read/write
- [ ] Both users authenticated
- [ ] Chat room created

**Debug:**
```dart
// Check chat room ID:
print('Chat Room: ${ChatService().getChatRoomId(user1, user2)}');
```

#### Issue 2: Read receipts not updating
**Solution:**
- Call `markMessagesAsRead()` when opening chat
- ✅ Already implemented in chat_screen.dart

---

### 🔍 Search & Filter Issues

#### Issue 1: Search not working
**Current:** Uses local filtering with sample data  
**Future:** Will use Firestore queries

**To Enable Firestore Search:**
```dart
// In browse_gigs_screen.dart
// Replace SampleGigs.gigs with:
StreamBuilder<QuerySnapshot>(
  stream: FirestoreService().getAllGigs(),
  builder: (context, snapshot) {
    // Convert to gigs list
  }
)
```

---

### 🎯 Package Compatibility Issues

#### Current Compatible Versions:
```yaml
firebase_core: ^2.24.2              ✅
firebase_auth: ^4.15.3              ✅
cloud_firestore: ^4.13.6            ✅
firebase_storage: ^11.5.6           ✅
firebase_messaging: ^14.7.9         ✅
flutter_local_notifications: ^15.1.0 ✅ (Fixed!)
google_sign_in: ^6.1.6              ✅
image_picker: ^1.0.7                ✅
intl: ^0.18.1                       ✅
iconsax: ^0.0.8                     ✅
```

#### If Build Fails:
```bash
# Nuclear option - clean everything:
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool
rm -rf build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
flutter pub cache repair
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

### 🌐 Network Issues

#### Issue 1: Firebase connection timeout
**Solution:**
- Check internet connection
- Verify Firebase project is active
- Check API keys in firebase_options.dart

#### Issue 2: "PERMISSION_DENIED" in Firestore
**Solution:**
1. Go to Firestore → Rules
2. Start with test mode:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

---

### 📦 Dependency Conflicts

#### Issue: Version solving failed
**Solution:**
```bash
# Update Flutter
flutter upgrade

# Clean and reinstall
flutter clean
rm pubspec.lock
flutter pub get

# If still fails, try:
flutter pub upgrade --major-versions
```

---

### 🏃 Runtime Errors

#### Issue 1: "Null check operator used on null"
**Common Causes:**
- User not logged in
- Firebase not initialized
- Data not loaded yet

**Solution:**
- Check `FirebaseAuth.instance.currentUser != null`
- Use null-safe operators (`?.`, `??`)
- Add loading states

#### Issue 2: "setState() called after dispose()"
**Solution:**
- Check `if (mounted)` before setState
- ✅ Already implemented in all screens

---

### 🧪 Testing Tips

#### Test Authentication:
```bash
# Enable debug logging:
flutter run --verbose

# Watch Firebase console:
# Authentication → Users (should appear after signup)
```

#### Test Firestore:
```bash
# Firebase Console → Firestore
# Should see collections appear when creating data
```

#### Test Notifications:
```bash
# Must test on physical device
# Emulators have limited FCM support
# Check device notification settings
```

#### Test Chat:
```bash
# Best with two devices or accounts
# Check Firestore → chats collection
# Messages should appear immediately
```

---

### 🔑 Firebase Console Checklist

Visit: https://console.firebase.google.com/project/skilllink-fd388

- [ ] **Authentication**
  - [x] Email/Password enabled
  - [ ] Users appear after signup
  
- [ ] **Firestore Database**
  - [ ] Database created
  - [ ] Test mode or proper rules set
  - [ ] Collections appear when data added
  
- [ ] **Cloud Messaging**
  - [ ] Enabled
  - [ ] Server key available
  
- [ ] **Storage**
  - [ ] Bucket created (optional for images)

---

### 📱 Device-Specific Issues

#### iOS Simulator:
- Notifications: Limited support
- Camera: Not available
- Solution: Test on physical device

#### Android Emulator:
- Notifications: May work with Google APIs image
- FCM: Limited support
- Solution: Use physical device for full testing

#### Physical Devices:
- ✅ Full notification support
- ✅ All features work
- ✅ Real Firebase connection

---

### 🚀 Quick Fixes

#### App won't start:
```bash
flutter clean
flutter pub get
flutter run
```

#### Build errors:
```bash
cd android
./gradlew clean
cd ..
flutter run
```

#### Firebase errors:
```bash
flutterfire configure
flutter run
```

#### Cache issues:
```bash
flutter pub cache repair
flutter clean
flutter pub get
```

---

### 💡 Pro Tips

1. **Always test on physical device** for notifications
2. **Check Firebase Console** to see data being saved
3. **Use --verbose flag** for detailed error logs
4. **Clear app data** on device when testing auth
5. **Check Firestore rules** if getting permission errors
6. **Verify internet connection** for Firebase features

---

### 📞 Need Help?

1. **Check Documentation:**
   - FIREBASE_SETUP.md
   - QUICK_START.md
   - FIREBASE_INTEGRATION_COMPLETE.md

2. **Firebase Documentation:**
   - https://firebase.flutter.dev/
   - https://firebase.google.com/docs

3. **Team Contact:**
   - Muhammad Ali: muhammadali.2112000@gmail.com
   - Muhammad Alyan: alyanjaved632@gmail.com
   - Affan Naveed: Affannaveed25@gmail.com

---

### ✅ Current Status

- ✅ Build configuration fixed
- ✅ Core library desugaring enabled
- ✅ flutter_local_notifications downgraded to 15.1.0
- ✅ All Firebase services integrated
- ✅ App should build successfully now!

---

**If you're still having issues, run:**
```bash
flutter doctor -v
```
And share the output with the team!

🎉 **Happy Coding!**


