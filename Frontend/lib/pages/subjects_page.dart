import 'package:flutter/material.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Konular'),
          backgroundColor: Colors.blue[600],
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
          leading: const Icon(Icons.note, color: Colors.white, size: 25),
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
