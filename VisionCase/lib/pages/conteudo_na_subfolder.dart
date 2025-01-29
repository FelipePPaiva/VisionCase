import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Para selecionar arquivos
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/upload_service.dart';

class SubfolderFilesPage extends StatefulWidget {
  final int subfolderId;

  SubfolderFilesPage({Key? key, required this.subfolderId});

  @override
  _SubfolderFilesPageState createState() => _SubfolderFilesPageState();
}

class _SubfolderFilesPageState extends State<SubfolderFilesPage> {
  late Future<List<dynamic>> _files;
  String? subfolderName;
  late int subfolderId;
  int? _idPerfil;
  // Vamos usar um Future para controlar a inicialização
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeData();
  }

  Future<void> _initializeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idPerfil = prefs.getString('id_perfil');

    if (idPerfil != null) {
      _idPerfil = int.parse(idPerfil);
    }

    subfolderId = widget.subfolderId;
    _files = fetchSubfolderFiles(widget.subfolderId);
    await fetchSubfolderName(widget.subfolderId);
  }

  // Atualize o método fetchSubfolderName
  Future<void> fetchSubfolderName(int subfolderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

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
        final Map<String, dynamic> data = json.decode(response.body);
        String fullPath = data['caminho'] ?? "";

        // Extrair apenas o nome da pasta atual do caminho completo
        String currentFolderName = fullPath.split('/').last;

        setState(() {
          subfolderName = currentFolderName;
        });
      } else {
        throw Exception('Erro ao carregar o nome da subpasta');
      }
    } catch (e) {
      setState(() {
        subfolderName = "Erro ao carregar";
      });
    }
  }

  // Método para buscar os arquivos da subpasta
  Future<List<dynamic>> fetchSubfolderFiles(int subfolderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

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
        if (data is List) {
          return List<dynamic>.from(data);
        } else if (data is Map && data['files'] != null) {
          return List<dynamic>.from(data['files']);
        } else {
          throw Exception('Formato inesperado de dados.');
        }
      } else {
        throw Exception('Erro ao carregar arquivos da subpasta');
      }
    } catch (e) {
      return [];
    }
  }

  void _showFileOptions(BuildContext context, dynamic file) {
    showModalBottomSheet(
      context: context,
      shape: Border(),
      builder: (BuildContext context) {
        return Container(
            color: Colors.white, // Background branco
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text("Editar"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _editItem(file);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text("Deletar"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteItem(file);
                  },
                ),
              ],
            ));
      },
    );
  }

