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
            title: Text("Konular"),
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
