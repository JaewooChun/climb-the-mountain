class GoalValidationRequest {
  final String goalText;
  final String? userId;

  GoalValidationRequest({
    required this.goalText,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'goal_text': goalText,
      if (userId != null) 'user_id': userId,
    };
  }
}

class GoalValidationResponse {
  final bool isValid;
  final double confidenceScore;
  final List<String>? suggestions;
  final String? processedGoal;

  GoalValidationResponse({
    required this.isValid,
    required this.confidenceScore,
    this.suggestions,
    this.processedGoal,
  });

  factory GoalValidationResponse.fromJson(Map<String, dynamic> json) {
    return GoalValidationResponse(
      isValid: json['is_valid'] ?? false,
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      suggestions: json['suggestions'] != null 
          ? List<String>.from(json['suggestions']) 
          : null,
      processedGoal: json['processed_goal'],
    );
  }
}

class GoalValidationException implements Exception {
  final String message;
  final int? statusCode;

  GoalValidationException(this.message, {this.statusCode});

  @override
  String toString() => 'GoalValidationException: $message';
}