import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'note_page.dart';

class SubjectsPage extends StatefulWidget {
  final String token;
  const SubjectsPage({Key? key, required this.token}) : super(key: key);

  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> lessons = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    fetchLessons();
  }

  Future<void> fetchLessons() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/lesson/NoteLessons'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      setState(() {
        lessons = List<Map<String, dynamic>>.from(decoded);
        _tabController = TabController(length: lessons.length, vsync: this);
      });
    } else {
      setState(() {
        lessons = [];
        _tabController = null;
      });
    }
  }

  Future<void> addLesson(String lessonTitle) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/lesson/NoteLesson/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'lesson_title': lessonTitle}),
    );
    if (response.statusCode == 200) {
      await fetchLessons();
    }
  }

  void showAddLessonDialog() {
    final TextEditingController _lessonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ders Ekle"),
        content: TextField(
          controller: _lessonController,
          decoration: InputDecoration(hintText: "Ders adı"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              if (_lessonController.text.trim().isNotEmpty) {
                await addLesson(_lessonController.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text("Ekle"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null || lessons.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Konular"),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              tooltip: "Ders Ekle",
              onPressed: showAddLessonDialog,
            ),
          ],
        ),
        body: const Center(child: Text("Hiç ders bulunamadı.")),
      );
    }

    return DefaultTabController(
      length: lessons.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Konular"),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              tooltip: "Ders Ekle",
              onPressed: showAddLessonDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: lessons.map((lesson) => Tab(text: lesson['title'])).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: lessons.map((lesson) {
            return TermListWidget(
              token: widget.token,
              lessonId: lesson['id'],
              lessonTitle: lesson['title'],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TermListWidget extends StatefulWidget {
  final String token;
  final int lessonId;
  final String lessonTitle;

  const TermListWidget({
    Key? key,
    required this.token,
    required this.lessonId,
    required this.lessonTitle,
  }) : super(key: key);

  @override
  _TermListWidgetState createState() => _TermListWidgetState();
}

class _TermListWidgetState extends State<TermListWidget> {
  List<Map<String, dynamic>> terms = [];
  final TextEditingController _termController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/term/NoteTerms/${widget.lessonId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      setState(() {
        terms = List<Map<String, dynamic>>.from(decoded);
      });
    } else {
      setState(() {
        terms = [];
      });
    }
  }

  Future<void> addTerm(String termTitle) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/term/NoteTerm/create/${widget.lessonId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'term_title': termTitle}),
    );

    if (response.statusCode == 200) {
      _termController.clear();
      await fetchTerms();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konu eklenemedi')),
      );
    }
  }

  void showAddTermDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konu Ekle"),
        content: TextField(
          controller: _termController,
          decoration: InputDecoration(hintText: "Konu başlığı"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              if (_termController.text.trim().isNotEmpty) {
                await addTerm(_termController.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text("Ekle"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        terms.isEmpty
            ? Center(child: Text("Henüz konu eklenmedi"))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                scrollDirection: Axis.vertical,
                itemCount: terms.length,
                itemBuilder: (context, index) {
                  final term = terms[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotePage(
                            token: widget.token,
                            lessonId: widget.lessonId,
                            termTitle: term['title'],
                            termId: term['id'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          term['title'],
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: showAddTermDialog,
            child: Icon(Icons.add),
            tooltip: "Konu Ekle",
          ),
        ),
      ],
    );
  }
}
