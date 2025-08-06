import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_note_page.dart';
import 'view_note_page.dart';

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

  @override
  void initState() {
    super.initState();
    fetchNotes();
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
    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8000/notes/${widget.lessonId}/${widget.termId}'),
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
      print(response.body);
    }
  }

  Future<void> deleteNote(int noteId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/notes/$noteId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      await fetchNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not başarıyla silindi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not silinemedi')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*if (_tabController == null || terms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notlar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }*/
    return Scaffold(
      appBar: AppBar(
          title: Text("${widget.termTitle}"),
          titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: IconThemeData(size: 28, color: Colors.white)),
      body: notes.isEmpty
          ? const Center(child: Text('Bu konuda henüz not eklenmemiş.'))
          : Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 12.0),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.note_alt),
                      title: Text(
                        notes[index]['content'].length > 100
                            ? '${notes[index]['content'].substring(0, 100)}...'
                            : notes[index]['content'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: notes[index]['content'].length > 100
                          ? Text('Devamını görmek için tıklayın')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black),
                        onPressed: () async {
                          // Silme onayı al
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Not Sil'),
                              content: const Text(
                                  'Bu notu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Sil',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await deleteNote(notes[index]['id']);
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewNotePage(
                              noteContent: notes[index]['content'],
                              noteTitle: 'Not',
                              token: widget.token,
                              lessonId: widget.lessonId,
                              termId: widget.termId,
                              noteId: notes[index]['id'],
                              onNoteUpdated: () => fetchNotes(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNotePage(
                token: widget.token,
                lessonId: widget.lessonId,
                termId: widget.termId,
                onNoteAdded: () => fetchNotes(),
              ),
            ),
          );
        },
        tooltip: 'Not Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
