/// Müşteri (Cari) modeli - Satış ve alacak takibi için
class Musteri {
  final int? id;
  final String unvan;           // Firma/Kişi adı
  final String? yetkiliKisi;    // İrtibat kişisi
  final String? vergiNo;        // Vergi numarası
  final String? vergiDairesi;   // Vergi dairesi
  final String? telefon;
  final String? email;
  final String? adres;
  final String? sehir;
  final String musteriTipi;     // 'bireysel', 'kurumsal', 'hal', 'komisyoncu'
  final double vadeGunu;        // Varsayılan vade günü
  final bool aktif;
  final String? notlar;
  final DateTime? createdAt;
  
  // Hesaplanan bakiye alanları (runtime'da hesaplanır)
  final double toplamSatis;     // Toplam satış tutarı
  final double toplamTahsilat;  // Toplam tahsilat tutarı

  Musteri({
    this.id,
    required this.unvan,
    this.yetkiliKisi,
    this.vergiNo,
    this.vergiDairesi,
    this.telefon,
    this.email,
    this.adres,
    this.sehir,
    this.musteriTipi = 'bireysel',
    this.vadeGunu = 0,
    this.aktif = true,
    this.notlar,
    this.createdAt,
    this.toplamSatis = 0,
    this.toplamTahsilat = 0,
  });

  /// Müşterinin borcu (satış - tahsilat)
  double get bakiye => toplamSatis - toplamTahsilat;
  
  /// Müşteri tipi etiketi
  String get musteriTipiLabel {
    switch (musteriTipi) {
      case 'kurumsal':
        return 'Kurumsal';
      case 'hal':
        return 'Hal';
      case 'komisyoncu':
        return 'Komisyoncu';
      default:
        return 'Bireysel';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unvan': unvan,
      'yetkili_kisi': yetkiliKisi,
      'vergi_no': vergiNo,
      'vergi_dairesi': vergiDairesi,
      'telefon': telefon,
      'email': email,
      'adres': adres,
      'sehir': sehir,
      'musteri_tipi': musteriTipi,
      'vade_gunu': vadeGunu,
      'aktif': aktif ? 1 : 0,
      'notlar': notlar,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Musteri.fromMap(Map<String, dynamic> map) {
    return Musteri(
      id: map['id'],
      unvan: map['unvan'] ?? '',
      yetkiliKisi: map['yetkili_kisi'],
      vergiNo: map['vergi_no'],
      vergiDairesi: map['vergi_dairesi'],
      telefon: map['telefon'],
      email: map['email'],
      adres: map['adres'],
      sehir: map['sehir'],
      musteriTipi: map['musteri_tipi'] ?? 'bireysel',
      vadeGunu: (map['vade_gunu'] ?? 0).toDouble(),
      aktif: map['aktif'] == 1,
      notlar: map['notlar'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  Musteri copyWith({
    int? id,
    String? unvan,
    String? yetkiliKisi,
    String? vergiNo,
    String? vergiDairesi,
    String? telefon,
    String? email,
    String? adres,
    String? sehir,
    String? musteriTipi,
    double? vadeGunu,
    bool? aktif,
    String? notlar,
    DateTime? createdAt,
    double? toplamSatis,
    double? toplamTahsilat,
  }) {
    return Musteri(
      id: id ?? this.id,
      unvan: unvan ?? this.unvan,
      yetkiliKisi: yetkiliKisi ?? this.yetkiliKisi,
      vergiNo: vergiNo ?? this.vergiNo,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      adres: adres ?? this.adres,
      sehir: sehir ?? this.sehir,
      musteriTipi: musteriTipi ?? this.musteriTipi,
      vadeGunu: vadeGunu ?? this.vadeGunu,
      aktif: aktif ?? this.aktif,
      notlar: notlar ?? this.notlar,
      createdAt: createdAt ?? this.createdAt,
      toplamSatis: toplamSatis ?? this.toplamSatis,
      toplamTahsilat: toplamTahsilat ?? this.toplamTahsilat,
    );
  }
}
