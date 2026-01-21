/// İşlem kaynağı türleri
enum IslemKaynagi {
  kasa,           // Normal kasa işlemi
  giderPusulasi,  // Gündelikçi ödemesi
  krediOdeme,     // Kredi taksit ödemesi
}

/// Para birimleri
enum ParaBirimi { TL, EUR, USD }

class KasaHareketi {
  final int? id;
  final DateTime tarih;
  final String aciklama;
  final String islemTipi;    // 'Giriş' veya 'Çıkış'
  final double tutar;
  final String? odemeBicimi; // 'Nakit', 'Kart', 'Havale'
  final String? kasa;        // Hangi kasa (Necati, Mert, Nev Seracılık, AveA)
  final String? notlar;
  final String paraBirimi;   // 'TL', 'EUR', 'USD'
  final double? dovizKuru;   // İşlem anındaki kur
  final double? tlKarsiligi; // TL karşılığı
  final String? islemKaynagi; // 'kasa', 'gider_pusulasi', 'kredi_odeme', 'resmilestirme'
  final int? iliskiliId;     // Gider pusulası veya kredi ID'si

  KasaHareketi({
    this.id,
    required this.tarih,
    required this.aciklama,
    required this.islemTipi,
    required this.tutar,
    this.odemeBicimi,
    this.kasa,
    this.notlar,
    this.paraBirimi = 'TL',
    this.dovizKuru,
    this.tlKarsiligi,
    this.islemKaynagi = 'kasa',
    this.iliskiliId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarih': tarih.toIso8601String(),
      'aciklama': aciklama,
      'islem_tipi': islemTipi,
      'tutar': tutar,
      'odeme_bicimi': odemeBicimi,
      'kasa': kasa,
      'notlar': notlar,
      'para_birimi': paraBirimi,
      'doviz_kuru': dovizKuru,
      'tl_karsiligi': tlKarsiligi,
      'islem_kaynagi': islemKaynagi,
      'iliskili_id': iliskiliId,
    };
  }

  factory KasaHareketi.fromMap(Map<String, dynamic> map) {
    return KasaHareketi(
      id: map['id'],
      tarih: DateTime.parse(map['tarih']),
      aciklama: map['aciklama'] ?? '',
      islemTipi: map['islem_tipi'] ?? 'Çıkış',
      tutar: (map['tutar'] ?? 0).toDouble(),
      odemeBicimi: map['odeme_bicimi'],
      kasa: map['kasa'],
      notlar: map['notlar'],
      paraBirimi: map['para_birimi'] ?? 'TL',
      dovizKuru: map['doviz_kuru']?.toDouble(),
      tlKarsiligi: map['tl_karsiligi']?.toDouble(),
      islemKaynagi: map['islem_kaynagi'] ?? 'kasa',
      iliskiliId: map['iliskili_id'],
    );
  }

  KasaHareketi copyWith({
    int? id,
    DateTime? tarih,
    String? aciklama,
    String? islemTipi,
    double? tutar,
    String? odemeBicimi,
    String? kasa,
    String? notlar,
    String? paraBirimi,
    double? dovizKuru,
    double? tlKarsiligi,
    String? islemKaynagi,
    int? iliskiliId,
  }) {
    return KasaHareketi(
      id: id ?? this.id,
      tarih: tarih ?? this.tarih,
      aciklama: aciklama ?? this.aciklama,
      islemTipi: islemTipi ?? this.islemTipi,
      tutar: tutar ?? this.tutar,
      odemeBicimi: odemeBicimi ?? this.odemeBicimi,
      kasa: kasa ?? this.kasa,
      notlar: notlar ?? this.notlar,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      dovizKuru: dovizKuru ?? this.dovizKuru,
      tlKarsiligi: tlKarsiligi ?? this.tlKarsiligi,
      islemKaynagi: islemKaynagi ?? this.islemKaynagi,
      iliskiliId: iliskiliId ?? this.iliskiliId,
    );
  }
  
  /// İşlem kaynağı için etiket
  String get islemKaynagiLabel {
    switch (islemKaynagi) {
      case 'gider_pusulasi': return '👷 Avans';
      case 'kredi_odeme': return '💳 Kredi';
      case 'resmilestirme': return '📄 G. Pusulası';
      case 'gider_pusulasi_vergi': return '🏛️ G.P. Vergisi';
      case 'doviz_bozdurma': return '💱 Döviz Bozd.';
      case 'islem_ucreti': return '🧾 İşlem Ücreti';
      default: return '💰 Kasa';
    }
  }
  
  /// Para birimi sembolü
  String get paraBirimiSembol {
    switch (paraBirimi) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      default: return '₺';
    }
  }
  
  /// Ödeme şekli etiketi
  String get odemeBicimiLabel {
    switch (odemeBicimi) {
      case 'Nakit': return '💵 Nakit';
      case 'Kart': return '💳 Kart';
      case 'Havale': return '🏦 Havale';
      default: return '';
    }
  }
}
