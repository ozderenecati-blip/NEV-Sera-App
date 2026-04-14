import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/bahce.dart';
import '../providers/auth_provider.dart';
import '../services/operasyon_service.dart';

/// Bahçe detay ekranı – parselleri listeler, sıraları düzenler
class BahceDetayScreen extends StatefulWidget {
  final Bahce bahce;
  const BahceDetayScreen({super.key, required this.bahce});

  @override
  State<BahceDetayScreen> createState() => _BahceDetayScreenState();
}

class _BahceDetayScreenState extends State<BahceDetayScreen> {
  final OperasyonService _service = OperasyonService();
  late Bahce _bahce;

  @override
  void initState() {
    super.initState();
    _bahce = widget.bahce;
  }

  Future<void> _reload() async {
    if (_bahce.id == null) return;
    final fresh = await _service.getBahce(_bahce.id!);
    if (fresh != null && mounted) {
      setState(() => _bahce = fresh);
    }
  }

  // ─────────────── PARSEL EKLEME ───────────────

  void _showParselEkleDialog() {
    if (_bahce.parseller.length >= 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir bahçeye en fazla 99 parsel eklenebilir')),
      );
      return;
    }

    final adCtrl = TextEditingController(
      text: '${_bahce.parseller.length + 1}. Parsel',
    );
    final siraSayisiCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Yeni Parsel Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: adCtrl,
                  decoration: InputDecoration(
                    labelText: 'Parsel Adı *',
                    hintText: 'ör: 1. Parsel',
                    prefixIcon: const Icon(Icons.grid_view),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: siraSayisiCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Sıra Sayısı *',
                    hintText: 'ör: 35',
                    prefixIcon: const Icon(Icons.view_column),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ad = adCtrl.text.trim();
                final siraSayisi =
                    int.tryParse(siraSayisiCtrl.text.trim()) ?? 0;
                if (ad.isEmpty || siraSayisi <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Parsel adı ve sıra sayısı zorunlu')),
                  );
                  return;
                }
                if (siraSayisi > 999) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sıra sayısı en fazla 999 olabilir')),
                  );
                  return;
                }

                // Boş sıralar oluştur
                final siralar = List.generate(
                  siraSayisi,
                  (i) => Sira(numara: i + 1, saksiSayisi: 0, uzunluk: 0),
                );

                final yeniParsel = Parsel(
                  ad: ad,
                  siraSayisi: siraSayisi,
                  siraBasinaSaksi: 0,
                  siralar: siralar,
                );

                final guncel =
                    List<Parsel>.from(_bahce.parseller)..add(yeniParsel);
                await _service
                    .updateBahce(_bahce.copyWith(parseller: guncel));

                if (ctx.mounted) Navigator.pop(ctx);
                await _reload();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$ad eklendi ($siraSayisi sıra)')),
                  );
                  // Otomatik olarak sıra düzenleme ekranını aç
                  _openSiraDuzenle(_bahce.parseller.length - 1);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  // ─────────────── PARSEL SİLME ───────────────

  void _deleteParsel(int idx) {
    final parsel = _bahce.parseller[idx];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Parseli Sil'),
        content: Text(
            '${parsel.ad} parselini silmek istediğinize emin misiniz?\nTüm sıra ve saksı verileri silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final guncel = List<Parsel>.from(_bahce.parseller)
                ..removeAt(idx);
              await _service
                  .updateBahce(_bahce.copyWith(parseller: guncel));
              if (ctx.mounted) Navigator.pop(ctx);
              await _reload();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─────────────── PARSEL DÜZENLEME (ad, sıra sayısı) ───────────────

  void _editParsel(int idx) {
    final parsel = _bahce.parseller[idx];
    final adCtrl = TextEditingController(text: parsel.ad);
    final siraSayisiCtrl =
        TextEditingController(text: parsel.siraSayisi.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Parseli Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adCtrl,
                decoration: InputDecoration(
                  labelText: 'Parsel Adı *',
                  prefixIcon: const Icon(Icons.grid_view),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: siraSayisiCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Sıra Sayısı *',
                  helperText: 'Değiştirirseniz mevcut sıra verileri korunur',
                  prefixIcon: const Icon(Icons.view_column),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ad = adCtrl.text.trim();
              final yeniSiraSayisi =
                  int.tryParse(siraSayisiCtrl.text.trim()) ?? 0;
              if (ad.isEmpty || yeniSiraSayisi <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Parsel adı ve sıra sayısı zorunlu')),
                );
                return;
              }

              // Mevcut sıraları koru, eksikleri ekle, fazlalıkları kes
              List<Sira> yeniSiralar = List<Sira>.from(parsel.siralar);
              if (yeniSiraSayisi > yeniSiralar.length) {
                for (int i = yeniSiralar.length;
                    i < yeniSiraSayisi;
                    i++) {
                  yeniSiralar.add(
                      Sira(numara: i + 1, saksiSayisi: 0, uzunluk: 0));
                }
              } else if (yeniSiraSayisi < yeniSiralar.length) {
                yeniSiralar = yeniSiralar.sublist(0, yeniSiraSayisi);
              }

              final guncelParsel = parsel.copyWith(
                ad: ad,
                siraSayisi: yeniSiraSayisi,
                siralar: yeniSiralar,
              );

              final guncelParseller = List<Parsel>.from(_bahce.parseller);
              guncelParseller[idx] = guncelParsel;
              await _service.updateBahce(
                  _bahce.copyWith(parseller: guncelParseller));

              if (ctx.mounted) Navigator.pop(ctx);
              await _reload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  // ─────────────── PDF PAYLAŞIM ───────────────

  Future<pw.Font> _loadTurkishFont() async {
    final font = await PdfGoogleFonts.notoSansRegular();
    return font;
  }

  Future<pw.Font> _loadTurkishFontBold() async {
    final font = await PdfGoogleFonts.notoSansBold();
    return font;
  }

  Future<void> _shareParselPdf(int idx) async {
    final parsel = _bahce.parseller[idx];
    await _generateAndSharePdf([parsel]);
  }

  Future<void> _shareAllParselsPdf() async {
    await _generateAndSharePdf(_bahce.parseller);
  }

  Future<void> _generateAndSharePdf(List<Parsel> parseller) async {
    final tarih = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    final font = await _loadTurkishFont();
    final fontBold = await _loadTurkishFontBold();
    final baseStyle = pw.TextStyle(font: font, fontSize: 10);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 10);
    final headerStyle = pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold, fontSize: 10);
    final titleStyle = pw.TextStyle(font: fontBold, fontSize: 20, fontWeight: pw.FontWeight.bold);
    final subtitleStyle = pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700);
    final smallStyle = pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500);
    final cellStyle = pw.TextStyle(font: font, fontSize: 9);
    final cellBoldStyle = pw.TextStyle(font: fontBold, fontSize: 9, fontWeight: pw.FontWeight.bold);

    // Renk paletleri (cins bazlı)
    final cinsRenkler = <String, PdfColor>{};
    final renkPaleti = [PdfColors.green600, PdfColors.orange600, PdfColors.blue600, PdfColors.red600, PdfColors.purple600, PdfColors.teal600, PdfColors.amber800, PdfColors.indigo600];

    final pdf = pw.Document();

    for (final parsel in parseller) {
      // Cins dağılımını hesapla
      final cinsSaksi = <String, int>{};
      final cinsMetre = <String, double>{};
      for (final s in parsel.siralar) {
        if (s.cins != null && s.cins!.isNotEmpty) {
          cinsSaksi[s.cins!] = (cinsSaksi[s.cins!] ?? 0) + s.saksiSayisi;
          cinsMetre[s.cins!] = (cinsMetre[s.cins!] ?? 0) + s.uzunluk;
          if (!cinsRenkler.containsKey(s.cins!)) {
            cinsRenkler[s.cins!] = renkPaleti[cinsRenkler.length % renkPaleti.length];
          }
        }
      }
      final toplamSaksi = parsel.siralar.fold<int>(0, (s, r) => s + r.saksiSayisi);
      final toplamMetre = parsel.siralar.fold<double>(0, (s, r) => s + r.uzunluk);
      final maxMetre = parsel.siralar.fold<double>(0, (m, s) => s.uzunluk > m ? s.uzunluk : m);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NEV Seracilik', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(tarih, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('${_bahce.ad} - ${parsel.ad}', style: titleStyle),
              pw.SizedBox(height: 4),
              pw.Text(
                  '${parsel.siraSayisi} sira  /  $toplamSaksi saksi  /  ${toplamMetre.toStringAsFixed(0)} m',
                  style: subtitleStyle),
              pw.Divider(),
            ],
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${_bahce.ad} - ${parsel.ad}', style: smallStyle),
              pw.Text('Sayfa ${context.pageNumber}/${context.pagesCount}', style: smallStyle),
            ],
          ),
          build: (context) => [
            // Cins dağılımı
            if (cinsSaksi.isNotEmpty) ...[
              pw.Text('Cins Dagilimi', style: pw.TextStyle(font: fontBold, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headerStyle: headerStyle,
                cellStyle: cellStyle,
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headers: ['Cins', 'Saksi Adedi', 'Toplam Metre'],
                data: cinsSaksi.entries
                    .map((e) => [
                          e.key,
                          '${e.value}',
                          '${(cinsMetre[e.key] ?? 0).toStringAsFixed(0)} m',
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 16),
            ],

            // Sıra detay tablosu
            pw.Text('Sira Detaylari', style: pw.TextStyle(font: fontBold, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: cellStyle,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FixedColumnWidth(60),
                2: const pw.FixedColumnWidth(60),
                3: const pw.FlexColumnWidth(),
              },
              headers: ['Sira', 'Metre', 'Saksi', 'Cins'],
              data: parsel.siralar
                  .map((s) => [
                        '${s.numara}',
                        s.uzunluk > 0
                            ? '${s.uzunluk.toStringAsFixed(s.uzunluk == s.uzunluk.roundToDouble() ? 0 : 1)} m'
                            : '-',
                        s.saksiSayisi > 0 ? '${s.saksiSayisi}' : '-',
                        s.cins ?? '-',
                      ])
                  .toList(),
            ),

            // Toplam satırı
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Toplam: ${parsel.siraSayisi} sira', style: pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('${toplamMetre.toStringAsFixed(0)} m', style: pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('$toplamSaksi saksi', style: pw.TextStyle(font: fontBold, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),

            // ═══ GÖRSEL İLÜSTRASYON ═══
            pw.SizedBox(height: 20),
            pw.Text('Sira Gorseli', style: pw.TextStyle(font: fontBold, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...parsel.siralar.map((s) {
              final ratio = maxMetre > 0 ? s.uzunluk / maxMetre : 0.0;
              final barWidth = 350.0 * ratio;
              final cins = s.cins ?? '';
              final barColor = cinsRenkler[cins] ?? PdfColors.grey400;

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  children: [
                    pw.SizedBox(width: 25, child: pw.Text('${s.numara}', style: pw.TextStyle(font: fontBold, fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.SizedBox(width: 6),
                    pw.Container(
                      width: math.max(2.0, barWidth),
                      height: 10,
                      decoration: pw.BoxDecoration(
                        color: barColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      '${s.uzunluk > 0 ? "${s.uzunluk.toStringAsFixed(s.uzunluk == s.uzunluk.roundToDouble() ? 0 : 1)}m" : ""}'
                      '${s.uzunluk > 0 && s.saksiSayisi > 0 ? " / " : ""}'
                      '${s.saksiSayisi > 0 ? "${s.saksiSayisi} sk" : ""}'
                      '${cins.isNotEmpty ? " ($cins)" : ""}',
                      style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey700),
                    ),
                  ],
                ),
              );
            }),

            // Cins renk açıklaması
            if (cinsRenkler.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 12,
                runSpacing: 4,
                children: cinsRenkler.entries.map((e) => pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: e.value, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)))),
                    pw.SizedBox(width: 4),
                    pw.Text(e.key, style: pw.TextStyle(font: font, fontSize: 8)),
                  ],
                )).toList(),
              ),
            ],
          ],
        ),
      );
    }

    final bytes = await pdf.save();

    if (mounted) {
      final filename = parseller.length == 1
          ? '${_bahce.ad}_${parseller.first.ad}.pdf'.replaceAll(' ', '_')
          : '${_bahce.ad}_tum_parseller.pdf'.replaceAll(' ', '_');
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: filename,
      );
    }
  }

    // ─────────────── SIRA DÜZENLEME EKRANI ───────────────

  void _openSiraDuzenle(int parselIdx) {
    if (parselIdx < 0 || parselIdx >= _bahce.parseller.length) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SiraDuzenleScreen(
          bahce: _bahce,
          parselIdx: parselIdx,
          service: _service,
        ),
      ),
    ).then((_) => _reload());
  }

  // ─────────────── UI ───────────────

  @override
  Widget build(BuildContext context) {
    final canWrite = context.read<AuthProvider>().canWriteOperasyon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_bahce.ad),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          if (_bahce.parseller.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Tüm Parselleri PDF',
              onPressed: _shareAllParselsPdf,
            ),
        ],
      ),
      body: _bahce.parseller.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _bahce.parseller.length,
                itemBuilder: (context, idx) =>
                    _buildParselCard(idx, isDark, canWrite),
              ),
            ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: _showParselEkleDialog,
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Parsel Ekle'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'Henüz parsel eklenmedi',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Parsel eklemek için + butonuna tıklayın',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildParselCard(int idx, bool isDark, bool canWrite) {
    final parsel = _bahce.parseller[idx];

    // Sıralardaki cinsleri ve adetlerini topla
    final cinsSaksi = <String, int>{};
    for (final s in parsel.siralar) {
      if (s.cins != null && s.cins!.isNotEmpty) {
        cinsSaksi[s.cins!] = (cinsSaksi[s.cins!] ?? 0) + s.saksiSayisi;
      }
    }

    final toplamSaksi =
        parsel.siralar.fold<int>(0, (sum, s) => sum + s.saksiSayisi);
    final toplamMetre =
        parsel.siralar.fold<double>(0, (sum, s) => sum + s.uzunluk);

    // Kaç sıra doldurulmuş
    final doluSira = parsel.siralar
        .where((s) => s.saksiSayisi > 0 || s.uzunluk > 0)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSiraDuzenle(idx),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parsel.ad,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$doluSira/${parsel.siraSayisi} sıra dolduruldu',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'share') _shareParselPdf(idx);
                      if (v == 'edit' && canWrite) _editParsel(idx);
                      if (v == 'delete' && canWrite) _deleteParsel(idx);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share, color: Color(0xFF2563EB)),
                          title: Text('PDF Paylaş'),
                          dense: true,
                        ),
                      ),
                      if (canWrite)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Düzenle'),
                            dense: true,
                          ),
                        ),
                      if (canWrite)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading:
                                Icon(Icons.delete, color: Colors.red),
                            title: Text('Sil',
                                style: TextStyle(color: Colors.red)),
                            dense: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // İstatistik satırı
              Row(
                children: [
                  _chip(Icons.view_column, '${parsel.siraSayisi} Sıra',
                      const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _chip(Icons.local_florist, '$toplamSaksi Saksı',
                      const Color(0xFFD97706)),
                  if (toplamMetre > 0) ...[
                    const SizedBox(width: 8),
                    _chip(
                        Icons.straighten,
                        '${toplamMetre.toStringAsFixed(0)} m',
                        const Color(0xFF7C3AED)),
                  ],
                ],
              ),

              // Cins dağılımı (adetli)
              if (cinsSaksi.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cinsSaksi.entries
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🌱 ${e.key}: ${e.value} adet',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                ),
              ],

              // İlerleme barı
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: parsel.siraSayisi > 0
                      ? doluSira / parsel.siraSayisi
                      : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    doluSira == parsel.siraSayisi
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * idx)).slideX(
        begin: 0.02, end: 0);
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SIRA DÜZENLEME EKRANI
// Her sıra için: metre, saksı sayısı, cins
// ═══════════════════════════════════════════════════════════

