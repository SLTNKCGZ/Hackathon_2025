import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hackathon_2025/models/quiz_models.dart';
import 'package:hackathon_2025/pages/profile_page.dart';
import 'package:hackathon_2025/pages/question_pages/questions_page.dart';
import 'package:http/http.dart' as http;
import 'note_pages/subjects_page.dart';
import 'package:hackathon_2025/pages/quiz_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.token});
  final String token;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = [
      HomePageContent(token: widget.token),
      SubjectsPage(token: widget.token),
      QuestionsPage(token: widget.token),
      ProfilePage(token: widget.token)
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _pages = [
      HomePageContent(token: widget.token),
      SubjectsPage(token: widget.token),
      QuestionsPage(token: widget.token),
      ProfilePage(token: widget.token)
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple[600],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Konular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Sorular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key, required this.token});
  final String token;

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  String? firstName;

  @override
  void initState() {
    super.initState();
    fetch_name();
  }

  Future<void> fetch_name() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/auth/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-type': 'application/json'
        });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        firstName = data["firstName"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Merhaba $firstName"),
        backgroundColor: Colors.purple[600],
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        leading: const Icon(Icons.waving_hand, color: Colors.white, size: 25),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(
              top: 40), // AppBar'a yakınlık buradan ayarlanır
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => QuizDialog(token: widget.token),
              );
            },
            child: Container(
              width: 300,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple[300],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Hadi Quiz Yapalım!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizDialog extends StatefulWidget {
  final String token;

  const QuizDialog({super.key, required this.token});

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  String? selectedLesson;
  String? selectedLessonTitle;
  String? selectedDifficulty;
  int? selectedLessonId;
  int? selectedTermId;
  String? selectedSource;
  List<Map<String, dynamic>> availableTerms = [];
  bool isLoadingTerms = false;
  int? questionCount;

  List<Map<String, dynamic>> combinedLessons = [];
  final List<String> difficultyLevels = ["Kolay", "Orta", "Zor"];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLessonsFromBothSources();
  }

  Future<void> fetchLessonsFromBothSources() async {
    final noteUrl = Uri.parse("http://10.0.2.2:8000/lesson/NoteLessons");
    final questionUrl =
        Uri.parse("http://10.0.2.2:8000/lesson/QuestionLessons");

    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };

    try {
      final noteResponse = await http.get(noteUrl, headers: headers);
      final questionResponse = await http.get(questionUrl, headers: headers);

      if (noteResponse.statusCode != 200) {
        throw Exception(
            "NoteLessons hata: ${noteResponse.statusCode} - ${noteResponse.body}");
      }
      if (questionResponse.statusCode != 200) {
        throw Exception(
            "QuestionLessons hata: ${questionResponse.statusCode} - ${questionResponse.body}");
      }

      final noteLessons = jsonDecode(noteResponse.body) as List;
      final questionLessons = jsonDecode(questionResponse.body) as List;

      // source içeren ve farklılaştırılmış başlıkla birlikte her dersi sakla
      final allLessons = [
        ...noteLessons.map((lesson) => {
              "id": lesson["id"],
              "title": lesson["title"],
              "source": "note",
              "displayTitle": "${lesson["title"]} (Not)"
            }),
        ...questionLessons.map((lesson) => {
              "id": lesson["id"],
              "title": lesson["title"],
              "source": "question",
              "displayTitle": "${lesson["title"]} (Soru)"
            }),
      ];

      setState(() {
        combinedLessons = allLessons;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dersler yüklenirken hata: $e")),
      );
    }
  }

  Future<void> fetchTermsForLesson(int lessonId, String source) async {
    final url = Uri.parse(
        "http://10.0.2.2:8000/term/${source == 'note' ? 'NoteTerms' : 'QuestionTerms'}/$lessonId");

    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode != 200) {
        throw Exception("Konular getirilemedi.");
      }

      final terms = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      final unique = <String, Map<String, dynamic>>{};
      for (var term in terms) {
        unique[term['title']] = Map<String, dynamic>.from(term);
      }

      setState(() {
        availableTerms = unique.values.toList();
        isLoadingTerms = false;
      });
    } catch (e) {
      setState(() => isLoadingTerms = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Konu yüklenirken hata: $e")),
      );
    }
  }

  Future<QuizResponse> fetchNoteQuiz({
    required int lessonId,
    required int termId,
    required int difficulty,
    required int count,
  }) async {
    final url = Uri.parse(
        'http://10.0.2.2:8000/api/createNoteQuiz/$lessonId/$termId/$difficulty/$count');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('API cevabı: $data'); // Konsola basarak kontrol et
      return QuizResponse.fromJson(data);
    } else {
      throw Exception('AI quiz yüklenemedi: ${response.statusCode}');
    }
  }

  Future<QuizResponse> fetchQuestionQuiz({
    required int lessonId,
    required int termId,
    required int difficulty,
    required int count,
  }) async {
    final url = Uri.parse(
        'http://10.0.2.2:8000/api/createQuestionQuiz/$lessonId/$termId/$difficulty/$count');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return QuizResponse.fromJson(data);
    } else {
      throw Exception(
          'AI görsel sorulardan quiz yüklenemedi: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Quiz Ayarları"),
      content: isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Ders Seçin"),
                  value: selectedLessonTitle,
                  items: combinedLessons.map((lesson) {
                    return DropdownMenuItem<String>(
                      value: lesson["displayTitle"],
                      child: Text(lesson["displayTitle"]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selected = combinedLessons
                        .firstWhere((e) => e["displayTitle"] == value);
                    setState(() {
                      selectedLessonTitle = value;
                      selectedLessonId = selected["id"];
                      selectedSource = selected["source"];
                      selectedTermId = null;
                      availableTerms = [];
                      isLoadingTerms = true;
                    });
                    fetchTermsForLesson(selected["id"], selected["source"]);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: "Zorluk Seviyesi"),
                  value: selectedDifficulty,
                  items: difficultyLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDifficulty = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                isLoadingTerms
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<int>(
                        decoration:
                            const InputDecoration(labelText: "Konu Seçin"),
                        value: selectedTermId,
                        items: availableTerms.map((term) {
                          return DropdownMenuItem<int>(
                            value: term["id"],
                            child: Text(term["title"]),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTermId = value;
                          });
                        },
                      ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Soru Sayısı",
                    hintText: "Örn: 5",
                  ),
                  onChanged: (value) {
                    setState(() {
                      questionCount = int.tryParse(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (selectedLessonId != null &&
                selectedDifficulty != null &&
                selectedTermId != null &&
                selectedSource != null) {
              // Dialog'u kapatmadan önce işlem yapacağız çünkü quiz çağrısı asenkron ve uzun sürebilir
              print("Seçimler tamamlandı, quiz başlatılıyor");

              // Zorluk seviyesini string'ten int'e çevir
              int? difficultyValue;
              switch (selectedDifficulty) {
                case "Kolay":
                  difficultyValue = 1;
                  break;
                case "Orta":
                  difficultyValue = 2;
                  break;
                case "Zor":
                  difficultyValue = 3;
                  break;
                default:
                  difficultyValue = null;
              }

              if (difficultyValue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Geçerli bir zorluk seviyesi seçin")),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Quiz yükleniyor, lütfen bekleyin...")),
              );


              try {
                final quiz = selectedSource == "note"
                    ? await fetchNoteQuiz(
                        lessonId: selectedLessonId!,
                        termId: selectedTermId!,
                        difficulty: difficultyValue,
                        count: questionCount ?? 5,
                      )
                    : await fetchQuestionQuiz(
                        lessonId: selectedLessonId!,
                        termId: selectedTermId!,
                        difficulty: difficultyValue,
                        count: questionCount ?? 5,
                       );

                print("Quiz çekildi. Soru sayısı: ${quiz.questions.length}");

                Navigator.pop(
                    context); // Dialog'u kapat (quiz yüklendikten sonra)

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(quiz: quiz),
                  ),
                );
              } catch (e) {
                print("Quiz yüklenirken hata: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Quiz yüklenirken hata oluştu: $e")),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Lütfen ders, zorluk ve konu seçin")),
              );
            }
          },
          child: const Text("Başla"),
        ),
      ],
    );
  }
}

