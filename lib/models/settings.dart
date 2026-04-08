// Ayarlar modeli - Kasalar, Şahıslar, Gider Pusulası Kişileri
class AppSettings {
  final int? id;
  final String tip; // 'kasa', 'sahis', 'gider_pusulasi_kisi', 'aciklama'
  final String deger;
  final bool aktif;
  final int? ortakId; // Kasanın bağlı olduğu ortak
  final String? paraBirimi; // Kasanın para birimi (TL, EUR, USD)

  AppSettings({
    this.id,
    required this.tip,
    required this.deger,
    this.aktif = true,
    this.ortakId,
    this.paraBirimi,
  });

  /// Kasa için görünen ad (para birimi varsa ekle)
  String get kasaGosterimAdi {
    if (paraBirimi != null && paraBirimi!.isNotEmpty && paraBirimi != 'TL') {
      return '$deger ($paraBirimi)';
    }
    return deger;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tip': tip,
      'deger': deger,
      'aktif': aktif ? 1 : 0,
      'ortak_id': ortakId,
      'para_birimi': paraBirimi,
    };
  }

  /// Firestore için id hariç, aktif boolean olarak
  Map<String, dynamic> toFirestoreMap() {
    return {
      'tip': tip,
      'deger': deger,
      'aktif': aktif,
      'ortak_id': ortakId,
      'para_birimi': paraBirimi,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      tip: map['tip'] ?? '',
      deger: map['deger'] ?? '',
      aktif: map['aktif'] == 1 || map['aktif'] == true || map['aktif'] == 1.0,
      ortakId: map['ortak_id'],
      paraBirimi: map['para_birimi'],
    );
  }

  AppSettings copyWith({
    int? id,
    String? tip,
    String? deger,
    bool? aktif,
    int? ortakId,
    String? paraBirimi,
  }) {
    return AppSettings(
      id: id ?? this.id,
      tip: tip ?? this.tip,
      deger: deger ?? this.deger,
      aktif: aktif ?? this.aktif,
      ortakId: ortakId ?? this.ortakId,
      paraBirimi: paraBirimi ?? this.paraBirimi,
    );
  }
}
