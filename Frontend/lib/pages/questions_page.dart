import 'package:flutter/material.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sorular'),
          backgroundColor: Colors.blue[600],
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
          leading: const Icon(Icons.quiz, color: Colors.white, size: 25),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Matematik'),
              Tab(text: 'Türkçe'),
              Tab(text: 'İngilizce'),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        body: TabBarView(
          children: [
            // Hastalıklar
            SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text("Matematik"),
                )
            ),
            SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text("Türkçe"),
                )
            ),
            SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text("İngilizce"),
                )
            ),
          ],
        ),
      ),
    );
  }
}
