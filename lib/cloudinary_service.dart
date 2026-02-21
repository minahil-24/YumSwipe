import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class CloudinaryService {
  static const String cloudName = 'dhwt4pwb7';
  static const String uploadPreset =
      'preset-for-file-upload'; // create from Cloudinary Media Library settings

  static Future<String?> uploadImage({
    File? file,
    Uint8List? bytes,
    required String fileName,
  }) async {
    try {
      var uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset;

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType.parse(
              lookupMimeType(file.path) ?? 'image/jpeg',
            ),
          ),
        );
      } else if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        throw Exception("No file or byte data provided");
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data['secure_url'];
      } else {
        throw Exception(
          "Cloudinary upload failed with status ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Cloudinary upload error: $e");
      return null;
    }
  }
}
