/// Hasat kaydı modeli - parsel bazlı hasat miktarları
class Hasat {
  final String? id;
  final String bahceId;
  final String bahceAd;
  final String parselId;
  final String parselAd;
  final String urun; // ürün / cins
  final DateTime tarih;
  final double miktar;
  final String birim; // 'kg', 'kasa', 'adet'
  final String? kalite; // '1. Boy', '2. Boy', 'Iskarta' vb.
  final double? saksiSayisi; // hasat anındaki parsel saksı sayısı (verim için)
  final String? not;
  final DateTime createdAt;

  Hasat({
    this.id,
    required this.bahceId,
    required this.bahceAd,
    required this.parselId,
    required this.parselAd,
    required this.urun,
    required this.tarih,
    required this.miktar,
    this.birim = 'kg',
    this.kalite,
    this.saksiSayisi,
    this.not,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Saksı başına verim (birim/saksı) - saksı sayısı yoksa null
  double? get verimSaksiBasi {
    if (saksiSayisi == null || saksiSayisi! <= 0) return null;
    return miktar / saksiSayisi!;
  }

  Map<String, dynamic> toMap() => {
        'bahce_id': bahceId,
        'bahce_ad': bahceAd,
        'parsel_id': parselId,
        'parsel_ad': parselAd,
        'urun': urun,
        'tarih': tarih.toIso8601String(),
        'miktar': miktar,
        'birim': birim,
        'kalite': kalite,
        'saksi_sayisi': saksiSayisi,
        'not': not,
        'created_at': createdAt.toIso8601String(),
      };

  factory Hasat.fromMap(Map<String, dynamic> map, {String? docId}) => Hasat(
        id: docId ?? map['id']?.toString(),
        bahceId: map['bahce_id'] ?? '',
        bahceAd: map['bahce_ad'] ?? '',
        parselId: map['parsel_id'] ?? '',
        parselAd: map['parsel_ad'] ?? '',
        urun: map['urun'] ?? '',
        tarih: map['tarih'] != null
            ? DateTime.tryParse(map['tarih']) ?? DateTime.now()
            : DateTime.now(),
        miktar: (map['miktar'] as num?)?.toDouble() ?? 0,
        birim: map['birim'] ?? 'kg',
        kalite: map['kalite'],
        saksiSayisi: (map['saksi_sayisi'] as num?)?.toDouble(),
        not: map['not'],
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
            : DateTime.now(),
      );

  Hasat copyWith({
    String? id,
    String? bahceId,
    String? bahceAd,
    String? parselId,
    String? parselAd,
    String? urun,
    DateTime? tarih,
    double? miktar,
    String? birim,
    String? kalite,
    double? saksiSayisi,
    String? not,
    DateTime? createdAt,
  }) =>
      Hasat(
        id: id ?? this.id,
        bahceId: bahceId ?? this.bahceId,
        bahceAd: bahceAd ?? this.bahceAd,
        parselId: parselId ?? this.parselId,
        parselAd: parselAd ?? this.parselAd,
        urun: urun ?? this.urun,
        tarih: tarih ?? this.tarih,
        miktar: miktar ?? this.miktar,
        birim: birim ?? this.birim,
        kalite: kalite ?? this.kalite,
        saksiSayisi: saksiSayisi ?? this.saksiSayisi,
        not: not ?? this.not,
        createdAt: createdAt ?? this.createdAt,
      );
}