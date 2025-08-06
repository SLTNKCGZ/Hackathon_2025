import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'QuestionDetailPage.dart';

class TopicDetailPage extends StatefulWidget {
  final int lessonId;
  final int termId;
  final String termTitle;
  final String token;

  const TopicDetailPage({
    super.key,
    required this.lessonId,
    required this.termId,
    required this.termTitle,
    required this.token,
  });

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  int selectedDifficulty = 1;
  Map<int, List<Map<String, dynamic>>> questionsByDifficulty = {
    1: [],
    2: [],
    3: [],
  };

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllQuestions();
  }

  Future<void> fetchAllQuestions() async {
    for (int difficulty in [1, 2, 3]) {
      await fetchQuestionsByDifficulty(difficulty);
    }
  }

  Future<void> fetchQuestionsByDifficulty(int difficulty) async {
    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8000/questions/${widget.lessonId}/$difficulty/${widget.termId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        questionsByDifficulty[difficulty] =
            List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      print("Hata: ${response.statusCode} - ${response.body}");
    }
  }

  void _showAddQuestionDialog() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Soru Notu (Opsiyonel)"),
          content: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(hintText: "Not yazabilirsiniz"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _uploadImage(imageFile, _noteController.text);
                _noteController.clear();
              },
              child: Text("Kaydet"),
            )
          ],
        );
      },
    );
  }

  Future<void> _uploadImage(File imageFile, String note) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/questions/create'),
    );
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    request.fields['difficulty_category'] = selectedDifficulty.toString();
    request.fields['lesson_id'] = widget.lessonId.toString();
    request.fields['term_id'] = widget.termId.toString();
    if (note.isNotEmpty) {
      request.fields['note'] = note;
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Soru eklendi")),
      );
      await fetchQuestionsByDifficulty(selectedDifficulty);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Soru eklenemedi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.termTitle),
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 25),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white,size:25),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        child: Icon(Icons.add_a_photo),
        tooltip: "Soru Ekle",
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                int star = index + 1;
                String label = star == 1
                    ? "Kolay"
                    : star == 2
                        ? "Orta"
                        : "Zor";
                return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDifficulty = star;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedDifficulty == star
                            ? Theme.of(context).colorScheme.tertiary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(
                            12), // <-- Daire değil, yumuşak köşe
                        border: Border.all(
                          color: selectedDifficulty == star
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              3,
                              (i) => Icon(
                                i < star ? Icons.star : Icons.star_border,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:Colors.black54,
                            ),
                          )
                        ],
                      ),
                    ));
              }),
            ),
          ),
          Expanded(
            child: questionsByDifficulty[selectedDifficulty]!.isEmpty
                ? Center(child: Text("Soru yok"))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount:
                        questionsByDifficulty[selectedDifficulty]!.length,
                    itemBuilder: (context, index) {
                      final question =
                          questionsByDifficulty[selectedDifficulty]![index];
                      return GestureDetector(
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionDetailPage(
                                question: question,
                                token: widget.token,
                                lessonId: widget.lessonId,
                                termTitle: widget.termTitle,
                                termId: widget.termId,
                              ),
                            ),
                          );
                          setState(() async {
                            await fetchQuestionsByDifficulty(
                                selectedDifficulty);
                          });

                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: question['image_path'] != null
                                    ? Image.network(
                                        'http://10.0.2.2:8000${question['image_path']}',
                                        height: 180,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 180,
                                        color: Colors.grey.shade300,
                                        child: Icon(Icons.image_not_supported,
                                            size: 40),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  question['note'] != null &&
                                          question['note'].isNotEmpty
                                      ? question['note']
                                      : "Not yok",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                ),
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
    );
  }
}
