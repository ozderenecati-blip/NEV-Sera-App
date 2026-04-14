import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole? get currentRole => _currentUser?.rol;

  // Yetki kontrolleri
  bool get canAccessFinans => _currentUser?.canAccessFinans ?? false;
  bool get canAccessOperasyon => _currentUser?.canAccessOperasyon ?? false;
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;
  bool get canWriteOperasyon => _currentUser?.canWriteOperasyon ?? false;
  bool get canAssignTask => _currentUser?.canAssignTask ?? false;
  bool get canVerifyDailyReport => _currentUser?.canVerifyDailyReport ?? false;

  /// Uygulama başlangıcında varsayılan kullanıcıları kontrol et
  Future<void> initialize() async {
    await _authService.ensureDefaultUsers();
    
    // SharedPreferences'tan oturum kontrolü
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('current_user_id');
    final savedUsername = prefs.getString('current_username');
    
    if (savedUserId != null && savedUsername != null) {
      // Oturum kayıtlı, kullanıcıyı yükle
      final users = await _authService.getUsers();
      try {
        _currentUser = users.firstWhere(
          (u) => u.id == savedUserId && u.aktif,
        );
        _authService.login(_currentUser!.kullaniciAdi, _currentUser!.sifre);
      } catch (_) {
        // Kullanıcı bulunamadı veya deaktif, oturumu temizle
        await _clearSession();
      }
    }
    notifyListeners();
  }

  /// Giriş yap
  Future<bool> login(String kullaniciAdi, String sifre) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.login(kullaniciAdi, sifre);
      
      if (user != null) {
        _currentUser = user;
        
        // Oturumu kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('current_user_id', user.id ?? '');
        await prefs.setString('current_username', user.kullaniciAdi);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Kullanıcı adı veya şifre hatalı';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Giriş yapılırken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    _authService.logout();
    _currentUser = null;
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('current_user_id');
    await prefs.remove('current_username');
    await prefs.remove('rememberMe');
    await prefs.remove('savedUsername');
    await prefs.remove('savedPassword');
  }

  /// Kullanıcıları getir (admin paneli için)
  Future<List<AppUser>> getUsers() async {
    return await _authService.getUsers();
  }

  /// Aktif çalışanları getir (görev atama için)
  Future<List<AppUser>> getCalisanlar() async {
    return await _authService.getCalisanlar();
  }

  /// Yeni kullanıcı ekle
  Future<bool> addUser(AppUser user) async {
    final result = await _authService.addUser(user);
    notifyListeners();
    return result;
  }

  /// Kullanıcı güncelle
  Future<bool> updateUser(AppUser user) async {
    final result = await _authService.updateUser(user);
    notifyListeners();
    return result;
  }

  /// Kullanıcıyı deaktif et
  Future<bool> deactivateUser(String userId) async {
    final result = await _authService.deactivateUser(userId);
    notifyListeners();
    return result;
  }


  /// Kullanıcıyı tamamen sil
  Future<bool> deleteUser(String userId) async {
    final result = await _authService.deleteUser(userId);
    notifyListeners();
    return result;
  }

  /// Pasif kullanıcıyı aktif et
  Future<bool> activateUser(String userId) async {
    final result = await _authService.activateUser(userId);
    notifyListeners();
    return result;
  }

    /// Şifre değiştir
  Future<bool> changePassword(String userId, String newPassword) async {
    final result = await _authService.changePassword(userId, newPassword);
    notifyListeners();
    return result;
  }
}
