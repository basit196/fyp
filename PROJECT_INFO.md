# SkillLink: A Gig-Based Platform for Local Workers and Craftsmen

## 📋 Project Information

**Project Name:** SkillLink  
**Team Members:**
1. Muhammad Ali Khalid Khan (CSF120222080) - BSCS 7th
2. Muhammad Alyan (CS120222080) - BSCS 7th  
3. Affan Naveed (CS120222079) - BSCS 7th

**Institution:** [Your University Name]  
**Program:** Bachelor of Science in Computer Science

---

## 🎯 Abstract

SkillLink is a gig-based platform similar to Fiverr, but tailored specifically for skilled workers and craftsmen such as plumbers, carpenters, electricians, ceramic potters, painters, mechanics, tailors, and other service providers. The platform allows workers to create customized profiles, post their gigs, and be discovered by potential clients.

A hierarchical leveling system (Newbie, Professional, Expert) incentivizes workers to enhance their profiles and performance. Clients can browse gigs, assign projects, and rate completed work. With the integration of Artificial Intelligence (AI), the platform features smart recommendation systems and skill-location based matchmaking, ensuring efficient, reliable, and personalized connections between workers and clients.

---

## 🚀 Features Implemented

### ✅ Core Features

#### Worker Side:
1. **Customized Profiles**
   - Name, contact, location, experience
   - Skills showcase
   - Portfolio support
   - Hierarchical levels (Newbie 🌱, Professional ⭐, Expert 👑)

2. **Gig Creation**
   - Detailed service descriptions
   - Hourly rate setting
   - Hour range configuration (min-max)
   - Category selection (+ custom categories)
   - Skills and requirements listing

3. **Level Hierarchy System**
   - **Newbie**: 0-50 completed projects, <95% success rate
   - **Professional**: 51-150 completed projects, 95-98% success rate
   - **Expert**: 150+ completed projects, 98%+ success rate
   - Visual badges throughout UI

4. **Job Management**
   - Accept/decline requests
   - Track active jobs
   - View completed projects
   - Monitor earnings

#### Client Side:
1. **Browse & Search**
   - Search across all gigs
   - Filter by category
   - View worker levels
   - See ratings and reviews

2. **Detailed Gig View**
   - Complete service information
   - Worker credentials and experience
   - Skills and requirements
   - Pricing transparency

3. **Flexible Hiring**
   - Select exact hours needed (slider-based)
   - Real-time cost calculation
   - Custom job description
   - Location and date selection

4. **Project Management**
   - Track active requests
   - View job history
   - Rate completed work
   - Make secure payments

### ✅ AI-Ready Features

1. **Skill-Based Matching**
   - Workers tagged with specific skills
   - Gigs categorized by service type
   - Ready for NLP integration

2. **Location-Based Data**
   - Worker location stored
   - Job location specified
   - Infrastructure for proximity matching

3. **Rating & Performance Metrics**
   - Success rate tracking
   - Completion statistics
   - Review system
   - Data ready for collaborative filtering

---

## 🛠️ Technology Stack

### Frontend
- **Flutter** - Cross-platform mobile & web development
- **Dart** - Programming language
- **Material Design 3** - Modern UI components
- **Iconsax** - Beautiful modern icon set

### Backend (Planned)
- **Node.js** / **Django** - Server-side logic
- **MySQL** / **Firebase** - Database
- **JWT** / **Firebase Auth** - Authentication

### AI Integration (Planned)
- **Scikit-learn** - Recommendation algorithms
- **TensorFlow Lite** - Mobile ML
- **Firebase ML** - Cloud-based ML
- **Google Maps API** - Location services
- **NLP Libraries** - Skill matching

### Payment Gateway (Planned)
- **Stripe** / **PayPal** / Local Bank APIs

---

## 📱 Screens & UI Components

### Authentication Flow
1. **Splash Screen** - Brand introduction
2. **Role Selection** - Worker vs Client choice
3. **Login/Signup** - Secure authentication

### Worker Interface
1. **Dashboard** - Stats, pending requests, quick actions
2. **Create Gig** - Comprehensive gig creation form
3. **Jobs Management** - Pending, active, completed tabs
4. **Earnings** - Revenue tracking and history
5. **Profile** - Personal information and portfolio

### Client Interface
1. **Browse Gigs** - Marketplace with search & filters
2. **Gig Details** - Complete service information
3. **Request Service** - Hour selection and booking
4. **My Jobs** - Track all service requests
5. **Payment** - Secure checkout process

---

## 🎨 Design System

