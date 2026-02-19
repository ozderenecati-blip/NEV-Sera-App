/// Bahçe köşe noktası (kroki çizimi için)
class BahceKose {
  final double x; // metre cinsinden x (kroki)
  final double y; // metre cinsinden y (kroki)
  final double metraj; // bu köşeden sonraki kenara kadar metre
  final double? lat; // GPS enlem
  final double? lng; // GPS boylam
  final double? gpsMetraj; // GPS'e göre hesaplanan mesafe (teyit için)

  BahceKose({
    required this.x,
    required this.y,
    this.metraj = 0,
    this.lat,
    this.lng,
    this.gpsMetraj,
  });

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'metraj': metraj,
        'lat': lat,
        'lng': lng,
        'gps_metraj': gpsMetraj,
      };

  factory BahceKose.fromMap(Map<String, dynamic> map) => BahceKose(
        x: (map['x'] ?? 0).toDouble(),
        y: (map['y'] ?? 0).toDouble(),
        metraj: (map['metraj'] ?? 0).toDouble(),
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        gpsMetraj: (map['gps_metraj'] as num?)?.toDouble(),
      );

  BahceKose copyWith({
    double? x,
    double? y,
    double? metraj,
    double? lat,
    double? lng,
    double? gpsMetraj,
  }) =>
      BahceKose(
        x: x ?? this.x,
        y: y ?? this.y,
        metraj: metraj ?? this.metraj,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        gpsMetraj: gpsMetraj ?? this.gpsMetraj,
      );
}

/// Saksı modeli
class Saksi {
  final String? id;
  final int numara;
  final String? cins; // bitkinin cinsi
  final String? durum; // bos, dikili, hasat, hasta vb.
  final String? not;

  Saksi({
    this.id,
    required this.numara,
    this.cins,
    this.durum = 'bos',
    this.not,
  });

  Map<String, dynamic> toMap() => {
        'numara': numara,
        'cins': cins,
        'durum': durum,
        'not': not,
      };

  factory Saksi.fromMap(Map<String, dynamic> map, {String? docId}) => Saksi(
        id: docId ?? map['id']?.toString(),
        numara: map['numara'] ?? 0,
        cins: map['cins'],
        durum: map['durum'] ?? 'bos',
        not: map['not'],
      );

  Saksi copyWith({String? cins, String? durum, String? not}) => Saksi(
        id: id,
        numara: numara,
        cins: cins ?? this.cins,
        durum: durum ?? this.durum,
        not: not ?? this.not,
      );
}

/// Sıra modeli (bir parsel içindeki sıra)
class Sira {
  final String? id;
  final int numara;
  final int saksiSayisi;
  final double uzunluk; // metre cinsinden sıra uzunluğu (otomatik hesaplanan)
  final String? cins; // tüm sıraya toplu cins
  final List<Saksi> saksilar;

  Sira({
    this.id,
    required this.numara,
    required this.saksiSayisi,
    this.uzunluk = 0,
    this.cins,
    this.saksilar = const [],
  });

  Map<String, dynamic> toMap() => {
        'numara': numara,
        'saksi_sayisi': saksiSayisi,
        'uzunluk': uzunluk,
        'cins': cins,
        'saksilar': saksilar.map((s) => s.toMap()).toList(),
      };

  factory Sira.fromMap(Map<String, dynamic> map, {String? docId}) {
    final saksiList = (map['saksilar'] as List<dynamic>?)
            ?.map((s) => Saksi.fromMap(s as Map<String, dynamic>))
            .toList() ??
        [];
    return Sira(
      id: docId ?? map['id']?.toString(),
      numara: map['numara'] ?? 0,
      saksiSayisi: map['saksi_sayisi'] ?? 0,
      uzunluk: (map['uzunluk'] as num?)?.toDouble() ?? 0,
      cins: map['cins'],
      saksilar: saksiList,
    );
  }

  Sira copyWith({String? cins, int? saksiSayisi, double? uzunluk, List<Saksi>? saksilar}) =>
      Sira(
        id: id,
        numara: numara,
        saksiSayisi: saksiSayisi ?? this.saksiSayisi,
        uzunluk: uzunluk ?? this.uzunluk,
        cins: cins ?? this.cins,
        saksilar: saksilar ?? this.saksilar,
      );
}

/// Parsel modeli (bahçe içindeki bölüm)
class Parsel {
  final String? id;
  final String ad;
  final int siraSayisi;
  final int siraBasinaSaksi;
  final String? cins;
  final List<Sira> siralar;
  final String? not;
  final List<BahceKose> koseler; // parsel sınır köşeleri
  final double siraAraligi; // metre cinsinden sıra aralığı
  final double saksiAraligi; // metre cinsinden saksı aralığı
  final double? siraAcisi; // sıraların yönü (derece, 0=yatay, 90=dikey)

  Parsel({
    this.id,
    required this.ad,
    required this.siraSayisi,
    required this.siraBasinaSaksi,
    this.cins,
    this.siralar = const [],
    this.not,
    this.koseler = const [],
    this.siraAraligi = 1.0,
    this.saksiAraligi = 0.4,
    this.siraAcisi,
  });

