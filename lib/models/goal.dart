import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalStatus {
  active,
  completed,
  cancelled,
}

enum GoalType {
  daily,
  weekly,
  monthly,
  custom,
}

class Goal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final GoalType type;
  final int target;
  final int current;
  final DateTime deadline;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.current = 0,
    required this.deadline,
    this.status = GoalStatus.active,
    required this.createdAt,
    this.completedAt,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == GoalStatus.completed || current >= target;

  int get remaining => (target - current).clamp(0, target);

  // Factory method from Firestore
  factory Goal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: GoalType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => GoalType.custom,
      ),
      target: data['target'] ?? 0,
      current: data['current'] ?? 0,
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: GoalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'target': target,
      'current': current,
      'deadline': Timestamp.fromDate(deadline),
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    GoalType? type,
    int? target,
    int? current,
    DateTime? deadline,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      current: current ?? this.current,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}




