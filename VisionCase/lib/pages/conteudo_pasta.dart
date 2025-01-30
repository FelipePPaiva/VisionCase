import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'home_page.dart';
import 'conteudo_subpasta.dart';
import '../services/listar_arquivos.dart';

class SubfolderContentPage extends StatefulWidget {
  final int folderId;
  final int subfolderId;

  const SubfolderContentPage({
    Key? key,
    required this.folderId,
    required this.subfolderId,
  }) : super(key: key);

  @override
  _SubfolderContentPageState createState() => _SubfolderContentPageState();
}

class _SubfolderContentPageState extends State<SubfolderContentPage> {
  bool _isLoading = true;
  Map<String, dynamic> _folderContent = {};
  Map<int, bool> _favoritos = {}; // Mapa para controlar os favoritos de cada subpasta

  @override
  void initState() {
    super.initState();
    _carregarConteudoPasta();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      await Permission.storage.request();
    }
  }

  //Carregar conteudo das pastas e verificar se as subpastas estão como favoritas
  Future<void> _carregarConteudoPasta() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token não encontrado');
      }

      // Carregar conteúdo da pasta
      final response = await http.get(
        Uri.parse('https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/folder/${widget.folderId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _folderContent = json.decode(response.body);
          _isLoading = false;
        });

        // Verificar se as subpastas estão favoritas
        for (var subfolder in _folderContent['subfolders']) {
          await _verificarFavorito(subfolder['id_subpasta'], token);
        }
      } else {
        throw Exception('Erro ao carregar o conteúdo da pasta');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

//Função para verificar se uma subpasta está favoritada
  Future<void> _verificarFavorito(int subfolderId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/favorite-subfolder/subfolder/$subfolderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        bool isFavorited = false;
        if (responseData is Map<String, dynamic>) {
          isFavorited = responseData['isFavorite'] ?? false; // Acessa o valor de 'isFavorite'
        }

        setState(() {
          _favoritos[subfolderId] = isFavorited; // Atualiza o estado de favorito
        });
      }
    } catch (e) {}
  }

  // Função para alternar o estado de favoritação
  Future<void> _toggleFavorito(int subfolderId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token não encontrado');
      }

      // Verificar se a subpasta está favoritada ou não
      final isFavorited = _favoritos[subfolderId] ?? false;
      final url = Uri.parse('https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/favorite-subfolder/subfolder/$subfolderId');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Enviar requisição POST ou DELETE com base no status de favoritado
      final response = isFavorited
          ? await http.delete(url, headers: headers) // Desmarcar (DELETE)
          : await http.post(url, headers: headers); // Marcar (POST)

      // Verificar se a resposta da API foi bem-sucedida
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Atualizar o estado com o novo valor de favorito
        setState(() {
          _favoritos[subfolderId] = !isFavorited; // Alterna entre favoritado e não favoritado
        });

        // Verifica o estado retornado pela API
        if (responseData['isFavorite'] == true) {
        } else if (responseData['isFavorite'] == false) {
        } else {}
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    // Inicializa o formatador de datas
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final bool eTablet = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 25.0, left: 15.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios,
              color: Color.fromRGBO(0, 114, 239, 1),
              size: eTablet ? 20 :16,
            ),
            hoverColor: Colors.transparent, // Remove o fundo cinza ao passar o mouse
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: Row(
            children: [
              Expanded(
                // Adiciona Expanded aqui
                child: Text(
                  _folderContent['folderName'] ?? 'Conteúdo da Pasta',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: eTablet ? 24 : 20, fontFamily: 'Frutiger',),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, // Limita a uma linha
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
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ajusta o Column para ter o mínimo de altura necessário
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 28),
                    //Verificação se há conteudo, caso não centraliza a mensagem
                    if ((_folderContent['subfolders'] == null ||
                            _folderContent['subfolders'].isEmpty) &&
                        (_folderContent['files'] == null ||
                            _folderContent['files'].isEmpty))
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 100, 8, 100),
                          child: Text(
                            'Esta pasta está vazia.',
                            style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Frutiger',),
                          ),
                        ),
                      ),
                    //se houver conteudo, mostra conteudo da pasta
                    if (_folderContent['subfolders'] != null &&
                        _folderContent['subfolders'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._folderContent['subfolders']
                                .map<Widget>((subfolder) {
                              final String? dataCriacao = subfolder['criado_em'];
                              final String dataFormatada = dataCriacao != null
                                  ? dateFormat.format(DateTime.parse(dataCriacao))
                                  : 'Data desconhecida';

                              final subfolderId = subfolder['id_subpasta'];
                              final isFavorited = _favoritos[subfolderId] ?? false;

                              return ListTile(
                                hoverColor: Colors.transparent,
                                leading: Icon(Icons.folder,
                                  color: Colors.amber,
                                  size: eTablet ? 50 : 38,
                                ),
                                title: Text(subfolder['nome'],
                                style: TextStyle(
                                  fontSize: eTablet ? 20 : 14,
                                  fontFamily: 'Frutiger',
                                  fontWeight: FontWeight.w400,
                                )),
                                subtitle: Text('Criado em: $dataFormatada',
                                style: TextStyle(
                                  fontSize: eTablet ? 16 : 12,
                                  fontFamily: 'Frutiger',
                                  fontWeight: FontWeight.w400,
                                )
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    _favoritos[subfolder['id_subpasta']] == true
                                        ? Icons.star
                                        : Icons.star_border,
                                        size: 20,
                                    color:
                                        _favoritos[subfolder['id_subpasta']] == true
                                            ? Colors.blue
                                            : Colors.grey,
                                  ),
                                  onPressed: () {
                                    _toggleFavorito(subfolder['id_subpasta']);
                                  },
                                ),
                                onTap: () {
                                  final int idSubfolder = subfolder['id_subpasta'];
                                  Navigator.push(context,
                                    MaterialPageRoute(
                                      builder: (context) => SubfolderContentSubPage(
                                              subfolderId: idSubfolder),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    if (_folderContent['files'] != null &&
                        _folderContent['files'].isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(),
                          child: FileListWidget(
                            arquivos: _folderContent['files'],
                            selectedFiles: List.generate(
                              _folderContent['files'].length,
                              (index) => false,
                            ),
                            onFileSelected: (index, isSelected) {
                              setState(() {});
                            },
                            onTap: (index) async {
                              final arquivo = _folderContent['files'][index];
                              final filePath = arquivo['path'];

                              if (filePath != null && filePath is String) {
                                final file = File(filePath);
                                if (await file.exists()) {
                                  final fileUrl = Uri.parse(filePath);
                                  await OpenFile.open(fileUrl.toString());
                                } else {}
                              } else {}
                            },
                          )),
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(
                      builder: (context) => HomePage(initialIndex: 0)));
              break;
            case 1:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(
                      builder: (context) => HomePage(initialIndex: 1)));
              break;
            case 2:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(
                      builder: (context) => HomePage(initialIndex: 2)));
              break;
          }
        },
      ),
      
    );
  }
}
