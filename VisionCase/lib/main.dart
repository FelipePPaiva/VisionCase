// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/login_page.dart';

void main() async {
  await dotenv.load();
  runApp(BriefCase());//Nome da Aplicação
}

class BriefCase extends StatelessWidget {
  // Construtor do BriefCase
  const BriefCase({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionCase',
      home: LoginPage(),//Informa que a primeira página a aparecer é a LoginPage
      debugShowCheckedModeBanner: false,// Remove o banner de debug
       routes: {
        '/login': (context) => LoginPage(),
      }, 
    );
  }
}