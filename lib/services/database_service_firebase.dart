// Web için Firebase Firestore database service
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

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _kasaRef => _db.collection('kasa_hareketleri');
  CollectionReference get _gundelikciRef => _db.collection('gundelikciler');
  CollectionReference get _krediRef => _db.collection('krediler');
  CollectionReference get _taksitRef => _db.collection('kredi_taksitleri');
  CollectionReference get _ortakRef => _db.collection('ortaklar');
  CollectionReference get _musteriRef => _db.collection('musteriler');
  CollectionReference get _satisRef => _db.collection('satislar');
  CollectionReference get _odemeRef => _db.collection('yaklasan_odemeler');
  CollectionReference get _settingsRef => _db.collection('settings');
  CollectionReference get _tahsilatRef => _db.collection('tahsilatlar');

  // ==================== KASA ====================
  Future<List<KasaHareketi>> getKasaHareketleri({int? limit, String? islemKaynagi}) async {
    try {
      Query query = _kasaRef.orderBy('tarih', descending: true);
      if (islemKaynagi != null) {
        query = query.where('islem_kaynagi', isEqualTo: islemKaynagi);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        if (data['tarih'] is Timestamp) {
          data['tarih'] = (data['tarih'] as Timestamp).toDate().toIso8601String();
        }
        return KasaHareketi.fromMap(data);
      }).toList();
    } catch (e) {
      print('getKasaHareketleri error: $e');
      return [];
    }
  }
  
  Future<int> insertKasaHareketi(KasaHareketi hareket) async {
    try {
      final docRef = await _kasaRef.add({
        'tarih': Timestamp.fromDate(hareket.tarih),
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
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertKasaHareketi error: $e');
      return -1;
    }
  }
  
  Future<int> updateKasaHareketi(KasaHareketi hareket) async {
    try {
      final snapshot = await _kasaRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == hareket.id) {
          await doc.reference.update({
            'tarih': Timestamp.fromDate(hareket.tarih),
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
        }
      }
      return 0;
    } catch (e) {
      print('updateKasaHareketi error: $e');
      return 0;
    }
  }
  
  Future<int> deleteKasaHareketi(int id) async {
    try {
      final snapshot = await _kasaRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.delete();
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteKasaHareketi error: $e');
      return 0;
    }
  }
  
  Future<Map<String, double>> getKasaOzet() async {
    try {
      final hareketler = await getKasaHareketleri();
      double toplamGiris = 0;
      double toplamCikis = 0;
      
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
  
  Future<List<Map<String, dynamic>>> getKasaBakiyeleri() async {
    try {
      final hareketler = await getKasaHareketleri();
      final Map<String, double> bakiyeler = {};
      
      for (var h in hareketler) {
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
    } catch (e) {
      print('getKasaBakiyeleri error: $e');
      return [];
    }
  }

  // ==================== GÜNDELİKÇİLER ====================
  Future<List<Gundelikci>> getGundelikciler() async {
    try {
      final snapshot = await _gundelikciRef.where('aktif', isEqualTo: 1).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        return Gundelikci.fromMap(data);
      }).toList();
    } catch (e) {
      print('getGundelikciler error: $e');
      return [];
    }
  }
  
  Future<int> insertGundelikci(Gundelikci g) async {
    try {
      final docRef = await _gundelikciRef.add({
        'ad_soyad': g.adSoyad,
        'tc_no': g.tcNo,
        'adres': g.adres,
        'telefon': g.telefon,
        'aktif': g.aktif ? 1 : 0,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertGundelikci error: $e');
      return -1;
    }
  }
  
  Future<int> updateGundelikci(Gundelikci g) async {
    try {
      final snapshot = await _gundelikciRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == g.id) {
          await doc.reference.update({
            'ad_soyad': g.adSoyad,
            'tc_no': g.tcNo,
            'adres': g.adres,
            'telefon': g.telefon,
            'aktif': g.aktif ? 1 : 0,
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('updateGundelikci error: $e');
      return 0;
    }
  }
  
  Future<int> deleteGundelikci(int id) async {
    try {
      final snapshot = await _gundelikciRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.update({'aktif': 0});
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteGundelikci error: $e');
      return 0;
    }
  }
  
  Future<Map<String, double>> getGundelikciOdemeToplami(int gundelikciId) async {
    return {'toplam': 0};
  }
  
  Future<Map<String, double>> getGundelikciOzet() async {
    try {
      final gundelikciler = await getGundelikciler();
      return {
        'toplamOdeme': 0,
        'toplamCalisan': gundelikciler.length.toDouble(),
      };
    } catch (e) {
      return {'toplamOdeme': 0, 'toplamCalisan': 0};
    }
  }

  // ==================== KREDİLER ====================
  Future<List<Kredi>> getKrediler() async {
    try {
      final snapshot = await _krediRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        if (data['baslangic_tarihi'] is Timestamp) {
          data['baslangic_tarihi'] = (data['baslangic_tarihi'] as Timestamp).toDate().toIso8601String();
        }
        return Kredi.fromMap(data);
      }).toList();
    } catch (e) {
      print('getKrediler error: $e');
      return [];
    }
  }
  
  Future<int> insertKredi(Kredi k) async {
    try {
      final docRef = await _krediRef.add({
        'kredi_id': k.krediId,
        'banka_ad': k.bankaAd,
        'kasa': k.kasa,
        'cekilen_tutar': k.cekilenTutar,
        'faiz_orani': k.faizOrani,
        'vade_ay': k.vadeAy,
        'taksit_tipi': k.taksitTipi,
        'odeme_sikligi_ay': k.odemeSikligiAy,
        'kkdf_orani': k.kkdfOrani,
        'bsmv_orani': k.bsmvOrani,
        'faiz_girisi_turu': k.faizGirisiTuru,
        'para_birimi': k.paraBirimi,
        'baslangic_tarihi': Timestamp.fromDate(k.baslangicTarihi),
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertKredi error: $e');
      return -1;
    }
  }
  
  Future<int> updateKredi(Kredi k) async {
    try {
      final snapshot = await _krediRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == k.id) {
          await doc.reference.update({
            'kredi_id': k.krediId,
            'banka_ad': k.bankaAd,
            'kasa': k.kasa,
            'cekilen_tutar': k.cekilenTutar,
            'faiz_orani': k.faizOrani,
            'vade_ay': k.vadeAy,
            'taksit_tipi': k.taksitTipi,
            'odeme_sikligi_ay': k.odemeSikligiAy,
            'kkdf_orani': k.kkdfOrani,
            'bsmv_orani': k.bsmvOrani,
            'faiz_girisi_turu': k.faizGirisiTuru,
            'para_birimi': k.paraBirimi,
            'baslangic_tarihi': Timestamp.fromDate(k.baslangicTarihi),
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('updateKredi error: $e');
      return 0;
    }
  }
  
  Future<int> deleteKredi(int id) async {
    try {
      final snapshot = await _krediRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.delete();
          // Taksitleri de sil
          final taksitSnapshot = await _taksitRef.where('kredi_db_id', isEqualTo: id).get();
          for (var taksitDoc in taksitSnapshot.docs) {
            await taksitDoc.reference.delete();
          }
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteKredi error: $e');
      return 0;
    }
  }
  
  Future<List<KrediTaksit>> getTaksitler(int krediDbId) async {
    try {
      final snapshot = await _taksitRef.where('kredi_db_id', isEqualTo: krediDbId).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        if (data['vade_tarihi'] is Timestamp) {
          data['vade_tarihi'] = (data['vade_tarihi'] as Timestamp).toDate().toIso8601String();
        }
        return KrediTaksit.fromMap(data);
      }).toList();
    } catch (e) {
      print('getTaksitler error: $e');
      return [];
    }
  }
  
  Future<void> saveTaksitler(int krediDbId, List<KrediTaksit> taksitler) async {
    try {
      // Önce mevcut taksitleri sil
      final snapshot = await _taksitRef.where('kredi_db_id', isEqualTo: krediDbId).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      // Yeni taksitleri ekle
      for (var t in taksitler) {
        await _taksitRef.add({
          'kredi_db_id': krediDbId,
          'periyot': t.periyot,
          'vade_tarihi': Timestamp.fromDate(t.vadeTarihi),
          'anapara': t.anapara,
          'faiz': t.faiz,
          'bsmv': t.bsmv,
          'kkdf': t.kkdf,
          'toplam_taksit': t.toplamTaksit,
          'kalan_bakiye': t.kalanBakiye,
          'odendi': t.odendi ? 1 : 0,
        });
      }
    } catch (e) {
      print('saveTaksitler error: $e');
    }
  }
  
  Future<void> taksitOde(int taksitId, DateTime odemeTarihi) async {
    try {
      final snapshot = await _taksitRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == taksitId) {
          await doc.reference.update({'odendi': 1, 'odeme_tarihi': Timestamp.fromDate(odemeTarihi)});
          return;
        }
      }
    } catch (e) {
      print('taksitOde error: $e');
    }
  }
  
  Future<Map<String, double>> getKrediOzet() async {
    try {
      final krediler = await getKrediler();
      double toplamBorc = 0;
      double odenenTutar = 0;
      
      for (var k in krediler) {
        toplamBorc += k.cekilenTutar;
        final taksitler = await getTaksitler(k.id!);
        for (var t in taksitler) {
          if (t.odendi) {
            odenenTutar += t.toplamTaksit;
          }
        }
      }
      
      return {
        'toplamBorc': toplamBorc,
        'odenenTutar': odenenTutar,
        'kalanBorc': toplamBorc - odenenTutar,
        'krediSayisi': krediler.length.toDouble(),
      };
    } catch (e) {
      print('getKrediOzet error: $e');
      return {'toplamBorc': 0, 'odenenTutar': 0, 'kalanBorc': 0, 'krediSayisi': 0};
    }
  }

  // ==================== ORTAKLAR ====================
  Future<List<Ortak>> getOrtaklar() async {
    try {
      final snapshot = await _ortakRef.where('aktif', isEqualTo: 1).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        return Ortak.fromMap(data);
      }).toList();
    } catch (e) {
      print('getOrtaklar error: $e');
      return [];
    }
  }
  
  Future<Ortak?> getOrtakById(int id) async {
    try {
      final ortaklar = await getOrtaklar();
      return ortaklar.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<int> insertOrtak(Ortak o) async {
    try {
      final docRef = await _ortakRef.add({
        'ad_soyad': o.adSoyad,
        'tc_no': o.tcNo,
        'telefon': o.telefon,
        'adres': o.adres,
        'stopaj_orani': o.stopajOrani,
        'aktif': o.aktif ? 1 : 0,
        'notlar': o.notlar,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertOrtak error: $e');
      return -1;
    }
  }
  
  Future<int> updateOrtak(Ortak o) async {
    try {
      final snapshot = await _ortakRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == o.id) {
          await doc.reference.update({
            'ad_soyad': o.adSoyad,
            'tc_no': o.tcNo,
            'telefon': o.telefon,
            'adres': o.adres,
            'stopaj_orani': o.stopajOrani,
            'aktif': o.aktif ? 1 : 0,
            'notlar': o.notlar,
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('updateOrtak error: $e');
      return 0;
    }
  }
  
  Future<int> deleteOrtak(int id) async {
    try {
      final snapshot = await _ortakRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.update({'aktif': 0});
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteOrtak error: $e');
      return 0;
    }
  }
  
  Future<Map<String, double>> getOrtakBakiye(int ortakId) async {
    return {'bakiye': 0};
  }
  
  Future<Map<String, double>> getOrtakOzet() async {
    try {
      final ortaklar = await getOrtaklar();
      return {'toplamOrtak': ortaklar.length.toDouble()};
    } catch (e) {
      return {'toplamOrtak': 0};
    }
  }

  // ==================== YAKLASAN ÖDEMELER ====================
  Future<List<YaklasanOdeme>> getYaklasanOdemeler({bool sadeceBekleyenler = false}) async {
    try {
      Query query = _odemeRef;
      if (sadeceBekleyenler) {
        query = query.where('odendi', isEqualTo: 0);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        if (data['vade_tarihi'] is Timestamp) {
          data['vade_tarihi'] = (data['vade_tarihi'] as Timestamp).toDate().toIso8601String();
        }
        if (data['odenme_tarihi'] is Timestamp) {
          data['odenme_tarihi'] = (data['odenme_tarihi'] as Timestamp).toDate().toIso8601String();
        }
        return YaklasanOdeme.fromMap(data);
      }).toList();
    } catch (e) {
      print('getYaklasanOdemeler error: $e');
      return [];
    }
  }
  
  Future<List<YaklasanOdeme>> getYaklasanOdemelerByDateRange(DateTime start, DateTime end) async {
    try {
      final snapshot = await _odemeRef
          .where('vade_tarihi', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('vade_tarihi', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        if (data['vade_tarihi'] is Timestamp) {
          data['vade_tarihi'] = (data['vade_tarihi'] as Timestamp).toDate().toIso8601String();
        }
        return YaklasanOdeme.fromMap(data);
      }).toList();
    } catch (e) {
      print('getYaklasanOdemelerByDateRange error: $e');
      return [];
    }
  }
  
  Future<int> insertYaklasanOdeme(YaklasanOdeme o) async {
    try {
      final docRef = await _odemeRef.add({
        'alacakli': o.alacakli,
        'tutar': o.tutar,
        'para_birimi': o.paraBirimi,
        'vade_tarihi': Timestamp.fromDate(o.vadeTarihi),
        'aciklama': o.aciklama,
        'odendi': o.odendi ? 1 : 0,
        'odenme_tarihi': o.odenmeTarihi != null ? Timestamp.fromDate(o.odenmeTarihi!) : null,
        'alarm_aktif': o.alarmAktif ? 1 : 0,
        'alarm_gun_once': o.alarmGunOnce,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertYaklasanOdeme error: $e');
      return -1;
    }
  }
  
  Future<int> updateYaklasanOdeme(YaklasanOdeme o) async {
    try {
      final snapshot = await _odemeRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == o.id) {
          await doc.reference.update({
            'alacakli': o.alacakli,
            'tutar': o.tutar,
            'para_birimi': o.paraBirimi,
            'vade_tarihi': Timestamp.fromDate(o.vadeTarihi),
            'aciklama': o.aciklama,
            'odendi': o.odendi ? 1 : 0,
            'odenme_tarihi': o.odenmeTarihi != null ? Timestamp.fromDate(o.odenmeTarihi!) : null,
            'alarm_aktif': o.alarmAktif ? 1 : 0,
            'alarm_gun_once': o.alarmGunOnce,
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('updateYaklasanOdeme error: $e');
      return 0;
    }
  }
  
  Future<int> deleteYaklasanOdeme(int id) async {
    try {
      final snapshot = await _odemeRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.delete();
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteYaklasanOdeme error: $e');
      return 0;
    }
  }
  
  Future<int> odemeyiKapat(int id, DateTime odemeTarihi) async {
    try {
      final snapshot = await _odemeRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.update({
            'odendi': 1,
            'odenme_tarihi': Timestamp.fromDate(odemeTarihi),
            'alarm_aktif': 0,
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('odemeyiKapat error: $e');
      return 0;
    }
  }

  // ==================== MÜŞTERİLER ====================
  Future<List<Musteri>> getMusteriler({bool sadecAktif = true}) async {
    try {
      Query query = _musteriRef;
      if (sadecAktif) {
        query = query.where('aktif', isEqualTo: 1);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        return Musteri.fromMap(data);
      }).toList();
    } catch (e) {
      print('getMusteriler error: $e');
      return [];
    }
  }
  
  Future<Musteri?> getMusteri(int id) async {
    try {
      final musteriler = await getMusteriler(sadecAktif: false);
      return musteriler.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
  
  Future<int> insertMusteri(Musteri m) async {
    try {
      final docRef = await _musteriRef.add({
        'unvan': m.unvan,
        'yetkili_kisi': m.yetkiliKisi,
        'telefon': m.telefon,
        'email': m.email,
        'adres': m.adres,
        'vergi_dairesi': m.vergiDairesi,
        'vergi_no': m.vergiNo,
        'musteri_tipi': m.musteriTipi,
        'aktif': m.aktif ? 1 : 0,
        'notlar': m.notlar,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertMusteri error: $e');
      return -1;
    }
  }
  
  Future<int> updateMusteri(Musteri m) async {
    try {
      final snapshot = await _musteriRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == m.id) {
          await doc.reference.update({
            'unvan': m.unvan,
            'yetkili_kisi': m.yetkiliKisi,
            'telefon': m.telefon,
            'email': m.email,
            'adres': m.adres,
            'vergi_dairesi': m.vergiDairesi,
            'vergi_no': m.vergiNo,
            'musteri_tipi': m.musteriTipi,
            'aktif': m.aktif ? 1 : 0,
            'notlar': m.notlar,
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('updateMusteri error: $e');
      return 0;
    }
  }
  
  Future<int> deleteMusteri(int id) async {
    try {
      final snapshot = await _musteriRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.update({'aktif': 0});
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteMusteri error: $e');
      return 0;
    }
  }
  
  Future<Map<String, double>> getMusteriBakiye(int musteriId) async {
    return {'bakiye': 0};
  }
  
  Future<List<Map<String, dynamic>>> getMusterilerWithBakiye() async {
    try {
      final musteriler = await getMusteriler();
      return musteriler.map((m) => {
        'id': m.id,
        'unvan': m.unvan,
        'bakiye': 0.0,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== SATIŞLAR ====================
  Future<List<Satis>> getSatislar({int? musteriId, DateTime? baslangic, DateTime? bitis}) async {
    try {
      Query query = _satisRef;
      if (musteriId != null) {
        query = query.where('musteri_id', isEqualTo: musteriId);
      }
      final snapshot = await query.get();
      var list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        if (data['tarih'] is Timestamp) {
          data['tarih'] = (data['tarih'] as Timestamp).toDate().toIso8601String();
        }
        if (data['vade_tarihi'] is Timestamp) {
          data['vade_tarihi'] = (data['vade_tarihi'] as Timestamp).toDate().toIso8601String();
        }
        return Satis.fromMap(data);
      }).toList();
      
      if (baslangic != null) {
        list = list.where((s) => s.tarih.isAfter(baslangic)).toList();
      }
      if (bitis != null) {
        list = list.where((s) => s.tarih.isBefore(bitis)).toList();
      }
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
    } catch (_) {
      return null;
    }
  }
  
  Future<int> insertSatis(Satis s) async {
    try {
      final docRef = await _satisRef.add({
        'musteri_id': s.musteriId,
        'tarih': Timestamp.fromDate(s.tarih),
        'urun_adi': s.urunAdi,
        'miktar': s.miktar,
        'birim': s.birim,
        'birim_fiyat': s.birimFiyat,
        'toplam_tutar': s.toplamTutar,
        'para_birimi': s.paraBirimi,
        'doviz_kuru': s.dovizKuru,
        'tl_karsiligi': s.tlKarsiligi,
        'komisyon_orani': s.komisyonOrani,
        'komisyon_tutari': s.komisyonTutari,
        'vade_tarihi': s.vadeTarihi != null ? Timestamp.fromDate(s.vadeTarihi!) : null,
        'fatura_no': s.faturaNo,
        'irsaliye_no': s.irsaliyeNo,
        'aciklama': s.aciklama,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertSatis error: $e');
      return -1;
    }
  }
  
  Future<int> updateSatis(Satis s) async {
    try {
      final snapshot = await _satisRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == s.id) {
          await doc.reference.update({
            'musteri_id': s.musteriId,
            'tarih': Timestamp.fromDate(s.tarih),
            'urun_adi': s.urunAdi,
            'miktar': s.miktar,
            'birim': s.birim,
            'birim_fiyat': s.birimFiyat,
            'toplam_tutar': s.toplamTutar,
            'para_birimi': s.paraBirimi,
            'doviz_kuru': s.dovizKuru,
            'tl_karsiligi': s.tlKarsiligi,
            'komisyon_orani': s.komisyonOrani,
            'komisyon_tutari': s.komisyonTutari,
            'vade_tarihi': s.vadeTarihi != null ? Timestamp.fromDate(s.vadeTarihi!) : null,
            'fatura_no': s.faturaNo,
            'irsaliye_no': s.irsaliyeNo,
            'aciklama': s.aciklama,
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('updateSatis error: $e');
      return 0;
    }
  }
  
  Future<int> deleteSatis(int id) async {
    try {
      final snapshot = await _satisRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.delete();
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteSatis error: $e');
      return 0;
    }
  }

  // ==================== CARİ ÖZET ====================
  Future<Map<String, dynamic>> getCariOzet() async {
    try {
      final musteriler = await getMusteriler();
      return {
        'toplamAlacak': 0.0,
        'toplamBorc': 0.0,
        'netBakiye': 0.0,
        'musteriSayisi': musteriler.length,
      };
    } catch (e) {
      return {'toplamAlacak': 0.0, 'toplamBorc': 0.0, 'netBakiye': 0.0, 'musteriSayisi': 0};
    }
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
    try {
      final docRef = await _settingsRef.add({
        'tip': setting.tip,
        'deger': setting.deger,
        'aktif': setting.aktif ? 1 : 0,
        'ortak_id': setting.ortakId,
      });
      return docRef.id.hashCode;
    } catch (e) {
      print('insertSetting error: $e');
      return -1;
    }
  }
  
  Future<List<AppSettings>> getSettings(String tip) async {
    try {
      final snapshot = await _settingsRef.where('tip', isEqualTo: tip).where('aktif', isEqualTo: 1).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        return AppSettings.fromMap(data);
      }).toList();
    } catch (e) {
      print('getSettings error: $e');
      return [];
    }
  }
  
  Future<List<String>> getSettingValues(String tip) async {
    try {
      final settings = await getSettings(tip);
      if (settings.isEmpty && tip == 'kasa') {
        return ['Mert Anter', 'Necati Özdere', 'NEV Seracılık', 'AveA Sağlık'];
      }
      return settings.map((s) => s.deger).toList();
    } catch (e) {
      if (tip == 'kasa') {
        return ['Mert Anter', 'Necati Özdere', 'NEV Seracılık', 'AveA Sağlık'];
      }
      return [];
    }
  }
  
  Future<int> updateSetting(AppSettings setting) async {
    try {
      final snapshot = await _settingsRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == setting.id) {
          await doc.reference.update({
            'tip': setting.tip,
            'deger': setting.deger,
            'aktif': setting.aktif ? 1 : 0,
            'ortak_id': setting.ortakId,
          });
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('updateSetting error: $e');
      return 0;
    }
  }
  
  Future<int> deleteSetting(int id) async {
    try {
      final snapshot = await _settingsRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.update({'aktif': 0});
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteSetting error: $e');
      return 0;
    }
  }

  // ==================== TAHSİLATLAR ====================
  Future<int> insertTahsilat(Map<String, dynamic> tahsilat) async {
    try {
      final docRef = await _tahsilatRef.add(tahsilat);
      return docRef.id.hashCode;
    } catch (e) {
      print('insertTahsilat error: $e');
      return -1;
    }
  }
  
  Future<List<Map<String, dynamic>>> getTahsilatlar({int? musteriId, int? satisId}) async {
    try {
      Query query = _tahsilatRef;
      if (musteriId != null) {
        query = query.where('musteri_id', isEqualTo: musteriId);
      }
      if (satisId != null) {
        query = query.where('satis_id', isEqualTo: satisId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        return data;
      }).toList();
    } catch (e) {
      print('getTahsilatlar error: $e');
      return [];
    }
  }
  
  Future<int> deleteTahsilat(int id) async {
    try {
      final snapshot = await _tahsilatRef.get();
      for (var doc in snapshot.docs) {
        if (doc.id.hashCode == id) {
          await doc.reference.delete();
          return 1;
        }
      }
      return 0;
    } catch (e) {
      print('deleteTahsilat error: $e');
      return 0;
    }
  }
}
