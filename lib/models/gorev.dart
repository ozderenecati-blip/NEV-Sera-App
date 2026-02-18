/// Görev öncelik seviyesi
enum GorevOncelik {
  acil,
  normal,
  dusuk,
}

/// Görev tekrar tipi
enum GorevTekrar {
  tekSefer,
  gunluk,
  haftalik,
  aylik,
}

/// Görev durumu
enum GorevDurum {
  beklemede,
  devamEdiyor,
  tamamlandi,
  iptalEdildi,
}

class Gorev {
  final String? id;
  final String baslik;
  final String? aciklama;
  final GorevOncelik oncelik;
  final GorevTekrar tekrar;
  final GorevDurum durum;
  final String? atananKullaniciId;
  final String? atananKullaniciAdi;
  final String? atayan; // atayan kişinin adı
  final String? bahceId;
  final String? bahceAdi;
  final String? parselAdi;
  final DateTime baslangicTarihi;
  final DateTime? bitisTarihi;
  final DateTime? tamamlanmaTarihi;
  final String? tamamlayanNot;
  final List<String> fotograflar; // fotoğraf URL'leri
  final DateTime olusturmaTarihi;

  Gorev({
    this.id,
    required this.baslik,
    this.aciklama,
    this.oncelik = GorevOncelik.normal,
    this.tekrar = GorevTekrar.tekSefer,
    this.durum = GorevDurum.beklemede,
    this.atananKullaniciId,
    this.atananKullaniciAdi,
    this.atayan,
    this.bahceId,
    this.bahceAdi,
    this.parselAdi,
    required this.baslangicTarihi,
    this.bitisTarihi,
    this.tamamlanmaTarihi,
    this.tamamlayanNot,
    this.fotograflar = const [],
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  /// 3 gün içinde mi?
  bool get yaklasan {
    final fark = baslangicTarihi.difference(DateTime.now()).inDays;
    return fark >= 0 && fark <= 3 && durum == GorevDurum.beklemede;
  }

  bool get gecmis =>
      baslangicTarihi.isBefore(DateTime.now()) &&
      durum == GorevDurum.beklemede;

  String get oncelikLabel => switch (oncelik) {
        GorevOncelik.acil => '🔴 Acil',
        GorevOncelik.normal => '🟡 Normal',
        GorevOncelik.dusuk => '🟢 Düşük',
      };

  String get durumLabel => switch (durum) {
        GorevDurum.beklemede => 'Beklemede',
        GorevDurum.devamEdiyor => 'Devam Ediyor',
        GorevDurum.tamamlandi => 'Tamamlandı',
        GorevDurum.iptalEdildi => 'İptal Edildi',
      };

  String get tekrarLabel => switch (tekrar) {
        GorevTekrar.tekSefer => 'Tek Sefer',
        GorevTekrar.gunluk => 'Günlük',
        GorevTekrar.haftalik => 'Haftalık',
        GorevTekrar.aylik => 'Aylık',
      };

  Map<String, dynamic> toMap() => {
        'baslik': baslik,
        'aciklama': aciklama,
        'oncelik': oncelik.name,
        'tekrar': tekrar.name,
        'durum': durum.name,
        'atanan_kullanici_id': atananKullaniciId,
        'atanan_kullanici_adi': atananKullaniciAdi,
        'atayan': atayan,
        'bahce_id': bahceId,
        'bahce_adi': bahceAdi,
        'parsel_adi': parselAdi,
        'baslangic_tarihi': baslangicTarihi.toIso8601String(),
        'bitis_tarihi': bitisTarihi?.toIso8601String(),
        'tamamlanma_tarihi': tamamlanmaTarihi?.toIso8601String(),
        'tamamlayan_not': tamamlayanNot,
        'fotograflar': fotograflar,
        'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
      };

  factory Gorev.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Gorev(
      id: docId ?? map['id']?.toString(),
      baslik: map['baslik'] ?? '',
      aciklama: map['aciklama'],
      oncelik: GorevOncelik.values.firstWhere(
        (e) => e.name == (map['oncelik'] ?? 'normal'),
        orElse: () => GorevOncelik.normal,
      ),
      tekrar: GorevTekrar.values.firstWhere(
        (e) => e.name == (map['tekrar'] ?? 'tekSefer'),
        orElse: () => GorevTekrar.tekSefer,
      ),
      durum: GorevDurum.values.firstWhere(
        (e) => e.name == (map['durum'] ?? 'beklemede'),
        orElse: () => GorevDurum.beklemede,
      ),
      atananKullaniciId: map['atanan_kullanici_id'],
      atananKullaniciAdi: map['atanan_kullanici_adi'],
      atayan: map['atayan'],
      bahceId: map['bahce_id'],
      bahceAdi: map['bahce_adi'],
      parselAdi: map['parsel_adi'],
      baslangicTarihi: map['baslangic_tarihi'] != null
          ? DateTime.tryParse(map['baslangic_tarihi']) ?? DateTime.now()
          : DateTime.now(),
      bitisTarihi: map['bitis_tarihi'] != null
          ? DateTime.tryParse(map['bitis_tarihi'])
          : null,
      tamamlanmaTarihi: map['tamamlanma_tarihi'] != null
          ? DateTime.tryParse(map['tamamlanma_tarihi'])
          : null,
      tamamlayanNot: map['tamamlayan_not'],
      fotograflar: List<String>.from(map['fotograflar'] ?? []),
      olusturmaTarihi: map['olusturma_tarihi'] != null
          ? DateTime.tryParse(map['olusturma_tarihi']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Gorev copyWith({
    String? baslik,
    String? aciklama,
    GorevOncelik? oncelik,
    GorevTekrar? tekrar,
    GorevDurum? durum,
    String? atananKullaniciId,
    String? atananKullaniciAdi,
    String? atayan,
    String? bahceId,
    String? bahceAdi,
    String? parselAdi,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    DateTime? tamamlanmaTarihi,
    String? tamamlayanNot,
    List<String>? fotograflar,
  }) =>
      Gorev(
        id: id,
        baslik: baslik ?? this.baslik,
        aciklama: aciklama ?? this.aciklama,
        oncelik: oncelik ?? this.oncelik,
        tekrar: tekrar ?? this.tekrar,
        durum: durum ?? this.durum,
        atananKullaniciId: atananKullaniciId ?? this.atananKullaniciId,
        atananKullaniciAdi: atananKullaniciAdi ?? this.atananKullaniciAdi,
        atayan: atayan ?? this.atayan,
        bahceId: bahceId ?? this.bahceId,
        bahceAdi: bahceAdi ?? this.bahceAdi,
        parselAdi: parselAdi ?? this.parselAdi,
        baslangicTarihi: baslangicTarihi ?? this.baslangicTarihi,
        bitisTarihi: bitisTarihi ?? this.bitisTarihi,
        tamamlanmaTarihi: tamamlanmaTarihi ?? this.tamamlanmaTarihi,
        tamamlayanNot: tamamlayanNot ?? this.tamamlayanNot,
        fotograflar: fotograflar ?? this.fotograflar,
        olusturmaTarihi: olusturmaTarihi,
      );
}
