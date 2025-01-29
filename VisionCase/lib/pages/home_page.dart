import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'usuario_page.dart';
import 'folder_page.dart';
import 'conteudo_pasta.dart';
import 'conteudo_subpasta.dart';
import 'pagina_pesquisa.dart';
import 'detalhes_pages.dart';
import 'trocar_senha_dentro_app.dart';
import '../services/listar_arquivos.dart';
import '../services/auth_services.dart';
import '../services/download_service.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

//Index inicial é 0
  const HomePage({super.key, this.initialIndex = 0});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selecionaIndex = 0;
  List<Map<String, dynamic>> _pastas = [];
  List<Map<String, dynamic>> _favoritos = [];
  bool _isLoading = true;
  bool _areaAdminExpandida = false;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  //Variaveis para Dados do SharedPreferences
  String? nome;
  String? email;
  String? idPerfil;

  @override
  void initState() {
    super.initState();
    _carregarPastas();
    _selecionaIndex = widget.initialIndex;
    _carregarFavoritos();
    carregarDadosUsuario();
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

//Carregar as pastas na homepage
  Future<void> _carregarPastas() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/user/folders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 && mounted) {
        // Adicionada verificação mounted
        final data = json.decode(response.body);
        setState(() {
          _pastas = List<Map<String, dynamic>>.from(data)
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Adicionada verificação mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //Carregar Favoritos
  Future<void> _carregarFavoritos() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _favoritos = [];

          // Adiciona arquivos
          List<Map<String, dynamic>> arquivos =
              List<Map<String, dynamic>>.from(data['files'] ?? []);
          _favoritos.addAll(arquivos.map((arquivo) {
            return {
              'type': 'file', // Define o tipo como 'file'
              'data': arquivo['file'], // Dados do arquivo
            };
          }));

          // Adiciona subpastas
          List<Map<String, dynamic>> subpastas =
              List<Map<String, dynamic>>.from(data['subfolders'] ?? []);
          _favoritos.addAll(subpastas.map((subpasta) {
            return {
              'type': 'subfolder', // Define o tipo como 'subfolder'
              'data': subpasta['subfolder'], // Dados da subpasta
            };
          }));

          _isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar favoritos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //Confirmar a saida do sistema
  void _logout(BuildContext context) {
    final AutenticacaoUser _autenticacaoUser = AutenticacaoUser();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
          backgroundColor: Colors.white,
          title: Text("Confirmar saída?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Frutiger',
              )),
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
                await _autenticacaoUser.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<FileSystemEntity>> _listarArquivosOffline() async {
    try {
      // Caminho específico do diretório
      final Directory appDirectory = Directory(
          '/storage/emulated/0/Android/data/com.zeiss.visioncase/files/downloads/');

      // Verifica se o diretório existe
      if (!await appDirectory.exists()) {
        return [];
      }

      // Lista os arquivos e subdiretórios
      return appDirectory.listSync();
    } catch (e) {
      return [];
    }
  }

  Widget _getImageForFile(String extension) {
    final icons = {
      'pdf': 'assets/images/pdf.png',
      'doc': 'assets/images/docx.png',
      'docx': 'assets/images/docx.png',
      'xls': 'assets/images/xls.png',
      'xlsx': 'assets/images/xls.png',
      'csv': 'assets/images/csv.png',
      'ppt': 'assets/images/ppt.png',
      'pptx': 'assets/images/ppt.png',
      'jpg': 'assets/images/jpg.png',
      'jpeg': 'assets/images/jpg.png',
      'png': 'assets/images/png.png',
      'mp4': 'assets/images/video.png',
      'avi': 'assets/images/video.png',
    };

    return Image.asset(
      icons[extension.toLowerCase()] ?? 'assets/images/file.png',
      width: 40,
      height: 40,
      errorBuilder: (context, error, stackTrace) {
        // Fallback para um ícone padrão caso a imagem não seja encontrada
        return Icon(Icons.insert_drive_file);
      },
    );
  }

  Widget _buildPastasList() {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
            color: Color.fromRGBO(0, 114, 239, 1),
          ))
        : _pastas.isEmpty
            ? Center(child: Text("Nenhuma pasta disponível"))
            : ListView.builder(
                // Mudança de separated para builder
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: _pastas.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      _buildPastaItem(context, index),
                      if (index < _pastas.length - 1)
                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                          indent: 20,
                          endIndent: 40,
                        ),
                    ],
                  );
                },
              );
  }

  Widget _buildPastaItem(BuildContext context, int index) {
    final pasta = _pastas[index];
    final String? dataCriacao = pasta['criado_em'];
    final String dataFormatada = dataCriacao != null
        ? dateFormat.format(DateTime.parse(dataCriacao))
        : 'Data desconhecida';

    return ListTile(
      leading: Icon(Icons.folder, color: Colors.amber, size: 38),
      hoverColor: Colors.transparent,
      title: Text(
        pasta['nome'] ?? 'Sem nome',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Frutiger',
        ),
      ),
      subtitle: Text(
        'Criado em: $dataFormatada',
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Frutiger',
        ),
      ),
      onTap: () {
        final folderId = pasta['id_pasta'];
        final subfolderId = pasta['subfolder_id'] ?? folderId;
        if (folderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubfolderContentPage(
                folderId: folderId,
                subfolderId: subfolderId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Pasta inválida! Não foi possível abrir.')),
          );
        }
      },
    );
  }

  Widget _buildFavoriteSubfolderItem(Map<String, dynamic> subfolder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(Icons.folder, color: Colors.amber, size: 38),
        title: Row(
          children: [
            Expanded(
              child: Text(subfolder['name'] ?? 'Sem nome'),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Icon(Icons.star, color: Colors.blue, size: 20),
            ),
          ],
        ),
        onTap: () {
          final subfolderId = subfolder['id'];
          final idFolder = subfolder['folderId'];

          if (subfolderId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: ID da subpasta não encontrado.')),
            );
            return;
          }

          if (idFolder == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Erro: Esta subpasta não está associada a nenhuma pasta.')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubfolderContentSubPage(
                subfolderId: subfolderId,
              ),
            ),
          );
        },
      ),
    );
  }

  //Alternar entre as paginas na barra de navegação
  void _barraNavegacaoAlternar(int index) {
    if (mounted) {
      setState(() {
        _selecionaIndex = index;
      });
      if (index == 0 && mounted) {
        _carregarPastas();
      }
    }
  }

