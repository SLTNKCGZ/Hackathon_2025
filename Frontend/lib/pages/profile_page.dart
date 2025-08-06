import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({super.key, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? _editingIndex;
  String? get token => widget.token;
  late List<TextEditingController> _controllers;
  String? username;
  String? firstName;
  String? lastName;
  String? email;
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (index) => TextEditingController());
    fetchProfileData();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Backend'e güncelleme gönderen fonksiyon
  Future<void> _updateProfile(int fieldIndex) async {
    try {
      final fieldNames = ['username', 'firstName', 'lastName', 'email'];
      final fieldName = fieldNames[fieldIndex];
      final newValue = _controllers[fieldIndex].text;

      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/auth/update'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          fieldName: newValue,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fieldName başarıyla güncellendi')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme başarısız: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  final List<String> _labels = [
    'Kullanıcı Adı',
    'Ad',
    'Soyad',
    'E-posta',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
        leading:
            const Icon(Icons.account_circle, color: Colors.white, size: 25),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Center(
                child: Stack(
                  children: [Icon(Icons.account_circle, size: 120)],
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(_labels.length, (index) {
                return Card(
                  color: Theme.of(context).colorScheme.tertiary,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    subtitle: _editingIndex == index
                        ? TextField(
                            controller: _controllers[index],
                            autofocus: true,
                            onSubmitted: (_) async {
                              setState(() {
                                _editingIndex = null;
                              });
                              await _updateProfile(index);
                            },
                          )
                        : Text(_controllers[index].text),
                    title: Text(_labels[index]),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          setState(() {
                            _editingIndex = index;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Değiştir'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final response = await http.delete(
                      Uri.parse('http://10.0.2.2:8000/auth/delete'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-type': 'application/json'
                      });
                  if (response.statusCode == 200) {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Hesabı sil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchProfileData() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-type': 'application/json'
        });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _controllers[0].text = data['username'];
        _controllers[1].text = data['firstName'];
        _controllers[2].text = data['lastName'];
        _controllers[3].text = data['email'];
      });
    }
  }
}
