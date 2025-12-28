#!/bin/bash

echo "🔥 SkillLink Firebase Setup Script"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
echo "📦 Checking Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
else
    echo -e "${GREEN}✓ Firebase CLI found${NC}"
fi

# Check if FlutterFire CLI is installed
echo "📦 Checking FlutterFire CLI..."
if ! command -v flutterfire &> /dev/null; then
    echo -e "${YELLOW}FlutterFire CLI not found. Installing...${NC}"
    dart pub global activate flutterfire_cli
else
    echo -e "${GREEN}✓ FlutterFire CLI found${NC}"
fi

# Login to Firebase
echo ""
echo "🔑 Logging into Firebase..."
firebase login

# Configure FlutterFire
echo ""
echo "⚙️  Configuring Firebase for SkillLink..."
echo "   Please select 'skilllink-fd388' when prompted"
echo ""
flutterfire configure

# Install dependencies
echo ""
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Clean and rebuild
echo ""
echo "🧹 Cleaning build..."
flutter clean

echo ""
echo "✅ ${GREEN}Setup Complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo "   1. Go to Firebase Console: https://console.firebase.google.com/project/skilllink-fd388"
echo "   2. Enable Authentication → Email/Password"
echo "   3. Create Firestore Database → Test mode"
echo "   4. Enable Cloud Messaging"
echo "   5. Run: flutter run"
echo ""
echo "📚 Need help? Check:"
echo "   - FIREBASE_SETUP.md"
echo "   - QUICK_START.md"
echo "   - FIREBASE_INTEGRATION_COMPLETE.md"
echo ""
echo "🎉 Happy coding!"


