import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bahce.dart';
import '../models/gubre.dart';
import '../providers/auth_provider.dart';
import '../services/operasyon_service.dart';

class GubrelemeScreen extends StatefulWidget {
  const GubrelemeScreen({super.key});

  @override
  State<GubrelemeScreen> createState() => _GubrelemeScreenState();
}

class _GubrelemeScreenState extends State<GubrelemeScreen>
    with SingleTickerProviderStateMixin {
  final OperasyonService _service = OperasyonService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  List<Bahce> _bahceler = [];
  List<GubreTank> _tanklar = [];
  List<GubreEnvanter> _envanter = [];
  bool _isLoading = true;

  String? _seciliBahceId;
  String? _seciliBahceAdi;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBahceler();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBahceler() async {
    setState(() => _isLoading = true);
    _bahceler = await _service.getBahceler();
    if (_bahceler.isNotEmpty && _seciliBahceId == null) {
      _seciliBahceId = _bahceler.first.id;
      _seciliBahceAdi = _bahceler.first.ad;
    }
    await _loadBahceVerileri();
    setState(() => _isLoading = false);
  }

  Future<void> _loadBahceVerileri() async {
    if (_seciliBahceId == null) return;
    _tanklar = await _service.getTanklar(bahceId: _seciliBahceId);
    _envanter = await _service.getEnvanter(bahceId: _seciliBahceId);
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadBahceVerileri();
    setState(() => _isLoading = false);
  }

  bool get _canWrite => context.read<AuthProvider>().canWriteOperasyon;

  @override
  Widget build(BuildContext context) {
    final stokDusukSayisi = _envanter.where((e) => e.stokDusuk).length;

    return Scaffold(
      body: Column(
        children: [
          // Bahçe seçici
          if (_bahceler.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          _seciliBahceAdi = b.ad;
                        });
                        _refresh();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFD97706),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFD97706),
            tabs: [
              const Tab(text: 'Tanklar'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Envanter'),
                    if (stokDusukSayisi > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text('$stokDusukSayisi',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Geçmiş'),
            ],
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _seciliBahceId == null
                    ? _buildNoBahce()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTanklarTab(),
                          _buildEnvanterTab(),
                          _buildGecmisTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: _seciliBahceId != null && _canWrite
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_tabController.index == 0) {
                  _showTankDialog();
                } else if (_tabController.index == 1) {
                  _showEnvanterDialog();
                }
              },
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                  _tabController.index == 1 ? 'Gübre Ekle' : 'Tank Ekle'),
            )
          : null,
    );
  }

  Widget _buildNoBahce() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.science_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Henüz bahçe yok',
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]),
    ).animate().fadeIn();
  }

  // ═══════════════ TANKLAR TAB ═══════════════

  Widget _buildTanklarTab() {
    if (_tanklar.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.propane_tank_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Henüz tank eklenmedi',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          if (_canWrite)
            Text('+ butonuyla yeni tank ekleyin',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ]),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _tanklar.length,
        itemBuilder: (context, index) =>
            _buildTankCard(_tanklar[index], index),
      ),
    );
  }

  Widget _buildTankCard(GubreTank tank, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTankDetay(tank),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(tank.ad,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tank ${tank.ad}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          Text(
                              '${tank.hacim > 0 ? _formatHacim(tank.hacim) : "Hacim girilmedi"} • ${tank.recete.length} gübre',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ]),
                  ),
                  // Katlama butonu — herkes kullanabilir
                  FilledButton.icon(
                    onPressed: tank.recete.isEmpty
                        ? null
                        : () => _showKatlamaDialog(tank),
                    icon: const Icon(Icons.layers, size: 18),
                    label: const Text('Katla'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              // Reçete özeti
              if (tank.recete.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text('Birim Reçete (1x)',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tank.recete.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF059669).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          '${r.gubreAdi}: ${_formatMiktar(r.miktar)} ${r.birimLabel}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(
        begin: 0.03, end: 0);
  }

  // ═══════════════ ENVANTER TAB ═══════════════

  Widget _buildEnvanterTab() {
    if (_envanter.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Gübre envanteri boş',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ]),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _envanter.length,
        itemBuilder: (context, index) =>
            _buildEnvanterCard(_envanter[index], index),
      ),
    );
  }

  Widget _buildEnvanterCard(GubreEnvanter item, int index) {
    final isDusuk = item.stokDusuk;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isDusuk
              ? const BorderSide(color: Colors.red, width: 1.5)
              : BorderSide.none),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color:
                (isDusuk ? Colors.red : const Color(0xFF059669)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDusuk ? Icons.warning_amber : Icons.science,
            color: isDusuk ? Colors.red : const Color(0xFF059669),
          ),
        ),
        title: Text(item.gubreAdi,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'Stok: ${_formatMiktar(item.miktar)} ${item.birimLabel}',
              style: TextStyle(
                  color: isDusuk ? Colors.red : Colors.grey.shade700,
                  fontWeight: isDusuk ? FontWeight.bold : FontWeight.normal),
            ),
            if (item.uyariSiniri > 0)
              Text('Uyarı sınırı: ${_formatMiktar(item.uyariSiniri)} ${item.birimLabel}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        trailing: _canWrite
            ? PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'stok_ekle':
                      _showStokEkleDialog(item);
                      break;
                    case 'duzenle':
                      _showEnvanterDialog(envanter: item);
                      break;
                    case 'sil':
                      _silEnvanter(item);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                      value: 'stok_ekle',
                      child: ListTile(
                          leading: Icon(Icons.add_box, color: Color(0xFF059669)),
                          title: Text('Stok Ekle'))),
                  const PopupMenuItem(
                      value: 'duzenle',
                      child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Düzenle'))),
                  const PopupMenuItem(
                      value: 'sil',
                      child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Sil',
                              style: TextStyle(color: Colors.red)))),
                ],
              )
            : null,
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index));
  }

  // ═══════════════ GEÇMİŞ TAB ═══════════════

  Widget _buildGecmisTab() {
    return FutureBuilder<List<KatlamaKaydi>>(
      future: _service.getKatlamaKayitlari(bahceId: _seciliBahceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final kayitlar = snapshot.data ?? [];
        if (kayitlar.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Henüz katlama kaydı yok',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 16)),
            ]),
          ).animate().fadeIn();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: kayitlar.length,
          itemBuilder: (context, index) {
            final k = kayitlar[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text('${k.katlama}x',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Tank ${k.tankAdi}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(
                                    '${k.yapanKullaniciAdi} • ${_dateFormat.format(k.tarih)}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ]),
                        ),
                      ],
                    ),
                    if (k.kullanilanGubreler.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: k.kullanilanGubreler
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                      '${g.gubreAdi}: ${_formatMiktar(g.miktar)} ${g.birimLabel}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple)),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 40 * index));
          },
        );
      },
    );
  }

  // ═══════════════ TANK DİALOGLARI ═══════════════

  void _showTankDialog({GubreTank? tank}) {
    final isEdit = tank != null;
    final adController = TextEditingController(text: tank?.ad ?? '');
    final hacimController =
        TextEditingController(text: tank != null ? tank.hacim.toString() : '');
    List<ReceteKalemi> recete =
        tank != null ? List<ReceteKalemi>.from(tank.recete) : [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Tank Düzenle' : 'Yeni Tank'),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: adController,
                    decoration: InputDecoration(
                      labelText: 'Tank Adı (A, B, C...)',
                      prefixIcon: const Icon(Icons.propane_tank),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: hacimController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hacim (litre)',
                      prefixIcon: const Icon(Icons.water_drop),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Reçete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reçete (${recete.length} gübre)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton.icon(
                        onPressed: () => _showReceteKalemiDialog(
                            ctx, null, (kalemi) {
                          setDialogState(() => recete.add(kalemi));
                        }),
                        icon: const Icon(Icons.add_circle,
                            size: 18, color: Color(0xFFD97706)),
                        label: const Text('Ekle',
                            style: TextStyle(
                                color: Color(0xFFD97706), fontSize: 13)),
                      ),
                    ],
                  ),
                  if (recete.isNotEmpty)
                    ...recete.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final r = entry.value;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.gubreAdi,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                            '${_formatMiktar(r.miktar)} ${r.birimLabel}',
                            style: const TextStyle(fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: Color(0xFFD97706)),
                              onPressed: () =>
                                  _showReceteKalemiDialog(ctx, r,
                                      (updated) {
                                setDialogState(
                                    () => recete[idx] = updated);
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  size: 18, color: Colors.red),
                              onPressed: () => setDialogState(
                                  () => recete.removeAt(idx)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      );
                    }),
                ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (adController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tank adı zorunlu')));
                  return;
                }
                final hacim =
                    double.tryParse(hacimController.text) ?? 0;
                if (isEdit) {
                  await _service.updateTank(tank.copyWith(
                    ad: adController.text.trim(),
                    hacim: hacim,
                    recete: recete,
                  ));
                } else {
                  await _service.addTank(GubreTank(
                    bahceId: _seciliBahceId!,
                    bahceAdi: _seciliBahceAdi!,
                    ad: adController.text.trim(),
                    hacim: hacim,
                    recete: recete,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white),
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceteKalemiDialog(
      BuildContext parentCtx, ReceteKalemi? existing, Function(ReceteKalemi) onSave) {
    final gubreCtrl =
        TextEditingController(text: existing?.gubreAdi ?? '');
    final miktarCtrl = TextEditingController(
        text: existing != null ? existing.miktar.toString() : '');
    GubreBirim birim = existing?.birim ?? GubreBirim.kg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              existing != null ? 'Gübre Düzenle' : 'Gübre Ekle'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: gubreCtrl,
              decoration: InputDecoration(
                labelText: 'Gübre Adı *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: miktarCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Miktar *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<GubreBirim>(
                  value: birim,
                  decoration: InputDecoration(
                    labelText: 'Birim',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: GubreBirim.values
                      .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(switch (b) {
                            GubreBirim.kg => 'kg',
                            GubreBirim.gram => 'g',
                            GubreBirim.litre => 'lt',
                          })))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => birim = v!),
                ),
              ),
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (gubreCtrl.text.trim().isEmpty ||
                    miktarCtrl.text.trim().isEmpty) return;
                onSave(ReceteKalemi(
                  gubreAdi: gubreCtrl.text.trim(),
                  miktar:
                      double.tryParse(miktarCtrl.text) ?? 0,
                  birim: birim,
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white),
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTankDetay(GubreTank tank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(tank.ad,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tank ${tank.ad}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        if (tank.hacim > 0)
                          Text(_formatHacim(tank.hacim),
                              style: TextStyle(
                                  color: Colors.grey.shade600)),
                      ]),
                ),
              ]),
              const SizedBox(height: 20),
              if (tank.recete.isNotEmpty) ...[
                const Text('Birim Reçete (1x)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...tank.recete.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.science,
                            size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(r.gubreAdi,
                                style: const TextStyle(fontSize: 15))),
                        Text(
                            '${_formatMiktar(r.miktar)} ${r.birimLabel}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ]),
                    )),
              ],
              const SizedBox(height: 20),
              // Aksiyonlar
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: tank.recete.isEmpty
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _showKatlamaDialog(tank);
                          },
                    icon: const Icon(Icons.layers),
                    label: const Text('Katlama Yap'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                if (_canWrite) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showTankDialog(tank: tank);
                    },
                    icon: const Icon(Icons.edit,
                        color: Color(0xFFD97706)),
                    tooltip: 'Düzenle',
                  ),
                  IconButton(
                    onPressed: () async {
                      final onay = await showDialog<bool>(
                        context: ctx,
                        builder: (c) => AlertDialog(
                          title: const Text('Tankı Sil'),
                          content: Text(
                              'Tank ${tank.ad} silinecek. Emin misiniz?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(c, false),
                                child: const Text('İptal')),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(c, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (onay == true) {
                        await _service.deleteTank(tank.id!);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _refresh();
                      }
                    },
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    tooltip: 'Sil',
                  ),
                ],
              ]),
            ]),
      ),
    );
  }

  // ═══════════════ KATLAMA DİALOGU ═══════════════

  void _showKatlamaDialog(GubreTank tank) {
    int katlama = 1;
    final katlamaCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final katlanmisRecete = tank.recete
              .map((r) => ReceteKalemi(
                    gubreAdi: r.gubreAdi,
                    miktar: r.miktar * katlama,
                    birim: r.birim,
                  ))
              .toList();

          return AlertDialog(
            title: Row(children: [
              const Icon(Icons.layers, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text('Tank ${tank.ad} — Katlama'),
            ]),
            content: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Katlama çarpanı
                    Row(children: [
                      IconButton(
                        onPressed: katlama > 1
                            ? () {
                                setDialogState(() {
                                  katlama--;
                                  katlamaCtrl.text = '$katlama';
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle,
                            color: Color(0xFFD97706)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: katlamaCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            labelText: 'Katlama',
                            suffixText: 'x',
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v) ?? 1;
                            if (val >= 1 && val <= 999) {
                              setDialogState(
                                  () => katlama = val);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            katlama++;
                            katlamaCtrl.text = '$katlama';
                          });
                        },
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFFD97706)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Hesaplanmış miktarlar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669)
                            .withOpacity(0.06),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF059669)
                                .withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${katlama}x Katlama Sonucu:',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 15,
                                  color:
                                      Color(0xFF059669))),
                          const SizedBox(height: 10),
                          ...katlanmisRecete.map((r) =>
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                        bottom: 6),
                                child: Row(children: [
                                  const Icon(
                                      Icons.science,
                                      size: 16,
                                      color:
                                          Color(0xFF059669)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          r.gubreAdi,
                                          style: const TextStyle(
                                              fontSize:
                                                  14))),
                                  Text(
                                      '${_formatMiktar(r.miktar)} ${r.birimLabel}',
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize: 15)),
                                ]),
                              )),
                        ],
                      ),
                    ),
                  ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal')),
              ElevatedButton.icon(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final user = auth.currentUser;
                  if (user == null) return;

                  // Envanterden düş
                  for (final r in katlanmisRecete) {
                    final envItem = _envanter.where((e) =>
                        e.gubreAdi.toLowerCase() ==
                            r.gubreAdi.toLowerCase() &&
                        e.bahceId == _seciliBahceId).firstOrNull;
                    if (envItem != null) {
                      await _service.envanterdenDus(
                          envItem.id!, r.miktar);
                    }
                  }

                  // Katlama kaydı oluştur
                  await _service.addKatlamaKaydi(KatlamaKaydi(
                    bahceId: _seciliBahceId!,
                    bahceAdi: _seciliBahceAdi!,
                    tankId: tank.id!,
                    tankAdi: tank.ad,
                    katlama: katlama,
                    kullanilanGubreler: katlanmisRecete,
                    yapanKullaniciId: user.id ?? '',
                    yapanKullaniciAdi: user.adSoyad,
                  ));

                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Tank ${tank.ad} — ${katlama}x katlama uygulandı ✓')),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Onayla & Uygula'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════ ENVANTER DİALOGLARI ═══════════════

  void _showEnvanterDialog({GubreEnvanter? envanter}) {
    final isEdit = envanter != null;
    final gubreCtrl =
        TextEditingController(text: envanter?.gubreAdi ?? '');
    final miktarCtrl = TextEditingController(
        text: envanter != null ? envanter.miktar.toString() : '');
    final sinirCtrl = TextEditingController(
        text: envanter != null
            ? envanter.uyariSiniri.toString()
            : '0');
    GubreBirim birim = envanter?.birim ?? GubreBirim.kg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit
              ? 'Envanter Düzenle'
              : 'Yeni Gübre Stoku'),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: gubreCtrl,
                    enabled: !isEdit,
                    decoration: InputDecoration(
                      labelText: 'Gübre Adı *',
                      prefixIcon: const Icon(Icons.science),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                      helperText: isEdit
                          ? 'Gübre adı değiştirilemez'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: miktarCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Mevcut Stok *',
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          DropdownButtonFormField<GubreBirim>(
                        value: birim,
                        decoration: InputDecoration(
                          labelText: 'Birim',
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        items: GubreBirim.values
                            .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(switch (b) {
                                  GubreBirim.kg => 'kg',
                                  GubreBirim.gram => 'g',
                                  GubreBirim.litre => 'lt',
                                })))
                            .toList(),
                        onChanged: isEdit
                            ? null
                            : (v) => setDialogState(
                                () => birim = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  TextField(
                    controller: sinirCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Uyarı Sınırı',
                      helperText:
                          'Stok bu değere düşünce uyarı verilir',
                      prefixIcon: const Icon(
                          Icons.warning_amber,
                          color: Colors.orange),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                  ),
                ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (gubreCtrl.text.trim().isEmpty) return;
                final miktar =
                    double.tryParse(miktarCtrl.text) ?? 0;
                final sinir =
                    double.tryParse(sinirCtrl.text) ?? 0;
                if (isEdit) {
                  await _service.updateEnvanter(
                      envanter.copyWith(
                    miktar: miktar,
                    uyariSiniri: sinir,
                  ));
                } else {
                  await _service.addEnvanter(GubreEnvanter(
                    bahceId: _seciliBahceId!,
                    bahceAdi: _seciliBahceAdi!,
                    gubreAdi: gubreCtrl.text.trim(),
                    miktar: miktar,
                    birim: birim,
                    uyariSiniri: sinir,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white),
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStokEkleDialog(GubreEnvanter item) {
    final miktarCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stok Ekle: ${item.gubreAdi}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              'Mevcut stok: ${_formatMiktar(item.miktar)} ${item.birimLabel}',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 14),
          TextField(
            controller: miktarCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Eklenecek Miktar (${item.birimLabel})',
              prefixIcon: const Icon(Icons.add_box,
                  color: Color(0xFF059669)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final ek = double.tryParse(miktarCtrl.text) ?? 0;
              if (ek <= 0) return;
              await _service.updateEnvanter(item.copyWith(
                miktar: item.miktar + ek,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              _refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${item.gubreAdi} stoku güncellendi ✓')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _silEnvanter(GubreEnvanter item) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Gübre Stoku Sil'),
        content: Text(
            '"${item.gubreAdi}" envanterden silinecek. Emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay == true) {
      await _service.deleteEnvanter(item.id!);
      _refresh();
    }
  }

  // ═══════════════ YARDIMCI ═══════════════

  String _formatMiktar(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  String _formatHacim(double lt) {
    if (lt >= 1000) {
      final m3 = lt / 1000;
      return '${_formatMiktar(m3)} m³';
    }
    return '${_formatMiktar(lt)} lt';
  }
}