### Color Palette
- **Primary**: Blue (#2563EB) - Trust, professionalism
- **Secondary**: Green (#10B981) - Success, growth
- **Accent**: Amber (#F59E0B) - Attention, ratings
- **Error**: Red (#EF4444) - Warnings, alerts

### Level Colors
- **Newbie**: Green (#10B981) - Growth, learning
- **Professional**: Amber (#F59E0B) - Excellence, experience
- **Expert**: Red/Purple (#EF4444) - Mastery, premium

### UI Principles
- Modern, clean interfaces
- Consistent spacing and shadows
- Intuitive navigation
- Clear information hierarchy
- Accessible design patterns

---

## 📊 Data Models

### Worker Model
```dart
- ID, Name, Email, Phone
- Profile Image, Description
- Category, Skills, Location
- Hourly Rate, Availability
- Level (Enum: Newbie/Professional/Expert)
- Years of Experience
- Completed Projects
- Success Rate
- Portfolio (images)
- Rating, Total Jobs
- Reviews
```

### Gig Model
```dart
- ID, Worker ID, Worker Details
- Title, Description
- Category (predefined/custom)
- Hourly Rate
- Min/Max Hours
- Skills, Requirements
- Rating, Total Orders
- Location, Availability
```

### Job/Request Model
```dart
- ID, Gig ID, User ID, Worker ID
- Description, Location, Date
- Selected Hours, Total Cost
- Status (pending/accepted/in-progress/completed)
- Timestamps
```

---

## 🎯 Alignment with Proposal Objectives

### ✅ Completed
1. ✅ Gig platform tailored for local service providers
2. ✅ Worker profiles with expertise showcase
3. ✅ Transparent hiring system for clients
4. ✅ Leveling system (Newbie/Professional/Expert) implemented
5. ✅ Foundation for AI recommendations (data structure ready)
6. ✅ Infrastructure for skill & location matching
7. ✅ Admin controls (dispute system in development)

### 🔄 In Progress / Planned
- AI recommendation engine implementation
- NLP-based skill matching algorithm
- Payment gateway integration
- Real-time chat system
- Admin panel development
- GPS-based worker discovery
- Push notifications

---

## 🚧 Challenges Addressed

### Trust & Reliability
- ✅ Level system with badges
- ✅ Rating and review system
- ✅ Success rate tracking
- ✅ Detailed worker profiles

### User-Friendly Interface
- ✅ Intuitive navigation
- ✅ Visual hierarchy
- ✅ Modern, clean design
- ✅ Consistent UI patterns

### Secure Transactions
- ⏳ Payment gateway integration planned
- ✅ Transaction tracking system in place
- ✅ Cost transparency

### Scalability
- ✅ Modular code architecture
- ✅ Reusable components
- ✅ Clean data models
- ✅ Ready for backend integration

---

## 📈 Future Enhancements

### Phase 1 (Current - UI Complete)
- ✅ Complete UI/UX for both sides
- ✅ Gig creation and browsing
- ✅ Level system implementation
- ✅ Request flow

### Phase 2 (Backend Integration)
- Backend API development
- Database implementation
- Real authentication system
- File upload for portfolios

### Phase 3 (AI Integration)
- Recommendation system
- NLP skill matching
- Location-based suggestions
- Smart search

### Phase 4 (Advanced Features)
- Real-time chat
- Push notifications
- Admin dashboard
- Analytics & insights
- Payment processing

---

## 📝 Methodology Followed

1. ✅ **Requirement Gathering** - Proposal analysis
2. ✅ **System Design** - Data models, UI wireframes
3. ✅ **Prototype Development** - Basic worker-client interaction
4. ✅ **Core Development** - Profiles, gigs, request system
5. ⏳ **AI Module Development** - Structure ready
6. ⏳ **Testing** - Unit testing in progress
7. ⏳ **Deployment** - Planned for final phase

---

## 🎓 Academic Contribution

This project demonstrates:
- **Software Engineering**: Agile methodology, version control
- **Mobile Development**: Cross-platform app using Flutter
- **UI/UX Design**: Modern, user-centered design principles
- **Database Design**: Normalized data models
- **AI/ML Concepts**: Recommendation systems, NLP applications
- **Project Management**: Team collaboration, documentation

---

## 📞 Contact Information

**Muhammad Ali Khalid Khan**  
Email: muhammadali.2112000@gmail.com  
Role: Project Lead & Full-Stack Developer

**Muhammad Alyan**  
Email: alyanjaved632@gmail.com  
Role: Frontend Developer & UI/UX Designer

**Affan Naveed**  
Email: Affannaveed25@gmail.com  
Role: Backend Developer & AI Integration Specialist

---

## 📄 License & Usage

This project is developed as part of academic coursework for BSCS 7th Semester.  
All rights reserved to the development team.

---

**Last Updated:** November 2025  
**Version:** 1.0.0 (UI Complete)  
**Status:** Active Development 🚀


