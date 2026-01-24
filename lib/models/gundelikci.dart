/// Gündelikçi modeli - Gider pusulası için işçiler
class Gundelikci {
  final int? id;
  final String adSoyad;
  final String? tcNo;
  final String? adres;
  final String? telefon;
  final bool aktif;
  
  // Hesaplanan alanlar (kasa işlemlerinden)
  double toplamOdeme;
  double resmilestirilenTutar;
  
  Gundelikci({
    this.id,
    required this.adSoyad,
    this.tcNo,
    this.adres,
    this.telefon,
    this.aktif = true,
    this.toplamOdeme = 0,
    this.resmilestirilenTutar = 0,
  });
  
  /// Kalan resmileştirilecek tutar (şirketten gündelikçiye borç)
  double get kalanBorc => toplamOdeme - resmilestirilenTutar;
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad_soyad': adSoyad,
      'tc_no': tcNo,
      'adres': adres,
      'telefon': telefon,
      'aktif': aktif ? 1 : 0,
    };
  }
  
  factory Gundelikci.fromMap(Map<String, dynamic> map) {
    return Gundelikci(
      id: map['id'],
      adSoyad: map['ad_soyad'] ?? '',
      tcNo: map['tc_no'],
      adres: map['adres'],
      telefon: map['telefon'],
      aktif: (map['aktif'] ?? 1) == 1 || map['aktif'] == true,
    );
  }
  
  Gundelikci copyWith({
    int? id,
    String? adSoyad,
    String? tcNo,
    String? adres,
    String? telefon,
    bool? aktif,
    double? toplamOdeme,
    double? resmilestirilenTutar,
  }) {
    return Gundelikci(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      tcNo: tcNo ?? this.tcNo,
      adres: adres ?? this.adres,
      telefon: telefon ?? this.telefon,
      aktif: aktif ?? this.aktif,
      toplamOdeme: toplamOdeme ?? this.toplamOdeme,
      resmilestirilenTutar: resmilestirilenTutar ?? this.resmilestirilenTutar,
    );
  }
}
