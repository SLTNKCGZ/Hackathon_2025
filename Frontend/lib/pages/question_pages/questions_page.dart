import 'dart:convert';
import 'package:hackathon_2025/pages/question_pages/topic_detail_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'QuestionDetailPage.dart';

class QuestionsPage extends StatefulWidget {
  final String token;
  const QuestionsPage({super.key, required this.token});

  @override
  _QuestionsPageState createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> lessons = [];

  @override
  void initState() {
    super.initState();
    fetchLessons();
  }

  Future<void> fetchLessons() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/lesson/QuestionLessons'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        lessons = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      setState(() {
        lessons = [];
      });
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
      await fetchLessons();
    }
  }

  void showAddLessonDialog() {
    final TextEditingController _lessonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
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
    if (lessons.isEmpty) {
      return Scaffold(
          appBar: AppBar(
        title: Text("Sorular"),
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: Icon(Icons.note, size: 30),
        actions: [
          GestureDetector(
            onTap: showAddLessonDialog,
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color:Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Text("Ders ekle",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 15)),
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
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: Icon(Icons.note, size: 30, color: Colors.white),
          actions: [
            GestureDetector(
              onTap: showAddLessonDialog,
              child: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Text("Ders ekle",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
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
            tabs: lessons.map((lesson) => Tab(text: lesson['title'])).toList(),
          ),
        ),
        body: TabBarView(
          children: lessons.map((lesson) {
            return TermList(
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

class TermList extends StatefulWidget {
  final String token;
  final int lessonId;
  final String lessonTitle;

  const TermList({
    Key? key,
    required this.token,
    required this.lessonId,
    required this.lessonTitle,
  }) : super(key: key);

  @override
  _TermListState createState() => _TermListState();
}

class _TermListState extends State<TermList> {
  List<Map<String, dynamic>> terms = [];
  final TextEditingController _termController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/term/QuestionTerms/${widget.lessonId}'),
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

  Future<void> addTerm(String title) async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2:8000/term/QuestionTerm/create/${widget.lessonId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'term_title': title}),
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

  Future<void> deleteTerm(int termId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/term/QuestionTerm/delete/$termId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      await fetchTerms();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konu başarıyla silindi')),
      );
    } else {
      // Hata durumunda mesaj göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konu silinirken hata oluştu')),
      );
    }
  }

  Future<void> updateTerm(int termId, String newTitle) async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/term/QuestionTerm/update/$termId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'term_title': newTitle}),
    );

    if (response.statusCode == 200) {
      await fetchTerms();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konu başarıyla güncellendi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konu güncellenemedi')),
      );
    }
  }

  void showUpdateTermDialog(int termId, String currentTitle) {
    final TextEditingController editController =
        TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konu Düzenle"),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(hintText: "Konu başlığı"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("İptal")),
          TextButton(
            onPressed: () async {
              await updateTerm(termId, editController.text.trim());
              Navigator.pop(context);
            },
            child: Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void showAddTopicDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        title: Text("Konu Ekle"),
        content: TextField(
          controller: _termController,
          decoration: InputDecoration(hintText: "Konu başlığı"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("İptal")),
          TextButton(
              onPressed: () async {
                if (_termController.text.trim().isNotEmpty) {
                  await addTerm(_termController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: Text("Ekle"))
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
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TopicDetailPage(
                                    token: widget.token,
                                    lessonId: widget.lessonId,
                                    termTitle: term['title'],
                                    termId: term['id'],
                                  ),
                                ),
                              );
                            },
                            child: Center(
                              child: Text(
                                term['title'],
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.black),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              showUpdateTermDialog(term['id'], term['title']);
                            } else if (value == 'delete') {
                              bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Konu Sil'),
                                  content: Text(
                                      'Bu konuyu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('İptal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('Sil',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await deleteTerm(term['id']);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Düzenle',
                                      style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Sil',
                                      style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: showAddTopicDialog,
            child: Icon(Icons.add),
            tooltip: "Konu Ekle",
          ),
        ),
      ],
    );
  }
}
