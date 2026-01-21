/// Satış kaydı modeli
class Satis {
  final int? id;
  final int musteriId;
  final String? musteriUnvan;   // Join'den gelir
  final DateTime tarih;
  final String urunAdi;
  final double miktar;
  final String birim;           // 'kg', 'kasa', 'adet'
  final double birimFiyat;
  final double toplamTutar;
  final String paraBirimi;
  final double? dovizKuru;
  final double? tlKarsiligi;
  final double? komisyonOrani;  // Hal/komisyoncu için
  final double? komisyonTutari;
  final DateTime? vadeTarihi;
  final String? faturaNo;
  final String? irsaliyeNo;
  final String? aciklama;
  final DateTime? createdAt;

  Satis({
    this.id,
    required this.musteriId,
    this.musteriUnvan,
    required this.tarih,
    required this.urunAdi,
    required this.miktar,
    this.birim = 'kg',
    required this.birimFiyat,
    required this.toplamTutar,
    this.paraBirimi = 'TL',
    this.dovizKuru,
    this.tlKarsiligi,
    this.komisyonOrani,
    this.komisyonTutari,
    this.vadeTarihi,
    this.faturaNo,
    this.irsaliyeNo,
    this.aciklama,
    this.createdAt,
  });

  /// Net tutar (toplam - komisyon)
  double get netTutar => toplamTutar - (komisyonTutari ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'musteri_id': musteriId,
      'tarih': tarih.toIso8601String(),
      'urun_adi': urunAdi,
      'miktar': miktar,
      'birim': birim,
      'birim_fiyat': birimFiyat,
      'toplam_tutar': toplamTutar,
      'para_birimi': paraBirimi,
      'doviz_kuru': dovizKuru,
      'tl_karsiligi': tlKarsiligi,
      'komisyon_orani': komisyonOrani,
      'komisyon_tutari': komisyonTutari,
      'vade_tarihi': vadeTarihi?.toIso8601String(),
      'fatura_no': faturaNo,
      'irsaliye_no': irsaliyeNo,
      'aciklama': aciklama,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Satis.fromMap(Map<String, dynamic> map) {
    return Satis(
      id: map['id'],
      musteriId: map['musteri_id'],
      musteriUnvan: map['musteri_unvan'],
      tarih: DateTime.parse(map['tarih']),
      urunAdi: map['urun_adi'] ?? '',
      miktar: (map['miktar'] ?? 0).toDouble(),
      birim: map['birim'] ?? 'kg',
      birimFiyat: (map['birim_fiyat'] ?? 0).toDouble(),
      toplamTutar: (map['toplam_tutar'] ?? 0).toDouble(),
      paraBirimi: map['para_birimi'] ?? 'TL',
      dovizKuru: map['doviz_kuru']?.toDouble(),
      tlKarsiligi: map['tl_karsiligi']?.toDouble(),
      komisyonOrani: map['komisyon_orani']?.toDouble(),
      komisyonTutari: map['komisyon_tutari']?.toDouble(),
      vadeTarihi: map['vade_tarihi'] != null 
          ? DateTime.parse(map['vade_tarihi']) 
          : null,
      faturaNo: map['fatura_no'],
      irsaliyeNo: map['irsaliye_no'],
      aciklama: map['aciklama'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  Satis copyWith({
    int? id,
    int? musteriId,
    String? musteriUnvan,
    DateTime? tarih,
    String? urunAdi,
    double? miktar,
    String? birim,
    double? birimFiyat,
    double? toplamTutar,
    String? paraBirimi,
    double? dovizKuru,
    double? tlKarsiligi,
    double? komisyonOrani,
    double? komisyonTutari,
    DateTime? vadeTarihi,
    String? faturaNo,
    String? irsaliyeNo,
    String? aciklama,
    DateTime? createdAt,
  }) {
    return Satis(
      id: id ?? this.id,
      musteriId: musteriId ?? this.musteriId,
      musteriUnvan: musteriUnvan ?? this.musteriUnvan,
      tarih: tarih ?? this.tarih,
      urunAdi: urunAdi ?? this.urunAdi,
      miktar: miktar ?? this.miktar,
      birim: birim ?? this.birim,
      birimFiyat: birimFiyat ?? this.birimFiyat,
      toplamTutar: toplamTutar ?? this.toplamTutar,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      dovizKuru: dovizKuru ?? this.dovizKuru,
      tlKarsiligi: tlKarsiligi ?? this.tlKarsiligi,
      komisyonOrani: komisyonOrani ?? this.komisyonOrani,
      komisyonTutari: komisyonTutari ?? this.komisyonTutari,
      vadeTarihi: vadeTarihi ?? this.vadeTarihi,
      faturaNo: faturaNo ?? this.faturaNo,
      irsaliyeNo: irsaliyeNo ?? this.irsaliyeNo,
      aciklama: aciklama ?? this.aciklama,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


/// Tahsilat kaydı modeli
class Tahsilat {
  final int? id;
  final int musteriId;
  final DateTime tarih;
  final double tutar;
  final String paraBirimi;
  final double? dovizKuru;
  final double? tlKarsiligi;
  final String odemeSekli;      // 'nakit', 'havale', 'cek', 'senet'
  final String? kasaAdi;        // Hangi kasaya girdi
  final String? cekSenetNo;     // Çek/senet numarası
  final DateTime? cekVadeTarihi;
  final String? bankaAdi;
  final String? aciklama;
  final DateTime? createdAt;

  Tahsilat({
    this.id,
    required this.musteriId,
    required this.tarih,
    required this.tutar,
    this.paraBirimi = 'TL',
    this.dovizKuru,
    this.tlKarsiligi,
    this.odemeSekli = 'nakit',
    this.kasaAdi,
    this.cekSenetNo,
    this.cekVadeTarihi,
    this.bankaAdi,
    this.aciklama,
    this.createdAt,
  });

  /// Ödeme şekli etiketi
  String get odemeSekliLabel {
    switch (odemeSekli) {
      case 'havale':
        return 'Havale/EFT';
      case 'cek':
        return 'Çek';
      case 'senet':
        return 'Senet';
      default:
        return 'Nakit';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'musteri_id': musteriId,
      'tarih': tarih.toIso8601String(),
      'tutar': tutar,
      'para_birimi': paraBirimi,
      'doviz_kuru': dovizKuru,
      'tl_karsiligi': tlKarsiligi,
      'odeme_sekli': odemeSekli,
      'kasa_adi': kasaAdi,
      'cek_senet_no': cekSenetNo,
      'cek_vade_tarihi': cekVadeTarihi?.toIso8601String(),
      'banka_adi': bankaAdi,
      'aciklama': aciklama,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Tahsilat.fromMap(Map<String, dynamic> map) {
    return Tahsilat(
      id: map['id'],
      musteriId: map['musteri_id'],
      tarih: DateTime.parse(map['tarih']),
      tutar: (map['tutar'] ?? 0).toDouble(),
      paraBirimi: map['para_birimi'] ?? 'TL',
      dovizKuru: map['doviz_kuru']?.toDouble(),
      tlKarsiligi: map['tl_karsiligi']?.toDouble(),
      odemeSekli: map['odeme_sekli'] ?? 'nakit',
      kasaAdi: map['kasa_adi'],
      cekSenetNo: map['cek_senet_no'],
      cekVadeTarihi: map['cek_vade_tarihi'] != null 
          ? DateTime.parse(map['cek_vade_tarihi']) 
          : null,
      bankaAdi: map['banka_adi'],
      aciklama: map['aciklama'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  Tahsilat copyWith({
    int? id,
    int? musteriId,
    DateTime? tarih,
    double? tutar,
    String? paraBirimi,
    double? dovizKuru,
    double? tlKarsiligi,
    String? odemeSekli,
    String? kasaAdi,
    String? cekSenetNo,
    DateTime? cekVadeTarihi,
    String? bankaAdi,
    String? aciklama,
    DateTime? createdAt,
  }) {
    return Tahsilat(
      id: id ?? this.id,
      musteriId: musteriId ?? this.musteriId,
      tarih: tarih ?? this.tarih,
      tutar: tutar ?? this.tutar,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      dovizKuru: dovizKuru ?? this.dovizKuru,
      tlKarsiligi: tlKarsiligi ?? this.tlKarsiligi,
      odemeSekli: odemeSekli ?? this.odemeSekli,
      kasaAdi: kasaAdi ?? this.kasaAdi,
      cekSenetNo: cekSenetNo ?? this.cekSenetNo,
      cekVadeTarihi: cekVadeTarihi ?? this.cekVadeTarihi,
      bankaAdi: bankaAdi ?? this.bankaAdi,
      aciklama: aciklama ?? this.aciklama,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
