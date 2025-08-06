import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddNotePage extends StatefulWidget {
  final String token;
  final int lessonId;
  final int termId;
  final VoidCallback onNoteAdded;

  const AddNotePage({
    Key? key,
    required this.token,
    required this.lessonId,
    required this.termId,
    required this.onNoteAdded,
  }) : super(key: key);

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  Future<void> saveNote() async {
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
      // Notu doğrudan kaydet (AI düzenlemesi olmadan)
      final createResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/notes/create'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'content': _noteController.text.trim(),
          'lesson_id': widget.lessonId.toString(),
          'term_id': widget.termId.toString(),
        },
      );

      if (createResponse.statusCode == 200) {
        widget.onNoteAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not başarıyla kaydedildi')),
        );
      } else {
        throw Exception('Not kaydedilemedi');
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
        title: const Text('Not Ekle'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 25,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                    icon: const Icon(Icons.edit,color:Colors.black),
                    label: const Text('Düzelt',style: TextStyle(color:Colors.black),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : saveNote,
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
                    label: Text(_isLoading ? 'Kaydediliyor...' : 'Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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