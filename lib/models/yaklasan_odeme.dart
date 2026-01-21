/// Yaklaşan ödeme modeli - Açık carilerin ve borçların takibi
class YaklasanOdeme {
  final int? id;
  final String alacakli; // Kime ödeme yapılacak
  final double tutar;
  final String paraBirimi;
  final DateTime vadeTarihi;
  final String? aciklama;
  final bool odendi;
  final DateTime? odenmeTarihi;
  final bool alarmAktif;
  final int? alarmGunOnce; // Kaç gün önce alarm

  YaklasanOdeme({
    this.id,
    required this.alacakli,
    required this.tutar,
    this.paraBirimi = 'TL',
    required this.vadeTarihi,
    this.aciklama,
    this.odendi = false,
    this.odenmeTarihi,
    this.alarmAktif = true,
    this.alarmGunOnce = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alacakli': alacakli,
      'tutar': tutar,
      'para_birimi': paraBirimi,
      'vade_tarihi': vadeTarihi.toIso8601String(),
      'aciklama': aciklama,
      'odendi': odendi ? 1 : 0,
      'odenme_tarihi': odenmeTarihi?.toIso8601String(),
      'alarm_aktif': alarmAktif ? 1 : 0,
      'alarm_gun_once': alarmGunOnce,
    };
  }

  factory YaklasanOdeme.fromMap(Map<String, dynamic> map) {
    return YaklasanOdeme(
      id: map['id'],
      alacakli: map['alacakli'] ?? '',
      tutar: (map['tutar'] ?? 0).toDouble(),
      paraBirimi: map['para_birimi'] ?? 'TL',
      vadeTarihi: DateTime.parse(map['vade_tarihi']),
      aciklama: map['aciklama'],
      odendi: map['odendi'] == 1,
      odenmeTarihi: map['odenme_tarihi'] != null ? DateTime.parse(map['odenme_tarihi']) : null,
      alarmAktif: map['alarm_aktif'] == 1,
      alarmGunOnce: map['alarm_gun_once'],
    );
  }

  YaklasanOdeme copyWith({
    int? id,
    String? alacakli,
    double? tutar,
    String? paraBirimi,
    DateTime? vadeTarihi,
    String? aciklama,
    bool? odendi,
    DateTime? odenmeTarihi,
    bool? alarmAktif,
    int? alarmGunOnce,
  }) {
    return YaklasanOdeme(
      id: id ?? this.id,
      alacakli: alacakli ?? this.alacakli,
      tutar: tutar ?? this.tutar,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      vadeTarihi: vadeTarihi ?? this.vadeTarihi,
      aciklama: aciklama ?? this.aciklama,
      odendi: odendi ?? this.odendi,
      odenmeTarihi: odenmeTarihi ?? this.odenmeTarihi,
      alarmAktif: alarmAktif ?? this.alarmAktif,
      alarmGunOnce: alarmGunOnce ?? this.alarmGunOnce,
    );
  }

  /// Vadeye kalan gün
  int get vadeKalanGun {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final vade = DateTime(vadeTarihi.year, vadeTarihi.month, vadeTarihi.day);
    return vade.difference(today).inDays;
  }

  /// Vade durumu
  String get vadeDurumu {
    if (odendi) return 'Ödendi';
    final kalan = vadeKalanGun;
    if (kalan < 0) return 'Gecikmiş (${-kalan} gün)';
    if (kalan == 0) return 'Bugün!';
    if (kalan == 1) return 'Yarın';
    return '$kalan gün kaldı';
  }

  /// Vade rengi
  bool get gecikmisMi => !odendi && vadeKalanGun < 0;
  bool get bugunMu => !odendi && vadeKalanGun == 0;
  bool get yakinMi => !odendi && vadeKalanGun > 0 && vadeKalanGun <= 3;

  /// Para birimi sembolü
  String get paraBirimiSembol {
    switch (paraBirimi) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return '₺';
    }
  }
}
