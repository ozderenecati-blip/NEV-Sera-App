/// Gübre birimi
enum GubreBirim {
  kg,
  gram,
  litre,
}

/// Reçete kalemi — bir tankta kullanılacak gübre ve miktarı
class ReceteKalemi {
  final String gubreAdi;
  final double miktar; // birim miktar (1x)
  final GubreBirim birim;

  ReceteKalemi({
    required this.gubreAdi,
    required this.miktar,
    this.birim = GubreBirim.kg,
  });

  String get birimLabel => switch (birim) {
        GubreBirim.kg => 'kg',
        GubreBirim.gram => 'g',
        GubreBirim.litre => 'lt',
      };

  Map<String, dynamic> toMap() => {
        'gubre_adi': gubreAdi,
        'miktar': miktar,
        'birim': birim.name,
      };

  factory ReceteKalemi.fromMap(Map<String, dynamic> map) => ReceteKalemi(
        gubreAdi: map['gubre_adi'] ?? '',
        miktar: (map['miktar'] as num?)?.toDouble() ?? 0,
        birim: GubreBirim.values.firstWhere(
          (b) => b.name == (map['birim'] ?? 'kg'),
          orElse: () => GubreBirim.kg,
        ),
      );

  ReceteKalemi copyWith({String? gubreAdi, double? miktar, GubreBirim? birim}) =>
      ReceteKalemi(
        gubreAdi: gubreAdi ?? this.gubreAdi,
        miktar: miktar ?? this.miktar,
        birim: birim ?? this.birim,
      );
}

/// Gübre tankı — bahçedeki otomasyon tankı
class GubreTank {
  final String? id;
  final String bahceId;
  final String bahceAdi;
  final String ad; // A, B, C, D, E ...
  final double hacim; // litre cinsinden
  final List<ReceteKalemi> recete; // birim reçete
  final DateTime olusturmaTarihi;

  GubreTank({
    this.id,
    required this.bahceId,
    required this.bahceAdi,
    required this.ad,
    this.hacim = 0,
    this.recete = const [],
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'bahce_id': bahceId,
        'bahce_adi': bahceAdi,
        'ad': ad,
        'hacim': hacim,
        'recete': recete.map((r) => r.toMap()).toList(),
        'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
      };

  factory GubreTank.fromMap(Map<String, dynamic> map, {String? docId}) =>
      GubreTank(
        id: docId ?? map['id']?.toString(),
        bahceId: map['bahce_id'] ?? '',
        bahceAdi: map['bahce_adi'] ?? '',
        ad: map['ad'] ?? '',
        hacim: (map['hacim'] as num?)?.toDouble() ?? 0,
        recete: (map['recete'] as List<dynamic>?)
                ?.map((r) => ReceteKalemi.fromMap(r as Map<String, dynamic>))
                .toList() ??
            [],
        olusturmaTarihi: map['olusturma_tarihi'] != null
            ? DateTime.tryParse(map['olusturma_tarihi']) ?? DateTime.now()
            : DateTime.now(),
      );

  GubreTank copyWith({
    String? ad,
    double? hacim,
    List<ReceteKalemi>? recete,
  }) =>
      GubreTank(
        id: id,
        bahceId: bahceId,
        bahceAdi: bahceAdi,
        ad: ad ?? this.ad,
        hacim: hacim ?? this.hacim,
        recete: recete ?? this.recete,
        olusturmaTarihi: olusturmaTarihi,
      );
}

/// Gübre envanteri — bahçedeki mevcut gübre stoğu
class GubreEnvanter {
  final String? id;
  final String bahceId;
  final String bahceAdi;
  final String gubreAdi;
  final double miktar;
  final GubreBirim birim;
  final double uyariSiniri; // bu değerin altına düşünce uyarı verilir
  final String? gorselUrl; // referans görsel URL'i (Firebase Storage)
  final DateTime sonGuncelleme;

  GubreEnvanter({
    this.id,
    required this.bahceId,
    required this.bahceAdi,
    required this.gubreAdi,
    this.miktar = 0,
    this.birim = GubreBirim.kg,
    this.uyariSiniri = 0,
    this.gorselUrl,
    DateTime? sonGuncelleme,
  }) : sonGuncelleme = sonGuncelleme ?? DateTime.now();

  bool get stokDusuk => uyariSiniri > 0 && miktar <= uyariSiniri;

  String get birimLabel => switch (birim) {
        GubreBirim.kg => 'kg',
        GubreBirim.gram => 'g',
        GubreBirim.litre => 'lt',
      };

  Map<String, dynamic> toMap() => {
        'bahce_id': bahceId,
        'bahce_adi': bahceAdi,
        'gubre_adi': gubreAdi,
        'miktar': miktar,
        'birim': birim.name,
        'uyari_siniri': uyariSiniri,
        'gorsel_url': gorselUrl,
        'son_guncelleme': sonGuncelleme.toIso8601String(),
      };

  factory GubreEnvanter.fromMap(Map<String, dynamic> map, {String? docId}) =>
      GubreEnvanter(
        id: docId ?? map['id']?.toString(),
        bahceId: map['bahce_id'] ?? '',
        bahceAdi: map['bahce_adi'] ?? '',
        gubreAdi: map['gubre_adi'] ?? '',
        miktar: (map['miktar'] as num?)?.toDouble() ?? 0,
        birim: GubreBirim.values.firstWhere(
          (b) => b.name == (map['birim'] ?? 'kg'),
          orElse: () => GubreBirim.kg,
        ),
        uyariSiniri: (map['uyari_siniri'] as num?)?.toDouble() ?? 0,
        gorselUrl: map['gorsel_url'] as String?,
        sonGuncelleme: map['son_guncelleme'] != null
            ? DateTime.tryParse(map['son_guncelleme']) ?? DateTime.now()
            : DateTime.now(),
      );

