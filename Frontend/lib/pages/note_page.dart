import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotePage extends StatefulWidget {
  final String token;
  final int lessonId;
  final String termTitle;
  final int termId;

  const NotePage({
    Key? key,
    required this.token,
    required this.lessonId,
    required this.termTitle,
    required this.termId,
  }) : super(key: key);

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> with TickerProviderStateMixin {
  List terms = [];
  List notes = [];
  TabController? _tabController;
  int selectedTermIndex = 0;
  final TextEditingController _noteController = TextEditingController();

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
      final data = List.from(json.decode(response.body));
      if (mounted) {
        setState(() {
          terms = data;
          _tabController = TabController(length: terms.length, vsync: this);
          _tabController!.addListener(() {
            if (_tabController!.index != selectedTermIndex) {
              setState(() {
                selectedTermIndex = _tabController!.index;
              });
              fetchNotes();
            }
          });
        });

        if (terms.isNotEmpty) {
          fetchNotes();
        }
      }
    } else {
      print('Terimler alınamadı: ${response.statusCode}');
    }
  }

  Future<void> fetchNotes() async {
    if (terms.isEmpty) return;

    int termId = terms[selectedTermIndex]['id'];

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/notes/${widget.lessonId}/$termId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = List.from(json.decode(response.body));
      if (mounted) {
        setState(() {
          notes = data.reversed.toList(); // son eklenen üstte
        });
      }
    } else {
      print('Notlar alınamadı: ${response.statusCode}');
    }
  }

  Future<void> addNoteDialog() async {
    _noteController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Ekle'),
        content: TextField(
          controller: _noteController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Notunuzu yazın...'),
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Kaydet'),
            onPressed: () async {
              await saveNote();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> saveNote() async {
    if (_noteController.text.trim().isEmpty || terms.isEmpty) return;

    int termId = terms[selectedTermIndex]['id'];

    final aiResponse = await http.post(
      Uri.parse('http://10.0.2.2:8000/notes/ai_checking'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'content': _noteController.text.trim(),
      },
    );

    if (aiResponse.statusCode == 200) {
      final aiData = json.decode(aiResponse.body);
      String editedContent = aiData['edited_content'];

      final createResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/notes/create'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'content': editedContent,
          'lesson_id': widget.lessonId.toString(),
          'term_id': termId.toString(),
        },
      );

      if (createResponse.statusCode == 200) {
        await fetchNotes();
      } else {
        print('Not oluşturulamadı: ${createResponse.statusCode}');
      }
    } else {
      print('AI düzenlemesi başarısız: ${aiResponse.statusCode}');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null || terms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notlar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(terms[selectedTermIndex]['title']),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: terms.map<Widget>((term) => Tab(text: term['title'])).toList(),
        ),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('Bu konuda henüz not eklenmemiş.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 12.0),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.note_alt),
                    title: Text(notes[index]['content']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNoteDialog,
        tooltip: 'Not Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
