import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/kasa_hareketi.dart';
import '../models/kredi.dart';
import '../models/gundelikci.dart';
import '../models/ortak.dart';
import '../models/musteri.dart';
import '../models/satis.dart';
import '../models/settings.dart';
import '../models/yaklasan_odeme.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const int _dbVersion = 8; // v8: müşteriler ve satışlar tablosu düzeltme

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'nev_seracilik_v8.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
    if (oldVersion < 5) {
      await _migrateToV5(db);
    }
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
    if (oldVersion < 7) {
      await _migrateToV7(db);
    }
    if (oldVersion < 8) {
      await _migrateToV7(db); // v7 tablolarını yeniden oluştur
    }
  }

  Future<void> _migrateToV4(Database db) async {
    try {
      await db.execute('ALTER TABLE kasa_hareketleri ADD COLUMN para_birimi TEXT DEFAULT "TL"');
      await db.execute('ALTER TABLE kasa_hareketleri ADD COLUMN doviz_kuru REAL');
      await db.execute('ALTER TABLE kasa_hareketleri ADD COLUMN tl_karsiligi REAL');
    } catch (e) {
      print('Migration v4: $e');
    }
  }

  Future<void> _migrateToV5(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS yaklasan_odemeler (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          alacakli TEXT NOT NULL,
          tutar REAL NOT NULL,
          para_birimi TEXT DEFAULT 'TL',
          vade_tarihi TEXT NOT NULL,
          aciklama TEXT,
          odendi INTEGER DEFAULT 0,
          odenme_tarihi TEXT,
          alarm_aktif INTEGER DEFAULT 1,
          alarm_gun_once INTEGER DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } catch (e) {
      print('Migration v5: $e');
    }
  }

  Future<void> _migrateToV6(Database db) async {
    try {
      // Ortaklar tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ortaklar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ad_soyad TEXT NOT NULL,
          tc_no TEXT,
          telefon TEXT,
          adres TEXT,
          stopaj_orani REAL DEFAULT 15.0,
          aktif INTEGER DEFAULT 1,
          notlar TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // app_settings tablosuna ortak_id kolonu ekle (kasa-ortak ilişkisi için)
      await db.execute('ALTER TABLE app_settings ADD COLUMN ortak_id INTEGER');
      
      // Varsayılan ortakları ekle (mevcut kasa sahipleri)
      await db.insert('ortaklar', {
        'ad_soyad': 'Mert Anter',
        'stopaj_orani': 15.0,
        'aktif': 1
      });
      await db.insert('ortaklar', {
        'ad_soyad': 'Necati Özdere',
        'stopaj_orani': 15.0,
        'aktif': 1
      });
    } catch (e) {
      print('Migration v6: $e');
    }
  }

  Future<void> _migrateToV7(Database db) async {
    try {
      // Müşteriler tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS musteriler (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          unvan TEXT NOT NULL,
          yetkili_kisi TEXT,
          vergi_no TEXT,
          vergi_dairesi TEXT,
          telefon TEXT,
          email TEXT,
          adres TEXT,
          sehir TEXT,
          musteri_tipi TEXT DEFAULT 'bireysel',
          vade_gunu REAL DEFAULT 0,
          aktif INTEGER DEFAULT 1,
          notlar TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Satışlar tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS satislar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          musteri_id INTEGER NOT NULL,
          tarih TEXT NOT NULL,
          urun_adi TEXT NOT NULL,
          miktar REAL NOT NULL,
          birim TEXT DEFAULT 'kg',
          birim_fiyat REAL NOT NULL,
          toplam_tutar REAL NOT NULL,
          para_birimi TEXT DEFAULT 'TL',
          doviz_kuru REAL,
          tl_karsiligi REAL,
          komisyon_orani REAL,
          komisyon_tutari REAL,
          vade_tarihi TEXT,
          fatura_no TEXT,
          irsaliye_no TEXT,
          aciklama TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (musteri_id) REFERENCES musteriler(id)
        )
      ''');
      
      // Tahsilatlar tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tahsilatlar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          musteri_id INTEGER NOT NULL,
          tarih TEXT NOT NULL,
          tutar REAL NOT NULL,
          para_birimi TEXT DEFAULT 'TL',
          doviz_kuru REAL,
          tl_karsiligi REAL,
          odeme_sekli TEXT DEFAULT 'nakit',
          kasa_adi TEXT,
          cek_senet_no TEXT,
          cek_vade_tarihi TEXT,
          banka_adi TEXT,
          aciklama TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (musteri_id) REFERENCES musteriler(id)
        )
      ''');
    } catch (e) {
      print('Migration v7: $e');
    }
  }
  Future<void> _createDB(Database db, int version) async {
    // Kasa Hareketleri tablosu - TÜM işlemler burada
    await db.execute('''
      CREATE TABLE kasa_hareketleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarih TEXT NOT NULL,
        aciklama TEXT NOT NULL,
        islem_tipi TEXT NOT NULL,
        tutar REAL NOT NULL,
        odeme_bicimi TEXT,
        kasa TEXT,
        notlar TEXT,
        parasut INTEGER DEFAULT 0,
        para_birimi TEXT DEFAULT 'TL',
        doviz_kuru REAL,
        tl_karsiligi REAL,
        islem_kaynagi TEXT DEFAULT 'kasa',
        iliskili_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Gündelikçiler tablosu
    await db.execute('''
      CREATE TABLE gundelikciler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad_soyad TEXT NOT NULL,
        tc_no TEXT,
        adres TEXT,
        telefon TEXT,
        aktif INTEGER DEFAULT 1
      )
    ''');

    // Krediler tablosu
    await db.execute('''
      CREATE TABLE krediler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kredi_id TEXT NOT NULL,
        banka_ad TEXT NOT NULL,
        kasa TEXT,
        cekilen_tutar REAL NOT NULL,
        faiz_orani REAL DEFAULT 0,
        vade_ay INTEGER NOT NULL,
        baslangic_tarihi TEXT NOT NULL,
        taksit_tipi TEXT NOT NULL,
        odeme_sikligi_ay INTEGER DEFAULT 1,
        kkdf_orani REAL DEFAULT 0,
        bsmv_orani REAL DEFAULT 0,
        faiz_girisi_turu TEXT DEFAULT 'Yıllık',
        para_birimi TEXT DEFAULT 'TL',
        notlar TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Kredi Taksitleri tablosu
    await db.execute('''
      CREATE TABLE kredi_taksitleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kredi_db_id INTEGER NOT NULL,
        periyot INTEGER NOT NULL,
        vade_tarihi TEXT NOT NULL,
        anapara REAL NOT NULL,
        faiz REAL DEFAULT 0,
        bsmv REAL DEFAULT 0,
        kkdf REAL DEFAULT 0,
        toplam_taksit REAL NOT NULL,
        kalan_bakiye REAL NOT NULL,
        odendi INTEGER DEFAULT 0,
        odeme_tarihi TEXT,
        FOREIGN KEY (kredi_db_id) REFERENCES krediler(id)
      )
    ''');

    // Settings tablosu
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tip TEXT NOT NULL,
        deger TEXT NOT NULL,
        aktif INTEGER DEFAULT 1,
        ortak_id INTEGER
      )
    ''');

    // Ortaklar tablosu
    await db.execute('''
      CREATE TABLE ortaklar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad_soyad TEXT NOT NULL,
        tc_no TEXT,
        telefon TEXT,
        adres TEXT,
        stopaj_orani REAL DEFAULT 15.0,
        aktif INTEGER DEFAULT 1,
        notlar TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Yaklaşan Ödemeler tablosu
    await db.execute('''
      CREATE TABLE yaklasan_odemeler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alacakli TEXT NOT NULL,
        tutar REAL NOT NULL,
        para_birimi TEXT DEFAULT 'TL',
        vade_tarihi TEXT NOT NULL,
        aciklama TEXT,
        odendi INTEGER DEFAULT 0,
        odenme_tarihi TEXT,
        alarm_aktif INTEGER DEFAULT 1,
        alarm_gun_once INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Müşteriler tablosu
    await db.execute('''
      CREATE TABLE musteriler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unvan TEXT NOT NULL,
        yetkili_kisi TEXT,
        vergi_no TEXT,
        vergi_dairesi TEXT,
        telefon TEXT,
        email TEXT,
        adres TEXT,
        sehir TEXT,
        musteri_tipi TEXT DEFAULT 'bireysel',
        vade_gunu REAL DEFAULT 0,
        aktif INTEGER DEFAULT 1,
        notlar TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Satışlar tablosu
    await db.execute('''
      CREATE TABLE satislar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        musteri_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        urun_adi TEXT NOT NULL,
        miktar REAL NOT NULL,
        birim TEXT DEFAULT 'kg',
        birim_fiyat REAL NOT NULL,
        toplam_tutar REAL NOT NULL,
        para_birimi TEXT DEFAULT 'TL',
        doviz_kuru REAL,
        tl_karsiligi REAL,
        komisyon_orani REAL,
        komisyon_tutari REAL,
        vade_tarihi TEXT,
        fatura_no TEXT,
        irsaliye_no TEXT,
        aciklama TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (musteri_id) REFERENCES musteriler(id)
      )
    ''');

    // Tahsilatlar tablosu
    await db.execute('''
      CREATE TABLE tahsilatlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        musteri_id INTEGER NOT NULL,
        tarih TEXT NOT NULL,
        tutar REAL NOT NULL,
        para_birimi TEXT DEFAULT 'TL',
        doviz_kuru REAL,
        tl_karsiligi REAL,
        odeme_sekli TEXT DEFAULT 'nakit',
        kasa_adi TEXT,
        cek_senet_no TEXT,
        cek_vade_tarihi TEXT,
        banka_adi TEXT,
        aciklama TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (musteri_id) REFERENCES musteriler(id)
      )
    ''');

    // Varsayılan kasalar
    await db.insert('app_settings', {'tip': 'kasa', 'deger': 'Mert Anter', 'aktif': 1, 'ortak_id': 1});
    await db.insert('app_settings', {'tip': 'kasa', 'deger': 'Necati Özdere', 'aktif': 1, 'ortak_id': 2});
    await db.insert('app_settings', {'tip': 'kasa', 'deger': 'Nev Seracılık', 'aktif': 1});
    await db.insert('app_settings', {'tip': 'kasa', 'deger': 'AveA Sağlık', 'aktif': 1});

    // Varsayılan ortaklar
    await db.insert('ortaklar', {'ad_soyad': 'Mert Anter', 'stopaj_orani': 15.0, 'aktif': 1});
    await db.insert('ortaklar', {'ad_soyad': 'Necati Özdere', 'stopaj_orani': 15.0, 'aktif': 1});

    // Varsayılan gündelikçiler
    final gundelikciler = [
      {'ad_soyad': 'Suat Özdere', 'tc_no': '', 'adres': 'Cumhuriyet Mah. Adnan Menderes Cad. No: 105 Beydağ / İzmir'},
      {'ad_soyad': 'Okan Dağlıoğlu', 'tc_no': '42880494234', 'adres': 'Cumhuriyet Mh. Atatürk caddesi no:10 kat:3 Beydağ / İzmir'},
      {'ad_soyad': 'Çiğdem Selek', 'tc_no': '15341412146', 'adres': 'Yağcılar mahallesi Rüzgar küme evleri no 93 Beydağ/ İzmir'},
      {'ad_soyad': 'İsmet Selek', 'tc_no': '12944492094', 'adres': 'Yağcılar mahallesi Yasemin küme evleri 247 Beydağ/ İzmir'},
      {'ad_soyad': 'Ali Özer', 'tc_no': '54163118188', 'adres': 'Zafer mah şehit Adnan menderes bul no 4 daire 9 ödemiş / İzmir'},
      {'ad_soyad': 'Eren Gümüştaş', 'tc_no': '12331702188', 'adres': 'CUMHURİYET MAH. 268 SK. NO: 108 İÇ KAPI NO: 1 NAZİLLİ / AYDIN'},
      {'ad_soyad': 'Şakir Çakıroğlu', 'tc_no': '48445308770', 'adres': 'Yukarıaktepe Mah. Palamutçuk Küme Evleri No:32 Beydağ/ İzmir'},
    ];
    for (var g in gundelikciler) {
      await db.insert('gundelikciler', {...g, 'aktif': 1});
    }
  }

  // ==================== KASA HAREKETLERİ ====================

  Future<int> insertKasaHareketi(KasaHareketi hareket) async {
    final db = await database;
    return await db.insert('kasa_hareketleri', hareket.toMap());
  }

  Future<List<KasaHareketi>> getKasaHareketleri({int? limit, String? islemKaynagi}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (islemKaynagi != null) {
      where = 'islem_kaynagi = ?';
      whereArgs = [islemKaynagi];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'kasa_hareketleri',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'tarih DESC, id DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => KasaHareketi.fromMap(maps[i]));
  }

  Future<int> updateKasaHareketi(KasaHareketi hareket) async {
    final db = await database;
    return await db.update(
      'kasa_hareketleri',
      hareket.toMap(),
      where: 'id = ?',
      whereArgs: [hareket.id],
    );
  }

  Future<int> deleteKasaHareketi(int id) async {
    final db = await database;
    return await db.delete('kasa_hareketleri', where: 'id = ?', whereArgs: [id]);
  }

  /// Kasa bazlı bakiye özeti - TL cinsinden
  Future<List<Map<String, dynamic>>> getKasaBakiyeleri() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT kasa,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Giriş' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as toplam_giris,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Çıkış' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as toplam_cikis,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Giriş' THEN COALESCE(tl_karsiligi, tutar) ELSE -COALESCE(tl_karsiligi, tutar) END), 0) as bakiye
      FROM kasa_hareketleri
      WHERE kasa IS NOT NULL AND kasa != ''
      GROUP BY kasa
      ORDER BY bakiye DESC
    ''');
  }

  /// Genel kasa özeti - TL cinsinden
  Future<Map<String, double>> getKasaOzet() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN islem_tipi = 'Giriş' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as toplam_giris,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Çıkış' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as toplam_cikis,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Giriş' THEN COALESCE(tl_karsiligi, tutar) ELSE -COALESCE(tl_karsiligi, tutar) END), 0) as net
      FROM kasa_hareketleri
    ''');
    return {
      'toplam_giris': (result.first['toplam_giris'] as num).toDouble(),
      'toplam_cikis': (result.first['toplam_cikis'] as num).toDouble(),
      'net': (result.first['net'] as num).toDouble(),
    };
  }

  // ==================== GÜNDELİKÇİLER ====================

  Future<int> insertGundelikci(Gundelikci gundelikci) async {
    final db = await database;
    return await db.insert('gundelikciler', gundelikci.toMap());
  }

  Future<List<Gundelikci>> getGundelikciler() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gundelikciler',
      where: 'aktif = 1',
      orderBy: 'ad_soyad ASC'
    );

    List<Gundelikci> gundelikciler = [];
    for (var map in maps) {
      var g = Gundelikci.fromMap(map);
      // iliskili_id üzerinden hesapla
      final odemeler = await getGundelikciOdemeToplami(g.id!);
      g.toplamOdeme = odemeler['toplam_odeme'] ?? 0;
      g.resmilestirilenTutar = odemeler['resmilestirilen'] ?? 0;
      gundelikciler.add(g);
    }
    return gundelikciler;
  }

  Future<Map<String, double>> getGundelikciOdemeToplami(int gundelikciId) async {
    final db = await database;

    // Gündelikçiye yapılan ödemeler (iliskili_id ile)
    final odemeler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE iliskili_id = ? AND islem_kaynagi = 'gider_pusulasi' AND islem_tipi = 'Çıkış'
    ''', [gundelikciId]);

    // Resmileştirmeler
    final resmilestirmeler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE iliskili_id = ? AND islem_kaynagi = 'resmilestirme'
    ''', [gundelikciId]);

    return {
      'toplam_odeme': (odemeler.first['toplam'] as num).toDouble(),
      'resmilestirilen': (resmilestirmeler.first['toplam'] as num).toDouble(),
    };
  }

  Future<int> updateGundelikci(Gundelikci gundelikci) async {
    final db = await database;
    return await db.update('gundelikciler', gundelikci.toMap(), where: 'id = ?', whereArgs: [gundelikci.id]);
  }

  Future<int> deleteGundelikci(int id) async {
    final db = await database;
    return await db.update('gundelikciler', {'aktif': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getGundelikciOzet() async {
    final db = await database;

    final odemeler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE islem_kaynagi = 'gider_pusulasi' AND islem_tipi = 'Çıkış'
    ''');

    final resmilestirmeler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE islem_kaynagi = 'resmilestirme'
    ''');

    final toplamOdeme = (odemeler.first['toplam'] as num).toDouble();
    final toplamResmilestirme = (resmilestirmeler.first['toplam'] as num).toDouble();

    return {
      'toplam_odeme': toplamOdeme,
      'toplam_resmilestirme': toplamResmilestirme,
      'kalan_borc': toplamOdeme - toplamResmilestirme,
    };
  }

  // ==================== KREDİLER ====================

  Future<int> insertKredi(Kredi kredi) async {
    final db = await database;
    return await db.insert('krediler', kredi.toMap());
  }

  Future<List<Kredi>> getKrediler() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('krediler', orderBy: 'baslangic_tarihi DESC');
    List<Kredi> krediler = [];
    for (var map in maps) {
      final taksitler = await getTaksitler(map['id'] as int);
      krediler.add(Kredi.fromMap(map, taksitler: taksitler));
    }
    return krediler;
  }

  Future<int> updateKredi(Kredi kredi) async {
    final db = await database;
    return await db.update('krediler', kredi.toMap(), where: 'id = ?', whereArgs: [kredi.id]);
  }

  Future<int> deleteKredi(int id) async {
    final db = await database;
    await db.delete('kredi_taksitleri', where: 'kredi_db_id = ?', whereArgs: [id]);
    return await db.delete('krediler', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveTaksitler(int krediDbId, List<KrediTaksit> taksitler) async {
    final db = await database;
    await db.delete('kredi_taksitleri', where: 'kredi_db_id = ?', whereArgs: [krediDbId]);
    for (var taksit in taksitler) {
      await db.insert('kredi_taksitleri', taksit.toMap());
    }
  }

  Future<List<KrediTaksit>> getTaksitler(int krediDbId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kredi_taksitleri', where: 'kredi_db_id = ?', whereArgs: [krediDbId], orderBy: 'periyot ASC',
    );
    return List.generate(maps.length, (i) => KrediTaksit.fromMap(maps[i]));
  }

  Future<void> taksitOde(int taksitId, DateTime odemeTarihi) async {
    final db = await database;
    await db.update(
      'kredi_taksitleri',
      {'odendi': 1, 'odeme_tarihi': odemeTarihi.toIso8601String()},
      where: 'id = ?',
      whereArgs: [taksitId],
    );
  }

  Future<Map<String, double>> getKrediOzet() async {
    final db = await database;
    final krediResult = await db.rawQuery('''
      SELECT COALESCE(COUNT(*), 0) as aktif_kredi, COALESCE(SUM(cekilen_tutar), 0) as toplam_bakiye FROM krediler
    ''');
    final taksitResult = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN odendi = 0 THEN toplam_taksit ELSE 0 END), 0) as aylik_taksit
      FROM kredi_taksitleri WHERE vade_tarihi BETWEEN date('now', 'start of month') AND date('now', 'start of month', '+1 month', '-1 day')
    ''');
    return {
      'aktif_kredi': (krediResult.first['aktif_kredi'] as num).toDouble(),
      'toplam_bakiye': (krediResult.first['toplam_bakiye'] as num).toDouble(),
      'aylik_taksit': (taksitResult.first['aylik_taksit'] as num).toDouble(),
    };
  }

  // ==================== SETTINGS ====================

  Future<int> insertSetting(AppSettings setting) async {
    final db = await database;
    return await db.insert('app_settings', setting.toMap());
  }

  Future<List<AppSettings>> getSettings(String tip) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings', where: 'tip = ? AND aktif = 1', whereArgs: [tip], orderBy: 'deger ASC',
    );
    return List.generate(maps.length, (i) => AppSettings.fromMap(maps[i]));
  }

  Future<List<String>> getSettingValues(String tip) async {
    final settings = await getSettings(tip);
    return settings.map((s) => s.deger).toList();
  }

  Future<int> updateSetting(AppSettings setting) async {
    final db = await database;
    return await db.update('app_settings', setting.toMap(), where: 'id = ?', whereArgs: [setting.id]);
  }

  Future<int> deleteSetting(int id) async {
    final db = await database;
    return await db.delete('app_settings', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ORTAKLAR ====================

  Future<int> insertOrtak(Ortak ortak) async {
    final db = await database;
    return await db.insert('ortaklar', ortak.toMap());
  }

  Future<List<Ortak>> getOrtaklar() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ortaklar',
      where: 'aktif = 1',
      orderBy: 'ad_soyad ASC'
    );

    List<Ortak> ortaklar = [];
    for (var map in maps) {
      var o = Ortak.fromMap(map);
      // Ortak bakiye bilgisini hesapla
      final bakiye = await getOrtakBakiye(o.id!);
      o = o.copyWith(
        toplamVerilen: bakiye['toplam_verilen'],
        toplamGeriOdenen: bakiye['toplam_geri_odenen'],
        toplamStopaj: bakiye['toplam_stopaj'],
      );
      ortaklar.add(o);
    }
    return ortaklar;
  }

  Future<Ortak?> getOrtakById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ortaklar',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    var o = Ortak.fromMap(maps.first);
    final bakiye = await getOrtakBakiye(o.id!);
    return o.copyWith(
      toplamVerilen: bakiye['toplam_verilen'],
      toplamGeriOdenen: bakiye['toplam_geri_odenen'],
      toplamStopaj: bakiye['toplam_stopaj'],
    );
  }

  Future<Map<String, double>> getOrtakBakiye(int ortakId) async {
    final db = await database;

    // Ortağın şirkete verdiği avanslar (şirket kasasına giriş)
    final verilenler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE iliskili_id = ? AND islem_kaynagi = 'ortak_avans'
    ''', [ortakId]);

    // Şirketin ortağa geri ödemeleri (şirket kasasından çıkış)
    final geriOdenenler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE iliskili_id = ? AND islem_kaynagi = 'ortak_geri_odeme'
    ''', [ortakId]);

    // Kesilen stopajlar
    final stopajlar = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE iliskili_id = ? AND islem_kaynagi = 'ortak_stopaj'
    ''', [ortakId]);

    return {
      'toplam_verilen': (verilenler.first['toplam'] as num).toDouble(),
      'toplam_geri_odenen': (geriOdenenler.first['toplam'] as num).toDouble(),
      'toplam_stopaj': (stopajlar.first['toplam'] as num).toDouble(),
    };
  }

  Future<int> updateOrtak(Ortak ortak) async {
    final db = await database;
    return await db.update('ortaklar', ortak.toMap(), where: 'id = ?', whereArgs: [ortak.id]);
  }

  Future<int> deleteOrtak(int id) async {
    final db = await database;
    return await db.update('ortaklar', {'aktif': 0}, where: 'id = ?', whereArgs: [id]);
  }

  /// Genel ortak özeti
  Future<Map<String, double>> getOrtakOzet() async {
    final db = await database;

    // Toplam ortaklara verilen (şirkete giriş)
    final verilenler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE islem_kaynagi = 'ortak_avans'
    ''');

    // Toplam geri ödenen
    final geriOdenenler = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE islem_kaynagi = 'ortak_geri_odeme'
    ''');

    // Toplam stopaj
    final stopajlar = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri
      WHERE islem_kaynagi = 'ortak_stopaj'
    ''');

    final toplamVerilen = (verilenler.first['toplam'] as num).toDouble();
    final toplamGeriOdenen = (geriOdenenler.first['toplam'] as num).toDouble();
    final toplamStopaj = (stopajlar.first['toplam'] as num).toDouble();

    return {
      'toplam_verilen': toplamVerilen,
      'toplam_geri_odenen': toplamGeriOdenen,
      'toplam_stopaj': toplamStopaj,
      'kalan_borc': toplamVerilen - toplamGeriOdenen - toplamStopaj,
    };
  }

  // ==================== RAPORLAR ====================

  Future<List<Map<String, dynamic>>> getAylikHarcamaRaporu(int yil) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT strftime('%m', tarih) as ay,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Giriş' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as gelir,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Çıkış' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as gider
      FROM kasa_hareketleri WHERE strftime('%Y', tarih) = ?
      GROUP BY strftime('%m', tarih) ORDER BY ay
    ''', [yil.toString()]);
  }

  Future<List<Map<String, dynamic>>> getKategoriBazliRapor() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT aciklama as kategori, COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM kasa_hareketleri WHERE islem_tipi = 'Çıkış'
      GROUP BY aciklama ORDER BY toplam DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getKasaBazliRapor() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT kasa, 
        COALESCE(SUM(CASE WHEN islem_tipi = 'Giriş' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as giris,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Çıkış' THEN COALESCE(tl_karsiligi, tutar) ELSE 0 END), 0) as cikis,
        COALESCE(SUM(CASE WHEN islem_tipi = 'Giriş' THEN COALESCE(tl_karsiligi, tutar) ELSE -COALESCE(tl_karsiligi, tutar) END), 0) as net
      FROM kasa_hareketleri WHERE kasa IS NOT NULL
      GROUP BY kasa ORDER BY net DESC
    ''');
  }

  // ==================== YAKLAŞAN ÖDEMELER ====================

  Future<int> insertYaklasanOdeme(YaklasanOdeme odeme) async {
    final db = await database;
    return await db.insert('yaklasan_odemeler', odeme.toMap());
  }

  Future<List<YaklasanOdeme>> getYaklasanOdemeler({bool sadeceBekleyenler = false}) async {
    final db = await database;
    String where = '';
    if (sadeceBekleyenler) {
      where = 'WHERE odendi = 0';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM yaklasan_odemeler $where ORDER BY vade_tarihi ASC
    ''');
    return maps.map((m) => YaklasanOdeme.fromMap(m)).toList();
  }

  Future<List<YaklasanOdeme>> getYaklasanOdemelerByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM yaklasan_odemeler 
      WHERE odendi = 0 AND vade_tarihi BETWEEN ? AND ?
      ORDER BY vade_tarihi ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return maps.map((m) => YaklasanOdeme.fromMap(m)).toList();
  }

  Future<int> updateYaklasanOdeme(YaklasanOdeme odeme) async {
    final db = await database;
    return await db.update('yaklasan_odemeler', odeme.toMap(), where: 'id = ?', whereArgs: [odeme.id]);
  }

  Future<int> deleteYaklasanOdeme(int id) async {
    final db = await database;
    return await db.delete('yaklasan_odemeler', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> odemeyiKapat(int id) async {
    final db = await database;
    return await db.update(
      'yaklasan_odemeler',
      {'odendi': 1, 'odenme_tarihi': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== MÜŞTERİLER (CARİ) ====================

  Future<int> insertMusteri(Musteri musteri) async {
    final db = await database;
    return await db.insert('musteriler', musteri.toMap());
  }

  Future<List<Musteri>> getMusteriler({bool sadecAktif = true}) async {
    final db = await database;
    String where = sadecAktif ? 'WHERE aktif = 1' : '';
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM musteriler $where ORDER BY unvan ASC
    ''');
    return maps.map((m) => Musteri.fromMap(m)).toList();
  }

  Future<Musteri?> getMusteri(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'musteriler',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Musteri.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMusteri(Musteri musteri) async {
    final db = await database;
    return await db.update('musteriler', musteri.toMap(), where: 'id = ?', whereArgs: [musteri.id]);
  }

  Future<int> deleteMusteri(int id) async {
    final db = await database;
    // Soft delete - sadece aktif = 0 yap
    return await db.update('musteriler', {'aktif': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getMusteriBakiye(int musteriId) async {
    final db = await database;
    
    // Toplam satış
    final satisResult = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, toplam_tutar)), 0) as toplam
      FROM satislar WHERE musteri_id = ?
    ''', [musteriId]);
    final toplamSatis = (satisResult.first['toplam'] as num?)?.toDouble() ?? 0;
    
    // Toplam tahsilat
    final tahsilatResult = await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam
      FROM tahsilatlar WHERE musteri_id = ?
    ''', [musteriId]);
    final toplamTahsilat = (tahsilatResult.first['toplam'] as num?)?.toDouble() ?? 0;
    
    return {
      'toplamSatis': toplamSatis,
      'toplamTahsilat': toplamTahsilat,
      'bakiye': toplamSatis - toplamTahsilat,
    };
  }

  Future<List<Map<String, dynamic>>> getMusterilerWithBakiye() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        m.*,
        COALESCE((SELECT SUM(COALESCE(tl_karsiligi, toplam_tutar)) FROM satislar WHERE musteri_id = m.id), 0) as toplam_satis,
        COALESCE((SELECT SUM(COALESCE(tl_karsiligi, tutar)) FROM tahsilatlar WHERE musteri_id = m.id), 0) as toplam_tahsilat
      FROM musteriler m
      WHERE m.aktif = 1
      ORDER BY m.unvan ASC
    ''');
    return maps;
  }

  // ==================== SATIŞLAR ====================

  Future<int> insertSatis(Satis satis) async {
    final db = await database;
    return await db.insert('satislar', satis.toMap());
  }

  Future<List<Satis>> getSatislar({int? musteriId, DateTime? baslangic, DateTime? bitis}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    
    List<String> conditions = [];
    if (musteriId != null) {
      conditions.add('musteri_id = ?');
      args.add(musteriId);
    }
    if (baslangic != null) {
      conditions.add('tarih >= ?');
      args.add(baslangic.toIso8601String());
    }
    if (bitis != null) {
      conditions.add('tarih <= ?');
      args.add(bitis.toIso8601String());
    }
    
    if (conditions.isNotEmpty) {
      where = 'WHERE ${conditions.join(' AND ')}';
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, m.unvan as musteri_unvan
      FROM satislar s
      LEFT JOIN musteriler m ON s.musteri_id = m.id
      $where
      ORDER BY s.tarih DESC
    ''', args);
    
    return maps.map((m) => Satis.fromMap(m)).toList();
  }

  Future<Satis?> getSatis(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, m.unvan as musteri_unvan
      FROM satislar s
      LEFT JOIN musteriler m ON s.musteri_id = m.id
      WHERE s.id = ?
    ''', [id]);
    if (maps.isNotEmpty) {
      return Satis.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSatis(Satis satis) async {
    final db = await database;
    return await db.update('satislar', satis.toMap(), where: 'id = ?', whereArgs: [satis.id]);
  }

  Future<int> deleteSatis(int id) async {
    final db = await database;
    return await db.delete('satislar', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Satis>> getVadesiGecenSatislar() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, m.unvan as musteri_unvan,
        s.toplam_tutar - COALESCE((
          SELECT SUM(COALESCE(tl_karsiligi, tutar)) 
          FROM tahsilatlar t 
          WHERE t.musteri_id = s.musteri_id
        ), 0) as kalan
      FROM satislar s
      LEFT JOIN musteriler m ON s.musteri_id = m.id
      WHERE s.vade_tarihi IS NOT NULL 
        AND s.vade_tarihi < ?
      ORDER BY s.vade_tarihi ASC
    ''', [now]);
    return maps.map((m) => Satis.fromMap(m)).toList();
  }

  // ==================== TAHSİLATLAR ====================

  Future<int> insertTahsilat(Map<String, dynamic> tahsilat) async {
    final db = await database;
    tahsilat['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('tahsilatlar', tahsilat);
  }

  Future<List<Map<String, dynamic>>> getTahsilatlar({int? musteriId}) async {
    final db = await database;
    String where = musteriId != null ? 'WHERE t.musteri_id = ?' : '';
    List<dynamic> args = musteriId != null ? [musteriId] : [];
    
    return await db.rawQuery('''
      SELECT t.*, m.unvan as musteri_unvan
      FROM tahsilatlar t
      LEFT JOIN musteriler m ON t.musteri_id = m.id
      $where
      ORDER BY t.tarih DESC
    ''', args);
  }

  Future<int> updateTahsilat(int id, Map<String, dynamic> tahsilat) async {
    final db = await database;
    return await db.update('tahsilatlar', tahsilat, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTahsilat(int id) async {
    final db = await database;
    return await db.delete('tahsilatlar', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CARİ RAPORLAR ====================

  Future<Map<String, dynamic>> getCariOzet() async {
    final db = await database;
    
    // Toplam müşteri sayısı
    final musteriSayisi = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM musteriler WHERE aktif = 1')
    ) ?? 0;
    
    // Toplam satış
    final toplamSatis = (await db.rawQuery(
      'SELECT COALESCE(SUM(COALESCE(tl_karsiligi, toplam_tutar)), 0) as toplam FROM satislar'
    )).first['toplam'] as num? ?? 0;
    
    // Toplam tahsilat
    final toplamTahsilat = (await db.rawQuery(
      'SELECT COALESCE(SUM(COALESCE(tl_karsiligi, tutar)), 0) as toplam FROM tahsilatlar'
    )).first['toplam'] as num? ?? 0;
    
    // Vadesi geçen alacak
    final now = DateTime.now().toIso8601String();
    final vadesiGecen = (await db.rawQuery('''
      SELECT COALESCE(SUM(COALESCE(s.tl_karsiligi, s.toplam_tutar)), 0) as toplam
      FROM satislar s
      WHERE s.vade_tarihi IS NOT NULL AND s.vade_tarihi < ?
    ''', [now])).first['toplam'] as num? ?? 0;
    
    return {
      'musteriSayisi': musteriSayisi,
      'toplamSatis': toplamSatis.toDouble(),
      'toplamTahsilat': toplamTahsilat.toDouble(),
      'toplamAlacak': toplamSatis.toDouble() - toplamTahsilat.toDouble(),
      'vadesiGecenAlacak': vadesiGecen.toDouble(),
    };
  }

  // ==================== EXCEL EXPORT ====================

  Future<List<Map<String, dynamic>>> getAllDataForExport() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        tarih, aciklama, islem_tipi, tutar, para_birimi, 
        COALESCE(tl_karsiligi, tutar) as tl_tutar,
        odeme_bicimi, kasa, notlar, islem_kaynagi
      FROM kasa_hareketleri
      ORDER BY tarih DESC
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