  GubreEnvanter copyWith({
    double? miktar,
    double? uyariSiniri,
    String? gorselUrl,
    bool clearGorsel = false,
  }) =>
      GubreEnvanter(
        id: id,
        bahceId: bahceId,
        bahceAdi: bahceAdi,
        gubreAdi: gubreAdi,
        miktar: miktar ?? this.miktar,
        birim: birim,
        uyariSiniri: uyariSiniri ?? this.uyariSiniri,
        gorselUrl: clearGorsel ? null : (gorselUrl ?? this.gorselUrl),
        sonGuncelleme: DateTime.now(),
      );
}

/// Katlama kaydı — log
class KatlamaKaydi {
  final String? id;
  final String bahceId;
  final String bahceAdi;
  final String tankId;
  final String tankAdi;
  final int katlama; // kaça katlandı
  final List<ReceteKalemi> kullanilanGubreler; // katlama uygulanmış miktarlar
  final String yapanKullaniciId;
  final String yapanKullaniciAdi;
  final DateTime tarih;

  KatlamaKaydi({
    this.id,
    required this.bahceId,
    required this.bahceAdi,
    required this.tankId,
    required this.tankAdi,
    required this.katlama,
    this.kullanilanGubreler = const [],
    required this.yapanKullaniciId,
    required this.yapanKullaniciAdi,
    DateTime? tarih,
  }) : tarih = tarih ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'bahce_id': bahceId,
        'bahce_adi': bahceAdi,
        'tank_id': tankId,
        'tank_adi': tankAdi,
        'katlama': katlama,
        'kullanilan_gubreler':
            kullanilanGubreler.map((r) => r.toMap()).toList(),
        'yapan_kullanici_id': yapanKullaniciId,
        'yapan_kullanici_adi': yapanKullaniciAdi,
        'tarih': tarih.toIso8601String(),
      };

  factory KatlamaKaydi.fromMap(Map<String, dynamic> map, {String? docId}) =>
      KatlamaKaydi(
        id: docId ?? map['id']?.toString(),
        bahceId: map['bahce_id'] ?? '',
        bahceAdi: map['bahce_adi'] ?? '',
        tankId: map['tank_id'] ?? '',
        tankAdi: map['tank_adi'] ?? '',
        katlama: (map['katlama'] as num?)?.toInt() ?? 1,
        kullanilanGubreler: (map['kullanilan_gubreler'] as List<dynamic>?)
                ?.map((r) => ReceteKalemi.fromMap(r as Map<String, dynamic>))
                .toList() ??
            [],
        yapanKullaniciId: map['yapan_kullanici_id'] ?? '',
        yapanKullaniciAdi: map['yapan_kullanici_adi'] ?? '',
        tarih: map['tarih'] != null
            ? DateTime.tryParse(map['tarih']) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Reçete geçmişi — her reçete değişikliğinde kaydedilir
class ReceteGecmisi {
  final String? id;
  final String bahceId;
  final String bahceAdi;
  final String tankId;
  final String tankAdi;
  final List<ReceteKalemi> recete; // o andaki reçete snapshot'ı
  final String degistirenKullaniciId;
  final String degistirenKullaniciAdi;
  final String not; // opsiyonel açıklama
  final DateTime tarih;

  ReceteGecmisi({
    this.id,
    required this.bahceId,
    required this.bahceAdi,
    required this.tankId,
    required this.tankAdi,
    required this.recete,
    required this.degistirenKullaniciId,
    required this.degistirenKullaniciAdi,
    this.not = '',
    DateTime? tarih,
  }) : tarih = tarih ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'bahce_id': bahceId,
        'bahce_adi': bahceAdi,
        'tank_id': tankId,
        'tank_adi': tankAdi,
        'recete': recete.map((r) => r.toMap()).toList(),
        'degistiren_kullanici_id': degistirenKullaniciId,
        'degistiren_kullanici_adi': degistirenKullaniciAdi,
        'not': not,
        'tarih': tarih.toIso8601String(),
      };

  factory ReceteGecmisi.fromMap(Map<String, dynamic> map, {String? docId}) =>
      ReceteGecmisi(
        id: docId ?? map['id']?.toString(),
        bahceId: map['bahce_id'] ?? '',
        bahceAdi: map['bahce_adi'] ?? '',
        tankId: map['tank_id'] ?? '',
        tankAdi: map['tank_adi'] ?? '',
        recete: (map['recete'] as List<dynamic>?)
                ?.map((r) => ReceteKalemi.fromMap(r as Map<String, dynamic>))
                .toList() ??
            [],
        degistirenKullaniciId: map['degistiren_kullanici_id'] ?? '',
        degistirenKullaniciAdi: map['degistiren_kullanici_adi'] ?? '',
        not: map['not'] ?? '',
        tarih: map['tarih'] != null
            ? DateTime.tryParse(map['tarih']) ?? DateTime.now()
            : DateTime.now(),
      );
}
