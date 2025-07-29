import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class QuestionsPage extends StatefulWidget {
  final String token;
  const QuestionsPage({super.key, required this.token});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  List<String> lessons = [];
  final TextEditingController _controller = TextEditingController();

  Future<void> fetchLessons() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/lesson/QuestionLessons'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        lessons = List<String>.from(
            json.decode(response.body).map((e) => e['lesson_title']));
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

  @override
  void initState() {
    super.initState();
    fetchLessons();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sorular")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            // Daha sonra soru ekleme sayfası burada açılır
          },
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                lessons[index],
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddLessonDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
