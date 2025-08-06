import 'package:flutter/material.dart';
import '../models/quiz_models.dart';

class QuizPage extends StatefulWidget {
  final QuizResponse quiz;

  const QuizPage({super.key, required this.quiz});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentIndex = 0;
  Map<int, String> userAnswers = {};
  bool answered = false;

  @override
  void initState() {
    super.initState();
    print("📘 QuizPage'e gelen soru sayısı: ${widget.quiz.questions.length}");

    for (var i = 0; i < widget.quiz.questions.length; i++) {
      print("👉 Soru ${i + 1}: ${widget.quiz.questions[i].question}");
      print("🔹 Şıklar: ${widget.quiz.questions[i].options}");
      print("✅ Doğru cevap: ${widget.quiz.questions[i].correctAnswer}");
    }
  }

  void selectAnswer(String answer) {
    if (answered) return; // bir kere cevap verince değişmesin

    setState(() {
      userAnswers[currentIndex] = answer;
      answered = true;
    });

    // Kısa gecikme ile sonraki soruya geç
    Future.delayed(const Duration(seconds: 1), () {
      if (currentIndex < widget.quiz.questions.length - 1) {
        setState(() {
          currentIndex++;
          answered = false;
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResultPage(
              quiz: widget.quiz,
              userAnswers: userAnswers,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[currentIndex];
    final selectedAnswer = userAnswers[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${currentIndex + 1}/${widget.quiz.questions.length}'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 25,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(size: 28, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.question,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...question.options.map((option) {
              final isSelected = option == selectedAnswer;
              final isCorrect = option == question.correctAnswer;

              Color optionColor;
              if (!answered) {
                optionColor = Colors.blueGrey.shade100;
              } else if (isSelected && isCorrect) {
                optionColor = Colors.green.shade300;
              } else if (isSelected && !isCorrect) {
                optionColor = Colors.red.shade300;
              } else if (isCorrect) {
                optionColor = Colors.green.shade100;
              } else {
                optionColor = Colors.grey.shade200;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: optionColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: answered ? null : () => selectAnswer(option),
                  child: Text(option, style: const TextStyle(fontSize: 16)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class QuizResultPage extends StatelessWidget {
  final QuizResponse quiz;
  final Map<int, String> userAnswers;

  const QuizResultPage({
    super.key,
    required this.quiz,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    int correctCount = 0;

    for (int i = 0; i < quiz.questions.length; i++) {
      if (userAnswers[i] == quiz.questions[i].correctAnswer) {
        correctCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Sonuçları')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Doğru Sayısı: $correctCount / ${quiz.questions.length}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: quiz.questions.length,
                itemBuilder: (context, index) {
                  final question = quiz.questions[index];
                  final userAnswer = userAnswers[index];
                  final isCorrect = userAnswer == question.correctAnswer;

                  return Card(
                    color:
                        isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(question.question),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Senin cevabın: $userAnswer"),
                          Text("Doğru cevap: ${question.correctAnswer}"),
                          if (question.explanation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text("Açıklama: ${question.explanation}"),
                            ),
                          if (question.hint != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text("İpucu: ${question.hint}"),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
