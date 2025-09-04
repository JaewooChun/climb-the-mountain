class UserProfile {
  final String id;
  final String? financialGoal;
  final DateTime createdAt;
  final DateTime? goalSetAt;
  final int currentLevel;
  final int totalTasksCompleted;
  final int chiselCount;
  final int tasksCompletedInCurrentLevel;
  final Map<String, dynamic>? transactionHistory; // Store mock transaction data

  const UserProfile({
    required this.id,
    this.financialGoal,
    required this.createdAt,
    this.goalSetAt,
    this.currentLevel = 1,
    this.totalTasksCompleted = 0,
    this.chiselCount = 0,
    this.tasksCompletedInCurrentLevel = 0,
    this.transactionHistory,
  });

  UserProfile copyWith({
    String? id,
    String? financialGoal,
    DateTime? createdAt,
    DateTime? goalSetAt,
    int? currentLevel,
    int? totalTasksCompleted,
    int? chiselCount,
    int? tasksCompletedInCurrentLevel,
    Map<String, dynamic>? transactionHistory,
  }) {
    return UserProfile(
      id: id ?? this.id,
      financialGoal: financialGoal ?? this.financialGoal,
      createdAt: createdAt ?? this.createdAt,
      goalSetAt: goalSetAt ?? this.goalSetAt,
      currentLevel: currentLevel ?? this.currentLevel,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      chiselCount: chiselCount ?? this.chiselCount,
      tasksCompletedInCurrentLevel: tasksCompletedInCurrentLevel ?? this.tasksCompletedInCurrentLevel,
      transactionHistory: transactionHistory ?? this.transactionHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'financialGoal': financialGoal,
      'createdAt': createdAt.toIso8601String(),
      'goalSetAt': goalSetAt?.toIso8601String(),
      'currentLevel': currentLevel,
      'totalTasksCompleted': totalTasksCompleted,
      'chiselCount': chiselCount,
      'tasksCompletedInCurrentLevel': tasksCompletedInCurrentLevel,
      'transactionHistory': transactionHistory,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      financialGoal: json['financialGoal'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      goalSetAt: json['goalSetAt'] != null
          ? DateTime.parse(json['goalSetAt'] as String)
          : null,
      currentLevel: json['currentLevel'] as int? ?? 1,
      totalTasksCompleted: json['totalTasksCompleted'] as int? ?? 0,
      chiselCount: json['chiselCount'] as int? ?? 0,
      tasksCompletedInCurrentLevel: json['tasksCompletedInCurrentLevel'] as int? ?? 0,
      transactionHistory: json['transactionHistory'] as Map<String, dynamic>?,
    );
  }
}