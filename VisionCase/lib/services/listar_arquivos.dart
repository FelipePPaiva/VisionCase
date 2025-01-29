import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'download_service.dart';
import '../pages/visualizacao_arquivo_web.dart';
import '../pages/detalhes_pages.dart';

class FileListWidget extends StatefulWidget {
  final List<dynamic> arquivos;
  final List<bool> selectedFiles;
  final Function(int, bool?) onFileSelected;
  final Function(int)? onTap;

  const FileListWidget({
    Key? key,
    required this.arquivos,
    required this.selectedFiles,
    required this.onFileSelected,
    this.onTap,
  }) : super(key: key);

  @override
  _FileListWidgetState createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  final Set<int> favoritedFiles =
      {}; // Set para armazenar IDs de arquivos favoritados
  final DownloadService _downloadService = DownloadService();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initializeFavorites();
  }

  @override
  void dispose() {
    // Cancela qualquer operação pendente
    _disposed = true; // Adicione esta variável no início da classe
    super.dispose();
  }

  // Inicializa o estado favorito dos arquivos ao carregar a página
  void _initializeFavorites() async {
    for (var i = 0; i < widget.arquivos.length; i++) {
      final fileId = widget.arquivos[i]['id_arquivo'];
      if (fileId != null && fileId is String) {
        final isFavorited = await _checkIfFavorite(fileId);
        if (mounted) {
          // Adiciona verificação aqui
          setState(() {
            if (isFavorited) {
              favoritedFiles.add(i);
            }
          });
        }
      }
    }
  }

