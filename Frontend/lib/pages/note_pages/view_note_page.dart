import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_note_page.dart';

class ViewNotePage extends StatefulWidget {
  final String noteContent;
  final String noteTitle;
  final String token;
  final int lessonId;
  final int termId;
  final int noteId;
  final VoidCallback onNoteUpdated;

  const ViewNotePage({
    Key? key,
    required this.noteContent,
    required this.token,
    required this.lessonId,
    required this.termId,
    required this.noteId,
    required this.onNoteUpdated,
    this.noteTitle = 'Not',
  }) : super(key: key);

    @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  String currentContent = '';

  @override
  void initState() {
    super.initState();
    currentContent = widget.noteContent;
  }

  Future<void> fetchUpdatedNote() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/notes/${widget.lessonId}/${widget.termId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = List.from(json.decode(response.body));
        final updatedNote = data.firstWhere(
          (note) => note['id'] == widget.noteId,
          orElse: () => null,
        );
        
        if (updatedNote != null) {
          setState(() {
            currentContent = updatedNote['content'];
          });
        }
      }
    } catch (e) {
      print('Not güncellenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteTitle),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 25,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(size: 28, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditNotePage(
                    token: widget.token,
                    lessonId: widget.lessonId,
                    termId: widget.termId,
                    noteId: widget.noteId,
                    initialContent: currentContent,
                    onNoteUpdated: () {
                      widget.onNoteUpdated();
                    },
                  ),
                ),
              );
              // Edit sayfasından döndüğünde güncel notu al
              await fetchUpdatedNote();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note_alt, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Not İçeriği',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentContent,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
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
  } 