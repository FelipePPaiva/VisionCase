import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import '../services/visualizar_arquivo_aws_service.dart';

class FileViewer extends StatefulWidget {
  final String s3FileName;
  final String originalFileName;
  final bool isConfidential;

  const FileViewer({
    required this.s3FileName,
    required this.originalFileName,
    this.isConfidential = false,
    Key? key,
  }) : super(key: key);

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  final AWSService awsService = AWSService();
  PDFViewController? _pdfViewController;
  bool _isLoading = true;
  String? _error;
  double _downloadProgress = 0;
  String? _extractedFilePath;
  String? _zipPath;
  bool _isPDF = false;
  int _totalPages = 0;
  int _currentPage = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _isPDF = widget.originalFileName.toLowerCase().endsWith('.pdf');
    if (_isPDF) {
      _secureScreen();
    }
    _loadUserName();
    _processFile();
  }

  Future<void> _secureScreen() async {
    try {
      if (Platform.isAndroid) {
        await ScreenProtector.preventScreenshotOn();
      }
    } catch (e) {}
  }

  Future<void> _processFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _downloadAndExtractFile();

      if (_extractedFilePath != null) {
        final file = File(_extractedFilePath!);
        if (await file.exists()) {
          if (_isPDF) {
            // Se for PDF, apenas atualiza o estado para mostrar o visualizador
            setState(() {
              _isLoading = false;
            });
          } else {
            // Se não for PDF, abre externamente
            final result = await OpenFile.open(_extractedFilePath!);

            if (result.type != ResultType.done) {
              setState(() {
                _error = 'Não foi possível abrir o arquivo: ${result.message}';
              });
            } else {
              Future.delayed(Duration(seconds: 10), () {
                _cleanupFiles();
                if (mounted) Navigator.of(context).pop();
              });
            }
          }
        } else {
          throw Exception('Arquivo extraído não encontrado');
        }
      }
    } catch (e, stack) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted && !_isPDF) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadAndExtractFile() async {
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    _zipPath =
        '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.zip';

    try {
      final presignedUrl =
          await awsService.generatePresignedUrl(widget.s3FileName);

      await dio.download(
        presignedUrl,
        _zipPath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      final bytes = await File(_zipPath!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.isEmpty) {
        throw Exception('Arquivo ZIP está vazio');
      }

      final file = archive.first;
      final sanitizedFileName =
          widget.originalFileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final extractedPath = '${tempDir.path}/$sanitizedFileName';

      await File(extractedPath).writeAsBytes(file.content as List<int>);

      // Remove o ZIP após extração
      await File(_zipPath!).delete();
      _zipPath = null;

      setState(() {
        _extractedFilePath = extractedPath;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cleanupFiles() async {
    if (_zipPath != null) {
      try {
        final zipFile = File(_zipPath!);
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
      } catch (e) {}
    }

    if (_extractedFilePath != null) {
      try {
        final extractedFile = File(_extractedFilePath!);
        if (await extractedFile.exists()) {
          await extractedFile.delete();
        }
      } catch (e) {}
    }
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nome = prefs.getString('nome');
      if (mounted) {
        setState(() {
          _userName = nome ?? 'Usuário';
        });
      }
    } catch (e) {}
  }

  Widget _buildPDFView() {
    return Column(
      children: [
        // Barra de ferramentas superior
        Container(
          padding: EdgeInsets.all(8),
          color: Color.fromRGBO(0, 114, 239, 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Página ${_currentPage + 1} de $_totalPages',
                  style: TextStyle(
                    color: Color.fromRGBO(0, 114, 239, 1),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Frutiger',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Visualizador PDF
        Expanded(
          child: Stack(
            children: [
              PDFView(
                filePath: _extractedFilePath!,
                enableSwipe: true,
                swipeHorizontal: true,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                defaultPage: _currentPage,
                onRender: (pages) {
                  setState(() {
                    _totalPages = pages!;
                  });
                },
                onError: (error) {
                  setState(() {
                    _error = error.toString();
                  });
                },
                onPageError: (page, error) {},
                onViewCreated: (PDFViewController pdfViewController) {
                  _pdfViewController = pdfViewController;
                },
                onPageChanged: (int? page, int? total) {
                  if (page != null) {
                    setState(() {
                      _currentPage = page;
                    });
                  }
                },
              ),

              // Marca d'água para arquivos confidenciais
              if (widget.isConfidential)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      alignment: Alignment.center,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Este arquivo foi compartilhado por',
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'Frutiger',
                                color: Colors.black.withOpacity(0.1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _userName, // Use a variável aqui
                              style: TextStyle(
                                fontSize: 24,
                                fontFamily: 'Frutiger',
                                color: Colors.black.withOpacity(0.1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Botões de navegação nas laterais
              if (_totalPages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Página Anterior
                    if (_currentPage > 0)
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                    // Botão Próxima Página
                    if (_currentPage < _totalPages - 1)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),

        // Barra inferior com miniaturas
        Container(
          height: 60,
          color: Colors.grey[200],
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _totalPages,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _pdfViewController?.setPage(index);
                },
                child: Container(
                  width: 40,
                  margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Color.fromRGBO(0, 114, 239, 1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Color.fromRGBO(0, 114, 239, 1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: _currentPage == index
                            ? Colors.white
                            : Color.fromRGBO(0, 114, 239, 1),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Frutiger',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Remove a sombra do AppBar
        elevation: 0,
        // Adiciona padding no topo
        toolbarHeight: 80,
        // Define cor de fundo
        backgroundColor: Colors.white,
        // Customiza a seta de voltar
        leading: Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 10.0),
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
        // Customiza o título
        title: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.originalFileName,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Frutiger',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        // Remove o botão de voltar padrão
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress,
                    color: Color.fromRGBO(0, 114, 239, 1),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Baixando arquivo: ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 16, fontFamily: 'Frutiger',),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red, fontFamily: 'Frutiger',),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _processFile,
                        child: Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _isPDF
                  ? _buildPDFView()
                  : Center(
                      child: CircularProgressIndicator(
                        color: Color.fromRGBO(0, 114, 239, 1),
                      ),
                    ),
    );
  }

  @override
  void dispose() {
    if (_isPDF) {
      try {
        ScreenProtector.preventScreenshotOff();
      } catch (e) {}
    } else {
      // Se for PDF, agenda a limpeza para quando o usuário sair
      Future.delayed(Duration(seconds: 10), () {
        _cleanupFiles();
      });
    }
    super.dispose();
  }
}
