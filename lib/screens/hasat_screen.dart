import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bahce.dart';
import '../models/hasat.dart';
import '../models/satis.dart';
import '../providers/auth_provider.dart';
import '../services/operasyon_service.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';

class HasatScreen extends StatefulWidget {
  const HasatScreen({super.key});

  @override
  State<HasatScreen> createState() => _HasatScreenState();
}

class _HasatScreenState extends State<HasatScreen>
    with SingleTickerProviderStateMixin {
  final OperasyonService _service = OperasyonService();
  final DatabaseService _db = DatabaseService();
  final _dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
  final _numFormat = NumberFormat('#,##0.##', 'tr_TR');

  late TabController _tabController;

  List<Bahce> _bahceler = [];
  List<Hasat> _tumHasatlar = [];
  List<Satis> _satislar = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  String? _seciliBahceId;

  static const List<String> _birimler = ['kg', 'kasa', 'adet', 'ton', 'demet'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canWrite => context.read<AuthProvider>().canWriteOperasyon;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _bahceler = await _service.getBahceler();
    if (_bahceler.isNotEmpty && _seciliBahceId == null) {
      _seciliBahceId = _bahceler.first.id;
    }
    _tumHasatlar = await _service.getHasatlar();
    try {
      _satislar = await _db.getSatislar();
    } catch (_) {
      _satislar = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Hasat> get _seciliHasatlar =>
      _tumHasatlar.where((h) => h.bahceId == _seciliBahceId).toList();

  Bahce? get _seciliBahce {
    for (final b in _bahceler) {
      if (b.id == _seciliBahceId) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_bahceler.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: _bahceler.map((b) {
                  final isSelected = _seciliBahceId == b.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(b.ad,
                          style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : null)),
                      selectedColor: const Color(0xFFD97706),
                      checkmarkColor: Colors.white,
                      onSelected: (_) {
                        setState(() {
                          _seciliBahceId = b.id;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFD97706),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFD97706),
            tabs: const [
              Tab(text: 'Kayıtlar'),
              Tab(text: 'Verim'),
              Tab(text: 'Stok'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bahceler.isEmpty
                    ? _buildNoBahce()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildKayitlarTab(),
                          _buildVerimTab(),
                          _buildStokTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: (_isLoading || _bahceler.isEmpty)
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'hasatExcel',
                  backgroundColor: Colors.green.shade600,
                  onPressed: _exportExcel,
                  child: const Icon(Icons.file_download, color: Colors.white),
                ),
                const SizedBox(height: 12),
                if (_canWrite && _tabController.index == 0)
                  FloatingActionButton.extended(
                    heroTag: 'hasatEkle',
                    backgroundColor: const Color(0xFFD97706),
                    onPressed: _showHasatDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Hasat Ekle',
                        style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
    );
  }

  Widget _buildNoBahce() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.park_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Önce bahçe eklemelisiniz',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Hasat kaydı için Bahçeler sekmesinden bahçe ve parsel oluşturun',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      );

  // ==================== KAYITLAR ====================
  Widget _buildKayitlarTab() {
    final hasatlar = _seciliHasatlar;
    if (hasatlar.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.eco_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Bu bahçede henüz hasat kaydı yok',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
        itemCount: hasatlar.length,
        itemBuilder: (context, i) {
          final h = hasatlar[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD97706).withOpacity(0.15),
                child: const Icon(Icons.eco, color: Color(0xFFD97706)),
              ),
              title: Text('${h.parselAd} • ${h.urun}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateFormat.format(h.tarih)),
                  if (h.kalite != null && h.kalite!.isNotEmpty)
                    Text('Kalite: ${h.kalite}',
                        style: const TextStyle(fontSize: 12)),
                  if (h.verimSaksiBasi != null)
                    Text(
                        'Verim: ${_numFormat.format(h.verimSaksiBasi)} ${h.birim}/saksı',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFD97706))),
                  if (h.not != null && h.not!.isNotEmpty)
                    Text(h.not!,
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_numFormat.format(h.miktar)} ${h.birim}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (_canWrite)
                    InkWell(
                      onTap: () => _deleteHasat(h),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                      ),
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  // ==================== VERIM ====================
  Widget _buildVerimTab() {
    final hasatlar = _seciliHasatlar;
    if (hasatlar.isEmpty) {
      return const Center(
          child: Text('Bu bahçede veri yok',
              style: TextStyle(color: Colors.grey)));
    }
    final bahce = _seciliBahce;

    // parsel+ürün+birim bazlı grupla
    final Map<String, Map<String, dynamic>> gruplar = {};
    for (final h in hasatlar) {
      final key = '${h.parselId}|${h.urun}|${h.birim}';
      final g = gruplar.putIfAbsent(
          key,
          () => {
                'parsel': h.parselAd,
                'parselId': h.parselId,
                'urun': h.urun,
                'birim': h.birim,
                'toplam': 0.0,
                'adet': 0,
              });
      g['toplam'] = (g['toplam'] as double) + h.miktar;
      g['adet'] = (g['adet'] as int) + 1;
    }

    final rows = gruplar.values.toList()
      ..sort((a, b) => (b['toplam'] as double).compareTo(a['toplam'] as double));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: rows.map((g) {
        double? saksi;
        if (bahce != null) {
          for (final p in bahce.parseller) {
            if (p.id == g['parselId']) {
              saksi = p.toplamSaksi.toDouble();
              break;
            }
          }
        }
        final toplam = g['toplam'] as double;
        final verim =
            (saksi != null && saksi > 0) ? toplam / saksi : null;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.grass, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${g['parsel']} • ${g['urun']}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text('${_numFormat.format(toplam)} ${g['birim']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('${g['adet']} kayıt',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    if (verim != null)
                      Text(
                          'Verim: ${_numFormat.format(verim)} ${g['birim']}/saksı',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706)))
                    else
                      const Text('Saksı bilgisi yok',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== STOK ====================
  Widget _buildStokTab() {
    // Tüm bahçelerdeki hasat (giren) vs satış (çıkan), ürün bazında
    final Map<String, Map<String, dynamic>> stok = {};

    String norm(String s) => s.trim().toLowerCase();

    for (final h in _tumHasatlar) {
      final key = norm(h.urun);
      if (key.isEmpty) continue;
      final s = stok.putIfAbsent(
          key,
          () => {
                'urun': h.urun,
                'birim': h.birim,
                'hasat': 0.0,
                'satis': 0.0,
              });
      s['hasat'] = (s['hasat'] as double) + h.miktar;
    }
    for (final sat in _satislar) {
      final key = norm(sat.urunAdi);
      if (key.isEmpty) continue;
      final s = stok.putIfAbsent(
          key,
          () => {
                'urun': sat.urunAdi,
                'birim': sat.birim,
                'hasat': 0.0,
                'satis': 0.0,
              });
      s['satis'] = (s['satis'] as double) + sat.miktar;
      (s.putIfAbsent('satisListe', () => <Satis>[]) as List<Satis>).add(sat);
    }

    if (stok.isEmpty) {
      return const Center(
          child: Text('Stok için hasat veya satış verisi yok',
              style: TextStyle(color: Colors.grey)));
    }

    final rows = stok.values.toList()
      ..sort((a, b) => (a['urun'] as String)
          .toLowerCase()
          .compareTo((b['urun'] as String).toLowerCase()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Kalan = Toplam Hasat − Toplam Satış. Ürünler ada göre eşleştirilir; '
            'hasat ve satış birimlerinin aynı olmasına dikkat edin.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        ...rows.map((s) {
          final hasat = s['hasat'] as double;
          final satis = s['satis'] as double;
          final kalan = hasat - satis;
          final satisListe =
              ((s['satisListe'] as List<Satis>?) ?? const <Satis>[]).toList()
                ..sort((a, b) => b.tarih.compareTo(a.tarih));
          final toplamCiro = satisListe.fold<double>(
              0, (t, x) => t + (x.tlKarsiligi ?? x.toplamTutar));
          final ortFiyat = satis > 0 ? toplamCiro / satis : null;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              shape: const Border(),
              title: Text(s['urun'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stokKolon('Hasat', hasat, s['birim'] as String,
                        Colors.green),
                    _stokKolon('Satış', satis, s['birim'] as String,
                        Colors.red),
                    _stokKolon('Kalan', kalan, s['birim'] as String,
                        kalan < 0 ? Colors.orange : const Color(0xFFD97706)),
                  ],
                ),
              ),
              children: [
                if (satisListe.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('Bu ürün için satış kaydı yok',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam Ciro: ${_numFormat.format(toplamCiro)} ₺',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      if (ortFiyat != null)
                        Text(
                          'Ort. Fiyat: ${_numFormat.format(ortFiyat)} ₺/${s['birim']}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  ...satisListe.map((sat) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_dateFormat.format(sat.tarih),
                                      style: const TextStyle(fontSize: 12)),
                                  if ((sat.musteriUnvan ?? '').isNotEmpty)
                                    Text(sat.musteriUnvan!,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey),
                                        overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${_numFormat.format(sat.miktar)} ${sat.birim}',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${_numFormat.format(sat.birimFiyat)} ${sat.paraBirimi}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _numFormat
                                    .format(sat.tlKarsiligi ?? sat.toplamTutar),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _stokKolon(String baslik, double deger, String birim, Color renk) {
    return Column(
      children: [
        Text(baslik,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('${_numFormat.format(deger)} $birim',
            style: TextStyle(fontWeight: FontWeight.bold, color: renk)),
      ],
    );
  }

  // ==================== EXCEL ====================
  Future<void> _exportExcel() async {
    final veri = _tabController.index == 2 ? _tumHasatlar : _seciliHasatlar;
    if (veri.isEmpty) {
      _snack('Dışa aktarılacak hasat kaydı yok', Colors.orange);
      return;
    }
    try {
      await ExcelService().exportHasat(veri);
      _snack('Excel dosyası indirildi ✓', Colors.green);
    } catch (e) {
      _snack('Excel oluşturulamadı: $e', Colors.red);
    }
  }

  // ==================== EKLE / SIL ====================
  Future<void> _deleteHasat(Hasat h) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hasat kaydını sil'),
        content: Text(
            '${h.parselAd} • ${h.urun} (${_numFormat.format(h.miktar)} ${h.birim}) kaydı silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (onay != true || h.id == null) return;
    final ok = await _service.deleteHasat(h.id!);
    if (ok) {
      _snack('Kayıt silindi', Colors.green);
      await _loadData();
    } else {
      _snack('Silinemedi', Colors.red);
    }
  }

  void _showHasatDialog() {
    final bahce = _seciliBahce;
    if (bahce == null) return;
    final parseller = bahce.parseller;
    if (parseller.isEmpty) {
      _snack('Bu bahçede parsel yok. Önce Bahçeler sekmesinden parsel ekleyin.',
          Colors.orange);
      return;
    }

    Parsel? seciliParsel = parseller.first;
    final urunController =
        TextEditingController(text: seciliParsel.cins ?? '');
    final miktarController = TextEditingController();
    final kaliteController = TextEditingController();
    final notController = TextEditingController();
    String birim = 'kg';
    DateTime tarih = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text('Hasat Ekle • ${bahce.ad}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Parsel>(
                      initialValue: seciliParsel,
                      decoration: const InputDecoration(
                        labelText: 'Parsel',
                        border: OutlineInputBorder(),
                      ),
                      items: parseller
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                    '${p.ad}${p.cins != null && p.cins!.isNotEmpty ? " (${p.cins})" : ""}'),
                              ))
                          .toList(),
                      onChanged: (p) {
                        setSheet(() {
                          seciliParsel = p;
                          if (p?.cins != null &&
                              p!.cins!.isNotEmpty &&
                              urunController.text.isEmpty) {
                            urunController.text = p.cins!;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urunController,
                      decoration: const InputDecoration(
                        labelText: 'Ürün',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: miktarController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Miktar',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: birim,
                            decoration: const InputDecoration(
                              labelText: 'Birim',
                              border: OutlineInputBorder(),
                            ),
                            items: _birimler
                                .map((b) => DropdownMenuItem(
                                    value: b, child: Text(b)))
                                .toList(),
                            onChanged: (v) =>
                                setSheet(() => birim = v ?? 'kg'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kaliteController,
                      decoration: const InputDecoration(
                        labelText: 'Kalite (opsiyonel)',
                        hintText: 'ör. 1. Boy, 2. Boy, Iskarta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final secilen = await showDatePicker(
                          context: ctx,
                          initialDate: tarih,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 1)),
                        );
                        if (secilen != null) {
                          setSheet(() => tarih = secilen);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tarih',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_dateFormat.format(tarih)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notController,
                      decoration: const InputDecoration(
                        labelText: 'Not (opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          if (_isProcessing) return;
                          final miktar = double.tryParse(
                              miktarController.text.replaceAll(',', '.'));
                          if (seciliParsel == null) {
                            _snack('Parsel seçin', Colors.orange);
                            return;
                          }
                          if (urunController.text.trim().isEmpty) {
                            _snack('Ürün girin', Colors.orange);
                            return;
                          }
                          if (miktar == null || miktar <= 0) {
                            _snack('Geçerli miktar girin', Colors.orange);
                            return;
                          }
                          _isProcessing = true;
                          final hasat = Hasat(
                            bahceId: bahce.id ?? '',
                            bahceAd: bahce.ad,
                            parselId: seciliParsel!.id ?? '',
                            parselAd: seciliParsel!.ad,
                            urun: urunController.text.trim(),
                            tarih: tarih,
                            miktar: miktar,
                            birim: birim,
                            kalite: kaliteController.text.trim().isEmpty
                                ? null
                                : kaliteController.text.trim(),
                            saksiSayisi:
                                seciliParsel!.toplamSaksi.toDouble(),
                            not: notController.text.trim().isEmpty
                                ? null
                                : notController.text.trim(),
                          );
                          final id = await _service.addHasat(hasat);
                          _isProcessing = false;
                          if (id != null) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            _snack('Hasat kaydedildi ✓', Colors.green);
                            await _loadData();
                          } else {
                            _snack('Kaydedilemedi', Colors.red);
                          }
                        },
                        child: const Text('Kaydet',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}