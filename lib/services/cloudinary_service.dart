import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/config/env.dart';

class CloudinaryService {
  static const String cloudName = Environment.cloudinaryCloudName;
  static const String uploadPreset = Environment.cloudinaryUploadPreset;
  
  Future<String> uploadImage(XFile imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      
      final request = http.MultipartRequest('POST', url);
      
      request.fields['upload_preset'] = uploadPreset;
      
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['secure_url'];
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading image: $e');
      }
      throw Exception('Error uploading image: $e');
    }
  }
}
