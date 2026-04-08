/// Cari hesap modeli - Tedarikçi/Firma borç-alacak takibi
class Cari {
  final int? id;
  final String firmaAdi;
  final String? yetkiliKisi;
  final String? telefon;
  final String? adres;
  final String? vergiNo;
  final String? notlar;
  final bool aktif;
  final DateTime? createdAt;

  // Runtime hesaplanan alanlar
  final double toplamBorc;    // Bizim onlara olan borcumuz (anlaşma toplamı)
  final double toplamOdenen;  // Bizim ödediğimiz
  final double toplamAlacak;  // Onların bize olan borcu
  final double toplamTahsilat; // Onlardan aldığımız

  Cari({
    this.id,
    required this.firmaAdi,
    this.yetkiliKisi,
    this.telefon,
    this.adres,
    this.vergiNo,
    this.notlar,
    this.aktif = true,
    this.createdAt,
    this.toplamBorc = 0,
    this.toplamOdenen = 0,
    this.toplamAlacak = 0,
    this.toplamTahsilat = 0,
  });

  /// Bizim kalan borcumuz (tedarikçiye)
  double get kalanBorc => toplamBorc - toplamOdenen;

  /// Onların bize kalan borcu
  double get kalanAlacak => toplamAlacak - toplamTahsilat;

  /// Net bakiye (+ ise biz borçluyuz, - ise onlar borçlu)
  double get netBakiye => kalanBorc - kalanAlacak;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firma_adi': firmaAdi,
      'yetkili_kisi': yetkiliKisi,
      'telefon': telefon,
      'adres': adres,
      'vergi_no': vergiNo,
      'notlar': notlar,
      'aktif': aktif ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Cari.fromMap(Map<String, dynamic> map) {
    return Cari(
      id: map['id'],
      firmaAdi: map['firma_adi'] ?? '',
      yetkiliKisi: map['yetkili_kisi'],
      telefon: map['telefon'],
      adres: map['adres'],
      vergiNo: map['vergi_no'],
      notlar: map['notlar'],
      aktif: map['aktif'] == 1 || map['aktif'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Cari copyWith({
    int? id,
    String? firmaAdi,
    String? yetkiliKisi,
    String? telefon,
    String? adres,
    String? vergiNo,
    String? notlar,
    bool? aktif,
    DateTime? createdAt,
    double? toplamBorc,
    double? toplamOdenen,
    double? toplamAlacak,
    double? toplamTahsilat,
  }) {
    return Cari(
      id: id ?? this.id,
      firmaAdi: firmaAdi ?? this.firmaAdi,
      yetkiliKisi: yetkiliKisi ?? this.yetkiliKisi,
      telefon: telefon ?? this.telefon,
      adres: adres ?? this.adres,
      vergiNo: vergiNo ?? this.vergiNo,
      notlar: notlar ?? this.notlar,
      aktif: aktif ?? this.aktif,
      createdAt: createdAt ?? this.createdAt,
      toplamBorc: toplamBorc ?? this.toplamBorc,
      toplamOdenen: toplamOdenen ?? this.toplamOdenen,
      toplamAlacak: toplamAlacak ?? this.toplamAlacak,
      toplamTahsilat: toplamTahsilat ?? this.toplamTahsilat,
    );
  }
}

/// Cari anlaşma modeli
class CariAnlasma {
  final int? id;
  final int cariId;
  final String baslik;        // Anlaşma başlığı (ör: "Kardeşler File Anlaşması")
  final double tutar;         // Anlaşma tutarı
  final String tip;           // 'borc' veya 'alacak'
  final String paraBirimi;
  final DateTime tarih;
  final String? notlar;
  final bool aktif;

  CariAnlasma({
    this.id,
    required this.cariId,
    required this.baslik,
    required this.tutar,
    required this.tip,
    this.paraBirimi = 'TL',
    required this.tarih,
    this.notlar,
    this.aktif = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cari_id': cariId,
      'baslik': baslik,
      'tutar': tutar,
      'tip': tip,
      'para_birimi': paraBirimi,
      'tarih': tarih.toIso8601String(),
      'notlar': notlar,
      'aktif': aktif ? 1 : 0,
    };
  }

  /// Firestore için id hariç, aktif boolean olarak
  Map<String, dynamic> toFirestoreMap() {
    return {
      'cari_id': cariId,
      'baslik': baslik,
      'tutar': tutar,
      'tip': tip,
      'para_birimi': paraBirimi,
      'tarih': tarih.toIso8601String(),
      'notlar': notlar,
      'aktif': aktif,
    };
  }

  factory CariAnlasma.fromMap(Map<String, dynamic> map) {
    return CariAnlasma(
      id: map['id'],
      cariId: map['cari_id'] ?? 0,
      baslik: map['baslik'] ?? '',
      tutar: (map['tutar'] ?? 0).toDouble(),
      tip: map['tip'] ?? 'borc',
      paraBirimi: map['para_birimi'] ?? 'TL',
      tarih: map['tarih'] != null
          ? DateTime.parse(map['tarih'])
          : DateTime.now(),
      notlar: map['notlar'],
      aktif: map['aktif'] == 1 || map['aktif'] == true,
    );
  }

  CariAnlasma copyWith({
    int? id,
    int? cariId,
    String? baslik,
    double? tutar,
    String? tip,
    String? paraBirimi,
    DateTime? tarih,
    String? notlar,
    bool? aktif,
  }) {
    return CariAnlasma(
      id: id ?? this.id,
      cariId: cariId ?? this.cariId,
      baslik: baslik ?? this.baslik,
      tutar: tutar ?? this.tutar,
      tip: tip ?? this.tip,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      tarih: tarih ?? this.tarih,
      notlar: notlar ?? this.notlar,
      aktif: aktif ?? this.aktif,
    );
  }
}
