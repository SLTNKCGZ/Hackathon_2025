import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'QuestionDetailPage.dart';

class QuestionsPage extends StatefulWidget {
  final String token;
  const QuestionsPage({super.key, required this.token});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  List<Map<String, dynamic>> lessons = [];
  Map<int, List<Map<String, dynamic>>> terms = {};
  Map<int, Map<int, List<Map<String, dynamic>>>> questions =
      {}; // lesson_id -> term_id -> questions
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  int selectedStarRating = 1;

  Future<void> fetchLessons() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/lesson/QuestionLessons'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        lessons = List<Map<String, dynamic>>.from(
            json.decode(response.body).map((e) => {
                  'title': e['title'],
                  'id': e['id'],
                }));
      });
      // Fetch terms for each lesson
      for (var lesson in lessons) {
        await fetchTerms(lesson['id']);
      }
    } else {
      print("Hata: ${response.statusCode} - ${response.body}");
    }
  }

  Future<void> fetchTerms(int lessonId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/term/QuestionTerms/$lessonId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        terms[lessonId] = List<Map<String, dynamic>>.from(
            json.decode(response.body).map((e) => {
                  'title': e['title'],
                  'id': e['id'],
                }));
      });
      // Initialize questions structure for this lesson
      if (!questions.containsKey(lessonId)) {
        questions[lessonId] = {};
      }
      // Fetch questions for each term
      for (var term in terms[lessonId]!) {
        await fetchQuestions(lessonId, term['id']);
      }
    } else {
      print("Hata: ${response.statusCode} - ${response.body}");
    }
  }

  Future<void> fetchQuestions(int lessonId, int termId) async {
    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8000/questions/$lessonId/$selectedStarRating/$termId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        questions[lessonId]![termId] = List<Map<String, dynamic>>.from(
            json.decode(response.body).map((e) => {
                  'id': e['id'],
                  'image_path': e['image_path'],
                  'note': e['note'],
                  'difficulty_category': e['difficulty_category'],
                }));
      });
    } else {
      print("Hata: ${response.statusCode} - ${response.body}");
    }
  }

  Future<void> addLesson(String title) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/lesson/QuestionLesson/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'lesson_title': title}),
    );
    if (response.statusCode == 200) {
      fetchLessons();
    } else {
      print("Hata: ${response.statusCode} - ${response.body}");
    }
  }

  Future<void> addTerm(int lessonId, String title) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/term/QuestionTerm/create/$lessonId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'term_title': title}),
    );
    print(response.body);
    if (response.statusCode == 200) {
      await fetchTerms(lessonId);
    } else {
      print("Hata: ${response.statusCode} - ${response.body}");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLessons();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showAddLessonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ders Ekle"),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: "Ders adı"),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("İptal")),
          TextButton(
              onPressed: () {
                addLesson(_controller.text);
                _controller.clear();
                Navigator.pop(context);
              },
              child: Text("Ekle"))
        ],
      ),
    );
  }

  void showAddTopicDialog(int lessonId, String lessonTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$lessonTitle - Konu Ekle"),
        content: TextField(
          controller: _topicController,
          decoration: InputDecoration(hintText: "Konu adı"),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("İptal")),
          TextButton(
              onPressed: () {
                addTerm(lessonId, _topicController.text);
                _topicController.clear();
                Navigator.pop(context);
              },
              child: Text("Ekle"))
        ],
      ),
    );
  }

  void showAddQuestionDialog(int lessonId, int termId, String termTitle) {
    final questionController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: EdgeInsets.all(16), // kenarlardan boşluk bırakır
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("$termTitle - Soru Ekle",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),

                    // Image picker
                    GestureDetector(
                      onTap: () async {
                        File? image = await pickImage();
                        if (image != null) {
                          setDialogState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.purple[50],
                        ),
                        child: selectedImage == null
                            ? Center(
                                child: Text(
                                  "Fotoğraf seç\n(Butona tıkla)",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.purple),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 16),
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(
                        hintText: "Soru notu (opsiyonel)",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Zorluk Seviyesi: ${selectedStarRating == 1 ? 'Kolay' : selectedStarRating == 2 ? 'Orta' : 'Zor'}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          3,
                          (index) => Icon(
                                index < selectedStarRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.orange,
                                size: 24,
                              )),
                    ),
                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("İptal"),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                            onPressed: () async {
                              if (selectedImage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Lütfen bir resim seçin")),
                                );
                                return;
                              }
                              if (lessons != null) {
                                await createQuestion(lessonId, termId,
                                    selectedImage!, questionController.text);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Lütfen bir resim seçin")),
                                );
                              }
                            },
                            child: Text("Ekle"))
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> createQuestion(
      int lessonId, int termId, File imageFile, String note) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/questions/create'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      // Add image file
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add form fields
      request.fields['difficulty_category'] = selectedStarRating.toString();
      request.fields['lesson_id'] = lessonId.toString();
      request.fields['term_id'] = termId.toString();
      if (note.isNotEmpty) {
        request.fields['note'] = note;
      }

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Refresh questions for this term
        await fetchQuestions(lessonId, termId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Soru başarıyla eklendi")),
        );
      } else {
        print("Hata: ${response.statusCode} - $responseData");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Soru eklenirken hata oluştu")),
        );
      }
    } catch (e) {
      print("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Soru eklenirken hata oluştu")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Scaffold(
          appBar: AppBar(
        title: Text("Sorular"),
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
        backgroundColor: Colors.purple[600],
        leading: Icon(Icons.quiz, size: 30, color: Colors.white),
        actions: [
          GestureDetector(
            onTap: showAddLessonDialog,
            child: Container(
              margin: EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.purple[300],
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Text("Ders ekle", style: TextStyle(color: Colors.white)),
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ]),
            ),
          ),
        ],
      ));
    }
    return DefaultTabController(
        length: lessons.length,
        child: Scaffold(
          appBar: AppBar(
              title: Text("Sorular"),
              titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 25),
              backgroundColor: Colors.purple[600],
              leading: Icon(Icons.quiz, size: 30, color: Colors.white),
              actions: [
                GestureDetector(
                  onTap: showAddLessonDialog,
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Text("Ders ekle", style: TextStyle(color: Colors.white)),
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ]),
                  ),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: lessons
                    .map((lesson) => Tab(
                          text: lesson["title"],
                        ))
                    .toList(),
              )),
          body: TabBarView(
            children: lessons.map((lesson) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    buildStars(lesson["id"]),
                    buildThePage(lesson["id"]),
                  ],
                ),
              );
            }).toList(),
          ),
        ));
  }

  Widget buildThePage(int lessonId) {
    List<Map<String, dynamic>> lessonTerms = terms[lessonId] ?? [];

    return Column(
      children: [
        // Add term button
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => showAddTopicDialog(lessonId,
                    lessons.firstWhere((l) => l['id'] == lessonId)['title']),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Text("Konu ekle", style: TextStyle(color: Colors.white)),
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // Terms with their questions
        ...lessonTerms.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> term = entry.value;
          int termId = term['id'];
          String termTitle = term['title'];
          List<Map<String, dynamic>> termQuestions =
              questions[lessonId]?[termId] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Term header with add button
              Container(
                margin: EdgeInsets.only(top: 20, bottom: 12),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      "${termTitle}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () =>
                          showAddQuestionDialog(lessonId, termId, termTitle),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Text("Soru ekle",
                              style: TextStyle(color: Colors.white)),
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 30,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),

              // Questions for this term
              if (termQuestions.isNotEmpty)
                Container(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: termQuestions.length,
                    itemBuilder: (context, questionIndex) => _buildQuestionCard(
                      termQuestions[questionIndex],
                    ),
                  ),
                )
              else
                Container(
                  height: 100,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      "Bu konuda henüz soru bulunmuyor",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    Color difficultyColor;
    switch (question['difficulty_category']) {
      case 1:
        difficultyColor = Colors.green;
        break;
      case 2:
        difficultyColor = Colors.orange;
        break;
      case 3:
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionDetailPage(
              question: question,
              token: widget.token,
            ),
          ),
        );

        if (changed == true) {
          int lessonId = question['lesson_id'];
          int termId = question['term_id'];
          await fetchQuestions(lessonId, termId);
          setState(() {});
        }
      },
      child: Container(
        width: 220,
        margin: EdgeInsets.only(right: 12),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // Question image
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: question['image_path'] != null
                      ? Image.network(
                          'http://10.0.2.2:8000${question['image_path']}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                ),
              ),

              // Difficulty indicator
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Soru",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: difficultyColor,
                      ),
                    ),
                    Row(
                      children: List.generate(
                          3,
                          (index) => Icon(
                                index < question['difficulty_category']
                                    ? Icons.star
                                    : Icons.star_border,
                                color: difficultyColor,
                                size: 16,
                              )),
                    ),
                  ],
                ),
              ),

              // Question note
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (question['note'] != null &&
                          question['note'].isNotEmpty)
                        Text(
                          question['note'],
                          style: TextStyle(fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          "Not yok",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          maxLines: 1,
                        ),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  buildStars(lesson_id) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStarRatingButton(1, "Kolay", lesson_id),
          _buildStarRatingButton(2, "Orta", lesson_id),
          _buildStarRatingButton(3, "Zor", lesson_id),
        ],
      ),
    );
  }

  Widget _buildStarRatingButton(int stars, String title, int lessonId) {
    bool isSelected = selectedStarRating == stars;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            selectedStarRating = stars;
          });
          // Refresh questions for all terms with new difficulty
          if (terms.containsKey(lessonId)) {
            for (var term in terms[lessonId]!) {
              await fetchQuestions(lessonId, term['id']);
            }
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple[700] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.purple : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    3,
                    (index) => Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color:
                              isSelected ? Colors.white : Colors.purpleAccent,
                          size: 20,
                        )),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
