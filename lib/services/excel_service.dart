import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/kasa_hareketi.dart';
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
