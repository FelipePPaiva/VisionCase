import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usuario_page.dart';
import 'home_page.dart';
import 'subfolder_page_admin.dart';

class PastasPage extends StatefulWidget {
  @override
  _PastasPageState createState() => _PastasPageState();
}

class _PastasPageState extends State<PastasPage> {
  List<Map<String, dynamic>> _pastas = [];
  List<Map<String, dynamic>> _profiles = [];
  Map<int, bool> _selectedProfiles = {};
  String? _errorMessage;
  bool _areaAdminExpandida = false;

//Variaveis para Dados do SharedPreferences
  String? nome;
  String? email;
  String? idPerfil;

  @override
  void initState() {
    super.initState();
    _fetchPastas();
    _fetchProfiles();
    carregarDadosUsuario();
  }

  //Buscar pastas e salvar em um array
  Future<void> _fetchPastas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Token não encontrado';
      });
      return;
    }

    token = token.replaceFirst("Token ", "");

    try {
      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/admin/folders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pastas = List<Map<String, dynamic>>.from(data['folders'])
            ..sort((a, b) {
              String normalizeString(String str) {
                return String.fromCharCodes(str.runes.toList())
                    .toLowerCase()
                    .replaceAll('á', 'a')
                    .replaceAll('à', 'a')
                    .replaceAll('ã', 'a')
                    .replaceAll('â', 'a')
                    .replaceAll('é', 'e')
                    .replaceAll('ê', 'e')
                    .replaceAll('í', 'i')
                    .replaceAll('ó', 'o')
                    .replaceAll('ô', 'o')
                    .replaceAll('õ', 'o')
                    .replaceAll('ú', 'u')
                    .replaceAll('ç', 'c');
              }

              return normalizeString(a['nome'] ?? '')
                  .compareTo(normalizeString(b['nome'] ?? ''));
            });
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar pastas: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar pastas: $e';
      });
    }
  }

  //Buscar perfis e salvar em um array
  Future<void> _fetchProfiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(
          'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/profiles'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(data['profiles']);
      });
    } else {}
  }

  //Abrir subfolder
  void _openSubfolderPage(dynamic pasta) {
    final folderId = pasta['id'] ?? pasta['id_pasta'];
    if (folderId == null) {
      setState(() {
        _errorMessage = 'ID da pasta não encontrado';
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SubfolderContentPage(
                folderId: folderId,
              )),
    );
  }

  Future<void> _fetchFolderProfiles(int folderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Token não encontrado';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/folders/$folderId/access'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _selectedProfiles.clear();
          for (var item in data) {
            int idPerfil = item['id_perfil'];
            bool acesso = item['acesso'];
            _selectedProfiles[idPerfil] = acesso;
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Erro ao carregar perfis da pasta: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar perfis da pasta: $e';
      });
    }
  }

  //Função para criar as pastas
  Future<void> _createFolder(String nome) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return;
    }

    // Filtra para enviar apenas perfis explicitamente marcados com true ou false
    Map<String, bool> profilesToSend = {
      for (var entry in _selectedProfiles.entries)
        entry.key.toString(): entry.value
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/create-folder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "nome": nome,
          "perfis": profilesToSend,
        }),
      );

      if (response.statusCode == 201) {
        _fetchPastas(); // Atualiza a lista após criar a pasta
      } else {}
    } catch (e) {}
  }

