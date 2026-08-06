import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityMediaUploader {
  static final _storage = Supabase.instance.client.storage.from('community-media');

  static String _sanitize(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w.\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static Future<String?> uploadImage(Uint8List bytes, String fileName, String userId) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_${_sanitize(fileName)}';
    await _storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    return _storage.getPublicUrl(path);
  }

  static Future<String?> uploadVideo(Uint8List bytes, String fileName, String userId) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_${_sanitize(fileName)}';
    await _storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'video/mp4'),
    );
    return _storage.getPublicUrl(path);
  }
}
