import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kasa_hareketi.dart';
import '../models/gundelikci.dart';
import '../models/kredi.dart';
import '../models/dropdown_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _kasaHareketleri =>
      _firestore.collection('kasa_hareketleri');
  CollectionReference get _gundelikciler =>
      _firestore.collection('gundelikciler');
  CollectionReference get _krediler => _firestore.collection('krediler');
  CollectionReference get _krediOdemeleri =>
      _firestore.collection('kredi_odemeleri');
  CollectionReference get _dropdownData =>
      _firestore.collection('dropdown_data');
  CollectionReference get _ayarlar => _firestore.collection('ayarlar');

  // ==================== KASA HAREKETLERİ ====================

  Future<List<KasaHareketi>> getKasaHareketleri() async {
    final snapshot =
        await _kasaHareketleri.orderBy('tarih', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
      return KasaHareketi.fromMap(data);
    }).toList();
  }

  Stream<List<KasaHareketi>> streamKasaHareketleri() {
    return _kasaHareketleri
        .orderBy('tarih', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
                return KasaHareketi.fromMap(data);
              }).toList(),
        );
  }

  Future<String> insertKasaHareketi(KasaHareketi hareket) async {
    final docRef = await _kasaHareketleri.add(_kasaHareketiToMap(hareket));
    return docRef.id;
  }

  Future<void> updateKasaHareketi(KasaHareketi hareket) async {
    await _kasaHareketleri
        .doc(hareket.id.toString())
        .update(_kasaHareketiToMap(hareket));
  }

  Future<void> deleteKasaHareketi(int id) async {
    // Önce id ile bul
    final snapshot =
        await _kasaHareketleri.where('local_id', isEqualTo: id).get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    } else {
      // Doğrudan doc id ile sil
      await _kasaHareketleri.doc(id.toString()).delete();
    }
  }

  Map<String, dynamic> _kasaHareketiToMap(KasaHareketi h) {
    return {
      'local_id': h.id,
      'tarih': Timestamp.fromDate(h.tarih),
      'aciklama': h.aciklama,
      'islem_tipi': h.islemTipi,
      'tutar': h.tutar,
      'para_birimi': h.paraBirimi,
      'doviz_kuru': h.dovizKuru,
      'tl_karsiligi': h.tlKarsiligi,
      'kasa': h.kasa,
      'odeme_bicimi': h.odemeBicimi,
      'islem_kaynagi': h.islemKaynagi,
      'iliskili_id': h.iliskiliId,
      'notlar': h.notlar,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // ==================== GÜNDELİKÇİLER ====================

  Future<List<Gundelikci>> getGundelikciler() async {
    final snapshot = await _gundelikciler.where('aktif', isEqualTo: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
      return Gundelikci.fromMap(data);
    }).toList();
  }

  Stream<List<Gundelikci>> streamGundelikciler() {
    return _gundelikciler
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
                return Gundelikci.fromMap(data);
              }).toList(),
        );
  }

  Future<String> insertGundelikci(Gundelikci g) async {
    final docRef = await _gundelikciler.add({
      'ad_soyad': g.adSoyad,
      'tc_no': g.tcNo,
      'adres': g.adres,
      'telefon': g.telefon,
      'aktif': g.aktif ? 1 : 0,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateGundelikci(Gundelikci g) async {
    final snapshot =
        await _gundelikciler.where('ad_soyad', isEqualTo: g.adSoyad).get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'ad_soyad': g.adSoyad,
        'tc_no': g.tcNo,
        'adres': g.adres,
        'telefon': g.telefon,
        'aktif': g.aktif ? 1 : 0,
      });
    }
  }

  Future<void> deleteGundelikci(int id) async {
    final snapshot = await _gundelikciler.get();
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['id'] == id || doc.id.hashCode == id) {
        await doc.reference.update({'aktif': 0});
        break;
      }
    }
  }

  // ==================== KREDİLER ====================

  Future<List<Kredi>> getKrediler() async {
    final snapshot = await _krediler.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
      // Timestamp'leri DateTime'a çevir
      if (data['baslangic_tarihi'] is Timestamp) {
        data['baslangic_tarihi'] =
            (data['baslangic_tarihi'] as Timestamp).toDate().toIso8601String();
      }
      return Kredi.fromMap(data);
    }).toList();
  }

  Stream<List<Kredi>> streamKrediler() {
    return _krediler.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
            if (data['baslangic_tarihi'] is Timestamp) {
              data['baslangic_tarihi'] =
                  (data['baslangic_tarihi'] as Timestamp)
                      .toDate()
                      .toIso8601String();
            }
            return Kredi.fromMap(data);
          }).toList(),
    );
  }

  Future<String> insertKredi(Kredi k) async {
    final docRef = await _krediler.add({
      'kredi_id': k.krediId,
      'banka_ad': k.bankaAd,
      'kasa': k.kasa,
      'cekilen_tutar': k.cekilenTutar,
      'faiz_orani': k.faizOrani,
      'faiz_girisi_turu': k.faizGirisiTuru,
      'vade_ay': k.vadeAy,
      'taksit_tipi': k.taksitTipi,
      'odeme_sikligi_ay': k.odemeSikligiAy,
      'baslangic_tarihi': Timestamp.fromDate(k.baslangicTarihi),
      'kkdf_orani': k.kkdfOrani,
      'bsmv_orani': k.bsmvOrani,
      'para_birimi': k.paraBirimi,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateKredi(Kredi k) async {
    final snapshot = await _krediler.get();
    for (var doc in snapshot.docs) {
      if (doc.id.hashCode == k.id || int.tryParse(doc.id) == k.id) {
        await doc.reference.update({
          'kredi_id': k.krediId,
          'banka_ad': k.bankaAd,
          'kasa': k.kasa,
          'cekilen_tutar': k.cekilenTutar,
          'faiz_orani': k.faizOrani,
          'faiz_girisi_turu': k.faizGirisiTuru,
          'vade_ay': k.vadeAy,
          'taksit_tipi': k.taksitTipi,
          'odeme_sikligi_ay': k.odemeSikligiAy,
          'baslangic_tarihi': Timestamp.fromDate(k.baslangicTarihi),
          'kkdf_orani': k.kkdfOrani,
          'bsmv_orani': k.bsmvOrani,
          'para_birimi': k.paraBirimi,
        });
        break;
      }
    }
  }

  Future<void> deleteKredi(int id) async {
    final snapshot = await _krediler.get();
    for (var doc in snapshot.docs) {
      if (doc.id.hashCode == id || int.tryParse(doc.id) == id) {
        await doc.reference.delete();
        break;
      }
    }
  }

  // ==================== KREDİ TAKSİTLERİ ====================

  Future<List<KrediTaksit>> getKrediTaksitleri(int krediDbId) async {
    final snapshot =
        await _krediOdemeleri.where('kredi_db_id', isEqualTo: krediDbId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
      if (data['vade_tarihi'] is Timestamp) {
        data['vade_tarihi'] =
            (data['vade_tarihi'] as Timestamp).toDate().toIso8601String();
      }
      return KrediTaksit.fromMap(data);
    }).toList();
  }

  Future<String> insertKrediTaksit(KrediTaksit taksit) async {
    final docRef = await _krediOdemeleri.add({
      'kredi_db_id': taksit.krediDbId,
      'periyot': taksit.periyot,
      'vade_tarihi': Timestamp.fromDate(taksit.vadeTarihi),
      'anapara': taksit.anapara,
      'faiz': taksit.faiz,
      'bsmv': taksit.bsmv,
      'kkdf': taksit.kkdf,
      'toplam_taksit': taksit.toplamTaksit,
      'kalan_bakiye': taksit.kalanBakiye,
      'odendi': taksit.odendi ? 1 : 0,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateKrediTaksitOdendi(int taksitId, bool odendi) async {
    final snapshot = await _krediOdemeleri.get();
    for (var doc in snapshot.docs) {
      if (doc.id.hashCode == taksitId || int.tryParse(doc.id) == taksitId) {
        await doc.reference.update({'odendi': odendi ? 1 : 0});
        break;
      }
    }
  }

  // ==================== DROPDOWN DATA ====================

  Future<Map<String, List<String>>> getDropdownData() async {
    final doc = await _dropdownData.doc('default').get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'kasalar': List<String>.from(data['kasalar'] ?? GiderKategorileri.kasa),
        'bankalar': List<String>.from(
          data['bankalar'] ?? KrediKategorileri.bankalar,
        ),
        'aciklamalar': List<String>.from(
          data['aciklamalar'] ?? GiderKategorileri.aciklama,
        ),
      };
    }
    // Varsayılan değerler - statik listelerden al
    final defaultData = {
      'kasalar': GiderKategorileri.kasa,
      'bankalar': KrediKategorileri.bankalar,
      'aciklamalar': GiderKategorileri.aciklama,
    };
    // Varsayılanları kaydet
    await _dropdownData.doc('default').set(defaultData);
    return defaultData;
  }

  Future<void> updateDropdownData(Map<String, List<String>> data) async {
    await _dropdownData.doc('default').set(data);
  }

  Future<void> addKasa(String kasa) async {
    await _dropdownData.doc('default').update({
      'kasalar': FieldValue.arrayUnion([kasa]),
    });
  }

  Future<void> addBanka(String banka) async {
    await _dropdownData.doc('default').update({
      'bankalar': FieldValue.arrayUnion([banka]),
    });
  }

  // ==================== AYARLAR ====================

  Future<Map<String, dynamic>> getAyarlar() async {
    final doc = await _ayarlar.doc('app_settings').get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> updateAyarlar(Map<String, dynamic> ayarlar) async {
    await _ayarlar.doc('app_settings').set(ayarlar, SetOptions(merge: true));
  }

  // ==================== KASA BAKİYE HESAPLAMA ====================

  Future<Map<String, double>> getKasaBakiyeleri() async {
    final hareketler = await getKasaHareketleri();
    final Map<String, double> bakiyeler = {};

    for (var h in hareketler) {
      final kasa = h.kasa ?? 'Genel';
      final tutar = h.tlKarsiligi ?? h.tutar;

      if (!bakiyeler.containsKey(kasa)) {
        bakiyeler[kasa] = 0;
      }

      if (h.islemTipi == 'Giriş') {
        bakiyeler[kasa] = bakiyeler[kasa]! + tutar;
      } else if (h.islemTipi == 'Çıkış') {
        bakiyeler[kasa] = bakiyeler[kasa]! - tutar;
      }
    }

    return bakiyeler;
  }

  Future<double> getToplamBakiye() async {
    final bakiyeler = await getKasaBakiyeleri();
    return bakiyeler.values.fold<double>(0.0, (total, val) => total + val);
  }
}
