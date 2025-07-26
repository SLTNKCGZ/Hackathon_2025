import 'package:flutter/material.dart';

class NotlarPage extends StatefulWidget {
  const NotlarPage({super.key});

  @override
  State<NotlarPage> createState() => _NotlarPageState();
}

class _NotlarPageState extends State<NotlarPage>
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
              children:
                  dersler.map((ders) => DersNotSayfasi(dersAdi: ders)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Not ekleme işlemi burada olacak
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        tooltip: 'Not Ekle',
      ),
    );
  }
}

class DersNotSayfasi extends StatelessWidget {
  final String dersAdi;
  const DersNotSayfasi({super.key, required this.dersAdi});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$dersAdi Notları', style: const TextStyle(fontSize: 20)),
    );
  }
}
