# Gig-Based Two-Sided Marketplace System

## 🎯 Overview

The app now operates as a complete two-sided marketplace where:
- **Workers** create detailed "gigs" (service offerings) with pricing and details
- **Users** browse, search, and request these services with customizable hour selections

## 🔧 Worker Side Features

### 1. Create Service Gigs
Workers can create comprehensive service listings:

#### Required Information:
- **Title**: e.g., "Professional Electrical Installation & Repair"
- **Description**: Detailed description of services offered
- **Category**: 
  - Predefined: Electrician, Plumber, Mechanic, Carpenter, Painter, Cleaner, Gardener, AC Technician
  - **Custom**: Workers can define their own category
- **Hourly Rate**: $X per hour (e.g., $50/hr)
- **Hour Range**: 
  - Minimum hours (e.g., 2 hours minimum)
  - Maximum hours (e.g., 8 hours maximum)
- **Skills**: Comma-separated list (e.g., "Wiring, Installation, Troubleshooting")
- **Requirements**: Optional qualifications (e.g., "Licensed, 10+ years experience")

### 2. Create Gig Screen
- Clean, form-based interface
- Category dropdown with custom option
- Dual sliders for min/max hours
- Real-time validation
- Success confirmation

### 3. Access
- From Worker Dashboard → "Create New Service Gig" button (green)
- Located prominently on the home tab

## 👤 User Side Features

### 1. Browse Services
- **Search**: Real-time search across titles, descriptions, categories, and skills
- **Filter by Category**: 
  - "All" to see everything
  - Specific categories (Electrician, Plumber, etc.)
- **View Count**: Shows "X Services Available"
- **Sort/Filter**: Additional filtering options

### 2. Service Cards Display
Each gig card shows:
- Worker profile picture and name
- Worker rating and total orders
- Category badge
- Service title
- Brief description (2 lines)
- Hourly rate: "Starting at $X/hr"
- Hour range: "X-Y hours"

### 3. Detailed Gig View
Tap any gig to see complete details:
- **Header**: Worker info with rating
- **Pricing Card**: Prominent hourly rate display with hour range
- **About**: Full title and description
- **Skills**: Chip-style display of all skills
- **Requirements**: Listed with checkmarks
- **Location & Category**: Info cards
- **Actions**: Message worker or Request Service

### 4. Request Service Flow

#### Hour Selection:
- **Slider**: Smooth adjustment between min and max hours
- **Half-hour increments**: 2.0, 2.5, 3.0, 3.5, etc.
- **Visual feedback**: Current selection prominently displayed
- **Range limits**: Enforced by gig's min/max settings

#### Additional Details:
- **Job Description**: Text area for specific requirements
- **Location**: Where the service is needed
- **Scheduled Date**: Date picker for when work should be done

#### Cost Calculation:
Real-time cost breakdown:
```
Service Cost: Hours × Hourly Rate
Service Fee: $5.00
─────────────────────────
Total: $XXX.XX
```

Example:
- 4.5 hours × $50/hr = $225.00
- Service Fee = $5.00
- **Total = $230.00**

## 📊 Sample Gigs Included

The app includes 6 pre-populated gigs:

1. **Electrical Services** - $50/hr (2-8 hours)
2. **Plumbing Services** - $45/hr (1-10 hours)
3. **Auto Mechanic** - $55/hr (2-8 hours)
4. **Interior/Exterior Painting** - $40/hr (3-10 hours)
5. **Custom Carpentry** - $48/hr (2-12 hours)
6. **Deep Cleaning** - $35/hr (2-8 hours)

## 🎨 UI/UX Highlights

### Modern Design Elements:
- **Gradient Cards**: Primary to secondary color gradients for pricing
- **Chip Badges**: Skills displayed as modern chips
- **Icon Integration**: Iconsax icons throughout
- **Smooth Animations**: Transitions and interactions
- **Visual Hierarchy**: Clear information architecture

### User Experience:
- **3-Click Booking**: Browse → View Details → Request
- **Clear Pricing**: Always visible, no hidden costs
- **Flexible Hours**: Users choose exactly what they need
- **Search First**: Instant search results
- **Category Browsing**: Quick filtering by service type

## 🔄 Complete User Journey

### For Users (Hiring Workers):
1. **Login/Signup** → Select "I Need a Worker"
2. **Browse Gigs** → Search or filter by category
3. **View Details** → See complete gig information
4. **Select Hours** → Choose 2.5-8 hours (example range)
5. **Add Details** → Description, location, date
6. **See Cost** → Real-time calculation
7. **Send Request** → Worker receives notification
8. **Track Job** → Monitor progress in "My Jobs"
9. **Complete & Pay** → After service completion

### For Workers (Offering Services):
1. **Login/Signup** → Select "I'm a Worker"
2. **Create Gig** → Define service offering
   - Set title and description
   - Choose or create category
   - Set hourly rate
   - Define hour range (min-max)
   - List skills and requirements
3. **Publish** → Gig appears in browse section
4. **Receive Requests** → Users can request your gig
5. **Accept Jobs** → Manage in jobs tab
6. **Track Earnings** → Monitor income

## 💡 Key Advantages

### For Workers:
✅ Create multiple gigs for different services
✅ Set flexible pricing per gig
✅ Define custom categories
✅ Control minimum/maximum hours
✅ Showcase skills and qualifications
✅ Build reputation with ratings

### For Users:
✅ Browse detailed service descriptions
✅ Compare rates and offerings
✅ Select exact hours needed
✅ See total cost upfront
✅ Read worker qualifications
✅ Filter by category and search
✅ Request multiple services easily

## 🔮 Future Enhancements

- **Multiple Gigs per Worker**: Workers can have several service offerings
- **Gig Management**: Edit, pause, or delete gigs
- **Advanced Search**: Price range, location radius, availability
- **Saved Gigs**: Users can bookmark favorite services
- **Gig Analytics**: Track views, requests, conversion rates
- **Dynamic Pricing**: Surge pricing, discounts, packages
- **Instant Booking**: Skip request, directly book available slots
- **Reviews per Gig**: Rate specific services, not just workers

## 📱 Technical Implementation

### New Models:
- `Gig`: Complete service offering model
- `GigCategories`: Predefined category list

### New Screens:
- `BrowseGigsScreen`: User-facing gig marketplace
- `GigDetailScreen`: Detailed gig view
- `RequestGigScreen`: Service request with hour selection
- `CreateGigScreen`: Worker gig creation form

### Data Flow:
```
SampleGigs → BrowseGigsScreen (search/filter)
              ↓
         GigDetailScreen (view)
              ↓
       RequestGigScreen (select hours)
              ↓
          Job Request Created
```

This system provides a complete marketplace experience where workers have full control over their service offerings and users get transparent, flexible booking options! 🚀


