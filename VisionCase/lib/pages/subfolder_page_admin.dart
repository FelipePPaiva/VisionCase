import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'conteudo_na_subfolder.dart';
import '../services/criar_subpasta.dart';
import '../services/upload_service.dart';

class SubfolderContentPage extends StatefulWidget {
  final int folderId;

  SubfolderContentPage({Key? key, required this.folderId});

  @override
  _SubfolderContentPageState createState() => _SubfolderContentPageState();
}

class _SubfolderContentPageState extends State<SubfolderContentPage> {
  late Future<Map<String, dynamic>> _folderContent;
  int? _idPerfil;
  late int folderId;
  String? folderName = "Carregando...";

  @override
  void initState() {
    super.initState();
    _getUserProfile();
    folderId = widget.folderId;
    _folderContent = FolderService.fetchFolderContent(widget.folderId);

    _folderContent.then((data) {
      setState(() {
        folderName = data['folderName'] ?? "Sem Nome";
      });
    }).catchError((error) {
      setState(() {
        folderName = "Erro ao carregar nome";
      });
    });
  }

  void showUploadModal(BuildContext context) {
  List<PlatformFile> selectedFiles = [];
  List<bool> isConfidential = [];
  bool isLoading = false;
  Map<String, double> uploadProgress = {};

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upload de Arquivo",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Frutiger',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Selecione até 5 arquivos para realizar o upload",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Frutiger',
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (selectedFiles.length > 5)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Você pode selecionar no máximo 5 arquivos",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontFamily: 'Frutiger',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (selectedFiles.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Text(
                            "Arquivos selecionados",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Frutiger',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...selectedFiles.asMap().entries.map((entry) {
                            int index = entry.key;
                            PlatformFile file = entry.value;
                            
                            if (isLoading) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            file.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Frutiger',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${((uploadProgress[file.name] ?? 0) * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Frutiger',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: uploadProgress[file.name] ?? 0,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromRGBO(0, 114, 239, 1),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(Icons.insert_drive_file),
                                title: Text(
                                  file.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Frutiger',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: isConfidential[index],
                                      onChanged: (bool? newValue) {
                                        if (newValue == true &&
                                            !file.name.toLowerCase().endsWith('.pdf')) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Aviso"),
                                              content: Text(
                                                "Para arquivos confidenciais, deverá ser em PDF",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text("OK"),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }
                                        setModalState(() {
                                          isConfidential[index] = newValue!;
                                        });
                                      },
                                    ),
                                    Text("Confidencial"),
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        setModalState(() {
                                          selectedFiles.removeAt(index);
                                          isConfidential.removeAt(index);
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

                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (selectedFiles.isEmpty) {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                                      allowMultiple: true,
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv',
                                        'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'mp3',
                                        'mp4', 'mkv', 'zip', '7z'
                                      ],
                                    );

                                    if (result != null) {
                                      setModalState(() {
                                        selectedFiles.addAll(result.files);
                                        isConfidential.addAll(
                                          List<bool>.filled(result.files.length, false),
                                        );
                                      });
                                    }
                                  } else if (selectedFiles.length <= 5) {
                                    setModalState(() {
                                      isLoading = true;
                                      uploadProgress.clear();
                                      for (var file in selectedFiles) {
                                        uploadProgress[file.name] = 0;
                                      }
                                    });

                                    try {
                                      for (int i = 0; i < selectedFiles.length; i++) {
                                        PlatformFile platformFile = selectedFiles[i];
                                        File file = File(platformFile.path!);
                                        bool isFileConfidential = isConfidential[i];

                                        await UploadService().uploadFile(
                                          file,
                                          folderId: widget.folderId,
                                          isConfidential: isFileConfidential,
                                          onProgress: (progress) {
                                            setModalState(() {
                                              uploadProgress[platformFile.name] = progress;
                                            });
                                          },
                                        );
                                      }

                                      setState(() {
                                        _folderContent = FolderService.fetchFolderContent(
                                          widget.folderId,
                                        );
                                      });
                                      Navigator.pop(context);
                                    } catch (e) {
                                      setModalState(() {
                                        isLoading = false;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Erro ao fazer upload. Tente novamente.',
                                          ),
                                          backgroundColor: Colors.red,
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
                              fontFamily: 'Frutiger',
                            ),
                          ),
                        ),
                      ),
                      if (selectedFiles.isNotEmpty &&
                          selectedFiles.length < 5 &&
                          !isLoading) ...[
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Color.fromRGBO(0, 114, 239, 1),
                          ),
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                              type: FileType.custom,
                              allowedExtensions: [
                                'pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv',
                                'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'mp3',
                                'mp4', 'mkv', 'zip', '7z'
                              ],
                            );

                            if (result != null) {
                              setModalState(() {
                                selectedFiles.addAll(result.files);
                                isConfidential.addAll(
                                  List<bool>.filled(result.files.length, false),
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
}

// Função para abrir modal e criar nova subpasta
  Future<void> createNewSubfolder(
      BuildContext context, String folderId, Function refreshContent) async {
    final TextEditingController nameController = TextEditingController();
    bool showError = false; // Variável para controlar a exibição do erro

    showModalBottomSheet(
      context: context,
      shape: Border(),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Adicionamos um Padding que considera a altura do teclado
            return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                // Adicionamos um SingleChildScrollView para permitir rolagem quando necessário
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Criar Nova Subpasta",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Frutiger',
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration:
                            InputDecoration(hintText: "Nome da Subpasta"),
                      ),
                      SizedBox(height: 8),
                      // Exibe a mensagem de erro caso o nome esteja vazio
                      if (showError)
                        Text(
                          "O nome da pasta não pode estar vazio.",
                          style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Frutiger',
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      SizedBox(height: 24),
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
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Cancelar"),
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
                            onPressed: () async {
                              // Atualize o estado antes de validar
                              setState(() {
                                showError =
                                    false; // Reseta o erro ao tentar criar
                              });

                              if (nameController.text.isNotEmpty) {
                                bool success =
                                    await FolderService.createNewSubfolder(
                                        int.parse(folderId),
                                        nameController.text,
                                        context);

                                if (success) {
                                  refreshContent();
                                  Navigator.of(context).pop();
                                }
                              } else {
                                // Se o nome estiver vazio, mostra a mensagem de erro
                                setState(() {
                                  showError = true;
                                });
                              }
                            },
                            child: Text("Criar"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ));
          },
        );
      },
    );
  }

  Future<void> _getUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idPerfil =
        prefs.getString('id_perfil'); // Verifique a chave correta

    if (idPerfil != null) {
      setState(() {
        _idPerfil = int.parse(idPerfil); // Atribua o id ao estado
      });
    } else {
      // Caso o perfil não tenha sido encontrado
    }
  }

  void _showFolderOptions(BuildContext context, dynamic item) async {
    // Exibe um indicador de carregamento enquanto verifica o status do favorito
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString('token');
    final String url =
        'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/favorite-file/${item['id_file']}';

    // Variável local para armazenar o estado de favorito
    bool isFavoriteFromServer = false;

    try {
      // Requisição GET para verificar se está favoritado
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        final responseData = json.decode(response.body);
        isFavoriteFromServer =
            responseData['message'] == "Este arquivo já está favoritado.";
      } else {}
    } catch (e) {}

    showModalBottomSheet(
      context: context,
      shape: Border(),
      builder: (BuildContext context) {
        return Container(
            color: Colors.white, // Background branco
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_idPerfil == 1 || _idPerfil == 2) ...[
                  ListTile(
                    hoverColor: Colors.transparent,
                    leading: Icon(Icons.edit_outlined),
                    title: Text("Editar"),
                    onTap: () {
                      Navigator.of(context).pop();
                      _editItem(item);
                    },
                  ),
                  ListTile(
                    hoverColor: Colors.transparent,
                    leading: Icon(Icons.delete_outline),
                    title: Text("Deletar"),
                    onTap: () {
                      Navigator.of(context).pop();
                      _deleteItem(item);
                    },
                  ),
                ],
              ],
            ));
      },
    );
  }

