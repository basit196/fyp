enum WorkerLevel {
  newbie,
  professional,
  expert,
}

class Worker {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final double? hourlyRate; // Optional; each gig has its own price
  final String description;
  final double rating;
  final int totalJobs;
  final List<String> skills;
  final String location;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final List<Review> reviews;
  final WorkerLevel level;
  final int yearsOfExperience;
  final List<String> portfolio; // URLs to work images
  final int completedProjects;
  final double successRate;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    this.hourlyRate,
    required this.description,
    this.rating = 0.0,
    this.totalJobs = 0,
    required this.skills,
    required this.location,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
    this.reviews = const [],
    this.level = WorkerLevel.newbie,
    this.yearsOfExperience = 0,
    this.portfolio = const [],
    this.completedProjects = 0,
    this.successRate = 100.0,
  });

  String get levelName {
    switch (level) {
      case WorkerLevel.newbie:
        return 'Newbie';
      case WorkerLevel.professional:
        return 'Professional';
      case WorkerLevel.expert:
        return 'Expert';
    }
  }

  String get levelBadge {
    switch (level) {
      case WorkerLevel.newbie:
        return '🌱';
      case WorkerLevel.professional:
        return '⭐';
      case WorkerLevel.expert:
        return '👑';
    }
  }
}

class Review {
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}


