class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String? hint;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.hint,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      hint: json['hint'],
    );
  }
}

class QuizResponse {
  final List<QuizQuestion> questions;
  final int totalTime;
  final int difficulty;
  final String type;

  QuizResponse({
    required this.questions,
    required this.totalTime,
    required this.difficulty,
    required this.type,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      totalTime: json['total_time'],
      difficulty: json['difficulty'],
      type: json['type'],
    );
  }
}
