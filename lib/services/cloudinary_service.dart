import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static CloudinaryPublic? get _cloudinary {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
    
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      debugPrint('Cloudinary Error: Cloud Name or Upload Preset is missing in .env');
      return null;
    }
    
    return CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  /// Uploads an image to Cloudinary and returns the URL.
  static Future<String?> uploadImage(XFile xFile) async {
    try {
      debugPrint('Cloudinary: Starting upload for ${xFile.name}...');
      
      final client = _cloudinary;
      if (client == null) return null;

      final bytes = await xFile.readAsBytes();
      
      // Using fromByteData as it's the most reliable across all platforms (Web/Android/iOS)
      final response = await client.uploadFile(
        CloudinaryFile.fromByteData(
          bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes),
          identifier: xFile.name,
          resourceType: CloudinaryResourceType.Image,
          folder: 'tutor_applications',
        ),
      );
      
      debugPrint('Cloudinary: Upload successful. URL: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary upload error details: $e');
      return null;
    }
  }
}