//Função que abre o modal de criar pasta
  void _showCreateFolderDialog() {
    // Limpar as seleções anteriores ao abrir o diálogo e a mensagem de erro
    setState(() {
      _selectedProfiles.clear();
    });

    showModalBottomSheet(
      context: context,
      shape: Border(),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        TextEditingController folderNameController = TextEditingController();
        String? localErrorMessage;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Container(
                color: Colors.white, // Background branco
                child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título do modal
                          Text("Criar Nova Pasta",
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.bold,
                              )),
                          SizedBox(height: 16),
                          // TextField para o nome da pasta com validação de erro
                          TextField(
                            controller: folderNameController,
                            decoration: InputDecoration(
                              labelText: "Nome da Pasta",
                              // errorText: localErrorMessage, // Mensagem de erro local
                            ),
                          ),
                          SizedBox(height: 16),
                          Text("Selecionar Perfis com Permissão",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.bold,
                              )),
                          // Lista de perfis com CheckboxListTile
                          Column(
                            children: _profiles.map((profile) {
                              int idPerfil = profile['id_perfil'];
                              return StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return CheckboxListTile(
                                    hoverColor: Colors.transparent,
                                    title: Text(profile['perfil']),
                                    value: _selectedProfiles[idPerfil] ?? false,
                                    onChanged: (bool? value) {
                                      setStateDialog(() {
                                        setState(() {
                                          _selectedProfiles[idPerfil] =
                                              value ?? false;
                                        });
                                      });
                                    },
                                  );
                                },
                              );
                            }).toList(),
                          ),
                          // Mensagem de erro (se houver) será exibida abaixo dos perfis
                          if (localErrorMessage != null &&
                              localErrorMessage!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                localErrorMessage!,
                                style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Frutiger',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(height: 16),
                          // Botões de ação (Criar e Cancelar)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromRGBO(0, 114, 239, 1),
                                  foregroundColor:
                                      Color.fromRGBO(255, 255, 255, 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Fecha o modal
                                },
                                child: Text("Cancelar"),
                              ),
                              SizedBox(width: 8), // Espaço entre os botões
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromRGBO(0, 114, 239, 1),
                                  foregroundColor:
                                      Color.fromRGBO(255, 255, 255, 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                onPressed: () {
                                  final nome = folderNameController.text;
                                  localErrorMessage =
                                      null; // Limpar erro anterior dentro do modal

                                  // Validações
                                  if (nome.isEmpty) {
                                    setStateDialog(() {
                                      localErrorMessage =
                                          'O nome da pasta não pode estar vazio';
                                    });
                                  } else if (_selectedProfiles.values
                                      .every((value) => !value)) {
                                    setStateDialog(() {
                                      localErrorMessage =
                                          'Selecione pelo menos um perfil';
                                    });
                                  } else {
                                    // Caso as validações passem, cria a pasta e fecha o modal
                                    _createFolder(nome);
                                    Navigator.of(context)
                                        .pop(); // Fecha o modal
                                  }
                                },
                                child: Text("Criar"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )));
          },
        );
      },
    );
  }

  //Modal para editar e deletar pastas
  void _showFolderOptions(BuildContext context, dynamic pasta) {
    showModalBottomSheet(
      context: context,
      shape: Border(),
      builder: (BuildContext context) {
        return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  hoverColor: Colors.transparent,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameFolderDialog(pasta);
                  },
                ),
                ListTile(
                  hoverColor: Colors.transparent,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Deletar'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, pasta['id_pasta']);
                  },
                ),
              ],
            ));
      },
    );
  }

