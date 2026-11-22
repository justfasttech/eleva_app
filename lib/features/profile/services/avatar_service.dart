import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Escolha, otimização e upload da foto de perfil.
///
/// A foto é recortada em quadrado, reduzida para [size]×[size] e salva como
/// JPEG com qualidade [quality] — normalmente fica entre 30 e 80 KB.
/// Cada usuário tem um único arquivo (`avatars/<uid>/avatar.jpg`), que é
/// sobrescrito a cada troca, então o bucket não acumula fotos antigas.
class AvatarService {
  static const String bucket = 'avatars';
  static const int size = 512;
  static const int quality = 80;

  static SupabaseClient get _client => Supabase.instance.client;

  static String _path(String userId) => '$userId/avatar.jpg';

  /// Abre a galeria ou a câmera. A primeira redução (1600 px) já acontece
  /// no próprio picker, o que deixa a decodificação seguinte bem mais leve.
  static Future<XFile?> pick(ImageSource source) {
    return ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 92,
      preferredCameraDevice: CameraDevice.front,
      requestFullMetadata: false,
    );
  }

  /// Recorta, redimensiona e comprime. Roda em outro isolate no mobile.
  static Future<Uint8List> optimize(Uint8List bytes) => compute(_process, bytes);

  static Uint8List _process(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Formato de imagem não suportado');
    }
    // Aplica a rotação do EXIF (fotos de câmera) antes de recortar.
    final oriented = img.bakeOrientation(decoded);

    final side = math.min(oriented.width, oriented.height);
    final square = img.copyCrop(
      oriented,
      x: (oriented.width - side) ~/ 2,
      y: (oriented.height - side) ~/ 2,
      width: side,
      height: side,
    );

    final resized = side > size
        ? img.copyResize(
            square,
            width: size,
            height: size,
            interpolation: img.Interpolation.average,
          )
        : square;

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  /// Envia a foto otimizada e grava a URL em `profiles.avatar_url`.
  static Future<String> upload(Uint8List jpg) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Usuário não autenticado');

    final storage = _client.storage.from(bucket);
    final path = _path(userId);
    await storage.uploadBinary(
      path,
      jpg,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
        cacheControl: '86400',
      ),
    );

    // O parâmetro de versão evita que o app mostre a foto antiga em cache.
    final url =
        '${storage.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    return url;
  }

  /// Fluxo completo: escolher → otimizar → enviar.
  /// Retorna `null` se o usuário cancelar a escolha.
  static Future<String?> pickAndUpload(ImageSource source) async {
    final file = await pick(source);
    if (file == null) return null;
    final original = await file.readAsBytes();
    final optimized = await optimize(original);
    debugPrint(
      'Avatar: ${(original.lengthInBytes / 1024).toStringAsFixed(0)} KB → '
      '${(optimized.lengthInBytes / 1024).toStringAsFixed(0)} KB',
    );
    return upload(optimized);
  }

  static Future<void> remove() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.storage.from(bucket).remove([_path(userId)]);
    await _client.from('profiles').update({'avatar_url': null}).eq('id', userId);
  }
}
