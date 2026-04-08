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
  final String? fisUrl;      // Fiş/Fatura görseli URL'si

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
    this.fisUrl,
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
      'fis_url': fisUrl,
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
      fisUrl: map['fis_url'],
    );
  }

  static const _sentinel = Object();

  KasaHareketi copyWith({
    int? id,
    DateTime? tarih,
    String? aciklama,
    String? islemTipi,
    double? tutar,
    Object? odemeBicimi = _sentinel,
    Object? kasa = _sentinel,
    Object? notlar = _sentinel,
    String? paraBirimi,
    Object? dovizKuru = _sentinel,
    Object? tlKarsiligi = _sentinel,
    String? islemKaynagi,
    Object? iliskiliId = _sentinel,
    Object? fisUrl = _sentinel,
  }) {
    return KasaHareketi(
      id: id ?? this.id,
      tarih: tarih ?? this.tarih,
      aciklama: aciklama ?? this.aciklama,
      islemTipi: islemTipi ?? this.islemTipi,
      tutar: tutar ?? this.tutar,
      odemeBicimi: odemeBicimi == _sentinel ? this.odemeBicimi : odemeBicimi as String?,
      kasa: kasa == _sentinel ? this.kasa : kasa as String?,
      notlar: notlar == _sentinel ? this.notlar : notlar as String?,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      dovizKuru: dovizKuru == _sentinel ? this.dovizKuru : dovizKuru as double?,
      tlKarsiligi: tlKarsiligi == _sentinel ? this.tlKarsiligi : tlKarsiligi as double?,
      islemKaynagi: islemKaynagi ?? this.islemKaynagi,
      iliskiliId: iliskiliId == _sentinel ? this.iliskiliId : iliskiliId as int?,
      fisUrl: fisUrl == _sentinel ? this.fisUrl : fisUrl as String?,
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
      case 'kasa_transfer': return '🔄 Transfer';
      case 'islem_ucreti': return '🧾 İşlem Ücreti';
      case 'maas_odemesi': return '💰 Maaş';
      case 'cari_odeme': return '🏢 Cari Ödeme';
      case 'cari_tahsilat': return '🏢 Cari Tahsilat';
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
