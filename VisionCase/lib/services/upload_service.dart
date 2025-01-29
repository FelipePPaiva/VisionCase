import 'package:diacritic/diacritic.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class UploadService {
  final String accessKey = dotenv.env['AWS_ACCESS_KEY_ID']!;
  final String secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY']!;
  final String region = dotenv.env['AWS_REGION']!;
  final String bucketName = dotenv.env['AWS_BUCKET_NAME']!;

  Future<void> uploadFile(
    File file, {
    int? folderId,
    int? subfolderId,
    bool isConfidential = false,
    Function(double)? onProgress,
  }) async {
    try {
      // Notify initial progress
      onProgress?.call(0.1);

      // Compressing file to ZIP
      File zipFile = await _compressToZip(file);
      onProgress?.call(0.3);

      String rawFileName = zipFile.uri.pathSegments.last;
      String sanitizedFileName = sanitizeFileName(rawFileName);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}-$sanitizedFileName';

      var s3Url =
          Uri.parse('https://$bucketName.s3.$region.amazonaws.com/$fileName');

      String method = 'PUT';
      String service = 's3';
      DateTime now = DateTime.now().toUtc();
      String dateTime = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
      String date = DateFormat('yyyyMMdd').format(now);

      String payloadHash =
          sha256.convert(await zipFile.readAsBytes()).toString();
      onProgress?.call(0.4);

      String canonicalHeaders = 'host:$bucketName.s3.$region.amazonaws.com\n' +
          'x-amz-content-sha256:$payloadHash\n' +
          'x-amz-date:$dateTime\n';

      String signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

      String canonicalRequest =
          '$method\n/$fileName\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

      String stringToSign =
          'AWS4-HMAC-SHA256\n$dateTime\n$date/$region/$service/aws4_request\n' +
              sha256.convert(utf8.encode(canonicalRequest)).toString();

      String signature =
          _generateSignature(secretKey, date, region, service, stringToSign);
      onProgress?.call(0.5);

      var headers = {
        'Authorization':
            'AWS4-HMAC-SHA256 Credential=$accessKey/$date/$region/$service/aws4_request, SignedHeaders=$signedHeaders, Signature=$signature',
        'x-amz-content-sha256': payloadHash,
        'x-amz-date': dateTime,
      };

      var request = http.Request(method, s3Url);
      request.headers.addAll(headers);

      // Read file in chunks to track upload progress
      final fileStream = http.ByteStream(Stream.castFrom(zipFile.openRead()));
      final fileLength = await zipFile.length();

      request.bodyBytes = await zipFile.readAsBytes();
      onProgress?.call(0.6);

      var response = await request.send();

      // Track streaming progress
      int bytesUploaded = 0;
      await for (var chunk in response.stream) {
        bytesUploaded += chunk.length;
        final progress = 0.6 + (0.3 * (bytesUploaded / fileLength));
        onProgress?.call(progress);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (folderId != null || subfolderId != null) {
          await sendFileDataToBackend(
            originalFileName: file.uri.pathSegments.last,
            s3FileName: fileName,
            idFolder: folderId,
            idSubfolder: subfolderId,
            isConfidential: isConfidential,
          );
        }
        onProgress?.call(1.0);
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Rest of your existing methods remain the same
  String sanitizeFileName(String fileName) {
    String decoded = Uri.decodeComponent(fileName);
    String sanitized = removeDiacritics(decoded);
    sanitized =
        sanitized.replaceAll('%20', '_').replaceAll(RegExp(r'\s+'), '_');
    sanitized = sanitized.replaceAll('.', '-');
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\-]'), '');
    sanitized = sanitized.toLowerCase();
    sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
    return sanitized;
  }

  Future<File> _compressToZip(File file) async {
    List<int> bytes = await file.readAsBytes();
    Archive archive = Archive();
    archive
        .addFile(ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes));

    List<int>? zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Erro ao compactar o arquivo em ZIP');
    }

    Directory appDocDir = await getTemporaryDirectory();
    String originalFileName = path.basenameWithoutExtension(file.uri.path);
    String sanitizedFileName = sanitizeFileName(originalFileName);
    String zipFileName = '$sanitizedFileName.zip';
    String zipFilePath = '${appDocDir.path}/$zipFileName';
    File zipFile = File(zipFilePath)..writeAsBytesSync(zipBytes);

    return zipFile;
  }

  Future<void> sendFileDataToBackend({
    required String originalFileName,
    required String s3FileName,
    int? idFolder,
    int? idSubfolder,
    required bool isConfidential,
  }) async {
    const String backendUrl =
        'https://x3ukfy0jb0.execute-api.sa-east-1.amazonaws.com/upload';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final Map<String, dynamic> body = {
      "originalFileName": originalFileName,
      "s3FileName": s3FileName,
      "id_folder": idFolder,
      "id_subfolder": idSubfolder,
      "is_confidential": isConfidential,
    };

    try {
      var headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send file data to backend');
      }
    } catch (e) {
      throw Exception('Error sending file data to backend: $e');
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







// import 'package:diacritic/diacritic.dart';
// import 'package:http/http.dart' as http;
// import 'package:crypto/crypto.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:archive/archive.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:io';
// import 'dart:convert';

// class UploadService {
//   final String accessKey = dotenv.env['AWS_ACCESS_KEY_ID']!;
//   final String secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY']!;
//   final String region = dotenv.env['AWS_REGION']!;
//   final String bucketName = dotenv.env['AWS_BUCKET_NAME']!;

//   Future<void> uploadFile(File file, {int? folderId, int? subfolderId, bool isConfidential = false}) async {
//     try {
//       // Compactando o arquivo em formato ZIP
//       File zipFile = await _compressToZip(file);

//       // Gerando nome sanitizado para o arquivo no S3
//       String rawFileName = zipFile.uri.pathSegments.last;
//       String sanitizedFileName = sanitizeFileName(rawFileName);
//       String fileName = '${DateTime.now().millisecondsSinceEpoch}-$sanitizedFileName'; // Cria o nome do arquivo // Deve mostrar o nome corretamente sanitizado.

//       var s3Url = Uri.parse('https://$bucketName.s3.$region.amazonaws.com/$fileName');

//       String method = 'PUT';
//       String service = 's3';
//       DateTime now = DateTime.now().toUtc();
//       String dateTime = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
//       String date = DateFormat('yyyyMMdd').format(now);

//       String payloadHash = sha256.convert(await zipFile.readAsBytes()).toString();

//       String canonicalHeaders =
//           'host:$bucketName.s3.$region.amazonaws.com\n' +
//           'x-amz-content-sha256:$payloadHash\n' +
//           'x-amz-date:$dateTime\n';

//       String signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

//       String canonicalRequest =
//           '$method\n/$fileName\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

//       String stringToSign =
//           'AWS4-HMAC-SHA256\n$dateTime\n$date/$region/$service/aws4_request\n' +
//           sha256.convert(utf8.encode(canonicalRequest)).toString();

//       String signature = _generateSignature(secretKey, date, region, service, stringToSign);

//       var headers = {
//         'Authorization':
//             'AWS4-HMAC-SHA256 Credential=$accessKey/$date/$region/$service/aws4_request, SignedHeaders=$signedHeaders, Signature=$signature',
//         'x-amz-content-sha256': payloadHash,
//         'x-amz-date': dateTime,
//       };

//       var request = http.Request(method, s3Url);
//       request.headers.addAll(headers);
//       request.bodyBytes = await zipFile.readAsBytes();

//       var response = await request.send();

//        if (response.statusCode == 200 || response.statusCode == 201) {
  
//       if (folderId != null || subfolderId != null) {
//        await sendFileDataToBackend(
//   originalFileName: file.uri.pathSegments.last,
//   s3FileName: fileName,
//   idFolder: folderId,
//   idSubfolder: subfolderId,
//   isConfidential: isConfidential,
// );
//       }
//     } else {
   
//     }
//   } catch (e) {
 
//   }
//   }

// String sanitizeFileName(String fileName) {
//   // Primeiro decodifica qualquer codificação URL que possa existir
//   String decoded = Uri.decodeComponent(fileName);
  
//   // Remove acentos
//   String sanitized = removeDiacritics(decoded);
  
//   // Substitui %20 ou qualquer espaço por underscore
//   sanitized = sanitized
//     .replaceAll('%20', '_')
//     .replaceAll(RegExp(r'\s+'), '_');
  
//   // Substitui ponto por hífen
//   sanitized = sanitized.replaceAll('.', '-');
  
//   // Remove caracteres especiais, mantendo apenas:
//   // - letras (a-z, A-Z)
//   // - números (0-9)
//   // - underscore (_)
//   // - hífen (-)
//   sanitized = sanitized.replaceAll(RegExp(r'[^\w\-]'), '');
  
//   // Converte para lowercase
//   sanitized = sanitized.toLowerCase();
  
//   // Remove underscores múltiplos consecutivos
//   sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
  
//   return sanitized;
// }

// Future<File> _compressToZip(File file) async {
//   List<int> bytes = await file.readAsBytes();
//   Archive archive = Archive();
//   archive.addFile(ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes));

//   List<int>? zipBytes = ZipEncoder().encode(archive);
//   if (zipBytes == null) {
//     throw Exception('Erro ao compactar o arquivo em ZIP');
//   }

//   Directory appDocDir = await getTemporaryDirectory();

//   // Sanitiza o nome do arquivo original
//   String originalFileName = path.basenameWithoutExtension(file.uri.path);
//   String sanitizedFileName = sanitizeFileName(originalFileName);

//   // Define o nome do arquivo ZIP
//   String zipFileName = '$sanitizedFileName.zip';

//   String zipFilePath = '${appDocDir.path}/$zipFileName';
//   File zipFile = File(zipFilePath)..writeAsBytesSync(zipBytes);

//   return zipFile;
// }

//   Future<void> sendFileDataToBackend({
//     required String originalFileName,
//     required String s3FileName,
//     int? idFolder,
//     int? idSubfolder,
//     required bool isConfidential,
//   }) async {
//     const String backendUrl = 'https://x3ukfy0jb0.execute-api.sa-east-1.amazonaws.com/upload';

//     // Obtendo o token JWT
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');

//     // Definindo o corpo da requisição
//     final Map<String, dynamic> body = {
//       "originalFileName": originalFileName,
//       "s3FileName": s3FileName,
//       "id_folder": idFolder,
//       "id_subfolder": idSubfolder,
//       "is_confidential": isConfidential,
//     };

//     try {
//       var headers = {
//         'Content-Type': 'application/json',
//       };

//       // Adicionando o JWT ao cabeçalho Authorization
//       if (token != null) {
//         headers['Authorization'] = 'Bearer $token';
//       }

//       // Enviando a requisição para o backend
//       final response = await http.post(
//         Uri.parse(backendUrl),
//         headers: headers,
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
    
//       } else {
    
//       }
//     } catch (e) {
   
//     }
//   }

//   String _generateSignature(String secretKey, String date, String region, String service, String stringToSign) {
//     var kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), date);
//     var kRegion = _hmacSha256(kDate, region);
//     var kService = _hmacSha256(kRegion, service);
//     var kSigning = _hmacSha256(kService, 'aws4_request');
//     return _hmacSha256(kSigning, stringToSign)
//         .map((b) => b.toRadixString(16).padLeft(2, '0')) // Convert each byte to a hex string
//         .join(); // Join all hex strings together
//   }

//   List<int> _hmacSha256(List<int> key, String message) {
//     var hmac = Hmac(sha256, key);
//     return hmac.convert(utf8.encode(message)).bytes;
//   }
// }