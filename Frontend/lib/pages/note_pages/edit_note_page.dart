import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditNotePage extends StatefulWidget {
  final String token;
  final int lessonId;
  final int termId;
  final int noteId;
  final String initialContent;
  final VoidCallback onNoteUpdated;

  const EditNotePage({
    Key? key,
    required this.token,
    required this.lessonId,
    required this.termId,
    required this.noteId,
    required this.initialContent,
    required this.onNoteUpdated,
  }) : super(key: key);

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialContent;
  }

  Future<void> updateNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir not yazın')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Notu güncelle
      final updateResponse = await http.put(
        Uri.parse('http://10.0.2.2:8000/notes/${widget.noteId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'content': _noteController.text.trim(),
        },
      );

      if (updateResponse.statusCode == 200) {
        widget.onNoteUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not başarıyla güncellendi')),
        );
      } else {
        throw Exception('Not güncellenemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> editNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir not yazın')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // AI düzenlemesi
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

        setState(() {
          _noteController.text = editedContent;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not düzenlendi')),
        );
      } else {
        throw Exception('AI düzenlemesi başarısız');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notu Düzenle'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 25,
        ),
        backgroundColor: Colors.purple[600],
        iconTheme: const IconThemeData(size: 28, color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Notunuzu buraya yazın...',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : editNote,
                    icon: const Icon(Icons.edit),
                    label: const Text('Düzelt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : updateNote,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Güncelleniyor...' : 'Güncelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 