//Editar item
  void _editItem(dynamic item) async {
    TextEditingController nameController =
        TextEditingController(text: item['nome']);

    // Melhorando a lógica para identificar se é arquivo ou pasta
    final bool isFile = item['id_file'] != null || item['id_arquivo'] != null;
    final String? itemId = isFile
        ? (item['id_file'] ?? item['id_arquivo'])?.toString()
        : item['id_subpasta']?.toString();

    final String? fileExtension =
        isFile ? _getFileExtension(item['nome']) : null;

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
                      suffix: isFile ? Text('.$fileExtension') : null,
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
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
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
                          if (nameController.text.isNotEmpty &&
                              itemId != null) {
                            String newName;
                            if (isFile && fileExtension != null) {
                              newName = '${nameController.text}.$fileExtension';
                            } else {
                              newName = nameController.text;
                            }

                            try {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              String? token = prefs.getString('token');

                              // Define a URL baseada no tipo do item
                              final String baseUrl =
                                  'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com';
                              final String url = isFile
                                  ? '$baseUrl/update-filename/$itemId'
                                  : '$baseUrl/subfolder/$itemId';

                              // Constrói o body com o campo correto
                              final body = json.encode(
                                isFile
                                    ? {'newName': newName}
                                    : {'nome': newName},
                              );

                              final response = isFile
                                  ? await http.put(
                                      Uri.parse(url),
                                      headers: {
                                        'Content-Type': 'application/json',
                                        'Authorization': 'Bearer $token',
                                      },
                                      body: body,
                                    )
                                  : await http.patch(
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
                                    content: Text(
                                        '${isFile ? "Arquivo" : "Subpasta"} renomeado(a) com sucesso!'),
                                    backgroundColor:
                                        Color.fromRGBO(0, 114, 239, 1),
                                  ),
                                );
                                setState(() {
                                  _folderContent =
                                      FolderService.fetchFolderContent(
                                          widget.folderId);
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
                ],
              ),
            ));
      },
    );

    // Lógica para lidar com a confirmação ou cancelamento
    if (confirmEdit != null && confirmEdit) {
    } else {}
  }

  String? _getFileExtension(String filename) {
    final lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex != -1 ? filename.substring(lastDotIndex + 1) : null;
  }

