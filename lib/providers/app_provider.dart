import 'package:flutter/foundation.dart';
import '../models/kasa_hareketi.dart';
import '../models/kredi.dart';
import '../models/gundelikci.dart';
import '../models/ortak.dart';
import '../models/settings.dart';
import '../models/yaklasan_odeme.dart';
import '../models/musteri.dart';
import '../models/satis.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  // Kasa verileri
  List<KasaHareketi> _kasaHareketleri = [];
  Map<String, double> _kasaOzet = {};
  List<Map<String, dynamic>> _kasaBakiyeleri = [];

  // Gündelikçiler
  List<Gundelikci> _gundelikciler = [];
  Map<String, double> _gundelikciOzet = {};

  // Krediler
  List<Kredi> _krediler = [];
  Map<String, double> _krediOzet = {};

  // Ortaklar
  List<Ortak> _ortaklar = [];
  Map<String, double> _ortakOzet = {};

  // Yaklaşan Ödemeler
  List<YaklasanOdeme> _yaklasanOdemeler = [];

  // Müşteriler ve Satışlar
  List<Musteri> _musteriler = [];
  List<Satis> _satislar = [];
  Map<String, dynamic> _cariOzet = {};

  // Ayarlar
  List<String> _kasalar = [];

  // Raporlar
  List<Map<String, dynamic>> _aylikRapor = [];
  List<Map<String, dynamic>> _kategoriRapor = [];
  List<Map<String, dynamic>> _kasaBazliRapor = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<KasaHareketi> get kasaHareketleri => _kasaHareketleri;
  Map<String, double> get kasaOzet => _kasaOzet;
  List<Map<String, dynamic>> get kasaBakiyeleri => _kasaBakiyeleri;
  List<Gundelikci> get gundelikciler => _gundelikciler;
  Map<String, double> get gundelikciOzet => _gundelikciOzet;
  List<Kredi> get krediler => _krediler;
  Map<String, double> get krediOzet => _krediOzet;
  List<Ortak> get ortaklar => _ortaklar;
  Map<String, double> get ortakOzet => _ortakOzet;
  List<YaklasanOdeme> get yaklasanOdemeler => _yaklasanOdemeler;
  List<YaklasanOdeme> get bekleyenOdemeler => _yaklasanOdemeler.where((o) => !o.odendi).toList();
  List<Musteri> get musteriler => _musteriler;
  List<Satis> get satislar => _satislar;
  Map<String, dynamic> get cariOzet => _cariOzet;
  List<String> get kasalar => _kasalar;
  List<Map<String, dynamic>> get aylikRapor => _aylikRapor;
  List<Map<String, dynamic>> get kategoriRapor => _kategoriRapor;
  List<Map<String, dynamic>> get kasaBazliRapor => _kasaBazliRapor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== LOAD ====================

  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _kasaHareketleri = await _db.getKasaHareketleri();
      _kasaOzet = await _db.getKasaOzet();
      _kasaBakiyeleri = await _db.getKasaBakiyeleri();
      _gundelikciler = await _db.getGundelikciler();
      _gundelikciOzet = await _db.getGundelikciOzet();
      _krediler = await _db.getKrediler();
      _krediOzet = await _db.getKrediOzet();
      _ortaklar = await _db.getOrtaklar();
      _ortakOzet = await _db.getOrtakOzet();
      _yaklasanOdemeler = await _db.getYaklasanOdemeler();
      _musteriler = await _db.getMusteriler();
      _satislar = await _db.getSatislar();
      _cariOzet = await _db.getCariOzet();
      _kasalar = await _db.getSettingValues('kasa');
      _kategoriRapor = await _db.getKategoriBazliRapor();
      _aylikRapor = await _db.getAylikHarcamaRaporu(DateTime.now().year);
      _kasaBazliRapor = await _db.getKasaBazliRapor();
      
      // Bildirimleri planla
      await _scheduleNotifications();
    } catch (e) {
      _error = 'Veriler yüklenirken hata: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tüm bildirimleri planla
  Future<void> _scheduleNotifications() async {
    try {
      // Yaklaşan ödemeler için hatırlatmalar
      final bekleyenOdemeler = _yaklasanOdemeler.where((o) => !o.odendi).toList();
      await _notificationService.scheduleAllOdemeHatirlatmalari(bekleyenOdemeler);
      
      // Kredi taksitleri için hatırlatmalar
      await _notificationService.scheduleAllKrediHatirlatmalari(_krediler);
    } catch (e) {
      debugPrint('Bildirim planlama hatası: $e');
    }
  }

  Future<void> loadKasaHareketleri() async {
    _isLoading = true;
    notifyListeners();
    try {
      _kasaHareketleri = await _db.getKasaHareketleri();
      _kasaOzet = await _db.getKasaOzet();
      _kasaBakiyeleri = await _db.getKasaBakiyeleri();
    } catch (e) {
      _error = 'Hata: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    try {
      _kasalar = await _db.getSettingValues('kasa');
    } catch (e) {
      _error = 'Ayarlar yüklenirken hata: $e';
    }
    notifyListeners();
  }

  Future<void> loadGundelikciler() async {
    try {
      _gundelikciler = await _db.getGundelikciler();
      _gundelikciOzet = await _db.getGundelikciOzet();
    } catch (e) {
      _error = 'Gündelikçiler yüklenirken hata: $e';
    }
    notifyListeners();
  }

  Future<void> loadAylikRapor(int yil) async {
    try {
      _aylikRapor = await _db.getAylikHarcamaRaporu(yil);
      notifyListeners();
    } catch (e) {
      _error = 'Aylık rapor yüklenirken hata: $e';
      notifyListeners();
    }
  }

  // ==================== KASA HAREKETLERİ ====================

  Future<bool> addKasaHareketi(KasaHareketi hareket) async {
    try {
      await _db.insertKasaHareketi(hareket);
      await loadKasaHareketleri();

      // Gündelikçi ödemesi ise özeti güncelle
      if (hareket.islemKaynagi == 'gider_pusulasi' || hareket.islemKaynagi == 'resmilestirme') {
        await loadGundelikciler();
      }
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateKasaHareketi(KasaHareketi hareket) async {
    try {
      await _db.updateKasaHareketi(hareket);
      await loadKasaHareketleri();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKasaHareketi(int id) async {
    try {
      await _db.deleteKasaHareketi(id);
      await loadKasaHareketleri();
      await loadGundelikciler();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== GÜNDELİKÇİLER ====================

  Future<bool> addGundelikci(Gundelikci gundelikci) async {
    try {
      await _db.insertGundelikci(gundelikci);
      await loadGundelikciler();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGundelikci(Gundelikci gundelikci) async {
    try {
      await _db.updateGundelikci(gundelikci);
      await loadGundelikciler();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGundelikci(int id) async {
    try {
      await _db.deleteGundelikci(id);
      await loadGundelikciler();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gündelikçiye ödeme yap - kasa işlemi olarak kaydet
  Future<bool> gundelikciyeOdemeYap({
    required Gundelikci gundelikci,
    required double tutar,
    required String kasa,
    required DateTime tarih,
    String? aciklama,
  }) async {
    try {
      final hareket = KasaHareketi(
        tarih: tarih,
        aciklama: aciklama ?? 'Gündelik işçi ücreti',
        islemTipi: 'Çıkış',
        tutar: tutar,
        kasa: kasa,
        islemKaynagi: 'gider_pusulasi',
        iliskiliId: gundelikci.id,
      );
      await _db.insertKasaHareketi(hareket);
      await loadKasaHareketleri();
      await loadGundelikciler();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gider pusulası kes - resmileştirme + vergi
  /// Avans olarak verilen para zaten kasadan çıkmıştı, şimdi sadece:
  /// 1. Resmileştirme kaydı (borcu kapatır, kasadan çıkış yok)
  /// 2. Vergi ödemesi (kasadan çıkış)
  Future<bool> giderPusulasiKes({
    required Gundelikci gundelikci,
    required double brutTutar, // Gider pusulası brüt tutar
    required double vergiTutari, // Ödenecek vergi
    required DateTime tarih,
    String? aciklama,
    String? kasa, // Vergi hangi kasadan ödenecek
  }) async {
    try {
      // 1. Resmileştirme kaydı - borcu kapatır (kasadan çıkış YOK, sadece kayıt)
      final resmilestirme = KasaHareketi(
        tarih: tarih,
        aciklama: aciklama ?? 'Gider Pusulası - ${gundelikci.adSoyad}',
        islemTipi: 'Kayıt', // Kasadan çıkış değil, sadece borç kapatma kaydı
        tutar: brutTutar,
        kasa: null, // Kasadan işlem yok
        islemKaynagi: 'resmilestirme',
        iliskiliId: gundelikci.id,
      );
      await _db.insertKasaHareketi(resmilestirme);

      // 2. Vergi ödemesi - kasadan çıkış
      if (vergiTutari > 0 && kasa != null) {
        final vergi = KasaHareketi(
          tarih: tarih,
          aciklama: 'Gider Pusulası Vergisi - ${gundelikci.adSoyad}',
          islemTipi: 'Çıkış',
          tutar: vergiTutari,
          kasa: kasa,
          islemKaynagi: 'gider_pusulasi_vergi',
          iliskiliId: gundelikci.id,
        );
        await _db.insertKasaHareketi(vergi);
      }

      await loadKasaHareketleri();
      await loadGundelikciler();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== KREDİLER ====================

  List<KrediTaksit> _taksitPlaniOlustur(Kredi kredi) {
    List<KrediTaksit> taksitler = [];
    double kalanBakiye = kredi.cekilenTutar;
    double aylikFaiz = kredi.faizGirisiTuru == 'Yıllık'
        ? kredi.faizOrani / 12 / 100 : kredi.faizOrani / 100;
    int taksitSayisi = kredi.vadeAy ~/ kredi.odemeSikligiAy;
    double taksitTutari = kredi.cekilenTutar / taksitSayisi;
    
    // KKDF ve BSMV oranları (faiz üzerine hesaplanır)
    double kkdfOrani = (kredi.kkdfOrani ?? 0) / 100;
    double bsmvOrani = (kredi.bsmvOrani ?? 0) / 100;

    for (int i = 1; i <= taksitSayisi; i++) {
      DateTime vadeTarihi = kredi.baslangicTarihi.add(Duration(days: 30 * i * kredi.odemeSikligiAy));
      double faiz = kalanBakiye * aylikFaiz * kredi.odemeSikligiAy;
      double kkdf = faiz * kkdfOrani;
      double bsmv = faiz * bsmvOrani;
      double anapara = taksitTutari;
      double toplamTaksit = anapara + faiz + kkdf + bsmv;
      kalanBakiye -= anapara;
      if (kalanBakiye < 0) kalanBakiye = 0;

      taksitler.add(KrediTaksit(
        krediDbId: kredi.id ?? 0, periyot: i, vadeTarihi: vadeTarihi,
        anapara: anapara, faiz: faiz, kkdf: kkdf, bsmv: bsmv, 
        toplamTaksit: toplamTaksit, kalanBakiye: kalanBakiye,
      ));
    }
    return taksitler;
  }

  Future<bool> addKredi(Kredi kredi) async {
    try {
      final krediId = await _db.insertKredi(kredi);
      final krediWithId = kredi.copyWith(id: krediId);
      final taksitler = _taksitPlaniOlustur(krediWithId);
      await _db.saveTaksitler(krediId, taksitler);
      _krediler = await _db.getKrediler();
      _krediOzet = await _db.getKrediOzet();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKredi(int id) async {
    try {
      await _db.deleteKredi(id);
      _krediler = await _db.getKrediler();
      _krediOzet = await _db.getKrediOzet();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> taksitOde(int krediId, int taksitId, DateTime odemeTarihi) async {
    try {
      await _db.taksitOde(taksitId, odemeTarihi);
      _krediler = await _db.getKrediler();
      _krediOzet = await _db.getKrediOzet();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Taksit ödenirken hata: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== ORTAKLAR ====================

  Future<void> loadOrtaklar() async {
    try {
      _ortaklar = await _db.getOrtaklar();
      _ortakOzet = await _db.getOrtakOzet();
    } catch (e) {
      _error = 'Ortaklar yüklenirken hata: $e';
    }
    notifyListeners();
  }

  Future<bool> addOrtak(Ortak ortak) async {
    try {
      await _db.insertOrtak(ortak);
      await loadOrtaklar();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrtak(Ortak ortak) async {
    try {
      await _db.updateOrtak(ortak);
      await loadOrtaklar();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrtak(int id) async {
    try {
      await _db.deleteOrtak(id);
      await loadOrtaklar();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Ortak şirkete para veriyor (avans)
  /// Kasa girişi yok, sadece borç kaydı tutulur
  Future<bool> ortakAvansiAl({
    required Ortak ortak,
    required double tutar,
    required DateTime tarih,
    String paraBirimi = 'TL',
    double? dovizKuru,
    String? aciklama,
  }) async {
    try {
      final tlKarsiligi = paraBirimi != 'TL' && dovizKuru != null 
          ? tutar * dovizKuru 
          : null;
          
      final hareket = KasaHareketi(
        tarih: tarih,
        aciklama: aciklama ?? 'Ortak Avansı - ${ortak.adSoyad}',
        islemTipi: 'Kayıt', // Kasadan işlem yok, sadece borç kaydı
        tutar: tutar,
        paraBirimi: paraBirimi,
        dovizKuru: dovizKuru,
        tlKarsiligi: tlKarsiligi,
        kasa: null, // Kasa seçimi yok
        islemKaynagi: 'ortak_avans',
        iliskiliId: ortak.id,
      );
      await _db.insertKasaHareketi(hareket);
      await loadOrtaklar();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Şirket ortağa geri ödeme yapıyor
  /// Şirket kasasından ÇIKIŞ
  Future<bool> ortakGeriOdeme({
    required Ortak ortak,
    required double tutar,
    required String kasa,
    required DateTime tarih,
    String paraBirimi = 'TL',
    double? dovizKuru,
    String? aciklama,
  }) async {
    try {
      final tlKarsiligi = paraBirimi != 'TL' && dovizKuru != null 
          ? tutar * dovizKuru 
          : null;
          
      final hareket = KasaHareketi(
        tarih: tarih,
        aciklama: aciklama ?? 'Ortak Geri Ödeme - ${ortak.adSoyad}',
        islemTipi: 'Çıkış',
        tutar: tutar,
        paraBirimi: paraBirimi,
        dovizKuru: dovizKuru,
        tlKarsiligi: tlKarsiligi,
        kasa: kasa,
        islemKaynagi: 'ortak_geri_odeme',
        iliskiliId: ortak.id,
      );
      await _db.insertKasaHareketi(hareket);
      await loadKasaHareketleri();
      await loadOrtaklar();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Ortak ödemesini stopajlı resmileştir
  /// Brüt tutar üzerinden stopaj kesilir, net tutar ödenir
  /// Bu işlem borcu kapatır ve stopaj kaydı oluşturur
  Future<bool> ortakOdemesiResmilestir({
    required Ortak ortak,
    required double brutTutar,       // Resmileştirilecek brüt tutar
    required double stopajTutari,    // Kesilecek stopaj
    required double netOdeme,        // Ortağa ödenecek net tutar
    required String kasa,
    required DateTime tarih,
    String paraBirimi = 'TL',
    double? dovizKuru,
    String? aciklama,
  }) async {
    try {
      final tlKarsiligistopaj = paraBirimi != 'TL' && dovizKuru != null 
          ? stopajTutari * dovizKuru 
          : null;
      final tlKarsiliginet = paraBirimi != 'TL' && dovizKuru != null 
          ? netOdeme * dovizKuru 
          : null;

      // 1. Geri ödeme kaydı (net tutar - ortağa ödenen)
      final geriOdeme = KasaHareketi(
        tarih: tarih,
        aciklama: aciklama ?? 'Ortak Geri Ödeme (Net) - ${ortak.adSoyad}',
        islemTipi: 'Çıkış',
        tutar: netOdeme,
        paraBirimi: paraBirimi,
        dovizKuru: dovizKuru,
        tlKarsiligi: tlKarsiliginet,
        kasa: kasa,
        islemKaynagi: 'ortak_geri_odeme',
        iliskiliId: ortak.id,
      );
      await _db.insertKasaHareketi(geriOdeme);

      // 2. Stopaj kaydı (vergi olarak kesilen, borcu azaltır)
      if (stopajTutari > 0) {
        final stopaj = KasaHareketi(
          tarih: tarih,
          aciklama: 'Ortak Stopaj (%${ortak.stopajOrani.toStringAsFixed(0)}) - ${ortak.adSoyad}',
          islemTipi: 'Kayıt', // Kasadan çıkış yok, sadece borç düşer
          tutar: stopajTutari,
          paraBirimi: paraBirimi,
          dovizKuru: dovizKuru,
          tlKarsiligi: tlKarsiligistopaj,
          kasa: null,
          islemKaynagi: 'ortak_stopaj',
          iliskiliId: ortak.id,
        );
        await _db.insertKasaHareketi(stopaj);
      }

      await loadKasaHareketleri();
      await loadOrtaklar();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== SETTINGS ====================

  Future<bool> addSetting(String tip, String deger) async {
    try {
      await _db.insertSetting(AppSettings(tip: tip, deger: deger));
      await loadSettings();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSettingWithOrtak(String tip, String deger, int? ortakId) async {
    try {
      await _db.insertSetting(AppSettings(tip: tip, deger: deger, ortakId: ortakId));
      await loadSettings();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSetting(AppSettings setting) async {
    try {
      await _db.updateSetting(setting);
      await loadSettings();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSetting(int id) async {
    try {
      await _db.deleteSetting(id);
      await loadSettings();
      return true;
    } catch (e) {
      _error = 'Hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<AppSettings>> getSettingsList(String tip) async {
    return await _db.getSettings(tip);
  }

  /// Belirli bir ortağa ait kasaları getir
  Future<List<AppSettings>> getKasalarByOrtak(int ortakId) async {
    final allKasalar = await _db.getSettings('kasa');
    return allKasalar.where((k) => k.ortakId == ortakId).toList();
  }

  /// Belirli bir kasanın ortağını getir
  Ortak? getOrtakByKasa(String kasaAdi) {
    // Bu senkron olmalı, kasalar listesinden çekilecek
    return null; // Async sorgu gerekiyor, aşağıda metod var
  }

  /// Kasadan ortağı bul (async)
  Future<Ortak?> getOrtakByKasaAsync(String kasaAdi) async {
    final kasalar = await _db.getSettings('kasa');
    final kasa = kasalar.where((k) => k.deger == kasaAdi).firstOrNull;
    if (kasa?.ortakId == null) return null;
    return await _db.getOrtakById(kasa!.ortakId!);
  }

  // ==================== YAKLAŞAN ÖDEMELER ====================

  Future<void> addYaklasanOdeme(YaklasanOdeme odeme) async {
    try {
      await _db.insertYaklasanOdeme(odeme);
      _yaklasanOdemeler = await _db.getYaklasanOdemeler();
      notifyListeners();
    } catch (e) {
      _error = 'Ödeme eklenirken hata: $e';
      notifyListeners();
    }
  }

  Future<void> updateYaklasanOdeme(YaklasanOdeme odeme) async {
    try {
      await _db.updateYaklasanOdeme(odeme);
      _yaklasanOdemeler = await _db.getYaklasanOdemeler();
      notifyListeners();
    } catch (e) {
      _error = 'Ödeme güncellenirken hata: $e';
      notifyListeners();
    }
  }

  Future<void> deleteYaklasanOdeme(int id) async {
    try {
      await _db.deleteYaklasanOdeme(id);
      _yaklasanOdemeler = await _db.getYaklasanOdemeler();
      notifyListeners();
    } catch (e) {
      _error = 'Ödeme silinirken hata: $e';
      notifyListeners();
    }
  }

  Future<void> odemeyiKapat(int odemeId, {KasaHareketi? kasaHareketi}) async {
    try {
      await _db.odemeyiKapat(odemeId);
      if (kasaHareketi != null) {
        await _db.insertKasaHareketi(kasaHareketi);
        _kasaHareketleri = await _db.getKasaHareketleri();
        _kasaOzet = await _db.getKasaOzet();
        _kasaBakiyeleri = await _db.getKasaBakiyeleri();
      }
      _yaklasanOdemeler = await _db.getYaklasanOdemeler();
      notifyListeners();
    } catch (e) {
      _error = 'Ödeme kapatılırken hata: $e';
      notifyListeners();
    }
  }

  // ==================== RAPORLAR ====================

  Future<void> loadRaporlar(int yil) async {
    try {
      _aylikRapor = await _db.getAylikHarcamaRaporu(yil);
      _kategoriRapor = await _db.getKategoriBazliRapor();
      _kasaBazliRapor = await _db.getKasaBazliRapor();
      notifyListeners();
    } catch (e) {
      _error = 'Rapor hatası: $e';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== MÜŞTERİLER ====================

  Future<void> loadMusteriler() async {
    try {
      _musteriler = await _db.getMusteriler();
      _cariOzet = await _db.getCariOzet();
      notifyListeners();
    } catch (e) {
      _error = 'Müşteriler yüklenirken hata: $e';
      notifyListeners();
    }
  }

  Future<bool> addMusteri(Musteri musteri) async {
    try {
      await _db.insertMusteri(musteri);
      await loadMusteriler();
      return true;
    } catch (e) {
      _error = 'Müşteri eklenirken hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMusteri(Musteri musteri) async {
    try {
      await _db.updateMusteri(musteri);
      await loadMusteriler();
      return true;
    } catch (e) {
      _error = 'Müşteri güncellenirken hata: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteMusteri(int id) async {
    try {
      await _db.deleteMusteri(id);
      await loadMusteriler();
    } catch (e) {
      _error = 'Müşteri silinirken hata: $e';
      notifyListeners();
    }
  }

  Future<Map<String, double>> getMusteriBakiye(int musteriId) async {
    return await _db.getMusteriBakiye(musteriId);
  }

  // ==================== SATIŞLAR ====================

  Future<void> loadSatislar({int? musteriId}) async {
    try {
      _satislar = await _db.getSatislar(musteriId: musteriId);
      _cariOzet = await _db.getCariOzet();
      notifyListeners();
    } catch (e) {
      _error = 'Satışlar yüklenirken hata: $e';
      notifyListeners();
    }
  }

  Future<void> addSatis(Satis satis) async {
    try {
      await _db.insertSatis(satis);
      await loadSatislar();
      await loadMusteriler();
    } catch (e) {
      _error = 'Satış eklenirken hata: $e';
      notifyListeners();
    }
  }

  Future<void> updateSatis(Satis satis) async {
    try {
      await _db.updateSatis(satis);
      await loadSatislar();
      await loadMusteriler();
    } catch (e) {
      _error = 'Satış güncellenirken hata: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSatis(int id) async {
    try {
      await _db.deleteSatis(id);
      await loadSatislar();
      await loadMusteriler();
    } catch (e) {
      _error = 'Satış silinirken hata: $e';
      notifyListeners();
    }
  }

  // ==================== TAHSİLATLAR ====================

  Future<void> addTahsilat({
    required int musteriId,
    required DateTime tarih,
    required double tutar,
    String paraBirimi = 'TL',
    double? dovizKuru,
    String odemeSekli = 'nakit',
    String? kasaAdi,
    String? cekSenetNo,
    DateTime? cekVadeTarihi,
    String? bankaAdi,
    String? aciklama,
  }) async {
    try {
      final tahsilat = {
        'musteri_id': musteriId,
        'tarih': tarih.toIso8601String(),
        'tutar': tutar,
        'para_birimi': paraBirimi,
        'doviz_kuru': dovizKuru,
        'tl_karsiligi': dovizKuru != null ? tutar * dovizKuru : null,
        'odeme_sekli': odemeSekli,
        'kasa_adi': kasaAdi,
        'cek_senet_no': cekSenetNo,
        'cek_vade_tarihi': cekVadeTarihi?.toIso8601String(),
        'banka_adi': bankaAdi,
        'aciklama': aciklama,
      };
      
      await _db.insertTahsilat(tahsilat);
      
      // Kasa hareketi olarak da kaydet
      if (kasaAdi != null && kasaAdi.isNotEmpty) {
        final musteri = _musteriler.firstWhere((m) => m.id == musteriId);
        final kasaHareketi = KasaHareketi(
          tarih: tarih,
          aciklama: '${musteri.unvan} - Tahsilat',
          islemTipi: 'Gelir',
          tutar: tutar,
          odemeBicimi: odemeSekli,
          kasa: kasaAdi,
          notlar: aciklama,
          paraBirimi: paraBirimi,
          dovizKuru: dovizKuru,
          tlKarsiligi: dovizKuru != null ? tutar * dovizKuru : null,
          islemKaynagi: 'tahsilat',
          iliskiliId: musteriId,
        );
        await _db.insertKasaHareketi(kasaHareketi);
        await loadKasaHareketleri();
      }
      
      await loadMusteriler();
      await loadSatislar();
    } catch (e) {
      _error = 'Tahsilat eklenirken hata: $e';
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getTahsilatlar({int? musteriId}) async {
    return await _db.getTahsilatlar(musteriId: musteriId);
  }

  Future<void> deleteTahsilat(int id) async {
    try {
      await _db.deleteTahsilat(id);
      await loadMusteriler();
      await loadSatislar();
    } catch (e) {
      _error = 'Tahsilat silinirken hata: $e';
      notifyListeners();
    }
  }
}
