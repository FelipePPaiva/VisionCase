import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../services/listar_arquivos.dart';

class SubfolderContentSubPage extends StatefulWidget {
  final int subfolderId;

  const SubfolderContentSubPage({super.key, required this.subfolderId});

  @override
  _SubfolderContentSubPageState createState() =>
      _SubfolderContentSubPageState();
}

class _SubfolderContentSubPageState extends State<SubfolderContentSubPage> {
  String? subfolderName; // Nome da subpasta
  List<dynamic> _files = []; // Lista de arquivos
  String? _caminho; // Caminho da subpasta
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarConteudoSubpasta(widget.subfolderId);
  }

  // Função para buscar nome, caminho e arquivos da subpasta
  Future<void> _carregarConteudoSubpasta(int subfolderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/subfolder/$subfolderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          subfolderName = data['folderName'] ?? 'Subpasta';
          _caminho = data['caminho'] ?? '';
          _files = data['files'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar conteúdo da subpasta');
      }
    } catch (e) {
      setState(() {
        subfolderName = 'Erro ao carregar';
        _isLoading = false;
      });
    }
  }

  String _getLastFolderName(String? path) {
    if (path == null || path.isEmpty) return '';

    // Remove qualquer barra final se existir
    final cleanPath =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;

    // Divide o caminho em partes usando a barra como separador
    final parts = cleanPath.split('/');

    // Retorna a última parte (nome da pasta atual)
    return parts.isNotEmpty ? parts.last : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 25, left: 15),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Color.fromRGBO(0, 114, 239, 1),
              size: 16,
            ),
            hoverColor: Colors.transparent,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getLastFolderName(_caminho),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFamily: 'Frutiger',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, // Limita a uma única linha
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: Color.fromRGBO(0, 114, 239, 1),
            ))
          : SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    // Exibe a lista de arquivos
                    if (_files.isNotEmpty)
                      FileListWidget(
                        arquivos: _files,
                        selectedFiles: List.generate(
                          _files.length,
                          (index) => false,
                        ),
                        onFileSelected: (index, isSelected) {
                          setState(() {});
                        },
                      )
                    else
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 95, 8, 95),
                              child: Text(
                                'Nenhum arquivo encontrado.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Frutiger',),
                              )))
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: 0,
        selectedItemColor: Color.fromRGBO(0, 114, 239, 1),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_outlined),
            label: 'Favoritos',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(initialIndex: 0)),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomePage(initialIndex: 1)));
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(initialIndex: 2)),
              );
              break;
          }
        },
      ),
    );
  }
}
