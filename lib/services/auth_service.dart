import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Kullanıcı kimlik doğrulama ve yönetimi servisi
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference get _usersRef => _db.collection('users');

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Varsayılan kullanıcıları oluştur (ilk kurulumda)
  Future<void> ensureDefaultUsers() async {
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.docs.isEmpty) {
        // Varsayılan admin kullanıcıları
        final defaultUsers = [
          AppUser(
            kullaniciAdi: 'necati',
            sifre: 'nev2026',
            adSoyad: 'Necati Özdere',
            rol: UserRole.admin,
          ),
          AppUser(
            kullaniciAdi: 'mert',
            sifre: 'nev2026',
            adSoyad: 'Mert Anter',
            rol: UserRole.admin,
          ),
          AppUser(
            kullaniciAdi: 'ibrahim',
            sifre: 'nev2026',
            adSoyad: 'İbrahim Elibaş',
            rol: UserRole.admin,
          ),
          AppUser(
            kullaniciAdi: 'operasyon',
            sifre: 'op2026',
            adSoyad: 'Operasyon Yöneticisi',
            rol: UserRole.operasyonYoneticisi,
          ),
          AppUser(
            kullaniciAdi: 'calisan1',
            sifre: 'cal2026',
            adSoyad: 'Çalışan 1',
            rol: UserRole.calisan,
          ),
        ];

        for (var user in defaultUsers) {
          await _usersRef.add(user.toMap());
        }
        debugPrint('Varsayılan kullanıcılar oluşturuldu');
      }
    } catch (e) {
      debugPrint('ensureDefaultUsers error: $e');
    }
  }

  /// Giriş yap
  Future<AppUser?> login(String kullaniciAdi, String sifre) async {
    try {
      final snapshot = await _usersRef
          .where('kullanici_adi', isEqualTo: kullaniciAdi.toLowerCase().trim())
          .where('sifre', isEqualTo: sifre)
          .where('aktif', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        _currentUser = AppUser.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );

        // Son giriş zamanını güncelle
        await doc.reference.update({
          'son_giris': DateTime.now().toIso8601String(),
        });

        return _currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('login error: $e');
      return null;
    }
  }

  /// Çıkış yap
  void logout() {
    _currentUser = null;
  }

  /// Tüm kullanıcıları getir
  Future<List<AppUser>> getUsers() async {
    try {
      final snapshot = await _usersRef.get();
      return snapshot.docs.map((doc) {
        return AppUser.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } catch (e) {
      debugPrint('getUsers error: $e');
      return [];
    }
  }

  /// Aktif kullanıcıları getir (görev atama için)
  Future<List<AppUser>> getActiveUsers() async {
    final users = await getUsers();
    return users.where((u) => u.aktif).toList();
  }

  /// Çalışanları getir (görev atama için)
  Future<List<AppUser>> getCalisanlar() async {
    final users = await getActiveUsers();
    return users.where((u) => u.rol == UserRole.calisan || u.rol == UserRole.operasyonYoneticisi).toList();
  }

  /// Yeni kullanıcı ekle (sadece admin)
  Future<bool> addUser(AppUser user) async {
    if (_currentUser?.canManageUsers != true) return false;
    
    try {
      // Kullanıcı adı benzersiz mi kontrol et
      final existing = await _usersRef
          .where('kullanici_adi', isEqualTo: user.kullaniciAdi.toLowerCase().trim())
          .get();
      
      if (existing.docs.isNotEmpty) return false;

      await _usersRef.add(user.toMap());
      return true;
    } catch (e) {
      debugPrint('addUser error: $e');
      return false;
    }
  }

  /// Kullanıcı güncelle (şifre değiştirme, rol değiştirme vb.)
  Future<bool> updateUser(AppUser user) async {
    if (_currentUser?.canManageUsers != true) return false;
    if (user.id == null) return false;
    
    try {
      await _usersRef.doc(user.id).update(user.toMap());
      return true;
    } catch (e) {
      debugPrint('updateUser error: $e');
      return false;
    }
  }

  /// Kullanıcıyı deaktif et
  Future<bool> deactivateUser(String userId) async {
    if (_currentUser?.canManageUsers != true) return false;
    
    try {
      await _usersRef.doc(userId).update({'aktif': false});
      return true;
    } catch (e) {
      debugPrint('deactivateUser error: $e');
      return false;
    }
  }

  /// Şifre değiştir (admin veya kendi şifresi)
  Future<bool> changePassword(String userId, String newPassword) async {
    // Admin her şifreyi değiştirebilir, kullanıcı sadece kendisini
    if (_currentUser?.canManageUsers != true && _currentUser?.id != userId) {
      return false;
    }
    
    try {
      await _usersRef.doc(userId).update({'sifre': newPassword});
      
      // Kendi şifresi ise currentUser'ı güncelle
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser!.copyWith(sifre: newPassword);
      }
      return true;
    } catch (e) {
      debugPrint('changePassword error: $e');
      return false;
    }
  }
}
