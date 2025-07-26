import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hackathon_2025/pages/profile_page.dart';
import 'package:hackathon_2025/pages/questions_page.dart';
import 'package:hackathon_2025/pages/subjects_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key,required this.token});
  final String token;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex=0;
  late List<Widget> _pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = [
      HomePageContent(token: widget.token),
      SubjectsPage(),
      QuestionsPage(),
      ProfilePage(token: widget.token)
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _pages=[
      HomePageContent(token: widget.token),
      SubjectsPage(),
      QuestionsPage(),
      ProfilePage(token: widget.token)];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Konular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Sorular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key,required this.token});
  final String token;


  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  String? firstName;

  @override
  void initState() {
    super.initState();
    fetch_name();
  }

  Future<void> fetch_name() async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/auth/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-type': 'application/json'
        }
    );
    if(response.statusCode==200){
      final data=jsonDecode(response.body);
      setState(() {
        firstName=data["firstName"];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Merhaba $firstName"),
        backgroundColor: Colors.blueAccent,
      ),
      body:Center(
        child: Text("HomePage"),
      ),

    );
  }
}


