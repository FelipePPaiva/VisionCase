import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AWSService {
  final String accessKey = dotenv.env['AWS_ACCESS_KEY_ID']!;
  final String secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY']!;
  final String region = dotenv.env['AWS_REGION']!;
  final String bucketName = dotenv.env['AWS_BUCKET_NAME']!;

  Future<String> generatePresignedUrl(String s3FileName, {Duration expiration = const Duration(minutes: 60)}) async {
    DateTime now = DateTime.now().toUtc();
    String dateStamp = DateFormat('yyyyMMdd').format(now);
    String amzDateTime = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
    
    int expiresIn = expiration.inSeconds;
    
    Map<String, String> queryParams = {
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': '$accessKey/$dateStamp/$region/s3/aws4_request',
      'X-Amz-Date': amzDateTime,
      'X-Amz-Expires': expiresIn.toString(),
      'X-Amz-SignedHeaders': 'host'
    };

    String canonicalRequest = _buildCanonicalRequest(s3FileName, queryParams);
    String stringToSign = _buildStringToSign(canonicalRequest, amzDateTime, dateStamp);
    String signature = _calculateSignature(stringToSign, dateStamp);
    
    queryParams['X-Amz-Signature'] = signature;

    String queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://$bucketName.s3.$region.amazonaws.com/$s3FileName?$queryString';
  }

  String _buildCanonicalRequest(String s3FileName, Map<String, String> queryParams) {
  // Corrigindo o método sorted para sort
  var sortedEntries = queryParams.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  String canonicalQueryString = sortedEntries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  return 'GET\n/$s3FileName\n$canonicalQueryString\nhost:$bucketName.s3.$region.amazonaws.com\n\nhost\nUNSIGNED-PAYLOAD';
}

  String _buildStringToSign(String canonicalRequest, String amzDateTime, String dateStamp) {
    String hashedRequest = sha256.convert(utf8.encode(canonicalRequest)).toString();
    return 'AWS4-HMAC-SHA256\n$amzDateTime\n$dateStamp/$region/s3/aws4_request\n$hashedRequest';
  }

  String _calculateSignature(String stringToSign, String dateStamp) {
    var kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), dateStamp);
    var kRegion = _hmacSha256(kDate, region);
    var kService = _hmacSha256(kRegion, 's3');
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