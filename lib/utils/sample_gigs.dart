import '../models/gig.dart';

class SampleGigs {
  static List<Gig> gigs = [
    Gig(
      id: 'g1',
      workerId: '1',
      workerName: 'John Smith',
      workerImage: 'https://ui-avatars.com/api/?name=John+Smith&background=2563EB&color=fff',
      title: 'Professional Electrical Installation & Repair',
      description: 'Expert electrical services for residential and commercial properties. I specialize in wiring, panel upgrades, circuit repairs, lighting installation, and electrical troubleshooting. Licensed and insured with 10+ years of experience.',
      category: 'Electrician',
      hourlyRate: 50.0,
      minHours: 2,
      maxHours: 8,
      skills: ['Wiring', 'Panel Installation', 'Circuit Repair', 'Lighting', 'Troubleshooting'],
      requirements: ['Licensed Electrician', '10+ Years Experience', 'Insured'],
      rating: 4.8,
      totalOrders: 156,
      location: 'New York, NY',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Gig(
      id: 'g2',
      workerId: '2',
      workerName: 'Mike Johnson',
      workerImage: 'https://ui-avatars.com/api/?name=Mike+Johnson&background=10B981&color=fff',
      title: 'Complete Plumbing Services - Fast & Reliable',
      description: 'Professional plumbing services including pipe repairs, drain cleaning, water heater installation, leak detection, and emergency plumbing. Available for residential and commercial projects.',
      category: 'Plumber',
      hourlyRate: 45.0,
      minHours: 1,
      maxHours: 10,
      skills: ['Pipe Repair', 'Drain Cleaning', 'Water Heater', 'Leak Detection', 'Emergency Service'],
      requirements: ['Certified Plumber', '8+ Years Experience', 'Same Day Service'],
      rating: 4.9,
      totalOrders: 203,
      location: 'Los Angeles, CA',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Gig(
      id: 'g3',
      workerId: '3',
      workerName: 'David Wilson',
      workerImage: 'https://ui-avatars.com/api/?name=David+Wilson&background=EF4444&color=fff',
      title: 'Auto Mechanic - All Makes & Models',
      description: 'Experienced automotive technician offering engine diagnostics, brake service, oil changes, transmission repair, and general maintenance. Mobile service available.',
      category: 'Mechanic',
      hourlyRate: 55.0,
      minHours: 2,
      maxHours: 8,
      skills: ['Engine Repair', 'Brake Service', 'Oil Change', 'Diagnostics', 'Transmission'],
      requirements: ['ASE Certified', '12+ Years Experience', 'Mobile Service'],
      rating: 4.7,
      totalOrders: 178,
      location: 'Chicago, IL',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Gig(
      id: 'g4',
      workerId: '4',
      workerName: 'Sarah Martinez',
      workerImage: 'https://ui-avatars.com/api/?name=Sarah+Martinez&background=8B5CF6&color=fff',
      title: 'Interior & Exterior Painting Services',
      description: 'Professional painting services with attention to detail. Specializing in residential and commercial painting, wall preparation, color consultation, and finishing.',
      category: 'Painter',
      hourlyRate: 40.0,
      minHours: 3,
      maxHours: 10,
      skills: ['Interior Painting', 'Exterior Painting', 'Wall Prep', 'Color Consulting', 'Finishing'],
      requirements: ['5+ Years Experience', 'Quality Materials', 'Clean Work'],
      rating: 4.8,
      totalOrders: 145,
      location: 'Houston, TX',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Gig(
      id: 'g5',
      workerId: '5',
      workerName: 'Robert Brown',
      workerImage: 'https://ui-avatars.com/api/?name=Robert+Brown&background=92400E&color=fff',
      title: 'Custom Carpentry & Furniture Assembly',
      description: 'Expert carpenter offering custom woodworking, furniture assembly, cabinet installation, door fitting, and deck building. Quality craftsmanship guaranteed.',
      category: 'Carpenter',
      hourlyRate: 48.0,
      minHours: 2,
      maxHours: 12,
      skills: ['Furniture Assembly', 'Custom Cabinets', 'Door Installation', 'Deck Building', 'Woodworking'],
      requirements: ['10+ Years Experience', 'Own Tools', 'Precision Work'],
      rating: 4.6,
      totalOrders: 134,
      location: 'Phoenix, AZ',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Gig(
      id: 'g6',
      workerId: '6',
      workerName: 'Emily Davis',
      workerImage: 'https://ui-avatars.com/api/?name=Emily+Davis&background=EC4899&color=fff',
      title: 'Deep Cleaning & Home Organization',
      description: 'Professional cleaning services for homes and offices. Deep cleaning, organization, move-in/out cleaning, and regular maintenance. Eco-friendly products available.',
      category: 'Cleaner',
      hourlyRate: 35.0,
      minHours: 2,
      maxHours: 8,
      skills: ['Deep Cleaning', 'Organization', 'Move-in/out', 'Eco-friendly', 'Maintenance'],
      requirements: ['Background Checked', '3+ Years Experience', 'Own Supplies'],
      rating: 4.9,
      totalOrders: 189,
      location: 'Miami, FL',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static List<Gig> getGigsByCategory(String category) {
    if (category == 'All') return gigs;
    return gigs.where((gig) => gig.category == category).toList();
  }

  static List<Gig> getWorkerGigs(String workerId) {
    return gigs.where((gig) => gig.workerId == workerId).toList();
  }

  static List<Gig> searchGigs(String query) {
    query = query.toLowerCase();
    return gigs.where((gig) {
      return gig.title.toLowerCase().contains(query) ||
          gig.description.toLowerCase().contains(query) ||
          gig.category.toLowerCase().contains(query) ||
          gig.skills.any((skill) => skill.toLowerCase().contains(query));
    }).toList();
  }
}


