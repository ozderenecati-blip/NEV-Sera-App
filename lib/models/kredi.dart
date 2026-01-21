class Kredi {
  final int? id;
  final String krediId;
  final String bankaAd;
  final String? kasa;
  final double cekilenTutar;
  final double faizOrani;
  final int vadeAy;
  final String taksitTipi;
  final int odemeSikligiAy;
  final double? kkdfOrani;
  final double? bsmvOrani;
  final String faizGirisiTuru;
  final String paraBirimi;
  final DateTime baslangicTarihi;
  final List<KrediTaksit> taksitler;

  Kredi({
    this.id,
    required this.krediId,
    required this.bankaAd,
    this.kasa,
    required this.cekilenTutar,
    this.faizOrani = 0,
    this.vadeAy = 12,
    this.taksitTipi = 'Eşit Taksit',
    this.odemeSikligiAy = 1,
    this.kkdfOrani,
    this.bsmvOrani,
    this.faizGirisiTuru = 'Yıllık',
    this.paraBirimi = 'TL',
    DateTime? baslangicTarihi,
    List<KrediTaksit>? taksitler,
  }) : baslangicTarihi = baslangicTarihi ?? DateTime.now(),
       taksitler = taksitler ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kredi_id': krediId,
      'banka_ad': bankaAd,
      'kasa': kasa,
      'cekilen_tutar': cekilenTutar,
      'faiz_orani': faizOrani,
      'vade_ay': vadeAy,
      'taksit_tipi': taksitTipi,
      'odeme_sikligi_ay': odemeSikligiAy,
      'kkdf_orani': kkdfOrani,
      'bsmv_orani': bsmvOrani,
      'faiz_girisi_turu': faizGirisiTuru,
      'para_birimi': paraBirimi,
      'baslangic_tarihi': baslangicTarihi.toIso8601String(),
    };
  }

  factory Kredi.fromMap(Map<String, dynamic> map, {List<KrediTaksit>? taksitler}) {
    return Kredi(
      id: map['id'],
      krediId: map['kredi_id'] ?? '',
      bankaAd: map['banka_ad'] ?? '',
      kasa: map['kasa'],
      cekilenTutar: (map['cekilen_tutar'] ?? 0).toDouble(),
      faizOrani: (map['faiz_orani'] ?? 0).toDouble(),
      vadeAy: map['vade_ay'] ?? 12,
      taksitTipi: map['taksit_tipi'] ?? 'Eşit Taksit',
      odemeSikligiAy: map['odeme_sikligi_ay'] ?? 1,
      kkdfOrani: map['kkdf_orani']?.toDouble(),
      bsmvOrani: map['bsmv_orani']?.toDouble(),
      faizGirisiTuru: map['faiz_girisi_turu'] ?? 'Yıllık',
      paraBirimi: map['para_birimi'] ?? 'TL',
      baslangicTarihi: map['baslangic_tarihi'] != null 
          ? DateTime.parse(map['baslangic_tarihi']) 
          : DateTime.now(),
      taksitler: taksitler,
    );
  }

  Kredi copyWith({
    int? id,
    String? krediId,
    String? bankaAd,
    String? kasa,
    double? cekilenTutar,
    double? faizOrani,
    int? vadeAy,
    String? taksitTipi,
    int? odemeSikligiAy,
    double? kkdfOrani,
    double? bsmvOrani,
    String? faizGirisiTuru,
    String? paraBirimi,
    DateTime? baslangicTarihi,
    List<KrediTaksit>? taksitler,
  }) {
    return Kredi(
      id: id ?? this.id,
      krediId: krediId ?? this.krediId,
      bankaAd: bankaAd ?? this.bankaAd,
      kasa: kasa ?? this.kasa,
      cekilenTutar: cekilenTutar ?? this.cekilenTutar,
      faizOrani: faizOrani ?? this.faizOrani,
      vadeAy: vadeAy ?? this.vadeAy,
      taksitTipi: taksitTipi ?? this.taksitTipi,
      odemeSikligiAy: odemeSikligiAy ?? this.odemeSikligiAy,
      kkdfOrani: kkdfOrani ?? this.kkdfOrani,
      bsmvOrani: bsmvOrani ?? this.bsmvOrani,
      faizGirisiTuru: faizGirisiTuru ?? this.faizGirisiTuru,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      baslangicTarihi: baslangicTarihi ?? this.baslangicTarihi,
      taksitler: taksitler ?? this.taksitler,
    );
  }
}

class KrediTaksit {
  final int? id;
  final int krediDbId;
  final int periyot;
  final DateTime vadeTarihi;
  final double anapara;
  final double faiz;
  final double bsmv;
  final double kkdf;
  final double toplamTaksit;
  final double kalanBakiye;
  final bool odendi;

  KrediTaksit({
    this.id,
    required this.krediDbId,
    required this.periyot,
    required this.vadeTarihi,
    required this.anapara,
    this.faiz = 0,
    this.bsmv = 0,
    this.kkdf = 0,
    required this.toplamTaksit,
    required this.kalanBakiye,
    this.odendi = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kredi_db_id': krediDbId,
      'periyot': periyot,
      'vade_tarihi': vadeTarihi.toIso8601String(),
      'anapara': anapara,
      'faiz': faiz,
      'bsmv': bsmv,
      'kkdf': kkdf,
      'toplam_taksit': toplamTaksit,
      'kalan_bakiye': kalanBakiye,
      'odendi': odendi ? 1 : 0,
    };
  }

  factory KrediTaksit.fromMap(Map<String, dynamic> map) {
    return KrediTaksit(
      id: map['id'],
      krediDbId: map['kredi_db_id'] ?? 0,
      periyot: map['periyot'] ?? 0,
      vadeTarihi: DateTime.parse(map['vade_tarihi']),
      anapara: (map['anapara'] ?? 0).toDouble(),
      faiz: (map['faiz'] ?? 0).toDouble(),
      bsmv: (map['bsmv'] ?? 0).toDouble(),
      kkdf: (map['kkdf'] ?? 0).toDouble(),
      toplamTaksit: (map['toplam_taksit'] ?? 0).toDouble(),
      kalanBakiye: (map['kalan_bakiye'] ?? 0).toDouble(),
      odendi: map['odendi'] == 1,
    );
  }
}
