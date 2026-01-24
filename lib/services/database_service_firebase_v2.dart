// Web için Firebase Firestore database service - V2 Simplified
import 'package:cloud_firestore/cloud_firestore.dart';
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

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Firebase doc.id -> int id mapping (hashCode çakışmasını önlemek için)
  final Map<String, Map<int, String>> _idMaps = {
    'kasa_hareketleri': {},
    'gundelikciler': {},
    'krediler': {},
    'kredi_taksitleri': {},
    'ortaklar': {},
    'yaklasan_odemeler': {},
    'musteriler': {},
    'satislar': {},
    'tahsilatlar': {},
    'settings': {},
  };
  
  int _autoId = 1;
  
  int _getIntId(String collection, String docId) {
    // Eğer bu docId için zaten bir int id varsa, onu döndür
    final map = _idMaps[collection]!;
    for (var entry in map.entries) {
      if (entry.value == docId) {
        return entry.key;
      }
    }
    // Yoksa yeni bir id ata
    final newId = _autoId++;
    map[newId] = docId;
    return newId;
  }
  
  String? _getDocId(String collection, int intId) {
    return _idMaps[collection]?[intId];
  }

  // ==================== KASA ====================
  Future<int> insertKasaHareketi(KasaHareketi hareket) async {
    try {
      final docRef = await _db.collection('kasa_hareketleri').add({
        'tarih': hareket.tarih.toIso8601String(),
        'aciklama': hareket.aciklama,
        'islem_tipi': hareket.islemTipi,
        'tutar': hareket.tutar,
        'odeme_bicimi': hareket.odemeBicimi,
        'kasa': hareket.kasa,
        'notlar': hareket.notlar,
        'para_birimi': hareket.paraBirimi,
        'doviz_kuru': hareket.dovizKuru,
        'tl_karsiligi': hareket.tlKarsiligi,
        'islem_kaynagi': hareket.islemKaynagi,
        'iliskili_id': hareket.iliskiliId,
      });
      return _getIntId('kasa_hareketleri', docRef.id);
    } catch (e) {
      print('insertKasaHareketi error: $e');
      return -1;
    }
  }

  Future<List<KasaHareketi>> getKasaHareketleri({int? limit, String? islemKaynagi}) async {
    try {
      final snapshot = await _db.collection('kasa_hareketleri').get();
      List<KasaHareketi> list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('kasa_hareketleri', doc.id);
        return KasaHareketi.fromMap(data);
      }).toList();
      
      if (islemKaynagi != null) {
        list = list.where((h) => h.islemKaynagi == islemKaynagi).toList();
      }
      list.sort((a, b) => b.tarih.compareTo(a.tarih));
      if (limit != null) {
        return list.take(limit).toList();
      }
      return list;
    } catch (e) {
      print('getKasaHareketleri error: $e');
      return [];
    }
  }

  Future<int> updateKasaHareketi(KasaHareketi hareket) async {
    try {
      final docId = _getDocId('kasa_hareketleri', hareket.id!);
      if (docId == null) return 0;
      
      await _db.collection('kasa_hareketleri').doc(docId).update({
        'tarih': hareket.tarih.toIso8601String(),
        'aciklama': hareket.aciklama,
        'islem_tipi': hareket.islemTipi,
        'tutar': hareket.tutar,
        'odeme_bicimi': hareket.odemeBicimi,
        'kasa': hareket.kasa,
        'notlar': hareket.notlar,
        'para_birimi': hareket.paraBirimi,
        'doviz_kuru': hareket.dovizKuru,
        'tl_karsiligi': hareket.tlKarsiligi,
      });
      return 1;
    } catch (e) {
      print('updateKasaHareketi error: $e');
      return 0;
    }
  }

  Future<int> deleteKasaHareketi(int id) async {
    try {
      final docId = _getDocId('kasa_hareketleri', id);
      if (docId == null) return 0;
      
      await _db.collection('kasa_hareketleri').doc(docId).delete();
      _idMaps['kasa_hareketleri']!.remove(id);
      return 1;
    } catch (e) {
      print('deleteKasaHareketi error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getKasaBakiyeleri() async {
    try {
      final hareketler = await getKasaHareketleri();
      final Map<String, Map<String, double>> bakiyeler = {};
      
      for (var h in hareketler) {
        // Kasa null olanları (resmileştirme gibi) dahil etme
        if (h.kasa == null || h.kasa!.isEmpty) continue;
        
        final kasa = h.kasa!;
        final tutar = h.tlKarsiligi ?? h.tutar;
        bakiyeler[kasa] ??= {'bakiye': 0, 'toplam_giris': 0, 'toplam_cikis': 0};
        if (h.islemTipi == 'Giriş') {
          bakiyeler[kasa]!['bakiye'] = bakiyeler[kasa]!['bakiye']! + tutar;
          bakiyeler[kasa]!['toplam_giris'] = bakiyeler[kasa]!['toplam_giris']! + tutar;
        } else if (h.islemTipi == 'Çıkış') {
          bakiyeler[kasa]!['bakiye'] = bakiyeler[kasa]!['bakiye']! - tutar;
          bakiyeler[kasa]!['toplam_cikis'] = bakiyeler[kasa]!['toplam_cikis']! + tutar;
        }
      }
      
      return bakiyeler.entries.map((e) => {
        'kasa': e.key, 
        'bakiye': e.value['bakiye'], 
        'toplam_giris': e.value['toplam_giris'],
        'toplam_cikis': e.value['toplam_cikis'],
      }).toList();
    } catch (e) {
      print('getKasaBakiyeleri error: $e');
      return [];
    }
  }

  Future<Map<String, double>> getKasaOzet() async {
    try {
      final hareketler = await getKasaHareketleri();
      double toplamGiris = 0, toplamCikis = 0;
      
      for (var h in hareketler) {
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
    } catch (e) {
      print('getKasaOzet error: $e');
      return {'toplamGiris': 0, 'toplamCikis': 0, 'bakiye': 0};
    }
  }

  // ==================== GÜNDELİKÇİLER ====================
  Future<int> insertGundelikci(Gundelikci g) async {
    try {
      final docRef = await _db.collection('gundelikciler').add(g.toMap());
      return _getIntId('gundelikciler', docRef.id);
    } catch (e) {
      print('insertGundelikci error: $e');
      return -1;
    }
  }

  Future<List<Gundelikci>> getGundelikciler() async {
    try {
      final snapshot = await _db.collection('gundelikciler').get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('gundelikciler', doc.id);
        return Gundelikci.fromMap(data);
      }).where((g) => g.aktif).toList();
    } catch (e) {
      print('getGundelikciler error: $e');
      return [];
    }
  }

  Future<Map<String, double>> getGundelikciOdemeToplami(int gundelikciId) async {
    try {
      final hareketler = await getKasaHareketleri(islemKaynagi: 'gundelikci');
      double toplam = 0;
      for (var h in hareketler) {
        if (h.iliskiliId == gundelikciId) {
          toplam += h.tlKarsiligi ?? h.tutar;
        }
      }
      return {'toplam': toplam};
    } catch (e) {
      return {'toplam': 0};
    }
  }

  Future<int> updateGundelikci(Gundelikci g) async {
    try {
      final docId = _getDocId('gundelikciler', g.id!);
      if (docId == null) return 0;
      
      await _db.collection('gundelikciler').doc(docId).update(g.toMap());
      return 1;
    } catch (e) {
      print('updateGundelikci error: $e');
      return 0;
    }
  }

  Future<int> deleteGundelikci(int id) async {
    try {
      final docId = _getDocId('gundelikciler', id);
      if (docId == null) return 0;
      
      await _db.collection('gundelikciler').doc(docId).update({'aktif': false});
      return 1;
    } catch (e) {
      print('deleteGundelikci error: $e');
      return 0;
    }
  }

  Future<Map<String, double>> getGundelikciOzet() async {
    try {
      final gundelikciler = await getGundelikciler();
      final hareketler = await getKasaHareketleri(islemKaynagi: 'gundelikci');
      double toplamOdeme = 0;
      for (var h in hareketler) {
        toplamOdeme += h.tlKarsiligi ?? h.tutar;
      }
      return {
        'toplamOdeme': toplamOdeme,
        'toplamCalisan': gundelikciler.length.toDouble(),
      };
    } catch (e) {
      return {'toplamOdeme': 0, 'toplamCalisan': 0};
    }
  }

  // ==================== KREDİLER ====================
  Future<int> insertKredi(Kredi k) async {
    try {
      final docRef = await _db.collection('krediler').add(k.toMap());
      return docRef.id.hashCode.abs();
    } catch (e) {
      print('insertKredi error: $e');
      return -1;
    }
  }

  Future<List<Kredi>> getKrediler() async {
    try {
      final snapshot = await _db.collection('krediler').get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('krediler', doc.id);
        return Kredi.fromMap(data);
      }).toList();
    } catch (e) {
      print('getKrediler error: $e');
      return [];
    }
  }

  Future<int> updateKredi(Kredi k) async {
    try {
      final docId = _getDocId('krediler', k.id!);
      if (docId == null) return 0;
      
      await _db.collection('krediler').doc(docId).update(k.toMap());
      return 1;
    } catch (e) {
      print('updateKredi error: $e');
      return 0;
    }
  }

  Future<int> deleteKredi(int id) async {
    try {
      final docId = _getDocId('krediler', id);
      if (docId == null) return 0;
      
      await _db.collection('krediler').doc(docId).delete();
      // Taksitleri de sil (kredi_db_id ile kayıtlı olanları)
      final taksitSnapshot = await _db.collection('kredi_taksitleri').get();
      for (var t in taksitSnapshot.docs) {
        final data = t.data();
        if (data['kredi_db_id'] == id) {
          await t.reference.delete();
        }
      }
      _idMaps['krediler']!.remove(id);
      return 1;
    } catch (e) {
      print('deleteKredi error: $e');
      return 0;
    }
  }

  Future<void> saveTaksitler(int krediDbId, List<KrediTaksit> taksitler) async {
    try {
      // Önce mevcut taksitleri sil
      final snapshot = await _db.collection('kredi_taksitleri').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['kredi_db_id'] == krediDbId) {
          await doc.reference.delete();
        }
      }
      // Yeni taksitleri ekle
      for (var t in taksitler) {
        final map = t.toMap();
        map['kredi_db_id'] = krediDbId;
        await _db.collection('kredi_taksitleri').add(map);
      }
    } catch (e) {
      print('saveTaksitler error: $e');
    }
  }

  Future<List<KrediTaksit>> getTaksitler(int krediDbId) async {
    try {
      final snapshot = await _db.collection('kredi_taksitleri').get();
      return snapshot.docs.where((doc) {
        return doc.data()['kredi_db_id'] == krediDbId;
      }).map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('kredi_taksitleri', doc.id);
        return KrediTaksit.fromMap(data);
      }).toList()..sort((a, b) => a.periyot.compareTo(b.periyot));
    } catch (e) {
      print('getTaksitler error: $e');
      return [];
    }
  }

  Future<void> taksitOde(int taksitId, DateTime odemeTarihi) async {
    try {
      final docId = _getDocId('kredi_taksitleri', taksitId);
      if (docId == null) return;
      
      await _db.collection('kredi_taksitleri').doc(docId).update({
        'odendi': true, 
        'odeme_tarihi': odemeTarihi.toIso8601String()
      });
    } catch (e) {
      print('taksitOde error: $e');
    }
  }

  Future<Map<String, double>> getKrediOzet() async {
    try {
      final krediler = await getKrediler();
      double toplamBorc = 0, odenenTutar = 0;
      
      for (var k in krediler) {
        toplamBorc += k.cekilenTutar;
        final taksitler = await getTaksitler(k.id!);
        for (var t in taksitler) {
          if (t.odendi) odenenTutar += t.toplamTaksit;
        }
      }
      
      return {
        'toplamBorc': toplamBorc,
        'odenenTutar': odenenTutar,
        'kalanBorc': toplamBorc - odenenTutar,
        'krediSayisi': krediler.length.toDouble(),
      };
    } catch (e) {
      return {'toplamBorc': 0, 'odenenTutar': 0, 'kalanBorc': 0, 'krediSayisi': 0};
    }
  }

  // ==================== SETTINGS ====================
  Future<int> insertSetting(AppSettings s) async {
    try {
      final docRef = await _db.collection('settings').add(s.toMap());
      return _getIntId('settings', docRef.id);
    } catch (e) {
      print('insertSetting error: $e');
      return -1;
    }
  }

  Future<List<AppSettings>> getSettings(String tip) async {
    try {
      final snapshot = await _db.collection('settings').get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('settings', doc.id);
        return AppSettings.fromMap(data);
      }).where((s) => s.tip == tip && s.aktif).toList();
    } catch (e) {
      print('getSettings error: $e');
      return [];
    }
  }

  Future<List<String>> getSettingValues(String tip) async {
    try {
      final settings = await getSettings(tip);
      // Eğer ayarlardan kasa tanımlanmamışsa boş liste döndür
      return settings.map((s) => s.deger).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> updateSetting(AppSettings s) async {
    try {
      final docId = _getDocId('settings', s.id!);
      if (docId == null) return 0;
      
      await _db.collection('settings').doc(docId).update(s.toMap());
      return 1;
    } catch (e) {
      print('updateSetting error: $e');
      return 0;
    }
  }

  Future<int> deleteSetting(int id) async {
    try {
      final docId = _getDocId('settings', id);
      if (docId == null) return 0;
      
      await _db.collection('settings').doc(docId).update({'aktif': false});
      return 1;
    } catch (e) {
      print('deleteSetting error: $e');
      return 0;
    }
  }

  // ==================== ORTAKLAR ====================
  Future<int> insertOrtak(Ortak o) async {
    try {
      final docRef = await _db.collection('ortaklar').add(o.toMap());
      return _getIntId('ortaklar', docRef.id);
    } catch (e) {
      print('insertOrtak error: $e');
      return -1;
    }
  }

  Future<List<Ortak>> getOrtaklar() async {
    try {
      final snapshot = await _db.collection('ortaklar').get();
      final hareketler = await getKasaHareketleri();
      
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        final ortakId = _getIntId('ortaklar', doc.id);
        data['id'] = ortakId;
        
        // Bu ortağın işlemlerini hesapla
        double toplamVerilen = 0;
        double toplamGeriOdenen = 0;
        double toplamStopaj = 0;
        
        for (var h in hareketler) {
          if (h.iliskiliId == ortakId) {
            final tutar = h.tlKarsiligi ?? h.tutar;
            if (h.islemKaynagi == 'ortak_avans') {
              toplamVerilen += tutar;
            } else if (h.islemKaynagi == 'ortak_geri_odeme') {
              toplamGeriOdenen += tutar;
            } else if (h.islemKaynagi == 'ortak_stopaj') {
              toplamStopaj += tutar;
            }
          }
        }
        
        return Ortak.fromMap(data).copyWith(
          toplamVerilen: toplamVerilen,
          toplamGeriOdenen: toplamGeriOdenen,
          toplamStopaj: toplamStopaj,
        );
      }).where((o) => o.aktif).toList();
    } catch (e) {
      print('getOrtaklar error: $e');
      return [];
    }
  }

  Future<Ortak?> getOrtakById(int id) async {
    try {
      final ortaklar = await getOrtaklar();
      return ortaklar.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, double>> getOrtakBakiye(int ortakId) async {
    try {
      final hareketler = await getKasaHareketleri(islemKaynagi: 'ortak');
      double bakiye = 0;
      for (var h in hareketler) {
        if (h.iliskiliId == ortakId) {
          if (h.islemTipi == 'Giriş') {
            bakiye += h.tlKarsiligi ?? h.tutar;
          } else {
            bakiye -= h.tlKarsiligi ?? h.tutar;
          }
        }
      }
      return {'bakiye': bakiye};
    } catch (e) {
      return {'bakiye': 0};
    }
  }

  Future<int> updateOrtak(Ortak o) async {
    try {
      final docId = _getDocId('ortaklar', o.id!);
      if (docId == null) return 0;
      
      await _db.collection('ortaklar').doc(docId).update(o.toMap());
      return 1;
    } catch (e) {
      print('updateOrtak error: $e');
      return 0;
    }
  }

  Future<int> deleteOrtak(int id) async {
    try {
      final docId = _getDocId('ortaklar', id);
      if (docId == null) return 0;
      
      await _db.collection('ortaklar').doc(docId).update({'aktif': false});
      return 1;
    } catch (e) {
      print('deleteOrtak error: $e');
      return 0;
    }
  }

  Future<Map<String, double>> getOrtakOzet() async {
    try {
      final hareketler = await getKasaHareketleri();
      
      double toplamVerilen = 0;
      double toplamGeriOdenen = 0;
      double toplamStopaj = 0;
      
      for (var h in hareketler) {
        final tutar = h.tlKarsiligi ?? h.tutar;
        if (h.islemKaynagi == 'ortak_avans') {
          // Ortağın şirket için yaptığı harcama (şirketin ortağa borcu)
          toplamVerilen += tutar;
        } else if (h.islemKaynagi == 'ortak_geri_odeme') {
          // Şirketin ortağa geri ödemesi
          toplamGeriOdenen += tutar;
        } else if (h.islemKaynagi == 'ortak_stopaj') {
          // Kesilen stopaj
          toplamStopaj += tutar;
        }
      }
      
      final kalanBorc = toplamVerilen - toplamGeriOdenen - toplamStopaj;
      
      return {
        'toplam_verilen': toplamVerilen,
        'toplam_geri_odenen': toplamGeriOdenen,
        'toplam_stopaj': toplamStopaj,
        'kalan_borc': kalanBorc,
      };
    } catch (e) {
      return {
        'toplam_verilen': 0,
        'toplam_geri_odenen': 0,
        'toplam_stopaj': 0,
        'kalan_borc': 0,
      };
    }
  }

  // ==================== RAPORLAR ====================
  Future<List<Map<String, dynamic>>> getAylikHarcamaRaporu(int yil) async {
    try {
      final hareketler = await getKasaHareketleri();
      final Map<int, Map<String, double>> aylik = {};
      
      for (int i = 1; i <= 12; i++) {
        aylik[i] = {'giris': 0.0, 'cikis': 0.0};
      }
      
      for (var h in hareketler) {
        if (h.tarih.year == yil) {
          final ay = h.tarih.month;
          final tutar = h.tlKarsiligi ?? h.tutar;
          if (h.islemTipi == 'Giriş') {
            aylik[ay]!['giris'] = aylik[ay]!['giris']! + tutar;
          } else {
            aylik[ay]!['cikis'] = aylik[ay]!['cikis']! + tutar;
          }
        }
      }
      
      return aylik.entries.map((e) => {
        'ay': e.key,
        'giris': e.value['giris'],
        'cikis': e.value['cikis'],
      }).toList();
    } catch (e) {
      return List.generate(12, (i) => {'ay': i + 1, 'giris': 0.0, 'cikis': 0.0});
    }
  }

  Future<List<Map<String, dynamic>>> getKategoriBazliRapor() async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getKasaBazliRapor() async {
    return await getKasaBakiyeleri();
  }

  // ==================== YAKLASAN ÖDEMELER ====================
  Future<int> insertYaklasanOdeme(YaklasanOdeme o) async {
    try {
      final docRef = await _db.collection('yaklasan_odemeler').add(o.toMap());
      return _getIntId('yaklasan_odemeler', docRef.id);
    } catch (e) {
      print('insertYaklasanOdeme error: $e');
      return -1;
    }
  }

  Future<List<YaklasanOdeme>> getYaklasanOdemeler({bool sadeceBekleyenler = false}) async {
    try {
      final snapshot = await _db.collection('yaklasan_odemeler').get();
      List<YaklasanOdeme> list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('yaklasan_odemeler', doc.id);
        return YaklasanOdeme.fromMap(data);
      }).toList();
      
      if (sadeceBekleyenler) {
        list = list.where((o) => !o.odendi).toList();
      }
      list.sort((a, b) => a.vadeTarihi.compareTo(b.vadeTarihi));
      return list;
    } catch (e) {
      print('getYaklasanOdemeler error: $e');
      return [];
    }
  }

  Future<List<YaklasanOdeme>> getYaklasanOdemelerByDateRange(DateTime start, DateTime end) async {
    try {
      final odemeler = await getYaklasanOdemeler();
      return odemeler.where((o) => 
        o.vadeTarihi.isAfter(start) && o.vadeTarihi.isBefore(end)
      ).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> updateYaklasanOdeme(YaklasanOdeme o) async {
    try {
      final docId = _getDocId('yaklasan_odemeler', o.id!);
      if (docId == null) return 0;
      
      await _db.collection('yaklasan_odemeler').doc(docId).update(o.toMap());
      return 1;
    } catch (e) {
      print('updateYaklasanOdeme error: $e');
      return 0;
    }
  }

  Future<int> deleteYaklasanOdeme(int id) async {
    try {
      final docId = _getDocId('yaklasan_odemeler', id);
      if (docId == null) return 0;
      
      await _db.collection('yaklasan_odemeler').doc(docId).delete();
      _idMaps['yaklasan_odemeler']!.remove(id);
      return 1;
    } catch (e) {
      print('deleteYaklasanOdeme error: $e');
      return 0;
    }
  }

  Future<int> odemeyiKapat(int id) async {
    try {
      final docId = _getDocId('yaklasan_odemeler', id);
      if (docId == null) return 0;
      
      await _db.collection('yaklasan_odemeler').doc(docId).update({
        'odendi': true,
        'odenme_tarihi': DateTime.now().toIso8601String(),
      });
      return 1;
    } catch (e) {
      print('odemeyiKapat error: $e');
      return 0;
    }
  }

  // ==================== MÜŞTERİLER ====================
  Future<int> insertMusteri(Musteri m) async {
    try {
      final docRef = await _db.collection('musteriler').add(m.toMap());
      return _getIntId('musteriler', docRef.id);
    } catch (e) {
      print('insertMusteri error: $e');
      return -1;
    }
  }

  Future<List<Musteri>> getMusteriler({bool sadecAktif = true}) async {
    try {
      final snapshot = await _db.collection('musteriler').get();
      List<Musteri> list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('musteriler', doc.id);
        return Musteri.fromMap(data);
      }).toList();
      
      if (sadecAktif) {
        list = list.where((m) => m.aktif).toList();
      }
      return list;
    } catch (e) {
      print('getMusteriler error: $e');
      return [];
    }
  }

  Future<Musteri?> getMusteri(int id) async {
    try {
      final musteriler = await getMusteriler(sadecAktif: false);
      return musteriler.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateMusteri(Musteri m) async {
    try {
      final docId = _getDocId('musteriler', m.id!);
      if (docId == null) return 0;
      
      await _db.collection('musteriler').doc(docId).update(m.toMap());
      return 1;
    } catch (e) {
      print('updateMusteri error: $e');
      return 0;
    }
  }

  Future<int> deleteMusteri(int id) async {
    try {
      final docId = _getDocId('musteriler', id);
      if (docId == null) return 0;
      
      await _db.collection('musteriler').doc(docId).update({'aktif': false});
      return 1;
    } catch (e) {
      print('deleteMusteri error: $e');
      return 0;
    }
  }

  Future<Map<String, double>> getMusteriBakiye(int musteriId) async {
    try {
      final satislar = await getSatislar(musteriId: musteriId);
      final tahsilatlar = await getTahsilatlar(musteriId: musteriId);
      
      double toplamSatis = 0, toplamTahsilat = 0;
      for (var s in satislar) {
        toplamSatis += s.toplamTutar;
      }
      for (var t in tahsilatlar) {
        toplamTahsilat += (t['tutar'] as num).toDouble();
      }
      
      return {'bakiye': toplamSatis - toplamTahsilat};
    } catch (e) {
      return {'bakiye': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getMusterilerWithBakiye() async {
    try {
      final musteriler = await getMusteriler();
      List<Map<String, dynamic>> result = [];
      
      for (var m in musteriler) {
        final bakiye = await getMusteriBakiye(m.id!);
        result.add({
          'id': m.id,
          'unvan': m.unvan,
          'bakiye': bakiye['bakiye'],
        });
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  // ==================== SATIŞLAR ====================
  Future<int> insertSatis(Satis s) async {
    try {
      final docRef = await _db.collection('satislar').add(s.toMap());
      return _getIntId('satislar', docRef.id);
    } catch (e) {
      print('insertSatis error: $e');
      return -1;
    }
  }

  Future<List<Satis>> getSatislar({int? musteriId, DateTime? baslangic, DateTime? bitis}) async {
    try {
      final snapshot = await _db.collection('satislar').get();
      List<Satis> list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('satislar', doc.id);
        return Satis.fromMap(data);
      }).toList();
      
      if (musteriId != null) {
        list = list.where((s) => s.musteriId == musteriId).toList();
      }
      if (baslangic != null) {
        list = list.where((s) => s.tarih.isAfter(baslangic)).toList();
      }
      if (bitis != null) {
        list = list.where((s) => s.tarih.isBefore(bitis)).toList();
      }
      list.sort((a, b) => b.tarih.compareTo(a.tarih));
      return list;
    } catch (e) {
      print('getSatislar error: $e');
      return [];
    }
  }

  Future<Satis?> getSatis(int id) async {
    try {
      final satislar = await getSatislar();
      return satislar.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateSatis(Satis s) async {
    try {
      final docId = _getDocId('satislar', s.id!);
      if (docId == null) return 0;
      
      await _db.collection('satislar').doc(docId).update(s.toMap());
      return 1;
    } catch (e) {
      print('updateSatis error: $e');
      return 0;
    }
  }

  Future<int> deleteSatis(int id) async {
    try {
      final docId = _getDocId('satislar', id);
      if (docId == null) return 0;
      
      await _db.collection('satislar').doc(docId).delete();
      _idMaps['satislar']!.remove(id);
      return 1;
    } catch (e) {
      print('deleteSatis error: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getCariOzet() async {
    try {
      final musteriler = await getMusteriler();
      final satislar = await getSatislar();
      final tahsilatlar = await getTahsilatlar();
      
      double toplamAlacak = 0;
      double toplamSatis = 0;
      double toplamTahsilat = 0;
      
      // Satış toplamı
      for (var s in satislar) {
        toplamSatis += s.toplamTutar;
      }
      
      // Tahsilat toplamı
      for (var t in tahsilatlar) {
        toplamTahsilat += (t['tutar'] as num?)?.toDouble() ?? 0;
      }
      
      // Müşteri bazlı alacak toplamı
      for (var m in musteriler) {
        final bakiye = await getMusteriBakiye(m.id!);
        if (bakiye['bakiye']! > 0) {
          toplamAlacak += bakiye['bakiye']!;
        }
      }
      
      return {
        'toplamAlacak': toplamAlacak,
        'toplamBorc': 0.0,
        'netBakiye': toplamAlacak,
        'musteriSayisi': musteriler.length,
        'toplamSatis': toplamSatis,
        'toplamTahsilat': toplamTahsilat,
      };
    } catch (e) {
      print('getCariOzet error: $e');
      return {
        'toplamAlacak': 0.0, 
        'toplamBorc': 0.0, 
        'netBakiye': 0.0, 
        'musteriSayisi': 0,
        'toplamSatis': 0.0,
        'toplamTahsilat': 0.0,
      };
    }
  }

  // ==================== TAHSİLATLAR ====================
  Future<int> insertTahsilat(Map<String, dynamic> t) async {
    try {
      final docRef = await _db.collection('tahsilatlar').add(t);
      return _getIntId('tahsilatlar', docRef.id);
    } catch (e) {
      print('insertTahsilat error: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getTahsilatlar({int? musteriId, int? satisId}) async {
    try {
      final snapshot = await _db.collection('tahsilatlar').get();
      final musteriler = await getMusteriler(sadecAktif: false);
      
      List<Map<String, dynamic>> list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = _getIntId('tahsilatlar', doc.id);
        // Müşteri unvanını ekle
        final mId = data['musteri_id'];
        final musteri = musteriler.where((m) => m.id == mId).firstOrNull;
        data['musteri_unvan'] = musteri?.unvan ?? 'Bilinmeyen';
        return data;
      }).toList();
      
      if (musteriId != null) {
        list = list.where((t) => t['musteri_id'] == musteriId).toList();
      }
      if (satisId != null) {
        list = list.where((t) => t['satis_id'] == satisId).toList();
      }
      
      // Tarihe göre sırala (yeniden eskiye)
      list.sort((a, b) {
        final dateA = DateTime.tryParse(a['tarih'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['tarih'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
      
      return list;
    } catch (e) {
      print('getTahsilatlar error: $e');
      return [];
    }
  }

  Future<int> deleteTahsilat(int id) async {
    try {
      final docId = _getDocId('tahsilatlar', id);
      if (docId == null) return 0;
      
      await _db.collection('tahsilatlar').doc(docId).delete();
      _idMaps['tahsilatlar']!.remove(id);
      return 1;
    } catch (e) {
      print('deleteTahsilat error: $e');
      return 0;
    }
  }

  Future<int> updateTahsilat(int id, Map<String, dynamic> t) async {
    try {
      final docId = _getDocId('tahsilatlar', id);
      if (docId == null) return 0;
      
      await _db.collection('tahsilatlar').doc(docId).update(t);
      return 1;
    } catch (e) {
      print('updateTahsilat error: $e');
      return 0;
    }
  }
}
