import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    // Sıralardaki cinsleri topla
    final cinsler = <String>{};
    for (final s in parsel.siralar) {
      if (s.cins != null && s.cins!.isNotEmpty) cinsler.add(s.cins!);
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
                  if (canWrite)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _editParsel(idx);
                        if (v == 'delete') _deleteParsel(idx);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Düzenle'),
                            dense: true,
                          ),
                        ),
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

              // Cins etiketleri
              if (cinsler.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cinsler
                      .map((c) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🌱 $c',
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

class _SiraDuzenleScreenState extends State<_SiraDuzenleScreen> {
  late Bahce _bahce;
  late List<_SiraForm> _formlar;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Toplu atama
  final _topluMetreCtrl = TextEditingController();
  final _topluSaksiCtrl = TextEditingController();
  final _topluCinsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bahce = widget.bahce;
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
            // Toplu atama butonu
            IconButton(
              onPressed: _topluAtama,
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Toplu Atama',
            ),
            // Kaydet butonu
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
        ),
        body: Column(
          children: [
            // Özet bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark
                  ? Colors.grey.shade900
                  : const Color(0xFF059669).withOpacity(0.05),
              child: Row(
                children: [
                  _summaryItem(Icons.view_column, '${_formlar.length}',
                      'Sıra'),
                  const SizedBox(width: 20),
                  _summaryItem(
                    Icons.local_florist,
                    _formlar
                        .fold<int>(
                            0,
                            (s, f) =>
                                s +
                                (int.tryParse(f.saksiCtrl.text) ?? 0))
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
                                (double.tryParse(f.metreCtrl.text) ??
                                    0))
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
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  SizedBox(width: 8),
                  SizedBox(
                      width: 70,
                      child: Text('Metre',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  SizedBox(width: 8),
                  SizedBox(
                      width: 70,
                      child: Text('Saksı',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Cins',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                ],
              ),
            ),

            // Sıra listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _formlar.length,
                itemBuilder: (context, idx) =>
                    _buildSiraRow(idx, isDark),
              ),
            ),
          ],
        ),
        // Alt kaydet butonu
        bottomSheet: _hasChanges
            ? SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: isDark
                      ? Colors.grey.shade900
                      : Colors.white,
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
