// Ayarlar modeli - Kasalar, Şahıslar, Gider Pusulası Kişileri
class AppSettings {
  final int? id;
  final String tip; // 'kasa', 'sahis', 'gider_pusulasi_kisi', 'aciklama'
  final String deger;
  final bool aktif;
  final int? ortakId; // Kasanın bağlı olduğu ortak

  AppSettings({
    this.id,
    required this.tip,
    required this.deger,
    this.aktif = true,
    this.ortakId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tip': tip,
      'deger': deger,
      'aktif': aktif ? 1 : 0,
      'ortak_id': ortakId,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      tip: map['tip'] ?? '',
      deger: map['deger'] ?? '',
      aktif: map['aktif'] == 1,
      ortakId: map['ortak_id'],
    );
  }

  AppSettings copyWith({
    int? id,
    String? tip,
    String? deger,
    bool? aktif,
    int? ortakId,
  }) {
    return AppSettings(
      id: id ?? this.id,
      tip: tip ?? this.tip,
      deger: deger ?? this.deger,
      aktif: aktif ?? this.aktif,
      ortakId: ortakId ?? this.ortakId,
    );
  }
}
