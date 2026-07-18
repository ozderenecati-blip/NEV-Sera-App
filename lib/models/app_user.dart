/// Kullanıcı rolleri
enum UserRole {
  admin,              // Ortaklar - Full yetki (Finans + Operasyon)
  operasyonYoneticisi, // Operasyon yöneticisi - Operasyon full yetki
  calisan,            // Çalışan - Read-only + görev tamamla + daily report
  boardMember,        // Yönetim Kurulu - Tüm verileri görür, hiçbir şeyi değiştiremez
}

class AppUser {
  final String? id;
  final String kullaniciAdi;
  final String sifre;
  final String adSoyad;
  final UserRole rol;
  final bool aktif;
  final DateTime? sonGiris;
  final DateTime olusturmaTarihi;
  final List<Map<String, String>> atanmisBahceler; // [{id: 'xxx', ad: 'Beydağ-BB'}]

  AppUser({
    this.id,
    required this.kullaniciAdi,
    required this.sifre,
    required this.adSoyad,
    required this.rol,
    this.aktif = true,
    this.sonGiris,
    this.atanmisBahceler = const [],
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  /// Kullanıcı salt-okunur mu? (Board Member hiçbir veriyi değiştiremez)
  bool get isReadOnly => rol == UserRole.boardMember;

  /// Kullanıcı finans modülüne erişebilir mi?
  bool get canAccessFinans => rol == UserRole.admin || rol == UserRole.boardMember;
  
  /// Kullanıcı operasyon modülüne erişebilir mi?
  bool get canAccessOperasyon => true; // Herkes erişebilir
  
  /// Kullanıcı finans verilerinde yazma yetkisi var mı?
  bool get canWriteFinans => rol == UserRole.admin;
  
  /// Kullanıcı operasyonda yazma yetkisi var mı?
  bool get canWriteOperasyon => rol == UserRole.admin || rol == UserRole.operasyonYoneticisi;
  
  /// Kullanıcı görev atayabilir mi?
  bool get canAssignTask => rol == UserRole.admin || rol == UserRole.operasyonYoneticisi;
  
  /// Kullanıcı görev tamamlayabilir mi?
  bool get canCompleteTask => rol != UserRole.boardMember;
  
  /// Kullanıcı daily report yazabilir mi?
  bool get canWriteDailyReport => rol != UserRole.boardMember;
  
  /// Kullanıcı daily report verify edebilir mi?
  bool get canVerifyDailyReport => rol == UserRole.admin || rol == UserRole.operasyonYoneticisi;
  
  /// Kullanıcı yönetimi yapabilir mi?
  bool get canManageUsers => rol == UserRole.admin;

  String get rolLabel => switch (rol) {
    UserRole.admin => 'Admin / Ortak',
    UserRole.operasyonYoneticisi => 'Operasyon Yöneticisi',
    UserRole.calisan => 'Çalışan',
    UserRole.boardMember => 'Yönetim Kurulu Üyesi',
  };

  String get rolIcon => switch (rol) {
    UserRole.admin => '👑',
    UserRole.operasyonYoneticisi => '🌱',
    UserRole.calisan => '👷',
    UserRole.boardMember => '📊',
  };

  Map<String, dynamic> toMap() {
    return {
      'kullanici_adi': kullaniciAdi,
      'sifre': sifre,
      'ad_soyad': adSoyad,
      'rol': rol.name,
      'aktif': aktif,
      'son_giris': sonGiris?.toIso8601String(),
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
      'atanmis_bahceler': atanmisBahceler.map((b) => {'id': b['id'], 'ad': b['ad']}).toList(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AppUser(
      id: docId ?? map['id']?.toString(),
      kullaniciAdi: map['kullanici_adi'] ?? '',
      sifre: map['sifre'] ?? '',
      adSoyad: map['ad_soyad'] ?? '',
      rol: UserRole.values.firstWhere(
        (r) => r.name == (map['rol'] ?? 'calisan'),
        orElse: () => UserRole.calisan,
      ),
      aktif: map['aktif'] ?? true,
      sonGiris: map['son_giris'] != null ? DateTime.tryParse(map['son_giris']) : null,
      atanmisBahceler: (map['atanmis_bahceler'] as List<dynamic>?)
          ?.map((b) => {'id': (b['id'] ?? '').toString(), 'ad': (b['ad'] ?? '').toString()})
          .toList() ?? [],
      olusturmaTarihi: map['olusturma_tarihi'] != null 
          ? DateTime.tryParse(map['olusturma_tarihi']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppUser copyWith({
    String? id,
    String? kullaniciAdi,
    String? sifre,
    String? adSoyad,
    UserRole? rol,
    bool? aktif,
    DateTime? sonGiris,
    List<Map<String, String>>? atanmisBahceler,
  }) {
    return AppUser(
      id: id ?? this.id,
      kullaniciAdi: kullaniciAdi ?? this.kullaniciAdi,
      sifre: sifre ?? this.sifre,
      adSoyad: adSoyad ?? this.adSoyad,
      rol: rol ?? this.rol,
      aktif: aktif ?? this.aktif,
      sonGiris: sonGiris ?? this.sonGiris,
      atanmisBahceler: atanmisBahceler ?? this.atanmisBahceler,
      olusturmaTarihi: olusturmaTarihi,
    );
  }
}
