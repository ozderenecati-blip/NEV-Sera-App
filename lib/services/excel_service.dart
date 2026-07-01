import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/kasa_hareketi.dart';
import '../models/gundelikci.dart';
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
}
