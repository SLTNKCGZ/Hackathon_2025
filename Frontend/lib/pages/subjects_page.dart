// NOTLAR SAYFASI (note_lessons ile calisir)

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  List<String> lessons = [];
  final TextEditingController _controller = TextEditingController();

  Future<void> fetchLessons() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/lesson/NoteLessons'),
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzZXltYSIsImlkIjoxLCJleHAiOjQ5MDczOTQ2NjB9.lNzqWG3JFNN-2wNSwuKlDRNvjETFj4yP-I3OzPZKeYM'
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        lessons = List<String>.from(json.decode(response.body));
      });
    }
  }

  Future<void> addLesson(String title) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/lesson/NoteLesson/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzZXltYSIsImlkIjoxLCJleHAiOjQ5MDczOTQ2NjB9.lNzqWG3JFNN-2wNSwuKlDRNvjETFj4yP-I3OzPZKeYM',
      },
      body: jsonEncode({'lesson_title': title}),
    );
    if (response.statusCode == 200) {
      fetchLessons();
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
          decoration: InputDecoration(hintText: "Ders adi"),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Iptal")),
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
      appBar: AppBar(title: Text("Notlar")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            // not ekleme sayfasına geçiş yapılabilir
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
