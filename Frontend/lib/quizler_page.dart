import 'package:flutter/material.dart';

class QuizlerPage extends StatefulWidget {
  const QuizlerPage({super.key});

  @override
  State<QuizlerPage> createState() => _QuizlerPageState();
}

class _QuizlerPageState extends State<QuizlerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> dersler = [
    'Matematik',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Türkçe',
    'Tarih',
    'Coğrafya',
    'Din Kültürü',
    'Felsefe',
    'İngilizce',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: dersler.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            tabs: dersler.map((ders) => Tab(text: ders)).toList(),
            labelColor: Colors.deepPurple,
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: dersler
                  .map((ders) => DersQuizSayfasi(dersAdi: ders))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Soru ekleme işlemi burada olacak
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        tooltip: 'Soru Ekle',
      ),
    );
  }
}

class DersQuizSayfasi extends StatelessWidget {
  final String dersAdi;
  const DersQuizSayfasi({super.key, required this.dersAdi});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$dersAdi Quizleri', style: const TextStyle(fontSize: 20)),
    );
  }
}
