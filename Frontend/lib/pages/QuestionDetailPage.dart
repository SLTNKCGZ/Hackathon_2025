import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class QuestionDetailPage extends StatefulWidget {
  final Map<String, dynamic> question;
  final String token;
  final int lessonId;
  final String termTitle;
  final int termId;

  const QuestionDetailPage({
    Key? key,
    required this.question,
    required this.token,
    required this.lessonId,
    required this.termTitle,
    required this.termId,
  }) : super(key: key);

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  bool isEditing = false;
  late TextEditingController _noteController;
  late int _selectedDifficulty;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteController =
        TextEditingController(text: widget.question['note'] ?? "");
    _selectedDifficulty = widget.question['difficulty_category'] ?? 1;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> updateQuestionApi({
    required int questionId,
    String? note,
    int? difficultyCategory,
    required String token,
  }) async {
    final uri = Uri.parse(
        'http://10.0.2.2:8000/questions/$questionId/$difficultyCategory');
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    if (note != null) request.fields['note'] = note;
    if (difficultyCategory != null)
      request.fields['difficulty_category'] = difficultyCategory.toString();

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Güncelleme başarısız');
    }
  }

  Future<void> _updateQuestion() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await updateQuestionApi(
        questionId: widget.question['id'],
        note: _noteController.text,
        difficultyCategory: _selectedDifficulty,
        token: widget.token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Soru güncellendi")),
      );

      setState(() {
        isEditing = false; // Düzenleme modunu kapat
        // Güncellenen not ve zorluk değerini güncelle
        widget.question['note'] = _noteController.text;
        widget.question['difficulty_category'] = _selectedDifficulty;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme başarısız: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteQuestionApi({
    required int questionId,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/questions/$questionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Silme başarısız: ${response.body}");
    }
  }

  Future<void> _deleteQuestion() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Soru Silinecek"),
        content: Text("Bu soruyu silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("İptal")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Sil")),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await deleteQuestionApi(
          questionId: widget.question['id'],
          token: widget.token,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Soru silindi")),
        );
        Navigator.pop(context, true); // değişiklik oldu, önceki sayfaya bildir
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silme başarısız: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;

    return Scaffold(
      appBar: AppBar(
        title: Text("Soru Detayı"),
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        isEditing = true;
                      });
                    },
              tooltip: "Düzenle",
            ),
          if (isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        isEditing = false;
                        // Düzenleme iptal edildi, eski değerleri geri yükle
                        _noteController.text = question['note'] ?? "";
                        _selectedDifficulty =
                            question['difficulty_category'] ?? 1;
                      });
                    },
              tooltip: "İptal",
            ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteQuestion,
            tooltip: "Sil",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: question['image_path'] != null
                        ? Image.network(
                            'http://10.0.2.2:8000${question['image_path']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image, size: 80),
                          )
                        : Icon(Icons.image_not_supported, size: 80),
                  ),
                  SizedBox(height: 16),

                  // Eğer düzenleme modunda değilsek sadece not ve zorluk göster
                  if (!isEditing) ...[
                    Text(
                      "Not:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      question['note'] != null && question['note'].isNotEmpty
                          ? question['note']
                          : "Not yok",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Zorluk Seviyesi:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Icon(
                          index < (question['difficulty_category'] ?? 1)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 30,
                        );
                      }),
                    ),
                  ],
                  // Düzenleme modunda ise not ve zorluk düzenleme alanları göster
                  if (isEditing) ...[
                    TextField(
                      controller: _noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Not giriniz",
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Zorluk Seviyesi:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        int starNum = index + 1;
                        return IconButton(
                          icon: Icon(
                            starNum <= _selectedDifficulty
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.orange,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedDifficulty = starNum;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateQuestion,
                      child: Text("Güncelle"),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
