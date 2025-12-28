# SkillLink: A Gig-Based Platform for Local Workers and Craftsmen

**A Final Year Project by:**
- Muhammad Ali Khalid Khan (CSF120222080)
- Muhammad Alyan (CS120222080)  
- Affan Naveed (CS120222079)

A complete Flutter application connecting skilled craftsmen with clients through a gig-based marketplace. Workers can create detailed service offerings with the skills (electrician, plumber, mechanic, tailor, carpenter, etc.) and clients can browse, request, and hire workers.

## ✨ Features

### 🔧 Worker Side (Service Providers)
- **Hierarchical Level System**: 
  - **Newbie** 🌱: Starting level for new workers
  - **Professional** ⭐: Intermediate level with proven track record
  - **Expert** 👑: Top-tier craftsmen with extensive experience
  
- **Gig Creation**: Workers can create detailed service offerings
  - Set hourly rates and hour ranges (min-max)
  - Choose from predefined categories or create custom ones
  - List skills and requirements
  - Build portfolio with work samples
  
- **Profile Management**: 
  - Years of experience showcase
  - Success rate tracking
  - Completed projects counter
  - Skills and qualifications display
  
- **Job Management**: 
  - View and respond to job requests
  - Accept or decline opportunities
  - Track active projects
  - Monitor earnings and statistics

### 👤 Client Side (Service Seekers)
- **Browse Gigs**: 
  - Search across all service offerings
  - Filter by category and worker level
  - View detailed gig information
  - See worker credentials and ratings
  
- **Service Categories**:
  - Electrician ⚡
  - Plumber 🔧
  - Mechanic 🔩
  - Carpenter 🪚
  - Painter 🎨
  - **Tailor** 👔 (New!)
  - Cleaner 🧹
  - Gardener 🌱
  - AC Technician ❄️
  - Potter 🏺
  - **Custom Categories** - Workers can define their own!
- **Flexible Hiring System**:
  - Select exact hours needed (slider-based selection)
  - Real-time cost calculation (hours × hourly rate)
  - Custom job descriptions
  - Location and date selection
  - Transparent pricing with service fees
- **Job Management**:
  - Track active jobs
  - View completed jobs
  - Contact workers
  - Cancel pending requests
- **Payment System**:
  - Multiple payment methods (Card, Wallet, Bank Transfer)
  - Secure payment processing
  - Job summary and cost breakdown
  - Service fee included

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── models/
│   ├── worker.dart                  # Worker and Review models
│   └── job.dart                     # Job and JobStatus models
├── screens/
│   ├── splash_screen.dart           # Animated splash screen
│   ├── auth/
│   │   ├── login_screen.dart        # Login with email/password
│   │   └── signup_screen.dart       # Registration screen
│   ├── welcome_screen.dart          # Role selection screen
│   ├── worker/
│   │   ├── worker_dashboard.dart    # Worker home with tabs
│   │   ├── worker_profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── worker_jobs_screen.dart
│   │   └── worker_earnings_screen.dart
│   └── user/
│       ├── user_home_screen.dart    # Browse workers
│       ├── worker_detail_screen.dart
│       ├── hire_worker_screen.dart
│       ├── user_jobs_screen.dart
│       └── payment_screen.dart
└── utils/
    ├── constants.dart               # Colors and categories
    └── sample_data.dart             # Demo data

```

## UI Highlights

### Design System
- **Primary Color**: Blue (#2563EB)
- **Secondary Color**: Green (#10B981)
- **Accent Color**: Amber (#F59E0B)
- Modern, clean interface with card-based layouts
- Consistent shadows and rounded corners
- Intuitive navigation with bottom tabs

### Key Screens

#### Splash Screen
- Animated logo with fade and scale effects
- Gradient background (Primary to Secondary colors)
- Auto-navigates to login after 3 seconds

#### Authentication Screens
- **Login Screen**:
  - Email and password fields with validation
  - Password visibility toggle
  - Forgot password option
  - Social login buttons (Google, Apple)
  - Link to sign up
- **Signup Screen**:
  - Full name, email, phone, and password fields
  - Password confirmation with matching validation
  - Terms & conditions checkbox
  - Form validation with error messages

#### Welcome Screen
- Choose between "I'm a Worker" or "I Need a Worker"
- Beautiful card-based selection interface

#### Worker Dashboard
- Stats cards showing rating, total jobs, and hourly rate
- Pending job requests with accept/decline actions
- Bottom navigation: Home, Jobs, Earnings, Profile

#### User Home
- Search bar for finding workers
- Horizontal scrolling category chips
- Worker cards with ratings, location, and hourly rates
- Availability indicators

#### Payment Flow
- Job summary with worker details
- Multiple payment method options
- Card details form
- Cost breakdown with service fees
- Success confirmation

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- iOS Simulator / Android Emulator / Physical Device

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd fyp
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Usage Flow

### Complete User Journey:

1. **Splash Screen** - Beautiful animated splash screen with app logo
2. **Authentication**:
   - Login with email and password
   - Or create a new account (Sign Up)
   - Social login options (Google, Apple)
   - Form validation and error handling
3. **Role Selection** - Choose between "I'm a Worker" or "I Need a Worker"

### As a Worker:
1. Launch app → Login/Signup → Select "I'm a Worker"
2. View your dashboard with stats and pending requests
3. Navigate to Profile to edit your details and hourly rate
4. Accept/decline job requests from the Jobs tab
5. Track your earnings in the Earnings tab

### As a User:
1. Launch app → Login/Signup → Select "I Need a Worker"
2. Browse workers or filter by category
3. Tap on a worker to view their detailed profile
4. Click "Hire Now" to request a job
5. Fill in job details, location, date, and estimated hours
6. Track your jobs in the Jobs screen
7. Pay workers after job completion

## Sample Data

The app includes sample data with:
- 5 pre-configured workers across different categories
- Sample jobs with various statuses
- Transaction history
- Reviews and ratings

## Future Enhancements

- Real-time chat between users and workers
- Push notifications for job updates
- GPS-based worker discovery
- In-app reviews and ratings
- Photo uploads for jobs
- Backend integration with Firebase/REST API
- User authentication
- Worker verification badges
- Advanced search filters
- Job history analytics

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Material Design 3**: Modern UI components
- **Dart**: Programming language

## License

This project is created for educational purposes.

## Contact

For questions or feedback, please open an issue in the repository.

---

## 🎓 Project Purpose

This app is developed as part of the Final Year Project (FYP) for Bachelor of Science in Computer Science program. It demonstrates:
- Mobile application development using Flutter
- Two-sided marketplace design patterns
- User experience design principles
- Database modeling and management
- Project planning and team collaboration

## 🤝 Team Contributions

- **Muhammad Ali Khalid Khan**: Project lead, full-stack development, system architecture
- **Muhammad Alyan**: Frontend development, UI/UX design, user interface implementation
- **Affan Naveed**: Backend integration planning, AI/ML research, data modeling

## 🔮 Future Roadmap (AI Integration)

As per the project proposal, the platform will integrate:
1. **AI Recommendation System**: Personalized gig suggestions for both workers and clients
2. **Skill-Location Matchmaking**: NLP-based matching of workers to relevant jobs in their area
3. **Smart Search**: AI-powered search with semantic understanding
4. **Rating Prediction**: ML models to predict worker performance

## 📞 Contact

For questions or collaboration:
- Muhammad Ali: muhammadali.2112000@gmail.com
- Muhammad Alyan: alyanjaved632@gmail.com
- Affan Naveed: Affannaveed25@gmail.com

---

Built with ❤️ using Flutter for BSCS Final Year Project