class _SiraDuzenleScreen extends StatefulWidget {
  final Bahce bahce;
  final int parselIdx;
  final OperasyonService service;

  const _SiraDuzenleScreen({
    required this.bahce,
    required this.parselIdx,
    required this.service,
  });

  @override
  State<_SiraDuzenleScreen> createState() => _SiraDuzenleScreenState();
}

class _SiraDuzenleScreenState extends State<_SiraDuzenleScreen>
    with SingleTickerProviderStateMixin {
  late Bahce _bahce;
  late List<_SiraForm> _formlar;
  bool _isSaving = false;
  bool _hasChanges = false;
  late TabController _tabCtrl;

  // Toplu atama
  final _topluMetreCtrl = TextEditingController();
  final _topluSaksiCtrl = TextEditingController();
  final _topluCinsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bahce = widget.bahce;
    _tabCtrl = TabController(length: 2, vsync: this);
    _initForm();
  }

  void _initForm() {
    final parsel = _bahce.parseller[widget.parselIdx];
    _formlar = parsel.siralar.map((s) {
      return _SiraForm(
        numara: s.numara,
        metreCtrl: TextEditingController(
            text: s.uzunluk > 0 ? s.uzunluk.toString() : ''),
        saksiCtrl: TextEditingController(
            text: s.saksiSayisi > 0 ? s.saksiSayisi.toString() : ''),
        cinsCtrl: TextEditingController(text: s.cins ?? ''),
      );
    }).toList();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _topluMetreCtrl.dispose();
    _topluSaksiCtrl.dispose();
    _topluCinsCtrl.dispose();
    for (final f in _formlar) {
      f.metreCtrl.dispose();
      f.saksiCtrl.dispose();
      f.cinsCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() => _isSaving = true);

    final parsel = _bahce.parseller[widget.parselIdx];
    final yeniSiralar = <Sira>[];

    for (final f in _formlar) {
      final metre = double.tryParse(f.metreCtrl.text.trim()) ?? 0;
      final saksi = int.tryParse(f.saksiCtrl.text.trim()) ?? 0;
      final cins =
          f.cinsCtrl.text.trim().isNotEmpty ? f.cinsCtrl.text.trim() : null;

      yeniSiralar.add(Sira(
        numara: f.numara,
        saksiSayisi: saksi,
        uzunluk: metre,
        cins: cins,
        saksilar: List.generate(
          saksi,
          (j) => Saksi(numara: j + 1, cins: cins),
        ),
      ));
    }

    // Toplam saksıyı hesapla (sıra başına ortalama)
    final toplamSaksi =
        yeniSiralar.fold<int>(0, (s, r) => s + r.saksiSayisi);
    final ortSaksi = yeniSiralar.isNotEmpty
        ? (toplamSaksi / yeniSiralar.length).round()
        : 0;

    final guncelParsel = parsel.copyWith(
      siralar: yeniSiralar,
      siraBasinaSaksi: ortSaksi,
    );

    final parseller = List<Parsel>.from(_bahce.parseller);
    parseller[widget.parselIdx] = guncelParsel;
    await widget.service.updateBahce(_bahce.copyWith(parseller: parseller));

    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${parsel.ad} kaydedildi – $toplamSaksi saksı, ${yeniSiralar.length} sıra'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _topluAtama() {
    _topluMetreCtrl.clear();
    _topluSaksiCtrl.clear();
    _topluCinsCtrl.clear();

    int baslangicSira = 1;
    int bitisSira = _formlar.length;
    final baslangicCtrl =
        TextEditingController(text: baslangicSira.toString());
    final bitisCtrl = TextEditingController(text: bitisSira.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Toplu Atama'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aşağıdaki değerleri belirtilen sıra aralığına uygula.\nBoş bırakılan alanlar değiştirilmez.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: baslangicCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Başlangıç Sıra',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: bitisCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bitiş Sıra',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topluMetreCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Metre',
                  hintText: 'ör: 120',
                  prefixIcon: const Icon(Icons.straighten, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topluSaksiCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Saksı / Fidan Sayısı',
                  hintText: 'ör: 250',
                  prefixIcon: const Icon(Icons.local_florist, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topluCinsCtrl,
                decoration: InputDecoration(
                  labelText: 'Cins',
                  hintText: 'ör: Legacy',
                  prefixIcon: const Icon(Icons.eco, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final b =
                  (int.tryParse(baslangicCtrl.text.trim()) ?? 1) - 1;
              final e = int.tryParse(bitisCtrl.text.trim()) ??
                  _formlar.length;

              for (int i = b; i < e && i < _formlar.length; i++) {
                if (_topluMetreCtrl.text.trim().isNotEmpty) {
                  _formlar[i].metreCtrl.text =
                      _topluMetreCtrl.text.trim();
                }
                if (_topluSaksiCtrl.text.trim().isNotEmpty) {
                  _formlar[i].saksiCtrl.text =
                      _topluSaksiCtrl.text.trim();
                }
                if (_topluCinsCtrl.text.trim().isNotEmpty) {
                  _formlar[i].cinsCtrl.text =
                      _topluCinsCtrl.text.trim();
                }
              }

              setState(() => _hasChanges = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsel = _bahce.parseller[widget.parselIdx];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Kaydedilmemiş Değişiklikler'),
              content: const Text(
                  'Değişiklikleriniz kaydedilmedi. Çıkmak istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hayır'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Evet, Çık',
                      style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _kaydet();
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kaydet & Çık'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(parsel.ad),
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _topluAtama,
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Toplu Atama',
            ),
            IconButton(
              onPressed: _isSaving ? null : _kaydet,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              tooltip: 'Kaydet',
            ),
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.table_chart, size: 18), text: 'Tablo'),
              Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Görsel'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Sekme 1: Tablo ──
            _buildTabloView(isDark),
            // ── Sekme 2: Görsel ──
            _buildGorselView(isDark),
          ],
        ),
        bottomSheet: _hasChanges
            ? SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _kaydet,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Değişiklikleri Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TABLO SEKMESİ (mevcut)
  // ═══════════════════════════════════════════

  Widget _buildTabloView(bool isDark) {
    return Column(
      children: [
        // Özet bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark
              ? Colors.grey.shade900
              : const Color(0xFF059669).withOpacity(0.05),
          child: Row(
            children: [
              _summaryItem(
                  Icons.view_column, '${_formlar.length}', 'Sıra'),
              const SizedBox(width: 20),
              _summaryItem(
                Icons.local_florist,
                _formlar
                    .fold<int>(
                        0,
                        (s, f) =>
                            s + (int.tryParse(f.saksiCtrl.text) ?? 0))
                    .toString(),
                'Saksı',
              ),
              const SizedBox(width: 20),
              _summaryItem(
                Icons.straighten,
                _formlar
                    .fold<double>(
                        0,
                        (s, f) =>
                            s +
                            (double.tryParse(f.metreCtrl.text) ?? 0))
                    .toStringAsFixed(0),
                'Metre',
              ),
            ],
          ),
        ),
        // Başlık satırı
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          child: const Row(
            children: [
              SizedBox(
                  width: 36,
                  child: Text('Sıra',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(
                  width: 70,
                  child: Text('Metre',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(
                  width: 70,
                  child: Text('Saksı',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Cins',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),
        // Sıra listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _formlar.length,
            itemBuilder: (context, idx) => _buildSiraRow(idx, isDark),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  GÖRSEL SEKMESİ (yeni kroki)
  // ═══════════════════════════════════════════

  // Cins renk paleti – aynı cins her zaman aynı renk
  static const _cinsRenkler = <Color>[
    Color(0xFF059669), // yeşil
    Color(0xFF2563EB), // mavi
    Color(0xFFD97706), // turuncu
    Color(0xFF7C3AED), // mor
    Color(0xFFDC2626), // kırmızı
    Color(0xFF0891B2), // cyan
    Color(0xFFDB2777), // pembe
    Color(0xFF65A30D), // lime
    Color(0xFF9333EA), // indigo
    Color(0xFFEA580C), // deep orange
    Color(0xFF0D9488), // teal
    Color(0xFFCA8A04), // sarı
  ];

  Map<String, Color> _cinsRenkMap() {
    final map = <String, Color>{};
    int idx = 0;
    for (final f in _formlar) {
      final c = f.cinsCtrl.text.trim();
      if (c.isNotEmpty && !map.containsKey(c)) {
        map[c] = _cinsRenkler[idx % _cinsRenkler.length];
        idx++;
      }
    }
    return map;
  }

  Map<String, int> _cinsSaksiToplam() {
    final map = <String, int>{};
    for (final f in _formlar) {
      final c = f.cinsCtrl.text.trim();
      final saksi = int.tryParse(f.saksiCtrl.text.trim()) ?? 0;
      if (c.isNotEmpty) {
        map[c] = (map[c] ?? 0) + saksi;
      }
    }
    return map;
  }

  void _showSiraDuzenlePopup(int idx) {
    final f = _formlar[idx];
    final tempMetre = TextEditingController(text: f.metreCtrl.text);
    final tempSaksi = TextEditingController(text: f.saksiCtrl.text);
    final tempCins = TextEditingController(text: f.cinsCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${f.numara}. Sıra'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempMetre,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Metre',
                  prefixIcon: const Icon(Icons.straighten, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempSaksi,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Saksı / Fidan',
                  prefixIcon: const Icon(Icons.local_florist, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempCins,
                decoration: InputDecoration(
                  labelText: 'Cins',
                  prefixIcon: const Icon(Icons.eco, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              f.metreCtrl.text = tempMetre.text;
              f.saksiCtrl.text = tempSaksi.text;
              f.cinsCtrl.text = tempCins.text;
              setState(() => _hasChanges = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  Widget _buildGorselView(bool isDark) {
    final cinsRenk = _cinsRenkMap();
    final cinsSaksi = _cinsSaksiToplam();

    // En uzun metre değerini bul (ölçek için)
    double maxMetre = 0;
    for (final f in _formlar) {
      final m = double.tryParse(f.metreCtrl.text.trim()) ?? 0;
      if (m > maxMetre) maxMetre = m;
    }
    if (maxMetre <= 0) maxMetre = 1;

    return Column(
      children: [
        // Özet bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark
              ? Colors.grey.shade900
              : const Color(0xFF059669).withOpacity(0.05),
          child: Row(
            children: [
              _summaryItem(
                  Icons.view_column, '${_formlar.length}', 'Sıra'),
              const SizedBox(width: 20),
              _summaryItem(
                Icons.local_florist,
                _formlar
                    .fold<int>(
                        0,
                        (s, f) =>
                            s + (int.tryParse(f.saksiCtrl.text) ?? 0))
                    .toString(),
                'Saksı',
              ),
              const SizedBox(width: 20),
              _summaryItem(
                Icons.straighten,
                _formlar
                    .fold<double>(
                        0,
                        (s, f) =>
                            s +
                            (double.tryParse(f.metreCtrl.text) ?? 0))
                    .toStringAsFixed(0),
                'Metre',
              ),
            ],
          ),
        ),

        // Renk lejandı
        if (cinsRenk.isNotEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: cinsRenk.entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(e.key,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700)),
                  ],
                );
              }).toList(),
            ),
          ),

        // Ölçek göstergesi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          child: Text(
            'En uzun sıra: ${maxMetre.toStringAsFixed(1)} m',
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
                fontStyle: FontStyle.italic),
          ),
        ),

        // Görsel sıra çubukları
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: _formlar.length,
            itemBuilder: (context, idx) {
              final f = _formlar[idx];
              final metre =
                  double.tryParse(f.metreCtrl.text.trim()) ?? 0;
              final saksi =
                  int.tryParse(f.saksiCtrl.text.trim()) ?? 0;
              final cins = f.cinsCtrl.text.trim();
              final ratio = maxMetre > 0 ? metre / maxMetre : 0.0;
              final barColor = (cins.isNotEmpty && cinsRenk.containsKey(cins))
                  ? cinsRenk[cins]!
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

              return GestureDetector(
                onTap: () => _showSiraDuzenlePopup(idx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      // Sıra numarası
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${f.numara}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Çubuk
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxBarW = constraints.maxWidth;
                            final barW = math.max(
                                4.0, maxBarW * ratio);

                            // Saksı noktacıkları (max 30 görsel nokta)
                            final dotCount = saksi > 0
                                ? math.min(saksi, 30)
                                : 0;

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Çubuk
                                Container(
                                  width: barW,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding:
                                      const EdgeInsets.only(left: 4),
                                  child: barW > 50
                                      ? Text(
                                          '${metre > 0 ? "${metre.toStringAsFixed(metre == metre.roundToDouble() ? 0 : 1)}m" : ""}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        )
                                      : null,
                                ),
                                // Saksı noktacıkları
                                if (dotCount > 0)
                                  SizedBox(
                                    width: barW,
                                    height: 8,
                                    child: Row(
                                      children: List.generate(
                                        dotCount,
                                        (i) => Expanded(
                                          child: Center(
                                            child: Container(
                                              width: 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: barColor
                                                    .withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Bilgi etiketleri
                      SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (metre > 0 || saksi > 0)
                              Text(
                                '${metre > 0 ? "${metre.toStringAsFixed(metre == metre.roundToDouble() ? 0 : 1)}m" : ""}'
                                '${metre > 0 && saksi > 0 ? " • " : ""}'
                                '${saksi > 0 ? "$saksi" : ""}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (cins.isNotEmpty)
                              Text(
                                cins,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: barColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Cins toplam dipnot
        if (cinsSaksi.isNotEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cins Dağılımı',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white70 : Colors.grey.shade800)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: cinsSaksi.entries.map((e) {
                    final color = cinsRenk[e.key] ?? Colors.grey;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${e.key}: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${e.value} adet',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF059669)),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildSiraRow(int idx, bool isDark) {
    final f = _formlar[idx];
    final rowColor = idx.isEven
        ? (isDark ? Colors.grey.shade900 : Colors.white)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          // Sıra numarası
          SizedBox(
            width: 36,
            child: Text(
              '${f.numara}.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Metre
          SizedBox(
            width: 70,
            child: TextField(
              controller: f.metreCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                hintText: 'm',
                hintStyle: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
              onChanged: (_) {
                if (!_hasChanges) setState(() => _hasChanges = true);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Saksı sayısı
          SizedBox(
            width: 70,
            child: TextField(
              controller: f.saksiCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                hintText: 'adet',
                hintStyle: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
              onChanged: (_) {
                if (!_hasChanges) setState(() => _hasChanges = true);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Cins
          Expanded(
            child: TextField(
              controller: f.cinsCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                hintText: 'cins',
                hintStyle: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
              onChanged: (_) {
                if (!_hasChanges) setState(() => _hasChanges = true);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Helper class ───────────────

class _SiraForm {
  final int numara;
  final TextEditingController metreCtrl;
  final TextEditingController saksiCtrl;
  final TextEditingController cinsCtrl;

  _SiraForm({
    required this.numara,
    required this.metreCtrl,
    required this.saksiCtrl,
    required this.cinsCtrl,
  });
}