// Função de edição
  void _editItem(dynamic item) async {
    TextEditingController nameController =
        TextEditingController(text: item['nome']);
    final String? itemId = item['id_arquivo'] ?? item['id'] ?? item['id_file'];
    final String? fileExtension = _getFileExtension(item['nome']);

    bool? confirmEdit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: Border(),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Editar ${item['nome']}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Frutiger',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Novo nome",
                    suffix: Text('.$fileExtension'),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text("Cancelar"),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: () async {
                        if (nameController.text.isNotEmpty && itemId != null) {
                          try {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String? token = prefs.getString('token');

                            final String url =
                                'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/update-filename/$itemId';

                            final body = json.encode({
                              'newName': '${nameController.text}.$fileExtension'
                            });

                            final response = await http.put(
                              Uri.parse(url),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $token',
                              },
                              body: body,
                            );

                            if (response.statusCode == 200) {
                              Navigator.of(context).pop(true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Arquivo renomeado com sucesso!'),
                                  backgroundColor:
                                      Color.fromRGBO(0, 114, 239, 1),
                                ),
                              );
                              setState(() {
                                _files =
                                    fetchSubfolderFiles(widget.subfolderId);
                              });
                            } else {
                              throw Exception(
                                  'Erro ${response.statusCode}: ${response.body}');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao renomear: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text("Salvar"),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteItem(dynamic item) async {
    String itemName = item['nome'] ?? '';

    bool? confirmDelete = await showModalBottomSheet<bool>(
      context: context,
      shape: Border(),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Confirmar Deleção",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Frutiger',
                ),
              ),
              SizedBox(height: 20),
              Text("Tem certeza que deseja deletar $itemName?",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Frutiger',
                  )),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("Cancelar"),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("Deletar"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmDelete == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        final String url =
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/file/${item['id_arquivo']}';

        var response = await http.delete(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );

        if (mounted) {
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Arquivo deletado com sucesso!'),
                backgroundColor: Color.fromRGBO(0, 114, 239, 1),
              ),
            );
            setState(() {
              _files = fetchSubfolderFiles(widget.subfolderId);
            });
          } else {
            throw Exception(
                'Erro ao deletar ${response.statusCode}: ${response.body}');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao deletar arquivo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

// Função auxiliar para pegar a extensão do arquivo
  String? _getFileExtension(String filename) {
    final lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex != -1 ? filename.substring(lastDotIndex + 1) : null;
  }

  String _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    // Mapeamento de extensões para os ícones correspondentes
    switch (extension) {
      case 'csv':
        return 'assets/images/csv.png';

      case 'doc':
      case 'docx':
        return 'assets/images/docx.png';

      case 'jpg':
      case 'jpeg':
        return 'assets/images/jpg.png';

      case 'pdf':
        return 'assets/images/pdf.png';

      case 'png':
        return 'assets/images/png.png';

      case 'ppt':
      case 'pptx':
        return 'assets/images/ppt.png';

      case 'xls':
      case 'xlsx':
        return 'assets/images/xls.png';

      case 'mp3':
      case 'mp4':
      case 'mkv':
        return 'assets/images/video.png';

      default:
        return 'assets/images/file.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        toolbarHeight: 100,
        title: Text(
          subfolderName ?? "Carregando...",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Frutiger',
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            size: 16,
            color: Color.fromRGBO(0, 114, 239, 1),
          ),
          hoverColor: Colors.transparent,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initialization,
        builder: (context, initSnapshot) {
          if (initSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Color.fromRGBO(0, 114, 239, 1),
            ));
          }

          return FutureBuilder<List<dynamic>>(
            future: _files,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                  color: Color.fromRGBO(0, 114, 239, 1),
                ));
              }

              // Se não houver dados ou a lista estiver vazia
              return Column(
                children: [
                  // Botão de upload (se for admin)
                  if (_idPerfil == 1 || _idPerfil == 2)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                              foregroundColor: Color.fromRGBO(255, 255, 255, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            onPressed: () async {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: Border(),
                                builder: (BuildContext context) {
                                  List<PlatformFile> selectedFiles = [];
                                  List<bool> isConfidential = [];
                                  bool isLoading = false;
                                  Map<String, double> uploadProgress = {};

                                  return StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setModalState) {
                                      return Container(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Header existente
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            15)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    spreadRadius: 1,
                                                    blurRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Upload de Arquivo",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontFamily: 'Frutiger',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.close),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Conteúdo com scroll
                                            Expanded(
                                              child: SingleChildScrollView(
                                                padding: EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Instruções
                                                    Container(
                                                      padding:
                                                          EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color:
                                                                  Colors.blue),
                                                          SizedBox(width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              "Selecione até 5 arquivos para realizar o upload",
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontFamily:
                                                                    'Frutiger',
                                                                color: Colors
                                                                    .blue[700],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Lista de arquivos
                                                    if (selectedFiles
                                                        .isNotEmpty) ...[
                                                      SizedBox(height: 16),
                                                      Text(
                                                        "Arquivos selecionados",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontFamily:
                                                              'Frutiger',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      ...selectedFiles
                                                          .asMap()
                                                          .entries
                                                          .map((entry) {
                                                        int index = entry.key;
                                                        PlatformFile file =
                                                            entry.value;

                                                        if (isLoading) {
                                                          return Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    bottom: 16),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        file.name,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          fontFamily:
                                                                              'Frutiger',
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '${((uploadProgress[file.name] ?? 0) * 100).toStringAsFixed(1)}%',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontFamily:
                                                                            'Frutiger',
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height: 8),
                                                                LinearProgressIndicator(
                                                                  value: uploadProgress[
                                                                          file.name] ??
                                                                      0,
                                                                  backgroundColor:
                                                                      Colors.grey[
                                                                          200],
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<
                                                                          Color>(
                                                                    Color
                                                                        .fromRGBO(
                                                                            0,
                                                                            114,
                                                                            239,
                                                                            1),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }

                                                        return Card(
                                                          color: Colors.white,
                                                          margin:
                                                              EdgeInsets.only(
                                                                  bottom: 8),
                                                          child: ListTile(
                                                            leading: Icon(Icons
                                                                .insert_drive_file),
                                                            title: Text(
                                                              file.name,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontFamily:
                                                                    'Frutiger',
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            trailing: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Checkbox(
                                                                      value: isConfidential[
                                                                          index],
                                                                      onChanged:
                                                                          (bool?
                                                                              newValue) {
                                                                        if (newValue ==
                                                                                true &&
                                                                            !file.name.toLowerCase().endsWith('.pdf')) {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            barrierColor:
                                                                                Colors.black54,
                                                                            builder:
                                                                                (BuildContext context) {
                                                                              return Dialog(
                                                                                insetPadding: EdgeInsets.zero,
                                                                                child: Container(
                                                                                  color: Colors.white,
                                                                                  padding: EdgeInsets.all(16),
                                                                                  width: MediaQuery.of(context).size.width * 0.8,
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    children: [
                                                                                      Text(
                                                                                        "Para arquivos confidencial, deverá ser em PDF",
                                                                                        style: TextStyle(
                                                                                          fontSize: 16,
                                                                                          fontFamily: 'Frutiger',
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(height: 16),
                                                                                      ElevatedButton(
                                                                                        style: ElevatedButton.styleFrom(
                                                                                          backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                                                                                          foregroundColor: Colors.white,
                                                                                          shape: RoundedRectangleBorder(
                                                                                            borderRadius: BorderRadius.circular(3),
                                                                                          ),
                                                                                        ),
                                                                                        onPressed: () => Navigator.pop(context),
                                                                                        child: Text("OK"),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                          return;
                                                                        }
                                                                        setModalState(
                                                                            () {
                                                                          isConfidential[index] =
                                                                              newValue!;
                                                                        });
                                                                      },
                                                                    ),
                                                                    Text(
                                                                        "Confidencial"),
                                                                  ],
                                                                ),
                                                                IconButton(
                                                                  icon: Icon(Icons
                                                                      .close),
                                                                  onPressed:
                                                                      () {
                                                                    setModalState(
                                                                        () {
                                                                      selectedFiles
                                                                          .removeAt(
                                                                              index);
                                                                      isConfidential
                                                                          .removeAt(
                                                                              index);
                                                                    });
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Botões de ação
                                            Container(
                                              padding: EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    spreadRadius: 1,
                                                    blurRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Color.fromRGBO(
                                                                0, 114, 239, 1),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                      ),
                                                      onPressed: isLoading
                                                          ? null
                                                          : () async {
                                                              if (selectedFiles
                                                                  .isEmpty) {
                                                                FilePickerResult?
                                                                    result =
                                                                    await FilePicker
                                                                        .platform
                                                                        .pickFiles(
                                                                  allowMultiple:
                                                                      true,
                                                                  type: FileType
                                                                      .custom,
                                                                  allowedExtensions: [
                                                                    'pdf',
                                                                    'doc',
                                                                    'docx',
                                                                    'xls',
                                                                    'xlsx',
                                                                    'csv',
                                                                    'ppt',
                                                                    'pptx',
                                                                    'jpg',
                                                                    'jpeg',
                                                                    'png',
                                                                    'mp3',
                                                                    'mp4',
                                                                    'mkv',
                                                                    'zip',
                                                                    '7z'
                                                                  ],
                                                                );

                                                                if (result !=
                                                                    null) {
                                                                  setModalState(
                                                                      () {
                                                                    selectedFiles
                                                                        .addAll(
                                                                            result.files);
                                                                    isConfidential
                                                                        .addAll(
                                                                      List<bool>.filled(
                                                                          result
                                                                              .files
                                                                              .length,
                                                                          false),
                                                                    );
                                                                  });
                                                                }
                                                              } else if (selectedFiles
                                                                      .length <=
                                                                  5) {
                                                                try {
                                                                  setModalState(
                                                                      () {
                                                                    isLoading =
                                                                        true;
                                                                    uploadProgress
                                                                        .clear();
                                                                    for (var file
                                                                        in selectedFiles) {
                                                                      uploadProgress[
                                                                          file.name] = 0;
                                                                    }
                                                                  });

                                                                  for (int i =
                                                                          0;
                                                                      i <
                                                                          selectedFiles
                                                                              .length;
                                                                      i++) {
                                                                    PlatformFile
                                                                        platformFile =
                                                                        selectedFiles[
                                                                            i];
                                                                    File file = File(
                                                                        platformFile
                                                                            .path!);
                                                                    bool
                                                                        isFileConfidential =
                                                                        isConfidential[
                                                                            i];

                                                                    await UploadService()
                                                                        .uploadFile(
                                                                      file,
                                                                      subfolderId:
                                                                          subfolderId,
                                                                      isConfidential:
                                                                          isFileConfidential,
                                                                      onProgress:
                                                                          (progress) {
                                                                        setModalState(
                                                                            () {
                                                                          uploadProgress[platformFile.name] =
                                                                              progress;
                                                                        });
                                                                      },
                                                                    );
                                                                  }

                                                                  setState(() {
                                                                    _files = fetchSubfolderFiles(
                                                                        widget
                                                                            .subfolderId);
                                                                  });
                                                                  Navigator.pop(
                                                                      context);
                                                                } catch (e) {
                                                                  setModalState(
                                                                      () {
                                                                    isLoading =
                                                                        false;
                                                                  });
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                          'Erro ao fazer upload. Tente novamente.'),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                      child: Text(
                                                        selectedFiles.isEmpty
                                                            ? "Selecionar Arquivos"
                                                            : isLoading
                                                                ? "Enviando..."
                                                                : "Fazer Upload",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontFamily:
                                                              'Frutiger',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedFiles
                                                          .isNotEmpty &&
                                                      selectedFiles.length <
                                                          5 &&
                                                      !isLoading) ...[
                                                    SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .add_circle_outline,
                                                        color: Color.fromRGBO(
                                                            0, 114, 239, 1),
                                                      ),
                                                      onPressed: () async {
                                                        FilePickerResult?
                                                            result =
                                                            await FilePicker
                                                                .platform
                                                                .pickFiles(
                                                          allowMultiple: true,
                                                          type: FileType.custom,
                                                          allowedExtensions: [
                                                            'pdf',
                                                            'doc',
                                                            'docx',
                                                            'xls',
                                                            'xlsx',
                                                            'csv',
                                                            'ppt',
                                                            'pptx',
                                                            'jpg',
                                                            'jpeg',
                                                            'png',
                                                            'mp3',
                                                            'mp4',
                                                            'mkv',
                                                            'zip',
                                                            '7z'
                                                          ],
                                                        );

                                                        if (result != null) {
                                                          setModalState(() {
                                                            selectedFiles
                                                                .addAll(result
                                                                    .files);
                                                            isConfidential
                                                                .addAll(
                                                              List<bool>.filled(
                                                                  result.files
                                                                      .length,
                                                                  false),
                                                            );
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Text("Upload de Arquivo"),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: (!snapshot.hasData || snapshot.data!.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Esta pasta está vazia',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Frutiger',
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Adicione arquivos para começar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Frutiger',
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(10.0),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final file = snapshot.data![index];
                              final bool isConfidencial =
                                  file['confidencial'] ?? false;
                              return GestureDetector(
                                onTap: () {
                                  // Lógica para abrir o arquivo
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 5.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        _getFileIcon(file['nome'] ?? ''),
                                        width: 32,
                                        height: 32,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file['nome'] ??
                                                  'Arquivo sem nome',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Frutiger',
                                                fontWeight: FontWeight.w400,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            // Indicador de confidencial com o novo design
                                            if (isConfidencial)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4.0),
                                                child: IntrinsicWidth(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0,
                                                            horizontal: 6.0),
                                                    decoration: BoxDecoration(
                                                      color: Color.fromRGBO(
                                                          220, 227, 233, 1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.lock_outline,
                                                          color: Colors.black,
                                                          size: 10,
                                                        ),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          'Confidencial',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontFamily:
                                                                'Frutiger',
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.more_vert_outlined,
                                          color: Color.fromRGBO(0, 114, 239, 1),
                                          size: 20,
                                        ),
                                        hoverColor: Colors.transparent,
                                        onPressed: () =>
                                            _showFileOptions(context, file),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
