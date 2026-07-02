import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/kasa_hareketi.dart';
import '../models/gundelikci.dart';
import '../models/hasat.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExcelService {
  
  Future<void> exportToExcel(List<KasaHareketi> hareketler) async {
    final excel = Excel.createExcel();
    final sheet = excel['İşlemler'];
    
    // Başlıklar
    final headers = [
      'Tarih',
      'Açıklama', 
      'İşlem Tipi',
      'Tutar',
      'Para Birimi',
      'TL Karşılığı',
      'Ödeme Şekli',
      'Kasa',
      'İşlem Kaynağı',
      'Notlar',
    ];
    
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
    
    // Veriler
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    for (var i = 0; i < hareketler.length; i++) {
      final h = hareketler[i];
      final row = i + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(dateFormat.format(h.tarih));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(h.aciklama);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(h.islemTipi);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(h.tutar);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(h.paraBirimi);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(h.tlKarsiligi ?? h.tutar);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(h.odemeBicimi ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(h.kasa ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = TextCellValue(_getKaynagiText(h.islemKaynagi));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = TextCellValue(h.notlar ?? '');
    }
    
    // Sütun genişlikleri
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 15);
    sheet.setColumnWidth(8, 15);
    sheet.setColumnWidth(9, 25);
    
    // Varsayılan Sheet1'i kaldır
    excel.delete('Sheet1');
    
    // Excel byte'larını oluştur
    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Excel dosyası oluşturulamadı');
    }
    
    // Web'de tarayıcı üzerinden indirme tetikle
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'nev_seracilik_$timestamp.xlsx';
    
    final uint8List = Uint8List.fromList(fileBytes);
    final blob = html.Blob([uint8List], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }
  
  /// Gider pusulası dışa aktarımı — kişilerin tüm bilgileriyle (TC, adres, telefon)
  Future<void> exportGiderPusulasi(
    List<Gundelikci> gundelikciler,
    List<KasaHareketi> hareketler,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Gider Pusulası'];

    final headers = [
      'Ad Soyad',
      'TC No',
      'Telefon',
      'Adres',
      'Verilen Avans (TL)',
      'Kesilen Pusula (TL)',
      'Açıkta Kalan / Bize Borç (TL)',
      'Durum',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    final sorted = [...gundelikciler]
      ..sort((a, b) => a.adSoyad.toLowerCase().compareTo(b.adSoyad.toLowerCase()));

    double genelAvans = 0;
    double genelResmilestirme = 0;
    double genelKalan = 0;

    for (var i = 0; i < sorted.length; i++) {
      final g = sorted[i];
      final row = i + 1;

      final toplamAvans = hareketler
          .where((h) => h.islemKaynagi == 'gider_pusulasi' && h.iliskiliId == g.id)
          .fold<double>(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
      final toplamResmilestirme = hareketler
          .where((h) => h.islemKaynagi == 'resmilestirme' && h.iliskiliId == g.id)
          .fold<double>(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
      final kalanBorc = toplamAvans - toplamResmilestirme;

      genelAvans += toplamAvans;
      genelResmilestirme += toplamResmilestirme;
      genelKalan += kalanBorc;

      String durum;
      if (kalanBorc > 0.001) {
        durum = 'Bize borçlu';
      } else if (kalanBorc < -0.001) {
        durum = 'Fazla pusula kesilmiş';
      } else {
        durum = 'Borç yok';
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(g.adSoyad);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(g.tcNo ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(g.telefon ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(g.adres ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(toplamAvans);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(toplamResmilestirme);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(kalanBorc);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(durum);
    }

    final totalRow = sorted.length + 1;
    final totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow));
    totalCell.value = TextCellValue('TOPLAM');
    totalCell.cellStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow)).value = DoubleCellValue(genelAvans);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow)).value = DoubleCellValue(genelResmilestirme);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow)).value = DoubleCellValue(genelKalan);
    for (final c in [4, 5, 6]) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: totalRow)).cellStyle = CellStyle(bold: true);
    }

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 38);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 26);
    sheet.setColumnWidth(7, 20);

    excel.delete('Sheet1');

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Excel dosyası oluşturulamadı');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'gider_pusulasi_$timestamp.xlsx';

    final uint8List = Uint8List.fromList(fileBytes);
    final blob = html.Blob([uint8List], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
  String _getKaynagiText(String? kaynagi) {
    switch (kaynagi) {
      case 'gider_pusulasi': return 'Gündelikçi Avansı';
      case 'resmilestirme': return 'Gider Pusulası';
      case 'gider_pusulasi_vergi': return 'G. Pusulası Vergisi';
      case 'kredi_odeme': return 'Kredi Ödemesi';
      default: return 'Normal İşlem';
    }
  }

  Future<void> exportHasat(List<Hasat> hasatlar) async {
    final excel = Excel.createExcel();
    final sheet = excel['Hasat Kayıtları'];

    final headers = [
      'Bahçe',
      'Parsel',
      'Ürün',
      'Tarih',
      'Miktar',
      'Birim',
      'Kalite',
      'Saksı Sayısı',
      'Verim (birim/saksı)',
      'Not',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D97706'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    final dateFormat = DateFormat('dd.MM.yyyy');
    final sorted = [...hasatlar]..sort((a, b) => b.tarih.compareTo(a.tarih));

    for (var i = 0; i < sorted.length; i++) {
      final h = sorted[i];
      final row = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(h.bahceAd);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(h.parselAd);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(h.urun);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(dateFormat.format(h.tarih));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(h.miktar);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(h.birim);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(h.kalite ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = h.saksiSayisi != null ? DoubleCellValue(h.saksiSayisi!) : TextCellValue('');
      final verim = h.verimSaksiBasi;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = verim != null ? DoubleCellValue(double.parse(verim.toStringAsFixed(3))) : TextCellValue('');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = TextCellValue(h.not ?? '');
    }

    for (var c = 0; c < headers.length; c++) {
      sheet.setColumnWidth(c, c == 9 ? 28 : (c == 8 ? 18 : 15));
    }

    // Parsel bazlı verim özeti (ikinci sayfa)
    final ozet = excel['Parsel Verim Özeti'];
    final ozetHeaders = ['Bahçe', 'Parsel', 'Ürün', 'Toplam Miktar', 'Birim', 'Kayıt Sayısı'];
    for (var i = 0; i < ozetHeaders.length; i++) {
      final cell = ozet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(ozetHeaders[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D97706'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    final Map<String, Map<String, dynamic>> gruplar = {};
    for (final h in sorted) {
      final key = '${h.bahceAd}|${h.parselAd}|${h.urun}|${h.birim}';
      final grup = gruplar.putIfAbsent(key, () => {
            'bahce': h.bahceAd,
            'parsel': h.parselAd,
            'urun': h.urun,
            'birim': h.birim,
            'toplam': 0.0,
            'adet': 0,
          });
      grup['toplam'] = (grup['toplam'] as double) + h.miktar;
      grup['adet'] = (grup['adet'] as int) + 1;
    }

    var r = 1;
    for (final g in gruplar.values) {
      ozet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue(g['bahce'] as String);
      ozet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue(g['parsel'] as String);
      ozet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue(g['urun'] as String);
      ozet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = DoubleCellValue(g['toplam'] as double);
      ozet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r)).value = TextCellValue(g['birim'] as String);
      ozet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r)).value = IntCellValue(g['adet'] as int);
      r++;
    }
    for (var c = 0; c < ozetHeaders.length; c++) {
      ozet.setColumnWidth(c, 16);
    }

    excel.delete('Sheet1');

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Excel dosyası oluşturulamadı');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'hasat_kayitlari_$timestamp.xlsx';

    final uint8List = Uint8List.fromList(fileBytes);
    final blob = html.Blob([uint8List], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // ignore: unused_local_variable
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
