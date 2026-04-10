#!/usr/bin/env python3
"""Fix getKasaBakiyeleri and getKasaOzet to use native currency instead of TL conversion"""

import re

filepath = 'lib/services/database_service_firebase_v2.dart'
with open(filepath, 'r') as f:
    content = f.read()

# ===== Fix 1: getKasaBakiyeleri =====
old_bakiyeler = """  Future<List<Map<String, dynamic>>> getKasaBakiyeleri() async {
    try {
      final hareketler = await getKasaHareketleri();
      final Map<String, Map<String, double>> bakiyeler = {};
      
      for (var h in hareketler) {
        // Kasa null olanlar\u0131 (resmile\u015ftirme gibi) dahil etme
        if (h.kasa == null || h.kasa!.isEmpty) continue;
        
        final kasa = h.kasa!;
        final tutar = h.tlKarsiligi ?? h.tutar;
        bakiyeler[kasa] ??= {'bakiye': 0, 'toplam_giris': 0, 'toplam_cikis': 0};
        if (h.islemTipi == 'Giri\u015f') {
          bakiyeler[kasa]!['bakiye'] = bakiyeler[kasa]!['bakiye']! + tutar;
          bakiyeler[kasa]!['toplam_giris'] = bakiyeler[kasa]!['toplam_giris']! + tutar;
        } else if (h.islemTipi == '\u00c7\u0131k\u0131\u015f') {
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
  }"""

new_bakiyeler = """  Future<List<Map<String, dynamic>>> getKasaBakiyeleri() async {
    try {
      final hareketler = await getKasaHareketleri();
      // Kasa ayarlar\u0131n\u0131 \u00e7ek - para birimi bilgisi i\u00e7in
      final kasaSettings = await getSettings('kasa');
      final Map<String, String> kasaParaBirimleri = {};
      for (var s in kasaSettings) {
        kasaParaBirimleri[s.deger] = s.paraBirimi ?? 'TL';
      }

      final Map<String, Map<String, double>> bakiyeler = {};
      
      for (var h in hareketler) {
        // Kasa null olanlar\u0131 (resmile\u015ftirme gibi) dahil etme
        if (h.kasa == null || h.kasa!.isEmpty) continue;
        
        final kasa = h.kasa!;
        // Her kasan\u0131n kendi birimi cinsinden tutar\u0131 kullan (TL'ye \u00e7evirme!)
        final tutar = h.tutar;
        bakiyeler[kasa] ??= {'bakiye': 0, 'toplam_giris': 0, 'toplam_cikis': 0};
        if (h.islemTipi == 'Giri\u015f') {
          bakiyeler[kasa]!['bakiye'] = bakiyeler[kasa]!['bakiye']! + tutar;
          bakiyeler[kasa]!['toplam_giris'] = bakiyeler[kasa]!['toplam_giris']! + tutar;
        } else if (h.islemTipi == '\u00c7\u0131k\u0131\u015f') {
          bakiyeler[kasa]!['bakiye'] = bakiyeler[kasa]!['bakiye']! - tutar;
          bakiyeler[kasa]!['toplam_cikis'] = bakiyeler[kasa]!['toplam_cikis']! + tutar;
        }
      }
      
      return bakiyeler.entries.map((e) => {
        'kasa': e.key, 
        'bakiye': e.value['bakiye'], 
        'toplam_giris': e.value['toplam_giris'],
        'toplam_cikis': e.value['toplam_cikis'],
        'para_birimi': kasaParaBirimleri[e.key] ?? 'TL',
      }).toList();
    } catch (e) {
      print('getKasaBakiyeleri error: \$e');
      return [];
    }
  }"""

assert old_bakiyeler in content, f'getKasaBakiyeleri block not found! Searching...'
content = content.replace(old_bakiyeler, new_bakiyeler)
print('OK: getKasaBakiyeleri fixed')

with open(filepath, 'w') as f:
    f.write(content)

print('All database fixes applied successfully')
