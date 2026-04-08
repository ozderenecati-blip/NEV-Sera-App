/// Günlük iş rapor kalemi
class IsKalemi {
  final String aciklama;
  final String? bahceAdi;
  final String? parselAdi;
  final String? kategori; // sulama, budama, ilaçlama, dikim, hasat, bakım, diğer
  final double? sure; // saat cinsinden
  final List<String> fotograflar;

  IsKalemi({
    required this.aciklama,
    this.bahceAdi,
    this.parselAdi,
    this.kategori,
    this.sure,
    this.fotograflar = const [],
  });

  Map<String, dynamic> toMap() => {
        'aciklama': aciklama,
        'bahce_adi': bahceAdi,
        'parsel_adi': parselAdi,
        'kategori': kategori,
        'sure': sure,
        'fotograflar': fotograflar,
      };

  factory IsKalemi.fromMap(Map<String, dynamic> map) => IsKalemi(
        aciklama: map['aciklama'] ?? '',
        bahceAdi: map['bahce_adi'],
        parselAdi: map['parsel_adi'],
        kategori: map['kategori'],
        sure: (map['sure'] as num?)?.toDouble(),
        fotograflar: List<String>.from(map['fotograflar'] ?? []),
      );
}

/// Günlük iş raporu
class DailyWorkReport {
  final String? id;
  final String kullaniciId;
  final String kullaniciAdi;
  final DateTime tarih;
  final String? bahceId;
  final String? bahceAdi;
  final List<IsKalemi> isler;
  final String? genelNot;
  final bool onaylandi; // admin verify
  final String? onaylayanId;
  final String? onaylayanAdi;
  final DateTime? onayTarihi;
  final DateTime olusturmaTarihi;

  DailyWorkReport({
    this.id,
    required this.kullaniciId,
    required this.kullaniciAdi,
    required this.tarih,
    this.bahceId,
    this.bahceAdi,
    this.isler = const [],
    this.genelNot,
    this.onaylandi = false,
    this.onaylayanId,
    this.onaylayanAdi,
    this.onayTarihi,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  /// Rapor kilitli mi? (onaylandıysa değiştirilemez)
  bool get kilitli => onaylandi;

  /// Toplam çalışma süresi (saat)
  double get toplamSure =>
      isler.fold(0.0, (sum, is_) => sum + (is_.sure ?? 0));

  /// Tarih anahtarı (yyyy-MM-dd) — aynı gün için tekil rapor
  String get tarihKey =>
      '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'kullanici_id': kullaniciId,
        'kullanici_adi': kullaniciAdi,
        'tarih': tarih.toIso8601String(),
        'bahce_id': bahceId,
        'bahce_adi': bahceAdi,
        'isler': isler.map((i) => i.toMap()).toList(),
        'genel_not': genelNot,
        'onaylandi': onaylandi,
        'onaylayan_id': onaylayanId,
        'onaylayan_adi': onaylayanAdi,
        'onay_tarihi': onayTarihi?.toIso8601String(),
        'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
      };

  factory DailyWorkReport.fromMap(Map<String, dynamic> map, {String? docId}) {
    final islerList = (map['isler'] as List<dynamic>?)
            ?.map((i) => IsKalemi.fromMap(i as Map<String, dynamic>))
            .toList() ??
        [];
    return DailyWorkReport(
      id: docId ?? map['id']?.toString(),
      kullaniciId: map['kullanici_id'] ?? '',
      kullaniciAdi: map['kullanici_adi'] ?? '',
      tarih: map['tarih'] != null
          ? DateTime.tryParse(map['tarih']) ?? DateTime.now()
          : DateTime.now(),
      bahceId: map['bahce_id'],
      bahceAdi: map['bahce_adi'],
      isler: islerList,
      genelNot: map['genel_not'],
      onaylandi: map['onaylandi'] ?? false,
      onaylayanId: map['onaylayan_id'],
      onaylayanAdi: map['onaylayan_adi'],
      onayTarihi: map['onay_tarihi'] != null
          ? DateTime.tryParse(map['onay_tarihi'])
          : null,
      olusturmaTarihi: map['olusturma_tarihi'] != null
          ? DateTime.tryParse(map['olusturma_tarihi']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DailyWorkReport copyWith({
    String? bahceId,
    String? bahceAdi,
    List<IsKalemi>? isler,
    String? genelNot,
    bool? onaylandi,
    String? onaylayanId,
    String? onaylayanAdi,
    DateTime? onayTarihi,
  }) =>
      DailyWorkReport(
        id: id,
        kullaniciId: kullaniciId,
        kullaniciAdi: kullaniciAdi,
        tarih: tarih,
        bahceId: bahceId ?? this.bahceId,
        bahceAdi: bahceAdi ?? this.bahceAdi,
        isler: isler ?? this.isler,
        genelNot: genelNot ?? this.genelNot,
        onaylandi: onaylandi ?? this.onaylandi,
        onaylayanId: onaylayanId ?? this.onaylayanId,
        onaylayanAdi: onaylayanAdi ?? this.onaylayanAdi,
        onayTarihi: onayTarihi ?? this.onayTarihi,
        olusturmaTarihi: olusturmaTarihi,
      );
}
