# 🚀 Quick Start Guide - Firebase Setup

## Prerequisites
- Flutter installed
- Node.js installed
- Firebase account

## ⚡ 5-Minute Firebase Setup

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

### Step 2: Login & Configure
```bash
# Login to Firebase
firebase login

# Navigate to project
cd /Users/apple/NewFolder/fyp

# Auto-configure (EASIEST WAY!)
flutterfire configure
```

This single command will:
- ✅ List your Firebase projects
- ✅ Let you select/create SkillLink project
- ✅ Generate `firebase_options.dart`
- ✅ Configure Android & iOS automatically
- ✅ Set up web config

### Step 3: Install Dependencies
```bash
flutter pub get
```

### Step 4: Update main.dart
The main.dart file needs this change:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}
```

### Step 5: Enable Firebase Services

In Firebase Console (https://console.firebase.google.com):

1. **Authentication**:
   - Go to Authentication → Get Started
   - Enable "Email/Password"
   - Enable "Google" (optional)

2. **Firestore Database**:
   - Go to Firestore Database → Create Database
   - Choose "Start in test mode" (for development)
   - Select your region

3. **Storage** (Optional - for images):
   - Go to Storage → Get Started
   - Start in test mode

### Step 6: Run Your App
```bash
flutter run
```

---

## 🎯 What's Already Done

✅ Firebase dependencies added to `pubspec.yaml`
✅ Auth service created (`lib/services/auth_service.dart`)
✅ Firestore service created (`lib/services/firestore_service.dart`)
✅ Storage service created (`lib/services/storage_service.dart`)
✅ Code structure ready for Firebase

---

## 🔧 Next Steps After Setup

### 1. Replace Mock Authentication

In `lib/screens/auth/login_screen.dart`, change:

```dart
// FROM:
await Future.delayed(const Duration(seconds: 2)); // Mock

// TO:
final authService = AuthService();
UserCredential? credential = await authService.signInWithEmail(
  email: _emailController.text.trim(),
  password: _passwordController.text.trim(),
);
```

### 2. Connect Gig Creation

In `lib/screens/worker/create_gig_screen.dart`:

```dart
// Import
import '../../services/firestore_service.dart';

// In _handleCreateGig():
final firestoreService = FirestoreService();
String gigId = await firestoreService.createGig({
  'workerId': currentUser.uid,
  'workerName': currentUser.displayName,
  'title': _titleController.text,
  'description': _descriptionController.text,
  'category': _selectedCategory,
  'hourlyRate': double.parse(_hourlyRateController.text),
  'minHours': _minHours,
  'maxHours': _maxHours,
  'skills': _skillsController.text.split(',').map((e) => e.trim()).toList(),
  // ... more fields
});
```

### 3. Load Real Gigs

In `lib/screens/user/browse_gigs_screen.dart`:

```dart
// Use StreamBuilder
StreamBuilder<QuerySnapshot>(
  stream: FirestoreService().getAllGigs(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    
    List<Gig> gigs = snapshot.data!.docs.map((doc) {
      // Convert document to Gig object
      return Gig.fromFirestore(doc);
    }).toList();
    
    return ListView.builder(...);
  },
)
```

---

## 🐛 Troubleshooting

### "MissingPluginException"
```bash
flutter clean
flutter pub get
flutter run
```

### "No Firebase App"
Make sure Firebase.initializeApp() is awaited in main()

### Build Errors on Android
Check `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 21  // Must be 21 or higher for Firebase
}
```

### iOS Build Issues
```bash
cd ios
pod install
cd ..
flutter run
```

---

## 📱 Test Firebase Connection

Add this to any screen to test:

```dart
import 'package:firebase_core/firebase_core.dart';

// In build method:
Text('Firebase Connected: ${Firebase.apps.isNotEmpty}')
```

---

## 🎓 For Your Team

**Muhammad Ali**: Focus on backend integration and Firebase setup
**Muhammad Alyan**: Update UI screens to use Firebase data
**Affan Naveed**: Implement AI features using Firebase ML

---

## 📚 Resources

- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
- [Firebase Auth Docs](https://firebase.google.com/docs/auth)
- [Firestore Docs](https://firebase.google.com/docs/firestore)

---

**Estimated Setup Time**: 15-20 minutes
**Difficulty**: Beginner-Friendly 🟢

Good luck with your FYP! 🎓🚀


