class GiderPusulasi {
  final int? id;
  final String sahis;
  final String? tcNo;
  final String? adres;
  final double toplamAvansOdeme;
  final double resmilestirilecekMeblag;
  final double kalanResmilestirilecek;

  GiderPusulasi({
    this.id,
    required this.sahis,
    this.tcNo,
    this.adres,
    this.toplamAvansOdeme = 0,
    this.resmilestirilecekMeblag = 0,
    this.kalanResmilestirilecek = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sahis': sahis,
      'tc_no': tcNo,
      'adres': adres,
      'toplam_avans_odeme': toplamAvansOdeme,
      'resmilestirilen_meblag': resmilestirilecekMeblag,
      'kalan_resmilestirilecek': kalanResmilestirilecek,
    };
  }

  factory GiderPusulasi.fromMap(Map<String, dynamic> map) {
    return GiderPusulasi(
      id: map['id'],
      sahis: map['sahis'] ?? '',
      tcNo: map['tc_no'],
      adres: map['adres'],
      toplamAvansOdeme: (map['toplam_avans_odeme'] ?? 0).toDouble(),
      resmilestirilecekMeblag: (map['resmilestirilen_meblag'] ?? 0).toDouble(),
      kalanResmilestirilecek: (map['kalan_resmilestirilecek'] ?? 0).toDouble(),
    );
  }

  GiderPusulasi copyWith({
    int? id,
    String? sahis,
    String? tcNo,
    String? adres,
    double? toplamAvansOdeme,
    double? resmilestirilecekMeblag,
    double? kalanResmilestirilecek,
  }) {
    return GiderPusulasi(
      id: id ?? this.id,
      sahis: sahis ?? this.sahis,
      tcNo: tcNo ?? this.tcNo,
      adres: adres ?? this.adres,
      toplamAvansOdeme: toplamAvansOdeme ?? this.toplamAvansOdeme,
      resmilestirilecekMeblag: resmilestirilecekMeblag ?? this.resmilestirilecekMeblag,
      kalanResmilestirilecek: kalanResmilestirilecek ?? this.kalanResmilestirilecek,
    );
  }
}
