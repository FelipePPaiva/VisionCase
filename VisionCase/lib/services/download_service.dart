import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'dart:io';
import 'dart:convert';

class DownloadService {
  final String accessKey = dotenv.env['AWS_ACCESS_KEY_ID']!;
  final String secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY']!;
  final String region = dotenv.env['AWS_REGION']!;
  final String bucketName = dotenv.env['AWS_BUCKET_NAME']!;

  // Método para baixar e mover o arquivo ZIP
  Future<File> downloadFile(String s3FileName, String originalFileName) async {
    try {
      // Construir a URL do S3
      var s3Url =
          Uri.parse('https://$bucketName.s3.$region.amazonaws.com/$s3FileName');

      String method = 'GET';
      String service = 's3';
      DateTime now = DateTime.now().toUtc();
      String dateTime = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
      String date = DateFormat('yyyyMMdd').format(now);

      // Hash do payload vazio para GET requests
      String payloadHash =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      // Montar cabeçalhos canônicos
      String canonicalHeaders = 'host:$bucketName.s3.$region.amazonaws.com\n' +
          'x-amz-content-sha256:$payloadHash\n' +
          'x-amz-date:$dateTime\n';

      String signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

      // Criar requisição canônica
      String canonicalRequest =
          '$method\n/$s3FileName\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

      // Criar string para assinar
      String stringToSign =
          'AWS4-HMAC-SHA256\n$dateTime\n$date/$region/$service/aws4_request\n' +
              sha256.convert(utf8.encode(canonicalRequest)).toString();

      // Gerar assinatura
      String signature =
          _generateSignature(secretKey, date, region, service, stringToSign);

      // Montar cabeçalhos da requisição
      var headers = {
        'Authorization':
            'AWS4-HMAC-SHA256 Credential=$accessKey/$date/$region/$service/aws4_request, SignedHeaders=$signedHeaders, Signature=$signature',
        'x-amz-content-sha256': payloadHash,
        'x-amz-date': dateTime,
      };

      // Fazer a requisição GET
      final response = await http.get(s3Url, headers: headers);

      if (response.statusCode == 200) {
        // Obter o diretório de downloads do aplicativo
        Directory? downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          throw Exception('Não foi possível acessar o diretório de downloads');
        }

        // Salva internamente com .zip mas mantém referência ao nome original
        String internalFileName = '${originalFileName}.zip';
        File zipFile = File('${downloadsDir.path}/$internalFileName');
        await zipFile.writeAsBytes(response.bodyBytes);

        return zipFile;
      } else {
        throw Exception('Falha ao baixar arquivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro durante o download: $e');
    }
  }

  // Método para descompactar o arquivo ZIP
  Future<File> decompressZip(File zipFile) async {
    try {
      List<int> bytes = await zipFile.readAsBytes();

      Archive archive = ZipDecoder().decodeBytes(bytes);

      if (archive.isEmpty) {
        throw Exception('Arquivo ZIP está vazio');
      }

      ArchiveFile archiveFile = archive.first;

      Directory tempDir = await getTemporaryDirectory();

      String outputPath = '${tempDir.path}/${archiveFile.name}';

      File outputFile = File(outputPath);

      await outputFile.writeAsBytes(archiveFile.content as List<int>);

      return outputFile;
    } catch (e, stackTrace) {
      throw Exception('Erro ao descompactar arquivo: $e');
    }
  }

  // Método para limpar arquivo temporário
  Future<void> cleanupTempFile(File tempFile) async {
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      // print('Erro ao deletar arquivo temporário: $e');
    }
  }

  String _generateSignature(String secretKey, String date, String region,
      String service, String stringToSign) {
    var kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), date);
    var kRegion = _hmacSha256(kDate, region);
    var kService = _hmacSha256(kRegion, service);
    var kSigning = _hmacSha256(kService, 'aws4_request');
    return _hmacSha256(kSigning, stringToSign)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  List<int> _hmacSha256(List<int> key, String message) {
    var hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(message)).bytes;
  }
}
