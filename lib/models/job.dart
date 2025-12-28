enum JobStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  paid,
}

class Job {
  final String id;
  final String workerId;
  final String workerName;
  final String userId;
  final String userName;
  final String category;
  final String description;
  final String location;
  final DateTime scheduledDate;
  final double estimatedHours;
  final double hourlyRate;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? finalAmount;
  final double? actualHours;

  Job({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.userId,
    required this.userName,
    required this.category,
    required this.description,
    required this.location,
    required this.scheduledDate,
    required this.estimatedHours,
    required this.hourlyRate,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.finalAmount,
    this.actualHours,
  });

  double get estimatedAmount => estimatedHours * hourlyRate;
}



