import 'package:flutter/material.dart';
import 'package:hackathon_2025/pages/login_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(0xff5d1049),
          onPrimary: Colors.white,
          secondary: Color(0xff936081),
          tertiary: Color(0xffede3e9),
          onTertiary: Colors.black,
          surface: Color(0xffffffff),
        ),
        useMaterial3: true,
      ),
      initialRoute: "/login",
      routes:
      {'/login':(context) => LoginPage()},
    );
  }
}





// Eğer User modelini ve ProfilPage'i kullanıyorsan, import etmeyi unutma!
