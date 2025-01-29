import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/listar_arquivos.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = "";
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false; // Adicionado para rastrear se já foi feita uma busca

  Future<void> _searchFiles(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        setState(() {
          _results =
              (jsonData['files'] ?? []).map<Map<String, dynamic>>((file) {
            return {
              'id_arquivo': file['id_arquivo'],
              'nome': file['nome'],
              'criado_em': file['criado_em'], // Mantém a data original no formato ISO
              'caminho': file['caminho'],
              'confidencial': file['confidencial'] ?? false,
              'arquivo_compactado': file['arquivo_compactado'],
            };
          }).toList();
        });
      } else {
        throw Exception('Erro ao buscar arquivos');
      }
    } catch (e) {
      setState(() {
        _results = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Ajusta o layout quando o teclado aparece
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Tornar o conteúdo rolável
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height: 80),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    hoverColor: Colors.transparent,
                    onPressed: () {
                      Navigator.pop(context); // Volta para a home_page
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    color: Color.fromRGBO(255, 255, 255, 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onSubmitted: (value) {
                            _searchFiles(value);
                          },
                          decoration: InputDecoration(
                            hintText: "Pesquisar por...",
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1.25,
                        color: Colors.grey,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Color.fromRGBO(0, 114, 239, 1),
                          size: 16,
                        ),
                        hoverColor: Colors.transparent,
                        onPressed: () {
                          _searchFiles(_searchQuery);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Resultados ou mensagens
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : !_hasSearched
                      ? SizedBox.shrink()
                      : _results.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(height: 125),
                                Image.asset(
                                  'assets/images/search.png',
                                  height: 220,
                                ),
                                SizedBox(height: 40),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Center(
                                      child: Text(
                                        "Não encontramos documentos para a pesquisa realizada",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'Frutiger',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )),
                                SizedBox(height: 24),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Center(
                                    child: Text(
                                      "Verifique os termos e tente novamente.",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Frutiger',
                                        fontWeight: FontWeight.w400,
                                        color: Color.fromRGBO(96, 106, 118, 1),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : FileListWidget(
                              arquivos: _results,
                              selectedFiles: List.generate(
                                  _results.length, (index) => false),
                              onFileSelected: (index, isSelected) {},
                            ),
            ],
          ),
        ),
      ),
    );
  }
}
