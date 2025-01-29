import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class FileDetailsPage extends StatelessWidget {
  final String fileId;
  final bool isOffline;

  const FileDetailsPage({
    Key? key, 
    required this.fileId,
    this.isOffline = false,
  }) : super(key: key);

  Future<Map<String, dynamic>> fetchFileDetails() async {
    if (isOffline) {
      try {
        final file = File(fileId);
        final FileSystemEntity fileInfo = file;
        final FileStat stat = await fileInfo.stat();
        
        // Extrair o nome do arquivo do caminho
        final String fileName = fileId.split('/').last.replaceAll('.zip', '');
        // Extrair o caminho sem o nome do arquivo
        final String filePath = fileId.replaceAll(fileName, '');

        return {
          'original_name': fileName,
          'size': stat.size,
          'lastModified': stat.modified.toIso8601String(),
          'caminho': 'VisionCase Local',
          'confidencial': false, // arquivos offline não são confidenciais
        };
      } catch (e) {
        throw Exception('Erro ao carregar detalhes do arquivo offline: $e');
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await http.get(
        Uri.parse('https://88gexv4azf.execute-api.sa-east-1.amazonaws.com/file-details/$fileId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['details'];
      } else {
        throw Exception('Falha ao carregar os dados');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 24.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Color.fromRGBO(0, 114, 239, 1),
              size: 16,
            ),
            hoverColor: Colors.transparent,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchFileDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color.fromRGBO(0, 114, 239, 1),));
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Nenhum dado encontrado'));
          } else {
            final fileDetails = snapshot.data!;

            // Formatação de data
            String formattedDate = 'Data desconhecida';
            if (fileDetails['lastModified'] != null) {
              final DateTime lastModified = DateTime.parse(fileDetails['lastModified']);
              formattedDate = "${lastModified.day.toString().padLeft(2, '0')}/${lastModified.month.toString().padLeft(2, '0')}/${lastModified.year}";
            }

            // Formatação de tamanho
            double fileSize = 0;
            if (fileDetails['size'] != null) {
              fileSize = fileDetails['size'] / (1024 * 1024); // Converte para MB
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de Confidencialidade
                  if (fileDetails['confidencial'] == true) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(220, 227, 233, 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 12,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Confidencial',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Frutiger',
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  Text(
                    'NOME DO ARQUIVO',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      fontFamily: 'Frutiger',
                      color: Color.fromRGBO(96, 106, 118, 1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    fileDetails['original_name'] ?? 'Nome não disponível',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Frutiger',
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'CRIADO EM',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Frutiger',
                      fontSize: 12,
                      color: Color.fromRGBO(96, 106, 118, 1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Frutiger',
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'TAMANHO',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Frutiger',
                      fontSize: 12,
                      color: Color.fromRGBO(96, 106, 118, 1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${fileSize.toStringAsFixed(2)} MB',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Frutiger',
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'LOCAL',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      fontFamily: 'Frutiger',
                      color: Color.fromRGBO(96, 106, 118, 1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    fileDetails['caminho'] ?? 'Local não disponível',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Frutiger',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}