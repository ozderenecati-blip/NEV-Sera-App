import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Firebase Storage üzerinde fiş görsellerini yöneten servis
class FisStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Fiş görselini yükler ve URL'sini döndürür
  /// [imageBytes]: Görsel byte array'i
  /// [fileName]: Dosya adı (opsiyonel)
  /// Returns: Yüklenen görselin URL'si
  Future<String?> uploadFisGorseli(Uint8List imageBytes, {String? fileName}) async {
    try {
      final String uniqueId = _uuid.v4();
      final String extension = fileName?.split('.').last ?? 'jpg';
      final String path = 'fisler/$uniqueId.$extension';
      
      final ref = _storage.ref().child(path);
      
      final metadata = SettableMetadata(
        contentType: 'image/$extension',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await ref.putData(imageBytes, metadata);
      final url = await ref.getDownloadURL();
      
      return url;
    } catch (e) {
      print('Fiş yükleme hatası: $e');
      return null;
    }
  }

  /// Fiş görselini siler
  Future<bool> deleteFisGorseli(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      print('Fiş silme hatası: $e');
      return false;
    }
  }

  /// Belirli bir tarih aralığındaki tüm fişleri listeler
  Future<List<String>> listFisler({String? prefix}) async {
    try {
      final ref = _storage.ref().child(prefix ?? 'fisler');
      final result = await ref.listAll();
      
      List<String> urls = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      print('Fiş listeleme hatası: $e');
      return [];
    }
  }
}
