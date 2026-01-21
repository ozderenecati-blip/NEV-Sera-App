// Web için localStorage tabanlı kalıcı database service
import 'dart:convert';
import 'dart:html' as html;
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
  DatabaseService._internal() {
    _loadFromStorage();
  }

  // In-memory storage (synced with localStorage)
  List<KasaHareketi> _kasaHareketleri = [];
  List<Kredi> _krediler = [];
  List<KrediTaksit> _krediTaksitleri = [];
  List<Gundelikci> _gundelikciler = [];
  List<Ortak> _ortaklar = [];
  List<Musteri> _musteriler = [];
  List<Satis> _satislar = [];
  List<YaklasanOdeme> _yaklasanOdemeler = [];
  List<AppSettings> _settings = [];
  List<Map<String, dynamic>> _tahsilatlar = [];
  
  int _nextKasaId = 1;
  int _nextKrediId = 1;
  int _nextTaksitId = 1;
  int _nextGundelikciId = 1;
  int _nextOrtakId = 1;
  int _nextMusteriId = 1;
  int _nextSatisId = 1;
  int _nextOdemeId = 1;
  int _nextSettingId = 1;
  int _nextTahsilatId = 1;

  // LocalStorage keys
  static const String _kasaKey = 'nev_kasa';
  static const String _krediKey = 'nev_kredi';
  static const String _taksitKey = 'nev_taksit';
  static const String _gundelikciKey = 'nev_gundelikci';
  static const String _ortakKey = 'nev_ortak';
  static const String _musteriKey = 'nev_musteri';
  static const String _satisKey = 'nev_satis';
  static const String _odemeKey = 'nev_odeme';
  static const String _settingsKey = 'nev_settings';
  static const String _tahsilatKey = 'nev_tahsilat';
  static const String _idsKey = 'nev_ids';

  void _loadFromStorage() {
    try {
      // Load IDs
      final idsJson = html.window.localStorage[_idsKey];
      if (idsJson != null) {
        final ids = jsonDecode(idsJson);
        _nextKasaId = ids['kasa'] ?? 1;
        _nextKrediId = ids['kredi'] ?? 1;
        _nextTaksitId = ids['taksit'] ?? 1;
        _nextGundelikciId = ids['gundelikci'] ?? 1;
        _nextOrtakId = ids['ortak'] ?? 1;
        _nextMusteriId = ids['musteri'] ?? 1;
        _nextSatisId = ids['satis'] ?? 1;
        _nextOdemeId = ids['odeme'] ?? 1;
        _nextSettingId = ids['setting'] ?? 1;
        _nextTahsilatId = ids['tahsilat'] ?? 1;
      }
      
      // Load Kasa
      final kasaJson = html.window.localStorage[_kasaKey];
      if (kasaJson != null) {
        final list = jsonDecode(kasaJson) as List;
        _kasaHareketleri = list.map((e) => KasaHareketi.fromMap(e)).toList();
      }
      
      // Load Kredi
      final krediJson = html.window.localStorage[_krediKey];
      if (krediJson != null) {
        final list = jsonDecode(krediJson) as List;
        _krediler = list.map((e) => Kredi.fromMap(e)).toList();
      }
      
      // Load Taksit
      final taksitJson = html.window.localStorage[_taksitKey];
      if (taksitJson != null) {
        final list = jsonDecode(taksitJson) as List;
        _krediTaksitleri = list.map((e) => KrediTaksit.fromMap(e)).toList();
      }
      
      // Load Gundelikci
      final gundelikciJson = html.window.localStorage[_gundelikciKey];
      if (gundelikciJson != null) {
        final list = jsonDecode(gundelikciJson) as List;
        _gundelikciler = list.map((e) => Gundelikci.fromMap(e)).toList();
      }
      
      // Load Ortak
      final ortakJson = html.window.localStorage[_ortakKey];
      if (ortakJson != null) {
        final list = jsonDecode(ortakJson) as List;
        _ortaklar = list.map((e) => Ortak.fromMap(e)).toList();
      }
      
      // Load Musteri
      final musteriJson = html.window.localStorage[_musteriKey];
      if (musteriJson != null) {
        final list = jsonDecode(musteriJson) as List;
        _musteriler = list.map((e) => Musteri.fromMap(e)).toList();
      }
      
      // Load Satis
      final satisJson = html.window.localStorage[_satisKey];
      if (satisJson != null) {
        final list = jsonDecode(satisJson) as List;
        _satislar = list.map((e) => Satis.fromMap(e)).toList();
      }
      
      // Load Odeme
      final odemeJson = html.window.localStorage[_odemeKey];
      if (odemeJson != null) {
        final list = jsonDecode(odemeJson) as List;
        _yaklasanOdemeler = list.map((e) => YaklasanOdeme.fromMap(e)).toList();
      }
      
      // Load Settings
      final settingsJson = html.window.localStorage[_settingsKey];
      if (settingsJson != null) {
        final list = jsonDecode(settingsJson) as List;
        _settings = list.map((e) => AppSettings.fromMap(e)).toList();
      }
      
      // Load Tahsilat
      final tahsilatJson = html.window.localStorage[_tahsilatKey];
      if (tahsilatJson != null) {
        final list = jsonDecode(tahsilatJson) as List;
        _tahsilatlar = list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      print('Data loaded from localStorage');
    } catch (e) {
      print('Error loading from localStorage: $e');
    }
  }

  void _saveToStorage() {
    try {
      // Save IDs
      html.window.localStorage[_idsKey] = jsonEncode({
        'kasa': _nextKasaId,
        'kredi': _nextKrediId,
        'taksit': _nextTaksitId,
        'gundelikci': _nextGundelikciId,
        'ortak': _nextOrtakId,
        'musteri': _nextMusteriId,
        'satis': _nextSatisId,
        'odeme': _nextOdemeId,
        'setting': _nextSettingId,
        'tahsilat': _nextTahsilatId,
      });
      
      // Save all data
      html.window.localStorage[_kasaKey] = jsonEncode(_kasaHareketleri.map((e) => e.toMap()).toList());
      html.window.localStorage[_krediKey] = jsonEncode(_krediler.map((e) => e.toMap()).toList());
      html.window.localStorage[_taksitKey] = jsonEncode(_krediTaksitleri.map((e) => e.toMap()).toList());
      html.window.localStorage[_gundelikciKey] = jsonEncode(_gundelikciler.map((e) => e.toMap()).toList());
      html.window.localStorage[_ortakKey] = jsonEncode(_ortaklar.map((e) => e.toMap()).toList());
      html.window.localStorage[_musteriKey] = jsonEncode(_musteriler.map((e) => e.toMap()).toList());
      html.window.localStorage[_satisKey] = jsonEncode(_satislar.map((e) => e.toMap()).toList());
      html.window.localStorage[_odemeKey] = jsonEncode(_yaklasanOdemeler.map((e) => e.toMap()).toList());
      html.window.localStorage[_settingsKey] = jsonEncode(_settings.map((e) => e.toMap()).toList());
      html.window.localStorage[_tahsilatKey] = jsonEncode(_tahsilatlar);
      
      print('Data saved to localStorage');
    } catch (e) {
      print('Error saving to localStorage: $e');
    }
  }

  // ==================== KASA ====================
  Future<List<KasaHareketi>> getKasaHareketleri({int? limit, String? islemKaynagi}) async {
    var list = List<KasaHareketi>.from(_kasaHareketleri);
    if (islemKaynagi != null) {
      list = list.where((h) => h.islemKaynagi == islemKaynagi).toList();
    }
    list.sort((a, b) => b.tarih.compareTo(a.tarih));
    if (limit != null) {
      return list.take(limit).toList();
    }
    return list;
  }
  
  Future<int> insertKasaHareketi(KasaHareketi hareket) async {
    final newHareket = KasaHareketi(
      id: _nextKasaId++,
      tarih: hareket.tarih,
      aciklama: hareket.aciklama,
      islemTipi: hareket.islemTipi,
      tutar: hareket.tutar,
      odemeBicimi: hareket.odemeBicimi,
      kasa: hareket.kasa,
      notlar: hareket.notlar,
      paraBirimi: hareket.paraBirimi,
      dovizKuru: hareket.dovizKuru,
      tlKarsiligi: hareket.tlKarsiligi,
      islemKaynagi: hareket.islemKaynagi,
      iliskiliId: hareket.iliskiliId,
    );
    _kasaHareketleri.add(newHareket);
    _saveToStorage();
    return newHareket.id!;
  }
  
  Future<int> updateKasaHareketi(KasaHareketi hareket) async {
    final index = _kasaHareketleri.indexWhere((h) => h.id == hareket.id);
    if (index != -1) {
      _kasaHareketleri[index] = hareket;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteKasaHareketi(int id) async {
    _kasaHareketleri.removeWhere((h) => h.id == id);
    _saveToStorage();
    return 1;
  }
  
  Future<Map<String, double>> getKasaOzet() async {
    double toplamGiris = 0;
    double toplamCikis = 0;
    
    for (var h in _kasaHareketleri) {
      final tutar = h.tlKarsiligi ?? h.tutar;
      if (h.islemTipi == 'Giriş') {
        toplamGiris += tutar;
      } else {
        toplamCikis += tutar;
      }
    }
    
    return {
      'toplamGiris': toplamGiris,
      'toplamCikis': toplamCikis,
      'bakiye': toplamGiris - toplamCikis,
    };
  }
  
  Future<List<Map<String, dynamic>>> getKasaBakiyeleri() async {
    final Map<String, double> bakiyeler = {};
    
    for (var h in _kasaHareketleri) {
      final kasa = h.kasa ?? 'Genel';
      final tutar = h.tlKarsiligi ?? h.tutar;
      
      bakiyeler[kasa] ??= 0;
      if (h.islemTipi == 'Giriş') {
        bakiyeler[kasa] = bakiyeler[kasa]! + tutar;
      } else {
        bakiyeler[kasa] = bakiyeler[kasa]! - tutar;
      }
    }
    
    return bakiyeler.entries.map((e) => {
      'kasa': e.key,
      'bakiye': e.value,
    }).toList();
  }

  // ==================== GÜNDELİKÇİLER ====================
  Future<List<Gundelikci>> getGundelikciler() async => 
      _gundelikciler.where((g) => g.aktif).toList();
  
  Future<int> insertGundelikci(Gundelikci g) async {
    final newG = Gundelikci(
      id: _nextGundelikciId++,
      adSoyad: g.adSoyad,
      tcNo: g.tcNo,
      adres: g.adres,
      telefon: g.telefon,
      aktif: g.aktif,
    );
    _gundelikciler.add(newG);
    _saveToStorage();
    return newG.id!;
  }
  
  Future<int> updateGundelikci(Gundelikci g) async {
    final index = _gundelikciler.indexWhere((x) => x.id == g.id);
    if (index != -1) {
      _gundelikciler[index] = g;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteGundelikci(int id) async {
    final index = _gundelikciler.indexWhere((g) => g.id == id);
    if (index != -1) {
      _gundelikciler[index] = _gundelikciler[index].copyWith(aktif: false);
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<Map<String, double>> getGundelikciOdemeToplami(int gundelikciId) async {
    return {'toplam': 0};
  }
  
  Future<Map<String, double>> getGundelikciOzet() async {
    return {
      'toplamOdeme': 0,
      'toplamCalisan': _gundelikciler.where((g) => g.aktif).length.toDouble(),
    };
  }

  // ==================== KREDİLER ====================
  Future<List<Kredi>> getKrediler() async => List.from(_krediler);
  
  Future<int> insertKredi(Kredi k) async {
    final id = _nextKrediId++;
    final newKredi = k.copyWith(id: id);
    _krediler.add(newKredi);
    _saveToStorage();
    return id;
  }
  
  Future<int> updateKredi(Kredi k) async {
    final index = _krediler.indexWhere((x) => x.id == k.id);
    if (index != -1) {
      _krediler[index] = k;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteKredi(int id) async {
    _krediler.removeWhere((k) => k.id == id);
    _krediTaksitleri.removeWhere((t) => t.krediDbId == id);
    _saveToStorage();
    return 1;
  }
  
  Future<List<KrediTaksit>> getTaksitler(int krediDbId) async =>
      _krediTaksitleri.where((t) => t.krediDbId == krediDbId).toList();
  
  Future<void> saveTaksitler(int krediDbId, List<KrediTaksit> taksitler) async {
    _krediTaksitleri.removeWhere((t) => t.krediDbId == krediDbId);
    for (var t in taksitler) {
      _krediTaksitleri.add(KrediTaksit(
        id: _nextTaksitId++,
        krediDbId: krediDbId,
        periyot: t.periyot,
        vadeTarihi: t.vadeTarihi,
        anapara: t.anapara,
        faiz: t.faiz,
        bsmv: t.bsmv,
        kkdf: t.kkdf,
        toplamTaksit: t.toplamTaksit,
        kalanBakiye: t.kalanBakiye,
        odendi: t.odendi,
      ));
    }
    _saveToStorage();
  }
  
  Future<void> taksitOde(int taksitId, DateTime odemeTarihi) async {
    final index = _krediTaksitleri.indexWhere((t) => t.id == taksitId);
    if (index != -1) {
      final t = _krediTaksitleri[index];
      _krediTaksitleri[index] = KrediTaksit(
        id: t.id,
        krediDbId: t.krediDbId,
        periyot: t.periyot,
        vadeTarihi: t.vadeTarihi,
        anapara: t.anapara,
        faiz: t.faiz,
        bsmv: t.bsmv,
        kkdf: t.kkdf,
        toplamTaksit: t.toplamTaksit,
        kalanBakiye: t.kalanBakiye,
        odendi: true,
      );
      _saveToStorage();
    }
  }
  
  Future<Map<String, double>> getKrediOzet() async {
    double toplamBorc = 0;
    double odenenTutar = 0;
    
    for (var k in _krediler) {
      toplamBorc += k.cekilenTutar;
      for (var t in _krediTaksitleri.where((t) => t.krediDbId == k.id)) {
        if (t.odendi) {
          odenenTutar += t.toplamTaksit;
        }
      }
    }
    
    return {
      'toplamBorc': toplamBorc,
      'odenenTutar': odenenTutar,
      'kalanBorc': toplamBorc - odenenTutar,
      'krediSayisi': _krediler.length.toDouble(),
    };
  }

  // ==================== ORTAKLAR ====================
  Future<List<Ortak>> getOrtaklar() async => 
      _ortaklar.where((o) => o.aktif).toList();
  
  Future<Ortak?> getOrtakById(int id) async {
    try {
      return _ortaklar.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<int> insertOrtak(Ortak o) async {
    final newO = o.copyWith(id: _nextOrtakId++);
    _ortaklar.add(newO);
    _saveToStorage();
    return newO.id!;
  }
  
  Future<int> updateOrtak(Ortak o) async {
    final index = _ortaklar.indexWhere((x) => x.id == o.id);
    if (index != -1) {
      _ortaklar[index] = o;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteOrtak(int id) async {
    final index = _ortaklar.indexWhere((o) => o.id == id);
    if (index != -1) {
      _ortaklar[index] = _ortaklar[index].copyWith(aktif: false);
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<Map<String, double>> getOrtakBakiye(int ortakId) async {
    return {'bakiye': 0};
  }
  
  Future<Map<String, double>> getOrtakOzet() async {
    return {
      'toplamOrtak': _ortaklar.where((o) => o.aktif).length.toDouble(),
    };
  }

  // ==================== YAKLASAN ÖDEMELER ====================
  Future<List<YaklasanOdeme>> getYaklasanOdemeler({bool sadeceBekleyenler = false}) async {
    if (sadeceBekleyenler) {
      return _yaklasanOdemeler.where((o) => !o.odendi).toList();
    }
    return List.from(_yaklasanOdemeler);
  }
  
  Future<List<YaklasanOdeme>> getYaklasanOdemelerByDateRange(DateTime start, DateTime end) async {
    return _yaklasanOdemeler.where((o) => 
      o.vadeTarihi.isAfter(start) && o.vadeTarihi.isBefore(end)
    ).toList();
  }
  
  Future<int> insertYaklasanOdeme(YaklasanOdeme o) async {
    final newO = YaklasanOdeme(
      id: _nextOdemeId++,
      alacakli: o.alacakli,
      tutar: o.tutar,
      paraBirimi: o.paraBirimi,
      vadeTarihi: o.vadeTarihi,
      aciklama: o.aciklama,
      odendi: o.odendi,
      odenmeTarihi: o.odenmeTarihi,
      alarmAktif: o.alarmAktif,
      alarmGunOnce: o.alarmGunOnce,
    );
    _yaklasanOdemeler.add(newO);
    _saveToStorage();
    return newO.id!;
  }
  
  Future<int> updateYaklasanOdeme(YaklasanOdeme o) async {
    final index = _yaklasanOdemeler.indexWhere((x) => x.id == o.id);
    if (index != -1) {
      _yaklasanOdemeler[index] = o;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteYaklasanOdeme(int id) async {
    _yaklasanOdemeler.removeWhere((o) => o.id == id);
    _saveToStorage();
    return 1;
  }

  // ==================== MÜŞTERİLER ====================
  Future<List<Musteri>> getMusteriler({bool sadecAktif = true}) async {
    if (sadecAktif) {
      return _musteriler.where((m) => m.aktif).toList();
    }
    return List.from(_musteriler);
  }
  
  Future<Musteri?> getMusteri(int id) async {
    try {
      return _musteriler.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<int> insertMusteri(Musteri m) async {
    final newM = m.copyWith(id: _nextMusteriId++);
    _musteriler.add(newM);
    _saveToStorage();
    return newM.id!;
  }
  
  Future<int> updateMusteri(Musteri m) async {
    final index = _musteriler.indexWhere((x) => x.id == m.id);
    if (index != -1) {
      _musteriler[index] = m;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteMusteri(int id) async {
    final index = _musteriler.indexWhere((m) => m.id == id);
    if (index != -1) {
      _musteriler[index] = _musteriler[index].copyWith(aktif: false);
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<Map<String, double>> getMusteriBakiye(int musteriId) async {
    return {'bakiye': 0};
  }
  
  Future<List<Map<String, dynamic>>> getMusterilerWithBakiye() async {
    return _musteriler.where((m) => m.aktif).map((m) => {
      'id': m.id,
      'unvan': m.unvan,
      'bakiye': 0.0,
    }).toList();
  }

  // ==================== SATIŞLAR ====================
  Future<List<Satis>> getSatislar({int? musteriId, DateTime? baslangic, DateTime? bitis}) async {
    var list = List<Satis>.from(_satislar);
    if (musteriId != null) {
      list = list.where((s) => s.musteriId == musteriId).toList();
    }
    if (baslangic != null) {
      list = list.where((s) => s.tarih.isAfter(baslangic)).toList();
    }
    if (bitis != null) {
      list = list.where((s) => s.tarih.isBefore(bitis)).toList();
    }
    return list;
  }
  
  Future<Satis?> getSatis(int id) async {
    try {
      return _satislar.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<int> insertSatis(Satis s) async {
    final newS = s.copyWith(id: _nextSatisId++);
    _satislar.add(newS);
    _saveToStorage();
    return newS.id!;
  }
  
  Future<int> updateSatis(Satis s) async {
    final index = _satislar.indexWhere((x) => x.id == s.id);
    if (index != -1) {
      _satislar[index] = s;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteSatis(int id) async {
    _satislar.removeWhere((s) => s.id == id);
    _saveToStorage();
    return 1;
  }

  // ==================== CARİ ÖZET ====================
  Future<Map<String, dynamic>> getCariOzet() async {
    return {
      'toplamAlacak': 0.0,
      'toplamBorc': 0.0,
      'netBakiye': 0.0,
      'musteriSayisi': _musteriler.where((m) => m.aktif).length,
    };
  }

  // ==================== RAPORLAR ====================
  Future<List<Map<String, dynamic>>> getAylikHarcamaRaporu(int yil) async {
    return List.generate(12, (i) => {
      'ay': i + 1,
      'giris': 0.0,
      'cikis': 0.0,
    });
  }
  
  Future<List<Map<String, dynamic>>> getKategoriBazliRapor() async {
    return [];
  }
  
  Future<List<Map<String, dynamic>>> getKasaBazliRapor() async {
    return [];
  }

  // ==================== SETTINGS ====================
  Future<int> insertSetting(AppSettings setting) async {
    final newS = setting.copyWith(id: _nextSettingId++);
    _settings.add(newS);
    _saveToStorage();
    return newS.id!;
  }
  
  Future<List<AppSettings>> getSettings(String tip) async {
    return _settings.where((s) => s.tip == tip && s.aktif).toList();
  }
  
  Future<List<String>> getSettingValues(String tip) async {
    if (tip == 'kasa') {
      final kasalar = _settings.where((s) => s.tip == 'kasa' && s.aktif).map((s) => s.deger).toList();
      if (kasalar.isEmpty) {
        return ['Mert Anter', 'Necati Özdere', 'NEV Seracılık', 'AveA Sağlık'];
      }
      return kasalar;
    }
    return _settings.where((s) => s.tip == tip && s.aktif).map((s) => s.deger).toList();
  }
  
  Future<int> updateSetting(AppSettings setting) async {
    final index = _settings.indexWhere((s) => s.id == setting.id);
    if (index != -1) {
      _settings[index] = setting;
      _saveToStorage();
      return 1;
    }
    return 0;
  }
  
  Future<int> deleteSetting(int id) async {
    final index = _settings.indexWhere((s) => s.id == id);
    if (index != -1) {
      _settings[index] = _settings[index].copyWith(aktif: false);
      _saveToStorage();
      return 1;
    }
    return 0;
  }

  // ==================== YAKLASAN ÖDEMELER EK ====================
  Future<int> odemeyiKapat(int id, DateTime odemeTarihi) async {
    final index = _yaklasanOdemeler.indexWhere((o) => o.id == id);
    if (index != -1) {
      final o = _yaklasanOdemeler[index];
      _yaklasanOdemeler[index] = YaklasanOdeme(
        id: o.id,
        alacakli: o.alacakli,
        tutar: o.tutar,
        paraBirimi: o.paraBirimi,
        vadeTarihi: o.vadeTarihi,
        aciklama: o.aciklama,
        odendi: true,
        odenmeTarihi: odemeTarihi,
        alarmAktif: false,
        alarmGunOnce: o.alarmGunOnce,
      );
      _saveToStorage();
      return 1;
    }
    return 0;
  }

  // ==================== TAHSİLATLAR ====================
  Future<int> insertTahsilat(Map<String, dynamic> tahsilat) async {
    tahsilat['id'] = _nextTahsilatId++;
    _tahsilatlar.add(tahsilat);
    _saveToStorage();
    return tahsilat['id'];
  }
  
  Future<List<Map<String, dynamic>>> getTahsilatlar({int? musteriId, int? satisId}) async {
    var list = List<Map<String, dynamic>>.from(_tahsilatlar);
    if (musteriId != null) {
      list = list.where((t) => t['musteri_id'] == musteriId).toList();
    }
    if (satisId != null) {
      list = list.where((t) => t['satis_id'] == satisId).toList();
    }
    return list;
  }
  
  Future<int> deleteTahsilat(int id) async {
    _tahsilatlar.removeWhere((t) => t['id'] == id);
    _saveToStorage();
    return 1;
  }
}
