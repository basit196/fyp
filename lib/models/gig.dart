class Gig {
  final String id;
  final String workerId;
  final String workerName;
  final String workerImage;
  final String title;
  final String description;
  final String category; // Predefined or custom
  final double hourlyRate;
  final int minHours;
  final int maxHours;
  final List<String> skills;
  final List<String> requirements;
  final double rating;
  final int totalOrders;
  final String location;
  final bool isAvailable;
  final DateTime createdAt;

  Gig({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.workerImage,
    required this.title,
    required this.description,
    required this.category,
    required this.hourlyRate,
    required this.minHours,
    required this.maxHours,
    required this.skills,
    required this.requirements,
    this.rating = 0.0,
    this.totalOrders = 0,
    required this.location,
    this.isAvailable = true,
    required this.createdAt,
  });

  double calculatePrice(int hours) {
    return hours * hourlyRate;
  }
}

// Predefined categories
class GigCategories {
  static const List<String> predefined = [
    'Electrician',
    'Plumber',
    'Mechanic',
    'Carpenter',
    'Painter',
    'Cleaner',
    'Gardener',
    'AC Technician',
    'Custom',
  ];
}


