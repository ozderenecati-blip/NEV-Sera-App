import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/bahce.dart';
import '../models/gorev.dart';
import '../models/daily_work_report.dart';
import '../models/gubre.dart';

/// Operasyon modülü Firestore CRUD servisi
class OperasyonService {
  static final OperasyonService _instance = OperasyonService._internal();
  factory OperasyonService() => _instance;
  OperasyonService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ==================== BAHÇE ====================

  CollectionReference get _bahcelerRef => _db.collection('bahceler');

  Future<List<Bahce>> getBahceler() async {
    try {
      final snapshot =
          await _bahcelerRef.orderBy('olusturma_tarihi', descending: true).get();
      return snapshot.docs.map((doc) {
        return Bahce.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('getBahceler error: $e');
      return [];
    }
  }

  Future<Bahce?> getBahce(String id) async {
    try {
      final doc = await _bahcelerRef.doc(id).get();
      if (doc.exists) {
        return Bahce.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('getBahce error: $e');
      return null;
    }
  }

  Future<String?> addBahce(Bahce bahce) async {
    try {
      final doc = await _bahcelerRef.add(bahce.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('addBahce error: $e');
      return null;
    }
  }

  Future<bool> updateBahce(Bahce bahce) async {
    if (bahce.id == null) return false;
    try {
      await _bahcelerRef.doc(bahce.id).update(bahce.toMap());
      return true;
    } catch (e) {
      debugPrint('updateBahce error: $e');
      return false;
    }
  }

  Future<bool> deleteBahce(String id) async {
    try {
      await _bahcelerRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteBahce error: $e');
      return false;
    }
  }

  // ==================== GÖREV ====================

  CollectionReference get _gorevlerRef => _db.collection('gorevler');

  Future<List<Gorev>> getGorevler() async {
    try {
      final snapshot =
          await _gorevlerRef.orderBy('baslangic_tarihi', descending: false).get();
      return snapshot.docs.map((doc) {
        return Gorev.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('getGorevler error: $e');
      return [];
    }
  }

  /// Belirli kullanıcının görevleri
  Future<List<Gorev>> getKullaniciGorevleri(String kullaniciId) async {
    try {
      final snapshot = await _gorevlerRef
          .where('atanan_kullanici_id', isEqualTo: kullaniciId)
          .get();
      final list = snapshot.docs.map((doc) {
        return Gorev.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
      list.sort((a, b) => a.baslangicTarihi.compareTo(b.baslangicTarihi));
      return list;
    } catch (e) {
      debugPrint('getKullaniciGorevleri error: $e');
      return [];
    }
  }

  /// Yaklaşan görevler (3 gün içinde başlayacak)
  Future<List<Gorev>> getYaklasanGorevler() async {
    final gorevler = await getGorevler();
    return gorevler.where((g) => g.yaklasan).toList();
  }

  Future<String?> addGorev(Gorev gorev) async {
    try {
      final doc = await _gorevlerRef.add(gorev.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('addGorev error: $e');
      return null;
    }
  }

  Future<bool> updateGorev(Gorev gorev) async {
    if (gorev.id == null) return false;
    try {
      await _gorevlerRef.doc(gorev.id).update(gorev.toMap());
      return true;
    } catch (e) {
      debugPrint('updateGorev error: $e');
      return false;
    }
  }

  Future<bool> deleteGorev(String id) async {
    try {
      await _gorevlerRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteGorev error: $e');
      return false;
    }
  }

  /// Görevi tamamla
  Future<bool> gorevTamamla(String gorevId, {String? not}) async {
    try {
      await _gorevlerRef.doc(gorevId).update({
        'durum': GorevDurum.tamamlandi.name,
        'tamamlanma_tarihi': DateTime.now().toIso8601String(),
        'tamamlayan_not': not,
      });
      return true;
    } catch (e) {
      debugPrint('gorevTamamla error: $e');
      return false;
    }
  }

  // ==================== DAILY WORK REPORT ====================

  CollectionReference get _reportsRef => _db.collection('daily_reports');

  Future<List<DailyWorkReport>> getDailyReports() async {
    try {
      final snapshot =
          await _reportsRef.orderBy('tarih', descending: true).get();
      return snapshot.docs.map((doc) {
        return DailyWorkReport.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } catch (e) {
      debugPrint('getDailyReports error: $e');
      return [];
    }
  }

  /// Belirli kullanıcının raporları
  Future<List<DailyWorkReport>> getKullaniciRaporlari(String kullaniciId) async {
    try {
      final snapshot = await _reportsRef
          .where('kullanici_id', isEqualTo: kullaniciId)
          .get();
      final list = snapshot.docs.map((doc) {
        return DailyWorkReport.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
      list.sort((a, b) => b.tarih.compareTo(a.tarih));
      return list;
    } catch (e) {
      debugPrint('getKullaniciRaporlari error: $e');
      return [];
    }
  }

  /// Belirli bir güne ait rapor
  Future<DailyWorkReport?> getGunlukRapor(
      String kullaniciId, DateTime tarih) async {
    final tarihKey =
        '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}';
    try {
      final snapshot = await _reportsRef
          .where('kullanici_id', isEqualTo: kullaniciId)
          .where('tarih_key', isEqualTo: tarihKey)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return DailyWorkReport.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        docId: snapshot.docs.first.id,
      );
    } catch (e) {
      debugPrint('getGunlukRapor error: $e');
      // Fallback: tüm raporlardan filtrele
      try {
        final reports = await getKullaniciRaporlari(kullaniciId);
        return reports.where((r) => r.tarihKey == tarihKey).firstOrNull;
      } catch (_) {
        return null;
      }
    }
  }

  Future<String?> addDailyReport(DailyWorkReport report) async {
    try {
      final doc = await _reportsRef.add(report.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('addDailyReport error: $e');
      return null;
    }
  }

  Future<bool> updateDailyReport(DailyWorkReport report) async {
    if (report.id == null) return false;
    // Onaylanmış rapor değiştirilemez
    if (report.kilitli) return false;
    try {
      await _reportsRef.doc(report.id).update(report.toMap());
      return true;
    } catch (e) {
      debugPrint('updateDailyReport error: $e');
      return false;
    }
  }

  /// Admin raporu onayla (verify & lock)
  Future<bool> approveReport(
      String reportId, String onaylayanId, String onaylayanAdi) async {
    try {
      await _reportsRef.doc(reportId).update({
        'onaylandi': true,
        'onaylayan_id': onaylayanId,
        'onaylayan_adi': onaylayanAdi,
        'onay_tarihi': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('approveReport error: $e');
      return false;
    }
  }

  Future<bool> deleteDailyReport(String id) async {
    try {
      await _reportsRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteDailyReport error: $e');
      return false;
    }
  }

  // ==================== GÜBRE TANKLARI ====================

  CollectionReference get _tanklarRef => _db.collection('gubre_tanklari');

  Future<List<GubreTank>> getTanklar({String? bahceId}) async {
    try {
      Query query = _tanklarRef;
      if (bahceId != null) {
        query = query.where('bahce_id', isEqualTo: bahceId);
      }
      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) {
        return GubreTank.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
      list.sort((a, b) => a.ad.compareTo(b.ad));
      return list;
    } catch (e) {
      debugPrint('getTanklar error: $e');
      return [];
    }
  }

  Future<String?> addTank(GubreTank tank) async {
    try {
      final doc = await _tanklarRef.add(tank.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('addTank error: $e');
      return null;
    }
  }

  Future<bool> updateTank(GubreTank tank) async {
    if (tank.id == null) return false;
    try {
      await _tanklarRef.doc(tank.id).update(tank.toMap());
      return true;
    } catch (e) {
      debugPrint('updateTank error: $e');
      return false;
    }
  }

  Future<bool> deleteTank(String id) async {
    try {
      await _tanklarRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteTank error: $e');
      return false;
    }
  }

  // ==================== GÜBRE ENVANTERİ ====================

  CollectionReference get _envanterRef => _db.collection('gubre_envanter');

  Future<List<GubreEnvanter>> getEnvanter({String? bahceId}) async {
    try {
      Query query = _envanterRef;
      if (bahceId != null) {
        query = query.where('bahce_id', isEqualTo: bahceId);
      }
      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) {
        return GubreEnvanter.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
      list.sort((a, b) => a.gubreAdi.compareTo(b.gubreAdi));
      return list;
    } catch (e) {
      debugPrint('getEnvanter error: $e');
      return [];
    }
  }

  Future<String?> addEnvanter(GubreEnvanter envanter) async {
    try {
      final doc = await _envanterRef.add(envanter.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('addEnvanter error: $e');
      return null;
    }
  }

  Future<bool> updateEnvanter(GubreEnvanter envanter) async {
    if (envanter.id == null) return false;
    try {
      await _envanterRef.doc(envanter.id).update(envanter.toMap());
      return true;
    } catch (e) {
      debugPrint('updateEnvanter error: $e');
      return false;
    }
  }

  Future<bool> deleteEnvanter(String id) async {
    try {
      await _envanterRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteEnvanter error: $e');
      return false;
    }
  }


  /// Gübre referans görseli yükle (Firebase Storage)
  Future<String?> uploadGubreGorsel(String envanterId, Uint8List bytes, String filename) async {
    try {
      final ext = filename.split('.').last.toLowerCase();
      final ref = FirebaseStorage.instance
          .ref()
          .child('gubre_gorseller')
          .child('$envanterId.$ext');
      final metadata = SettableMetadata(contentType: 'image/$ext');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();
      // Firestore kaydını güncelle
      await _envanterRef.doc(envanterId).update({'gorsel_url': url});
      return url;
    } catch (e) {
      debugPrint('uploadGubreGorsel error: $e');
      return null;
    }
  }

  /// Gübre görselini sil
  Future<bool> deleteGubreGorsel(String envanterId) async {
    try {
      // Storage'dan sil
      final listResult = await FirebaseStorage.instance
          .ref()
          .child('gubre_gorseller')
          .listAll();
      for (final item in listResult.items) {
        if (item.name.startsWith(envanterId)) {
          await item.delete();
          break;
        }
      }
      // Firestore'dan URL'i temizle
      await _envanterRef.doc(envanterId).update({'gorsel_url': null});
      return true;
    } catch (e) {
      debugPrint('deleteGubreGorsel error: $e');
      return false;
    }
  }

  /// Envanterden miktar düş (katlama sonrası)
  Future<bool> envanterdenDus(String envanterId, double dusulecekMiktar) async {
    try {
      final doc = await _envanterRef.doc(envanterId).get();
      if (!doc.exists) return false;
      final envanter = GubreEnvanter.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      final yeniMiktar = (envanter.miktar - dusulecekMiktar).clamp(0.0, double.infinity);
      await _envanterRef.doc(envanterId).update({
        'miktar': yeniMiktar,
        'son_guncelleme': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('envanterdenDus error: $e');
      return false;
    }
  }

  // ==================== KATLAMA KAYITLARI ====================

  CollectionReference get _katlamaRef => _db.collection('katlama_kayitlari');

  Future<List<KatlamaKaydi>> getKatlamaKayitlari({String? bahceId, String? tankId}) async {
    try {
      Query query = _katlamaRef;
      if (bahceId != null) {
        query = query.where('bahce_id', isEqualTo: bahceId);
      }
      if (tankId != null) {
        query = query.where('tank_id', isEqualTo: tankId);
      }
      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) {
        return KatlamaKaydi.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
      list.sort((a, b) => b.tarih.compareTo(a.tarih));
      return list;
    } catch (e) {
      debugPrint('getKatlamaKayitlari error: $e');
      return [];
    }
  }

  Future<String?> addKatlamaKaydi(KatlamaKaydi kaydi) async {
    try {
      final doc = await _katlamaRef.add(kaydi.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('addKatlamaKaydi error: $e');
      return null;
    }
  }

  // ==================== REÇETE GEÇMİŞİ ====================

  CollectionReference get _receteGecmisiRef => _db.collection('recete_gecmisi');

  Future<List<ReceteGecmisi>> getReceteGecmisi({String? bahceId, String? tankId}) async {
    try {
      Query query = _receteGecmisiRef;
      if (bahceId != null) {
        query = query.where('bahce_id', isEqualTo: bahceId);
      }
      if (tankId != null) {
        query = query.where('tank_id', isEqualTo: tankId);
      }
      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) {
        return ReceteGecmisi.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
      list.sort((a, b) => b.tarih.compareTo(a.tarih));
      return list;
    } catch (e) {
      debugPrint('getReceteGecmisi error: $e');
      return [];
    }
  }

  Future<String?> addReceteGecmisi(ReceteGecmisi gecmis) async {
    try {
      final doc = await _receteGecmisiRef.add(gecmis.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('addReceteGecmisi error: $e');
      return null;
    }
  }

  Future<bool> deleteReceteGecmisi(String id) async {
    try {
      await _receteGecmisiRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteReceteGecmisi error: $e');
      return false;
    }
  }

  Future<bool> deleteKatlamaKaydi(String id) async {
    try {
      await _katlamaRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteKatlamaKaydi error: $e');
      return false;
    }
  }
}