//Modal de deletar pastas
  void _showDeleteConfirmationDialog(BuildContext context, int folderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.only(left: 0, right: 0, bottom: 0),
          backgroundColor: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirmar exclusão',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Frutiger',
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Tem certeza de que deseja deletar esta pasta?',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Frutiger',
                      )),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                          foregroundColor: Color.fromRGBO(255, 255, 255, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child: Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha o diálogo
                        },
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                          foregroundColor: Color.fromRGBO(255, 255, 255, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child: Text('Deletar'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha o diálogo
                          _deleteFolder(folderId); // Chama a função de deletar
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteFolder(int folderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return;
    }

    final url =
        'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/folder/$folderId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _fetchPastas(); // Atualiza a lista de pastas após a exclusão
      } else {}
    } catch (e) {}
  }

  void _showRenameFolderDialog(dynamic pasta) async {
    await _fetchFolderProfiles(pasta[
        'id_pasta']); // Chama para buscar perfis com permissão configurada
    TextEditingController renameController =
        TextEditingController(text: pasta['nome']);
    String? errorMessage; // Mensagem de erro para exibir no modal

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Dialog(
              insetPadding: EdgeInsets.only(
                left: 0,
                right: 0,
                bottom: 0,
              ),
              backgroundColor: Colors.transparent,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Renomear Pasta",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Frutiger',
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: renameController,
                          decoration: InputDecoration(
                            labelText: "Novo Nome da Pasta",
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Selecionar Perfis com Permissão",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Frutiger',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          children: _profiles.map((profile) {
                            int idPerfil = profile['id_perfil'];
                            bool isSelected =
                                _selectedProfiles[idPerfil] ?? false;

                            return CheckboxListTile(
                              title: Text(profile['perfil']),
                              value: isSelected,
                              hoverColor: Colors.transparent,
                              onChanged: (bool? value) {
                                setStateDialog(() {
                                  _selectedProfiles[idPerfil] = value ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (errorMessage != null) ...[
                          SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontFamily: 'Frutiger',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                                foregroundColor:
                                    Color.fromRGBO(255, 255, 255, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("Cancelar"),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                                foregroundColor:
                                    Color.fromRGBO(255, 255, 255, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              onPressed: () {
                                if (renameController.text.trim().isEmpty) {
                                  setStateDialog(() {
                                    errorMessage =
                                        "O nome da pasta não pode estar vazio";
                                  });
                                  return;
                                }
                                _renameFolder(
                                    pasta['id_pasta'], renameController.text);
                                Navigator.of(context).pop();
                              },
                              child: Text("Salvar"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "Confirmar saída?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Frutiger',
            ),
          ),
          content: Text(
              "No próximo acesso serão solicitadas suas informações de Login e Senha.",
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Frutiger',
                  color: Color.fromRGBO(50, 55, 62, 1))),
          actions: [
            TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Text(
                "Cancelar",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Frutiger',
                  color: Color.fromRGBO(0, 139, 208, 1),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Text(
                "Sair",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Frutiger',
                  color: Color.fromRGBO(0, 139, 208, 1),
                ),
              ),
              onPressed: () async {
                SharedPreferences sharedPreferences =
                    await SharedPreferences.getInstance();
                await sharedPreferences.clear();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameFolder(int folderId, String nome) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return;
    }

    // Primeira etapa: renomear a pasta
    try {
      final renameResponse = await http.patch(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/folder/$folderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "nome": nome, // Atualiza o nome da pasta
        }),
      );

      if (renameResponse.statusCode == 200) {
      } else {
        return;
      }
    } catch (e) {
      return;
    }

    // Segunda etapa: atualizar permissões dos perfis
    Map<String, bool> profilesToSend = {
      for (var entry in _selectedProfiles.entries)
        entry.key.toString(): entry.value
    };

    try {
      final permissionResponse = await http.patch(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/folders/$folderId/access'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "perfis": profilesToSend, // Atualiza as permissões dos perfis
        }),
      );

      if (permissionResponse.statusCode == 200) {
        _fetchPastas(); // Atualiza a lista de pastas após a edição
      } else {}
    } catch (e) {}
  }

  Future<void> carregarDadosUsuario() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      nome = sharedPreferences.getString('nome');
      email = sharedPreferences.getString('email');
      idPerfil =
          sharedPreferences.getString('id_perfil'); // Carrega o id_perfil
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bloco da logo, VisionCase e CircleAvatar
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo-principal.png',
                        height: 40,
                      ),
                      SizedBox(width: 24),
                      Text(
                        'VisionCase',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Frutiger',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  // CircleAvatar com o PopupMenuButton
                  PopupMenuButton(
                    offset: Offset(0, 50),
                    color: Colors.white, // Posição do menu
                    itemBuilder: (context) {
                      List<PopupMenuEntry> menuItems = [
                        PopupMenuItem(
                          enabled: false,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                                child: Text(
                                  (nome ?? "Nome Usuario")
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Frutiger',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome ?? "Usuário",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      fontFamily: 'Frutiger',
                                      color: Color.fromRGBO(50, 55, 62, 1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          enabled: false,
                          child: Divider(
                            thickness: 1,
                            indent: 20, // Espaço à esquerda
                            endIndent: 40,
                            color: Color.fromRGBO(25, 25, 25, 0.16),
                          ),
                        ),
                      ];

                      // Área Administrativa para perfis
                      if (idPerfil == "1" || idPerfil == "2") {
                        menuItems.add(
                          PopupMenuItem(
                            child: StatefulBuilder(
                              builder:
                                  (BuildContext context, StateSetter setState) {
                                return Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _areaAdminExpandida =
                                              !_areaAdminExpandida;
                                        });
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Área Administrativa",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Frutiger',
                                            fontWeight: FontWeight.w400,
                                            height: 1.5,
                                          )),
                                          Icon(_areaAdminExpandida
                                              ? Icons.expand_less
                                              : Icons.expand_more),
                                        ],
                                      ),
                                    ),
                                    if (_areaAdminExpandida) ...[
                                      SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PastasPage()));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 60.0, bottom: 8),
                                          child: Text("Acesso a Pastas",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Frutiger',
                                            fontWeight: FontWeight.w400,
                                            height: 1.5,
                                          )),
                                        ),
                                      ),
                                      if (idPerfil == "1") ...[
                                        SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      UsuarioPage()),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 67.0),
                                            child: Text("Acesso Usuário",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Frutiger',
                                              fontWeight: FontWeight.w400,
                                              height: 1.5,
                                            )),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      }

                      menuItems.addAll([
                        PopupMenuItem(
                          child: Text("Página Inicial",
                           style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Frutiger',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            )),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(
                                Icons.exit_to_app,
                                color: Colors.grey,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text("Sair",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              )),
                            ],
                          ),
                          onTap: () {
                            _logout(context);
                          },
                        ),
                      ]);

                      return menuItems;
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                      child: Text(
                        (nome ?? "Nome Usuario")
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Frutiger',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Linha de separação
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: Offset(0, 2.0),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),

            // Bloco de pastas (fixo no topo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e botão "Criar Nova Pasta"
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Spacer(),
                        Text(
                          "Pastas",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Frutiger',
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          onPressed: _showCreateFolderDialog,
                          child: Text("Criar Nova Pasta"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bloco de conteúdo rolável (pastas e mensagens de erro)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Verifica se existe erro ou se as pastas estão vazias
                    _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : _pastas.isEmpty
                            ? Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color.fromRGBO(0, 114, 239, 1),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (var pasta in _pastas) ...[
                                    GestureDetector(
                                      onTap: () => _openSubfolderPage(pasta),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: ListTile(
                                          leading: Icon(Icons.folder,
                                              size: 38, color: Colors.amber),
                                          title: Text(
                                            pasta['nome'] ?? 'Pasta',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Frutiger',
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              Icons.more_vert_outlined,
                                              size: 20,
                                              color: Color.fromRGBO(
                                                  0, 114, 239, 1),
                                            ),
                                            hoverColor: Colors.transparent,
                                            onPressed: () => _showFolderOptions(
                                                context, pasta),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Divider(
                                        color: Colors.grey.shade300,
                                        thickness: 1.0,
                                        height: 1.0),
                                  ]
                                ],
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