// Método para deletar item
  void _deleteItem(dynamic item) async {
    // Logs iniciais para debug

    bool isFile = item.containsKey('id_arquivo');
    String itemType = isFile ? "arquivo" : "pasta";
    String itemName = item['nome'] ?? '';

    bool? confirmDelete = await showModalBottomSheet<bool>(
      context: context,
      shape: Border(),
      isScrollControlled:
          true, // Permite que o modal tenha o tamanho necessário
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
                    onPressed: () {
                      Navigator.of(context)
                          .pop(false); // Responde false para não deletar
                    },
                    child: Text("Cancelar"),
                  ),
                  SizedBox(width: 8), // Espaço entre botões
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(true); // Responde true para deletar
                    },
                    child: Text("Deletar"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmDelete != null && confirmDelete) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        // Constrói a URL com base no tipo
        final String baseUrl =
            'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com';

        String url;

        if (isFile) {
          // Para arquivos
          url =
              '$baseUrl/file/${item['id_arquivo']}'; // Ajuste aqui a rota correta
        } else {
          // Para pastas
          url = '$baseUrl/subfolder/${item['id_subpasta']}';
        }

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
                content: Text(
                    '${isFile ? "Arquivo deletado com sucesso!" : "Pasta deletada com sucesso!"} '),
                backgroundColor: Color.fromRGBO(0, 114, 239, 1),
              ),
            );
            setState(() {
              _folderContent =
                  FolderService.fetchFolderContent(widget.folderId);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Falha ao deletar $itemType. Status: ${response.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao tentar deletar $itemType: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
          folderName ?? "Carregando...",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Frutiger',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            size: 16,
            color: Color.fromRGBO(0, 114, 239, 1),
          ),
          hoverColor: Colors.transparent,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _folderContent,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: Color.fromRGBO(0, 114, 239, 1)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Nenhum conteúdo encontrado'));
          }

          final folderContent = snapshot.data!;
          final subfolders = folderContent['subfolders'] ?? [];
          final files = folderContent['files'] ?? [];
          final allItems = [...subfolders, ...files];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        onPressed: () => createNewSubfolder(
                          context,
                          widget.folderId.toString(),
                          () {
                            setState(() {
                              _folderContent = FolderService.fetchFolderContent(
                                widget.folderId,
                              );
                            });
                          },
                        ),
                        child: Text("Criar Nova Subpasta"),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(0, 114, 239, 1),
                          foregroundColor: Color.fromRGBO(255, 255, 255, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        onPressed: () => showUploadModal(context),
                        child: Text("Upload de Arquivo"),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: allItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Esta pasta está vazia',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Frutiger',
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Adicione arquivos ou subpastas para começar',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Frutiger',
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          final isFolder = item.containsKey('id_subpasta');

                          return GestureDetector(
                            onTap: () {
                              if (isFolder) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubfolderFilesPage(
                                      subfolderId: item['id_subpasta'],
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 5.0,
                              ),
                              child: Row(
                                children: [
                                  isFolder
                                      ? Icon(Icons.folder,
                                          color: Colors.amber, size: 38)
                                      : Image.asset(
                                          _getFileIcon(item['nome'] ?? ''),
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
                                          item['nome'] ?? 'Item sem nome',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Frutiger',
                                            fontWeight: FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (!isFolder &&
                                            item['confidencial'] == true)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: IntrinsicWidth(
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
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
                                                        fontFamily: 'Frutiger',
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
                                    icon: Icon(Icons.more_vert_outlined,
                                        color: Color.fromRGBO(0, 114, 239, 1),
                                        size: 20),
                                    hoverColor: Colors.transparent,
                                    onPressed: () =>
                                        _showFolderOptions(context, item),
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
      ),
    );
  }
}