//Funçao para mostrar o cabeçalho em todos os menus de navegação
  Widget _buildHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          Row(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Spacer(), // Adicione Spacer corretamente aqui
              PopupMenuButton(
                offset: Offset(0, 50), // Posição do menu
                color: Colors.white,
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
                                  fontFamily: 'Frutiger',
                                  fontSize: 16,
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
                                          right: 30.0, bottom: 8),
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
                                        padding:
                                            const EdgeInsets.only(right: 38.0),
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
                        height: 50,
                        child: Text("Alterar Senha",
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
                                builder: (context) => AlterarSenhaPage()),
                          );
                        }),
                    PopupMenuItem(
                      height: 50,
                      child: Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: Color.fromRGBO(50, 55, 62, 1),
                            size: 18,
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
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Container(
            height: 1,
            decoration:
                BoxDecoration(color: Colors.white.withOpacity(0.3), boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: Offset(0, 2.0),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ]),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  //Lista de páginas associadas ao itens do menu inferior
  Widget _buildContent() {
    switch (_selecionaIndex) {
      case 0:
        return OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              // Layout vertical - Início e pesquisa fixos
              return Column(
                children: [
                  // Cabeçalho fixo
                  _buildHeader("Início"),

                  // Seção "Início" e pesquisa fixa
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Início",
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Frutiger',
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05), // Sombra bem suave
                                  offset:
                                      Offset(0, 2), // Sombra apenas para baixo
                                  blurRadius: 8, // Suavização da sombra
                                  spreadRadius: 0, // Não espalha a sombra
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    readOnly: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SearchPage(),
                                        ),
                                      );
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Pesquisar por...",
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 10),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.search,
                                    color: Color.fromRGBO(0, 114, 239, 1),
                                    size: 20,
                                  ),
                                  onPressed: () {},
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Lista de pastas scrollável
                  Expanded(
                    child: _buildPastasList(),
                  ),
                ],
              );
            } else {
              // Layout horizontal - Tudo scrollável exceto o cabeçalho
              return Column(
                children: [
                  // Cabeçalho fixo
                  _buildHeader("Início"),

                  // Conteúdo scrollável
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Seção "Início" e pesquisa
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Início",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Frutiger',
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            readOnly: true,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SearchPage(),
                                                ),
                                              );
                                            },
                                            decoration: InputDecoration(
                                              hintText: "Pesquisar por...",
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 10),
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 24,
                                          width: 1,
                                          color: Colors.grey,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.search,
                                            color:
                                                Color.fromRGBO(0, 114, 239, 1),
                                            size: 16,
                                          ),
                                          onPressed: () {},
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),

                          // Lista de pastas
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _pastas.isEmpty
                                  ? Center(
                                      child: Text("Nenhuma pasta disponível"))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: _pastas.length,
                                      itemBuilder: (context, index) {
                                        return Column(
                                          children: [
                                            _buildPastaItem(context, index),
                                            if (index < _pastas.length - 1)
                                              Divider(
                                                color: Colors.grey.shade300,
                                                thickness: 1,
                                                indent: 20,
                                                endIndent: 40,
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        );
      case 1: // Arquivos offline
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Downloads"),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                "Downloads",
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Frutiger',
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setStateBuilder) {
                  return FutureBuilder<List<FileSystemEntity>>(
                    key: UniqueKey(),
                    future: _listarArquivosOffline(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text("Erro ao carregar arquivos."));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                            child: Text("Nenhum arquivo encontrado."));
                      }

                      List<Map<String, dynamic>> arquivosFormatados =
                          snapshot.data!.map((item) {
                        final String nomeComZip = item.path.split('/').last;
                        final String nomeSemZip =
                            nomeComZip.replaceAll('.zip', '');
                        final File file = File(item.path);
                        final FileStat stat = file.statSync();

                        return {
                          'nome_exibicao':
                              nomeSemZip, // Nome sem .zip para exibição
                          'nome_completo':
                              nomeComZip, // Nome com .zip para sistema
                          'path': item.path,
                          'criado_em': stat.modified.toIso8601String(),
                          'size': stat.size,
                        };
                      }).toList();

                      return ListView.separated(
                        itemCount: arquivosFormatados.length,
                        physics: AlwaysScrollableScrollPhysics(),
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                          indent: 20,
                          endIndent: 40,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final arquivo = arquivosFormatados[index];
                          final extension = arquivo['nome_exibicao']
                              .split('.')
                              .last
                              .toLowerCase();

                          return Dismissible(
                            key: Key(arquivo['path']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Color.fromRGBO(0, 114, 239, 1),
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: Text("Confirmar exclusão"),
                                  content: Text(
                                      "Tem certeza que deseja excluir este arquivo?"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text("Cancelar"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text("Excluir"),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              try {
                                final file = File(arquivo['path']);
                                await file.delete();

                                if (mounted) {
                                  setStateBuilder(() {
                                    arquivosFormatados.removeAt(index);
                                  });
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Arquivo excluído com sucesso'),
                                      backgroundColor:
                                          Color.fromRGBO(0, 114, 239, 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Erro ao excluir arquivo: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: ListTile(
                              hoverColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: _getImageForFile(extension),
                              title: Text(
                                arquivo['nome_exibicao'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Frutiger',
                                ),
                              ),
                              subtitle: Text(
                                  'Criado em: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(arquivo['criado_em']))}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Frutiger',
                                  )),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Color.fromRGBO(0, 114, 239, 1),
                                  size: 20,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    isDismissible: true,
                                    barrierColor: Colors.black26,
                                    builder: (BuildContext context) {
                                      return Stack(
                                        children: [
                                          BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              height: double.infinity,
                                              width: double.infinity,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Material(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.zero,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  // Cabeçalho do modal
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16.0,
                                                        horizontal: 16.0),
                                                    child: Row(
                                                      children: [
                                                        _getImageForFile(
                                                            extension),
                                                        SizedBox(width: 16),
                                                        Expanded(
                                                          child: Text(
                                                            arquivo[
                                                                'nome_exibicao'],
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontFamily:
                                                                  'Frutiger',
                                                              fontSize: 14,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.grey.shade300,
                                                    thickness: 1,
                                                  ),
                                                  // Opção de Detalhes
                                                  ListTile(
                                                    leading: Icon(
                                                        Icons.info_outline,
                                                        size: 15),
                                                    title: Text(
                                                      'Detalhes',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Frutiger',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      // Navegação para a página de detalhes
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              FileDetailsPage(
                                                            fileId: arquivo[
                                                                'path'], // Passa o caminho do arquivo
                                                            isOffline:
                                                                true, // Marca como arquivo offline
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  // Opção de Excluir
                                                  ListTile(
                                                    leading: Icon(
                                                        Icons.delete_outline,
                                                        size: 15),
                                                    title: Text(
                                                      'Excluir',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Frutiger',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                    onTap: () async {
                                                      Navigator.pop(
                                                          context); // Fecha o modal

                                                      final confirm =
                                                          await showDialog<
                                                              bool>(
                                                        context: context,
                                                        builder: (BuildContext
                                                                context) =>
                                                            AlertDialog(
                                                          title: Text(
                                                              "Confirmar exclusão"),
                                                          content: Text(
                                                              "Tem certeza que deseja excluir este arquivo?"),
                                                          actions: <Widget>[
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                              child: Text(
                                                                  "Cancelar"),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      true),
                                                              child: Text(
                                                                  "Excluir"),
                                                              style: TextButton
                                                                  .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .red),
                                                            ),
                                                          ],
                                                        ),
                                                      );

                                                      if (confirm == true) {
                                                        try {
                                                          final file = File(
                                                              arquivo['path']);
                                                          await file.delete();

                                                          if (context.mounted) {
                                                            // Atualiza a lista
                                                            setStateBuilder(() {
                                                              arquivosFormatados
                                                                  .removeAt(
                                                                      index);
                                                            });

                                                            // Força a reconstrução do FutureBuilder

                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    'Arquivo excluído com sucesso'),
                                                                backgroundColor:
                                                                    Color
                                                                        .fromRGBO(
                                                                            0,
                                                                            114,
                                                                            239,
                                                                            1),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    'Erro ao excluir arquivo: $e'),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                      setState(() {
                                                        _listarArquivosOffline();
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              onTap: () async {
                                try {
                                  final zipFile = File(arquivo['path']);
                                  if (!await zipFile.exists()) {
                                    throw Exception(
                                        'Arquivo ZIP não encontrado');
                                  }

                                  final downloadService = DownloadService();

                                  // Descompacta o arquivo
                                  final decompressedFile = await downloadService
                                      .decompressZip(zipFile);

                                  // Abre o arquivo
                                  final result = await OpenFile.open(
                                      decompressedFile.path);

                                  if (result.type != ResultType.done) {
                                    throw Exception(
                                        'Erro ao abrir arquivo: ${result.message}');
                                  }

                                  // Agenda a limpeza para 60 segundos depois
                                  Future.delayed(Duration(seconds: 60),
                                      () async {
                                    await downloadService
                                        .cleanupTempFile(decompressedFile);
                                  });
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Erro ao abrir arquivo: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      case 2: // Favoritos
        return OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              // Layout vertical
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("Favoritos"),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: Text(
                      "Favoritos",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Frutiger',
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _favoritos.isEmpty
                            ? Center(child: Text("Nenhum item favorito"))
                            : Column(
                                children: [
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        // Subpastas favoritas
                                        ..._favoritos
                                            .where((item) =>
                                                item['type'] == 'subfolder')
                                            .map((item) {
                                          final subfolder = item['data'];
                                          return _buildFavoriteSubfolderItem(
                                              subfolder);
                                        }).toList(),

                                        // Arquivos favoritos
                                        if (_favoritos.any(
                                            (item) => item['type'] == 'file'))
                                          FileListWidget(
                                            arquivos: _favoritos
                                                .where((item) =>
                                                    item['type'] == 'file')
                                                .map((item) => item['data'])
                                                .toList(),
                                            selectedFiles: List.generate(
                                                _favoritos.length,
                                                (index) => false),
                                            onFileSelected:
                                                (int index, bool? selected) {
                                              final arquivo =
                                                  _favoritos[index]['data'];
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],
              );
            } else {
              // Layout horizontal
              return Column(
                children: [
                  _buildHeader("Favoritos"),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 8.0),
                            child: Text(
                              "Favoritos",
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'Frutiger',
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _favoritos.isEmpty
                                  ? Center(child: Text("Nenhum item favorito"))
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Subpastas favoritas
                                        ..._favoritos
                                            .where((item) =>
                                                item['type'] == 'subfolder')
                                            .map((item) {
                                          final subfolder = item['data'];
                                          return _buildFavoriteSubfolderItem(
                                              subfolder);
                                        }).toList(),

                                        // Arquivos favoritos
                                        if (_favoritos.any(
                                            (item) => item['type'] == 'file'))
                                          FileListWidget(
                                            arquivos: _favoritos
                                                .where((item) =>
                                                    item['type'] == 'file')
                                                .map((item) => item['data'])
                                                .toList(),
                                            selectedFiles: List.generate(
                                                _favoritos.length,
                                                (index) => false),
                                            onFileSelected:
                                                (int index, bool? selected) {
                                              final arquivo =
                                                  _favoritos[index]['data'];
                                            },
                                          ),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        );
      default:
        return Center(child: Text("Página não encontrada"));
    }
  }

//NOVA TELA DE HOME PAGE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildContent(),
      bottomNavigationBar: Stack(
        children: [
          BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selecionaIndex,
            onTap: _barraNavegacaoAlternar,
            selectedItemColor: Color.fromRGBO(0, 114, 239, 1),
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                label: "Downloads",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star_border_outlined),
                label: "Favoritos",
              ),
            ],
          ),
          Positioned(
            bottom:
                56, // Altura exata da linha em relação ao topo do BottomNavigationBar
            left: MediaQuery.of(context).size.width / 3 * _selecionaIndex + 25,
            child: Container(
              height: 2,
              width: MediaQuery.of(context).size.width / 3 - 50,
              color: Color.fromRGBO(0, 114, 239, 1),
            ),
          ),
        ],
      ),
    );
  }
}