  int get toplamSaksi => siralar.isEmpty
      ? siraSayisi * siraBasinaSaksi
      : siralar.fold(0, (sum, s) => sum + s.saksiSayisi);

  Map<String, dynamic> toMap() => {
        'ad': ad,
        'sira_sayisi': siraSayisi,
        'sira_basina_saksi': siraBasinaSaksi,
        'cins': cins,
        'siralar': siralar.map((s) => s.toMap()).toList(),
        'not': not,
        'koseler': koseler.map((k) => k.toMap()).toList(),
        'sira_araligi': siraAraligi,
        'saksi_araligi': saksiAraligi,
        'sira_acisi': siraAcisi,
      };

  factory Parsel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final siraList = (map['siralar'] as List<dynamic>?)
            ?.map((s) => Sira.fromMap(s as Map<String, dynamic>))
            .toList() ??
        [];
    final koseList = (map['koseler'] as List<dynamic>?)
            ?.map((k) => BahceKose.fromMap(k as Map<String, dynamic>))
            .toList() ??
        [];
    return Parsel(
      id: docId ?? map['id']?.toString(),
      ad: map['ad'] ?? '',
      siraSayisi: map['sira_sayisi'] ?? 0,
      siraBasinaSaksi: map['sira_basina_saksi'] ?? 0,
      cins: map['cins'],
      siralar: siraList,
      not: map['not'],
      koseler: koseList,
      siraAraligi: (map['sira_araligi'] as num?)?.toDouble() ?? 1.0,
      saksiAraligi: (map['saksi_araligi'] as num?)?.toDouble() ?? 0.4,
      siraAcisi: (map['sira_acisi'] as num?)?.toDouble(),
    );
  }

  Parsel copyWith({
    String? ad,
    int? siraSayisi,
    int? siraBasinaSaksi,
    String? cins,
    List<Sira>? siralar,
    String? not,
    List<BahceKose>? koseler,
    double? siraAraligi,
    double? saksiAraligi,
    double? siraAcisi,
  }) =>
      Parsel(
        id: id,
        ad: ad ?? this.ad,
        siraSayisi: siraSayisi ?? this.siraSayisi,
        siraBasinaSaksi: siraBasinaSaksi ?? this.siraBasinaSaksi,
        cins: cins ?? this.cins,
        siralar: siralar ?? this.siralar,
        not: not ?? this.not,
        koseler: koseler ?? this.koseler,
        siraAraligi: siraAraligi ?? this.siraAraligi,
        saksiAraligi: saksiAraligi ?? this.saksiAraligi,
        siraAcisi: siraAcisi ?? this.siraAcisi,
      );
}

/// Bahçe modeli (ana yapı)
class Bahce {
  final String? id;
  final String ad;
  final String? konum;
  final List<BahceKose> koseler; // kroki köşe noktaları
  final List<Parsel> parseller;
  final double? toplamAlan; // m²
  final String? not;
  final DateTime olusturmaTarihi;

  Bahce({
    this.id,
    required this.ad,
    this.konum,
    this.koseler = const [],
    this.parseller = const [],
    this.toplamAlan,
    this.not,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  int get toplamParsel => parseller.length;
  int get toplamSira =>
      parseller.fold(0, (sum, p) => sum + p.siraSayisi);
  int get toplamSaksi =>
      parseller.fold(0, (sum, p) => sum + p.toplamSaksi);

  Map<String, dynamic> toMap() => {
        'ad': ad,
        'konum': konum,
        'koseler': koseler.map((k) => k.toMap()).toList(),
        'parseller': parseller.map((p) => p.toMap()).toList(),
        'toplam_alan': toplamAlan,
        'not': not,
        'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
      };

  factory Bahce.fromMap(Map<String, dynamic> map, {String? docId}) {
    final koseList = (map['koseler'] as List<dynamic>?)
            ?.map((k) => BahceKose.fromMap(k as Map<String, dynamic>))
            .toList() ??
        [];
    final parselList = (map['parseller'] as List<dynamic>?)
            ?.map((p) => Parsel.fromMap(p as Map<String, dynamic>))
            .toList() ??
        [];
    return Bahce(
      id: docId ?? map['id']?.toString(),
      ad: map['ad'] ?? '',
      konum: map['konum'],
      koseler: koseList,
      parseller: parselList,
      toplamAlan: (map['toplam_alan'] as num?)?.toDouble(),
      not: map['not'],
      olusturmaTarihi: map['olusturma_tarihi'] != null
          ? DateTime.tryParse(map['olusturma_tarihi']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Bahce copyWith({
    String? ad,
    String? konum,
    List<BahceKose>? koseler,
    List<Parsel>? parseller,
    double? toplamAlan,
    String? not,
  }) =>
      Bahce(
        id: id,
        ad: ad ?? this.ad,
        konum: konum ?? this.konum,
        koseler: koseler ?? this.koseler,
        parseller: parseller ?? this.parseller,
        toplamAlan: toplamAlan ?? this.toplamAlan,
        not: not ?? this.not,
        olusturmaTarihi: olusturmaTarihi,
      );
}
