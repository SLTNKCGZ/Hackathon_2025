class CulturalQuestion {
  final String question;
  final String answer;

  CulturalQuestion({required this.question, required this.answer});

  factory CulturalQuestion.fromJson(Map<String, dynamic> json) {
    return CulturalQuestion(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}
