/// Ortak (şirket ortağı) modeli
class Ortak {
  final int? id;
  final String adSoyad;
  final String? tcNo;
  final String? telefon;
  final String? adres;
  final double stopajOrani; // Varsayılan %15
  final bool aktif;
  final String? notlar;
  final DateTime? createdAt;
  
  // Hesaplanan bakiye alanları (DB'den gelmez, runtime'da hesaplanır)
  final double toplamVerilen;     // Ortağın şirkete verdiği
  final double toplamGeriOdenen;  // Şirketin ortağa geri ödediği
  final double toplamStopaj;      // Kesilen stopaj

  Ortak({
    this.id,
    required this.adSoyad,
    this.tcNo,
    this.telefon,
    this.adres,
    this.stopajOrani = 15.0,
    this.aktif = true,
    this.notlar,
    this.createdAt,
    this.toplamVerilen = 0,
    this.toplamGeriOdenen = 0,
    this.toplamStopaj = 0,
  });

  /// Şirketin ortağa olan borcu (verilen - geri ödenen - stopaj)
  double get kalanBorc => toplamVerilen - toplamGeriOdenen - toplamStopaj;
  
  /// Stopaj oranı yüzde formatında
  String get stopajOraniStr => '%${stopajOrani.toStringAsFixed(0)}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad_soyad': adSoyad,
      'tc_no': tcNo,
      'telefon': telefon,
      'adres': adres,
      'stopaj_orani': stopajOrani,
      'aktif': aktif ? 1 : 0,
      'notlar': notlar,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Ortak.fromMap(Map<String, dynamic> map) {
    return Ortak(
      id: map['id'],
      adSoyad: map['ad_soyad'] ?? '',
      tcNo: map['tc_no'],
      telefon: map['telefon'],
      adres: map['adres'],
      stopajOrani: (map['stopaj_orani'] ?? 15.0).toDouble(),
      aktif: map['aktif'] == 1 || map['aktif'] == true,
      notlar: map['notlar'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  Ortak copyWith({
    int? id,
    String? adSoyad,
    String? tcNo,
    String? telefon,
    String? adres,
    double? stopajOrani,
    bool? aktif,
    String? notlar,
    DateTime? createdAt,
    double? toplamVerilen,
    double? toplamGeriOdenen,
    double? toplamStopaj,
  }) {
    return Ortak(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      tcNo: tcNo ?? this.tcNo,
      telefon: telefon ?? this.telefon,
      adres: adres ?? this.adres,
      stopajOrani: stopajOrani ?? this.stopajOrani,
      aktif: aktif ?? this.aktif,
      notlar: notlar ?? this.notlar,
      createdAt: createdAt ?? this.createdAt,
      toplamVerilen: toplamVerilen ?? this.toplamVerilen,
      toplamGeriOdenen: toplamGeriOdenen ?? this.toplamGeriOdenen,
      toplamStopaj: toplamStopaj ?? this.toplamStopaj,
    );
  }
}
