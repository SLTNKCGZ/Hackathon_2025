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
            title: Text("Sorular"),
            backgroundColor: Colors.blueAccent,
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
          body: const TabBarView(
              children:[
                SingleChildScrollView(
                  child: Center(
                    child: Text("Matematik"),
                  ),
                ),
                SingleChildScrollView(
                  child: Center(
                    child: Text("Türkçe"),
                  ),
                ),
                SingleChildScrollView(
                  child: Center(
                    child: Text("İngilizce"),
                  ),
                ),
              ] ),
    ));
  }
}
