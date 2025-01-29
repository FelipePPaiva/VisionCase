import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class FolderService {
  // Método para buscar conteúdo da pasta
  static Future<Map<String, dynamic>> fetchFolderContent(int folderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/folder/$folderId'),
      //Uri.parse('http://localhost:3000/folders/$folderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)); // Garante UTF-8
    } else {
      throw Exception('Erro ao carregar conteúdo da pasta');
    }
  }

  // Método para criar nova subpasta
  static Future<bool> createNewSubfolder(
      int folderId, String subfolderName, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    var response = await http.post(
      Uri.parse(
          'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/create-subfolder'),
      //Uri.parse('http://localhost:3000/subfolder'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'nome': subfolderName,
        'folderId': folderId,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subpasta criada com sucesso!',),
        backgroundColor: Color.fromRGBO(0, 114, 239, 1),),
      );
      return true;
    } else {
  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar subpasta')),
      );
      return false;
    }
  }

  // Método para buscar todos os itens
  static Future<List<Map<String, dynamic>>> fetchAllItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      //Uri.parse('http://localhost:3000/favorites'),
      Uri.parse('https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Erro ao carregar todos os itens');
    }
  }
}