//metodo para abrir arquivos
  Future<void> _openFile(String zipPath, String originalName) async {
    try {
      // Verificar se o arquivo ZIP existe
      final File zipFile = File(zipPath);
      final bool exists = await zipFile.exists();

      if (!exists) {
        return;
      }

      final decompressedFile = await _downloadService.decompressZip(zipFile);

      // Verificar se o arquivo descompactado existe
      final bool decompressedExists = await decompressedFile.exists();

      final result = await OpenFile.open(decompressedFile.path);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Não foi possível abrir o arquivo. Erro: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Aguardar antes de limpar

      await Future.delayed(Duration(seconds: 6));

      // Limpar arquivo temporário

      await _downloadService.cleanupTempFile(decompressedFile);
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar arquivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função para verificar se o arquivo está favoritado
  Future<bool> _checkIfFavorite(String fileId) async {
    final url =
        'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/favorite/file/$fileId';

    try {
      // Recupera o token JWT do SharedPreferences
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString('token');

      if (token == null || token.isEmpty) {
        return false;
      }

      // Configuração do cabeçalho com o token
      final headers = {
        'Authorization': 'Bearer $token',
      };

      // Requisição GET para verificar estado favorito
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['isFavorite'] ??
            false; // Retorna o estado do favorito
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Alterna o estado de favorito do arquivo
  Future<void> _toggleFavorite(
      String fileId, bool isFavorited, int index) async {
    final url =
        'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/favorite-file/$fileId';
    final sharedPreferences = await SharedPreferences.getInstance();
    final token = sharedPreferences.getString('token');

    try {
      final headers = {'Authorization': 'Bearer $token'};
      final response = isFavorited
          ? await http.delete(Uri.parse(url), headers: headers)
          : await http.post(Uri.parse(url), headers: headers);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          // Adiciona verificação aqui
          setState(() {
            if (isFavorited) {
              widget.arquivos.removeAt(index);
            } else {
              favoritedFiles.add(index);
            }
          });
        }
      }
    } catch (e) {}
  }

  // Função para determinar a imagem com base na extensão do arquivo
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
    );
  }

  // Função para exibir o menu com opções ao clicar no ícone "..."
  void _showOptionsMenu(BuildContext context, dynamic arquivo, int index) {
    final originalName =
        arquivo['original_name'] ?? arquivo['nome'] ?? 'Sem nome';
    final extension =
        originalName.contains('.') ? originalName.split('.').last : 'unknown';
    final isFavorited = favoritedFiles.contains(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Fundo transparente
      isDismissible: true,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.3),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          _getImageForFile(extension),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              originalName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Frutiger',
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                    ListTile(
                      hoverColor: Colors.transparent,
                      leading: Icon(Icons.info_outline, size: 15),
                      title: Text(
                        'Detalhes',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Frutiger',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        final idFile = arquivo['id_arquivo'];
                        final isOfflineFile = arquivo['path'] !=
                            null; // Verifica se é um arquivo offline

                        if (isOfflineFile) {
                          // Usa o caminho do arquivo como fileId e marca como offline
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FileDetailsPage(
                                fileId: arquivo['path'],
                                isOffline: true,
                              ),
                            ),
                          );
                        } else if (idFile != null && idFile is String) {
                          // Lógica para arquivos online
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FileDetailsPage(
                                fileId: idFile,
                                isOffline: false,
                              ),
                            ),
                          );
                        } else {}
                      },
                    ),
                    ListTile(
                      hoverColor: Colors.transparent,
                      leading: Icon(
                        isFavorited ? Icons.star : Icons.star_border_outlined,
                        size: 15,
                        color: isFavorited ? Colors.blue : Colors.black,
                      ),
                      title: Text(
                        isFavorited ? 'Remover dos favoritos' : 'Favoritar',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Frutiger',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () async {
                        final fileId = arquivo['id_arquivo'];
                        if (fileId != null && fileId is String) {
                          await _toggleFavorite(fileId, isFavorited, index);
                          setState(() {
                            if (isFavorited) {
                              favoritedFiles.remove(index);
                            } else {
                              favoritedFiles.add(index);
                            }
                          });
                          Navigator.pop(context);
                        } else {}
                      },
                    ),
                    if (!(arquivo['confidencial'] ?? false))
                      ListTile(
                        hoverColor: Colors.transparent,
                        leading: Icon(
                          Icons.file_download_outlined,
                          size: 15,
                          color: Colors.black,
                        ),
                        title: Text(
                          'Baixar',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Frutiger',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onTap: (arquivo['confidencial'] == true)
                            ? null
                            : () async {
                                try {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Center(
                                          child: CircularProgressIndicator(
                                              color: Color.fromRGBO(
                                                  0, 114, 239, 1)));
                                    },
                                  );

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final token = prefs.getString('token');

                                  if (token == null) {
                                    throw Exception('Token não encontrado');
                                  }

                                  final fileId = arquivo['id_arquivo'];

                                  final response = await http.get(
                                    Uri.parse(
                                        'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/download/$fileId'),
                                    headers: {'Authorization': 'Bearer $token'},
                                  );

                                  if (response.statusCode != 200) {
                                    throw Exception(
                                        'Erro ao obter informações do arquivo');
                                  }

                                  final fileData = json.decode(response.body);
                                  final s3FileName = fileData['s3FileName'];
                                  final originalFileName = fileData['fileName'];

                                  final downloadedFile =
                                      await _downloadService.downloadFile(
                                          s3FileName, originalFileName);

                                  Navigator.pop(
                                      context); // fecha o diálogo de progresso
                                  Navigator.pop(context); // fecha o modal

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Download concluído com sucesso!'),
                                      backgroundColor:
                                          Color.fromRGBO(0, 114, 239, 1),
                                    ),
                                  );
                                } catch (e, stackTrace) {
                                  if (Navigator.canPop(context))
                                    Navigator.pop(context);
                                  if (Navigator.canPop(context))
                                    Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro no download: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                      ),
                    if (!(arquivo['confidencial'] ?? false))
                      ListTile(
                        hoverColor: Colors.transparent,
                        leading: Icon(Icons.ios_share_outlined, size: 15),
                        title: Text(
                          'Compartilhar Arquivo',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Frutiger',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onTap: arquivo['confidencial'] ??
                                false // Verifica se o arquivo é confidencial
                            ? null // Não permite compartilhar se for confidencial
                            : () async {
                                final fileId = arquivo['id_arquivo'];
                                if (fileId != null && fileId is String) {
                                  try {
                                    final sharedPreferences =
                                        await SharedPreferences.getInstance();
                                    final token =
                                        sharedPreferences.getString('token');

                                    if (token == null || token.isEmpty) {
                                      return;
                                    }

                                    // URL da API de compartilhamento com o id_file como parâmetro
                                    final url = Uri.parse(
                                        'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/share/$fileId');

                                    final response = await http.get(
                                      url,
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Content-Type': 'application/json',
                                      },
                                    );

                                    if (response.statusCode == 200 ||
                                        response.statusCode == 201) {
                                      // Decodificando a resposta
                                      final responseData =
                                          json.decode(response.body);
                                      responseData.forEach((key, value) {});

                                      // Acessando e compartilhando a URL gerada
                                      final shareUrl = responseData['url'];
                                      if (shareUrl != null &&
                                          shareUrl is String) {
                                        Share.share(shareUrl);
                                      } else {}
                                    } else {}
                                  } catch (e) {}
                                } else {}
                                Navigator.pop(context);
                              },
                        enabled: !(arquivo['confidencial'] ??
                            false), // Desabilita o botão se o arquivo for confidencial
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_disposed) return Container();
    return ListView.separated(
      itemCount: widget.arquivos.length,
      shrinkWrap: true,
      primary: false,
      physics: NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade300,
        thickness: 1,
        indent: 20, // Espaço à esquerda
        endIndent: 40,
      ),
      itemBuilder: (context, index) {
        final arquivo = widget.arquivos[index];
        final originalName = arquivo['original_name'] ??
            arquivo['name'] ??
            arquivo['nome'] ??
            'Sem nome';

        if (originalName == 'Arquivo 1') {
          return Container();
        }

        final extension = originalName.contains('.')
            ? originalName.split('.').last
            : 'unknown';

        final criadoEm = arquivo['criado_em'] != null
            ? DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(arquivo['criado_em']))
            : 'Data desconhecida';
        final isConfidencial = arquivo['confidencial'] ?? false;

        return ListTile(
          leading: _getImageForFile(extension),
          hoverColor: Colors.transparent,
          title: Text(
            originalName,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Frutiger',
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Criado em: $criadoEm',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'Frutiger',)),
              if (isConfidencial)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: IntrinsicWidth(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(220, 227, 233, 1),
                        borderRadius: BorderRadius.circular(10.0),
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
                              fontWeight: FontWeight.w400,
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
          trailing: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Color.fromRGBO(0, 114, 239, 1),
              size: 20,
            ),
            hoverColor: Colors.transparent,
            onPressed: () {
              _showOptionsMenu(context, arquivo, index);
            },
          ),
          onTap: () async {
            final fileId = arquivo['id_arquivo'];
            if (fileId != null && fileId is String) {
              try {
                // Obter o token do SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');

                if (token == null) {
                  throw Exception('Token não encontrado');
                }

                final response = await http.get(
                  Uri.parse(
                      'https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/download/$fileId'),
                  headers: {'Authorization': 'Bearer $token'},
                );

                if (response.statusCode == 200) {
                  final fileData = json.decode(response.body);
                  final s3FileName = fileData['s3FileName'];
                  final originalName = fileData['fileName'];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FileViewer(
                              s3FileName: s3FileName,
                              originalFileName: originalName,
                              isConfidential: arquivo['confidencial'] ?? false,
                            )),
                  );
                } else {
                  throw Exception('Erro ao obter informações do arquivo');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao visualizar arquivo'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
