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
  final _dateFormatShort = DateFormat('dd.MM.yyyy', 'tr_TR');

  List<Bahce> _bahceler = [];
  List<GubreTank> _tanklar = [];
  List<GubreEnvanter> _envanter = [];
  bool _isLoading = true;
  bool _isProcessing = false; // Çift tıklama koruması

  String? _seciliBahceId;
  String? _seciliBahceAdi;

  Future<List<KatlamaKaydi>>? _gecmisKayitlariFuture; // FutureBuilder cache

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
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
    _gecmisKayitlariFuture = _service.getKatlamaKayitlari(bahceId: _seciliBahceId);
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
                          _seciliBahceAdi = b.ad;
                        });
                        _refresh();
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
          ? _tabController.index == 2
              ? null
              : FloatingActionButton.extended(
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
                  label: Text(_tabController.index == 1 ? 'Gübre Ekle' : 'Tank Ekle'),
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
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]),
    ).animate().fadeIn();
  }

  // ═══════════════ TANKLAR TAB ═══════════════

  Widget _buildTanklarTab() {
    if (_tanklar.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.propane_tank_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Henüz tank eklenmedi',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          if (_canWrite)
            Text('+ butonuyla yeni tank ekleyin',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ]),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _tanklar.length,
        itemBuilder: (context, index) => _buildTankCard(_tanklar[index], index),
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(tank.ad,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tank ${tank.ad}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text('${tank.hacim > 0 ? _formatHacim(tank.hacim) : "Hacim girilmedi"} • ${tank.recete.length} gübre',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ]),
                  ),
                  FilledButton.icon(
                    onPressed: tank.recete.isEmpty ? null : () => _showKatlamaDialog(tank),
                    icon: const Icon(Icons.layers, size: 18),
                    label: const Text('Katla'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (tank.recete.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Birim Reçete (1x)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (_canWrite)
                      InkWell(
                        onTap: () => _showReceteGecmisiDialog(tank),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.history, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text('Geçmiş', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                      ),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text('Gübre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text('Miktar', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                        const SizedBox(width: 8),
                        SizedBox(width: 30, child: Text('Birim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                      ]),
                    ),
                    ...tank.recete.asMap().entries.map((entry) {
                      final r = entry.value;
                      final isLast = entry.key == tank.recete.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(r.gubreAdi, style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 2, child: Text(_formatMiktar(r.miktar), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                          const SizedBox(width: 8),
                          SizedBox(width: 30, child: Text(r.birimLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                        ]),
                      );
                    }),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(begin: 0.03, end: 0);
  }

  // ═══════════════ ENVANTER TAB ═══════════════

  Widget _buildEnvanterTab() {
    if (_envanter.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Gübre envanteri boş', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ]),
      ).animate().fadeIn();
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _envanter.length,
        itemBuilder: (context, index) => _buildEnvanterCard(_envanter[index], index),
      ),
    );
  }

  Widget _buildEnvanterCard(GubreEnvanter item, int index) {
    final isDusuk = item.stokDusuk;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isDusuk ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (isDusuk ? Colors.red : const Color(0xFF059669)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(isDusuk ? Icons.warning_amber : Icons.science,
              color: isDusuk ? Colors.red : const Color(0xFF059669)),
        ),
        title: Text(item.gubreAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 2),
          Text('Stok: ${_formatMiktar(item.miktar)} ${item.birimLabel}',
              style: TextStyle(
                  color: isDusuk ? Colors.red : Colors.grey.shade700,
                  fontWeight: isDusuk ? FontWeight.bold : FontWeight.normal)),
          if (item.uyariSiniri > 0)
            Text('Uyarı sınırı: ${_formatMiktar(item.uyariSiniri)} ${item.birimLabel}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
        trailing: _canWrite
            ? PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'stok_ekle': _showStokEkleDialog(item); break;
                    case 'yaprak_uygula': _showYaprakUygulaDialog(item); break;
                    case 'duzenle': _showEnvanterDialog(envanter: item); break;
                    case 'sil': _silEnvanter(item); break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'stok_ekle', child: ListTile(leading: Icon(Icons.add_box, color: Color(0xFF059669)), title: Text('Stok Ekle'))),
                  const PopupMenuItem(value: 'yaprak_uygula', child: ListTile(leading: Icon(Icons.eco, color: Colors.teal), title: Text('Yaprak Gübre Uygula'))),
                  const PopupMenuItem(value: 'duzenle', child: ListTile(leading: Icon(Icons.edit), title: Text('Düzenle'))),
                  const PopupMenuItem(value: 'sil', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Sil', style: TextStyle(color: Colors.red)))),
                ],
              )
            : null,
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index));
  }

  // ═══════════════ GEÇMİŞ TAB ═══════════════

  Widget _buildGecmisTab() {
    _gecmisKayitlariFuture ??= _service.getKatlamaKayitlari(bahceId: _seciliBahceId);
    return FutureBuilder<List<KatlamaKaydi>>(
      future: _gecmisKayitlariFuture,
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
              Text('Henüz katlama kaydı yok', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text('${k.katlama}x', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tank ${k.tankAdi}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${k.yapanKullaniciAdi} • ${_dateFormat.format(k.tarih)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ])),
                    if (_canWrite)
                      IconButton(
                        onPressed: () => _silKatlamaKaydi(k),
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        tooltip: 'Sil',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                  ]),
                  if (k.kullanilanGubreler.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(children: k.kullanilanGubreler.asMap().entries.map((entry) {
                        final g = entry.value;
                        final isLast = entry.key == k.kullanilanGubreler.length - 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
                          child: Row(children: [
                            Expanded(child: Text(g.gubreAdi, style: const TextStyle(fontSize: 13))),
                            Text('${_formatMiktar(g.miktar)} ${g.birimLabel}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.purple)),
                          ]),
                        );
                      }).toList()),
                    ),
                  ],
                ]),
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
    final hacimController = TextEditingController(text: tank != null ? tank.hacim.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Tank Düzenle' : 'Yeni Tank'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: adController,
            decoration: InputDecoration(
              labelText: 'Tank Adı (A, B, C...)',
              prefixIcon: const Icon(Icons.propane_tank),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: hacimController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Hacim (litre)',
              prefixIcon: const Icon(Icons.water_drop),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (!isEdit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Reçeteyi tank oluşturduktan sonra tablo üzerinden girebilirsiniz.',
                      style: TextStyle(fontSize: 12, color: Colors.blue)),
                ),
              ]),
            ),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: _isProcessing ? null : () async {
              if (adController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tank adı zorunlu')));
                return;
              }
              setState(() => _isProcessing = true);
              try {
                final hacim = double.tryParse(hacimController.text) ?? 0;
                if (isEdit) {
                  await _service.updateTank(tank.copyWith(ad: adController.text.trim(), hacim: hacim));
                } else {
                  await _service.addTank(GubreTank(
                    bahceId: _seciliBahceId!,
                    bahceAdi: _seciliBahceAdi!,
                    ad: adController.text.trim(),
                    hacim: hacim,
                    recete: [],
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: Text(isEdit ? 'Güncelle' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  // ═══════════════ TANK DETAY + TABLO REÇETE ═══════════════

  void _showTankDetay(GubreTank tank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(controller: scrollController, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: const Color(0xFFD97706).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(tank.ad, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tank ${tank.ad}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (tank.hacim > 0) Text(_formatHacim(tank.hacim), style: TextStyle(color: Colors.grey.shade600)),
              ])),
              if (_canWrite) ...[
                IconButton(onPressed: () { Navigator.pop(ctx); _showTankDialog(tank: tank); }, icon: const Icon(Icons.edit, color: Color(0xFFD97706)), tooltip: 'Düzenle'),
                IconButton(onPressed: () => _silTank(ctx, tank), icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Sil'),
              ],
            ]),
            const SizedBox(height: 20),

            // Reçete bölümü
            Row(children: [
              const Icon(Icons.receipt_long, size: 20, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              const Text('Reçete', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_canWrite)
                TextButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showReceteTabloDialog(tank); },
                  icon: const Icon(Icons.edit_note, size: 20, color: Color(0xFFD97706)),
                  label: const Text('Tablo ile Düzenle', style: TextStyle(color: Color(0xFFD97706), fontSize: 13)),
                ),
            ]),
            const SizedBox(height: 10),

            if (tank.recete.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(children: [
                  Icon(Icons.receipt_long, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Reçete henüz girilmedi', style: TextStyle(color: Colors.grey.shade500)),
                  if (_canWrite) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () { Navigator.pop(ctx); _showReceteTabloDialog(tank); },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Reçete Gir'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                    ),
                  ],
                ]),
              )
            else
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
                    child: const Row(children: [
                      Expanded(flex: 4, child: Text('Gübre Adı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 2, child: Text('Miktar', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      SizedBox(width: 10),
                      SizedBox(width: 35, child: Text('Birim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ]),
                  ),
                  ...tank.recete.asMap().entries.map((entry) {
                    final r = entry.value;
                    final isLast = entry.key == tank.recete.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
                      child: Row(children: [
                        Expanded(flex: 4, child: Text(r.gubreAdi, style: const TextStyle(fontSize: 14))),
                        Expanded(flex: 2, child: Text(_formatMiktar(r.miktar), textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF059669)))),
                        const SizedBox(width: 10),
                        SizedBox(width: 35, child: Text(r.birimLabel, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                      ]),
                    );
                  }),
                ]),
              ),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showReceteGecmisiDialog(tank),
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Reçete Geçmişi'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700, side: BorderSide(color: Colors.grey.shade300), minimumSize: const Size(double.infinity, 44)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: tank.recete.isEmpty ? null : () { Navigator.pop(ctx); _showKatlamaDialog(tank); },
              icon: const Icon(Icons.layers),
              label: const Text('Katlama Yap'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════ REÇETE TABLO DİALOGU ═══════════════

  void _showReceteTabloDialog(GubreTank tank) {
    List<_ReceteSatiri> satirlar = tank.recete
        .map((r) => _ReceteSatiri(gubreCtrl: TextEditingController(text: r.gubreAdi), miktarCtrl: TextEditingController(text: _formatMiktar(r.miktar)), birim: r.birim))
        .toList();
    if (satirlar.isEmpty) {
      satirlar.add(_ReceteSatiri(gubreCtrl: TextEditingController(), miktarCtrl: TextEditingController()));
    }
    final notCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(children: [
              const Icon(Icons.table_chart, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text('Tank ${tank.ad} — Reçete'),
            ]),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFD97706).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Expanded(flex: 4, child: Text('Gübre Adı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Miktar', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 65, child: Text('Birim', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 32),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  ...satirlar.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Expanded(flex: 4, child: DropdownButtonFormField<String>(
                          value: _envanter.any((e) => e.gubreAdi == s.gubreCtrl.text) ? s.gubreCtrl.text : null,
                          isDense: true,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Gübre seç',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                          items: _envanter.map((e) => DropdownMenuItem(
                            value: e.gubreAdi,
                            child: Text('\${e.gubreAdi} (\${_formatMiktar(e.miktar)} \${e.birimLabel})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() {
                                s.gubreCtrl.text = v;
                                // Birim otomatik ayarla
                                final envItem = _envanter.firstWhere((e) => e.gubreAdi == v);
                                s.birim = envItem.birim;
                              });
                            }
                          },
                        )),
                        const SizedBox(width: 6),
                        Expanded(flex: 2, child: TextField(
                          controller: s.miktarCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(hintText: '0', hintStyle: const TextStyle(fontSize: 12), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          style: const TextStyle(fontSize: 13),
                        )),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 65,
                          child: DropdownButtonFormField<GubreBirim>(
                            value: s.birim,
                            isDense: true,
                            isExpanded: true,
                            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                            items: GubreBirim.values.map((b) => DropdownMenuItem(value: b, child: Text(switch (b) { GubreBirim.kg => 'kg', GubreBirim.gram => 'g', GubreBirim.litre => 'lt' }))).toList(),
                            onChanged: (v) => setDialogState(() => s.birim = v!),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(width: 28, child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: satirlar.length > 1 ? () => setDialogState(() => satirlar.removeAt(idx)) : null,
                          icon: Icon(Icons.remove_circle, size: 20, color: satirlar.length > 1 ? Colors.red : Colors.grey.shade300),
                        )),
                      ]),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setDialogState(() { satirlar.add(_ReceteSatiri(gubreCtrl: TextEditingController(), miktarCtrl: TextEditingController())); }),
                    icon: const Icon(Icons.add_circle, size: 18, color: Color(0xFFD97706)),
                    label: const Text('Satır Ekle', style: TextStyle(color: Color(0xFFD97706), fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notCtrl,
                    decoration: InputDecoration(labelText: 'Değişiklik notu (opsiyonel)', hintText: 'Örn: Kış dönemi reçetesi', prefixIcon: const Icon(Icons.note_alt, size: 20), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    style: const TextStyle(fontSize: 13),
                  ),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : () async {
                  setState(() => _isProcessing = true);
                  try {
                    final yeniRecete = <ReceteKalemi>[];
                    for (final s in satirlar) {
                      final gubreAdi = s.gubreCtrl.text.trim();
                      final miktar = double.tryParse(s.miktarCtrl.text) ?? 0;
                      if (gubreAdi.isNotEmpty && miktar > 0) {
                        yeniRecete.add(ReceteKalemi(gubreAdi: gubreAdi, miktar: miktar, birim: s.birim));
                      }
                    }
                    final auth = context.read<AuthProvider>();
                    final user = auth.currentUser;
                    // Sadece reçete boş değilse veya önceki reçete doluysa geçmiş kaydet
                    if (user != null && (yeniRecete.isNotEmpty || tank.recete.isNotEmpty)) {
                      await _service.addReceteGecmisi(ReceteGecmisi(
                        bahceId: tank.bahceId, bahceAdi: tank.bahceAdi,
                        tankId: tank.id!, tankAdi: tank.ad,
                        recete: yeniRecete,
                        degistirenKullaniciId: user.id ?? '',
                        degistirenKullaniciAdi: user.adSoyad,
                        not: notCtrl.text.trim(),
                      ));
                    }
                    await _service.updateTank(tank.copyWith(recete: yeniRecete));
                    if (ctx.mounted) Navigator.pop(ctx);
                    _refresh();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tank ${tank.ad} reçetesi güncellendi ✓')));
                    }
                  } finally {
                    if (mounted) setState(() => _isProcessing = false);
                  }
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════ REÇETE GEÇMİŞİ ═══════════════

  void _showReceteGecmisiDialog(GubreTank tank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.history, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text('Tank ${tank.ad} — Reçete Geçmişi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: FutureBuilder<List<ReceteGecmisi>>(
                future: _service.getReceteGecmisi(tankId: tank.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final gecmis = snapshot.data ?? [];
                  if (gecmis.isEmpty) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Henüz reçete geçmişi yok', style: TextStyle(color: Colors.grey.shade500)),
                    ]));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: gecmis.length,
                    itemBuilder: (ctx, index) {
                      final g = gecmis[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFD97706).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(_dateFormatShort.format(g.tarih), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(g.degistirenKullaniciAdi, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                              Text('${g.recete.length} gübre', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              if (_canWrite) ...[                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _silReceteGecmisi(ctx, g, tank),
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  ),
                                ),
                              ],
                            ]),
                            if (g.not.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Row(children: [
                                  Icon(Icons.note_alt, size: 14, color: Colors.blue.shade400),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(g.not, style: TextStyle(fontSize: 12, color: Colors.blue.shade700))),
                                ]),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(children: g.recete.asMap().entries.map((entry) {
                                final r = entry.value;
                                final isLast = entry.key == g.recete.length - 1;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
                                  child: Row(children: [
                                    Expanded(child: Text(r.gubreAdi, style: const TextStyle(fontSize: 13))),
                                    Text('${_formatMiktar(r.miktar)} ${r.birimLabel}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ]),
                                );
                              }).toList()),
                            ),
                          ]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
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
          final katlanmisRecete = tank.recete.map((r) => ReceteKalemi(gubreAdi: r.gubreAdi, miktar: r.miktar * katlama, birim: r.birim)).toList();
          return AlertDialog(
            title: Row(children: [
              const Icon(Icons.layers, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text('Tank ${tank.ad} — Katlama'),
            ]),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  IconButton(
                    onPressed: katlama > 1 ? () { setDialogState(() { katlama--; katlamaCtrl.text = '$katlama'; }); } : null,
                    icon: const Icon(Icons.remove_circle, color: Color(0xFFD97706)),
                  ),
                  Expanded(child: TextField(
                    controller: katlamaCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), labelText: 'Katlama', suffixText: 'x'),
                    onChanged: (v) { final val = int.tryParse(v) ?? 1; if (val >= 1 && val <= 999) setDialogState(() => katlama = val); },
                  )),
                  IconButton(
                    onPressed: () { setDialogState(() { katlama++; katlamaCtrl.text = '$katlama'; }); },
                    icon: const Icon(Icons.add_circle, color: Color(0xFFD97706)),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF059669).withOpacity(0.3))),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
                      child: Row(children: [Expanded(child: Text('${katlama}x Katlama Sonucu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF059669))))]),
                    ),
                    ...katlanmisRecete.asMap().entries.map((entry) {
                      final r = entry.value;
                      final isLast = entry.key == katlanmisRecete.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
                        child: Row(children: [
                          const Icon(Icons.science, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r.gubreAdi, style: const TextStyle(fontSize: 14))),
                          Text('${_formatMiktar(r.miktar)} ${r.birimLabel}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                      );
                    }),
                  ]),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : () async {
                  setState(() => _isProcessing = true);
                  try {
                    final auth = context.read<AuthProvider>();
                    final user = auth.currentUser;
                    if (user == null) return;
                    for (final r in katlanmisRecete) {
                      final envItem = _envanter.where((e) => e.gubreAdi.toLowerCase() == r.gubreAdi.toLowerCase() && e.bahceId == _seciliBahceId).firstOrNull;
                      if (envItem != null) await _service.envanterdenDus(envItem.id!, r.miktar);
                    }
                    await _service.addKatlamaKaydi(KatlamaKaydi(
                      bahceId: _seciliBahceId!, bahceAdi: _seciliBahceAdi!,
                      tankId: tank.id!, tankAdi: tank.ad,
                      katlama: katlama, kullanilanGubreler: katlanmisRecete,
                      yapanKullaniciId: user.id ?? '', yapanKullaniciAdi: user.adSoyad,
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                    _refresh();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tank ${tank.ad} — ${katlama}x katlama uygulandı ✓')));
                  } finally {
                    if (mounted) setState(() => _isProcessing = false);
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Onayla & Uygula'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
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
    final gubreCtrl = TextEditingController(text: envanter?.gubreAdi ?? '');
    final miktarCtrl = TextEditingController(text: envanter != null ? envanter.miktar.toString() : '');
    final sinirCtrl = TextEditingController(text: envanter != null ? envanter.uyariSiniri.toString() : '0');
    GubreBirim birim = envanter?.birim ?? GubreBirim.kg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Envanter Düzenle' : 'Yeni Gübre Stoku'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: gubreCtrl, enabled: !isEdit,
                decoration: InputDecoration(labelText: 'Gübre Adı *', prefixIcon: const Icon(Icons.science), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), helperText: isEdit ? 'Gübre adı değiştirilemez' : null),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(flex: 2, child: TextField(controller: miktarCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Mevcut Stok *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<GubreBirim>(
                  value: birim,
                  decoration: InputDecoration(labelText: 'Birim', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: GubreBirim.values.map((b) => DropdownMenuItem(value: b, child: Text(switch (b) { GubreBirim.kg => 'kg', GubreBirim.gram => 'g', GubreBirim.litre => 'lt' }))).toList(),
                  onChanged: isEdit ? null : (v) => setDialogState(() => birim = v!),
                )),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: sinirCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Uyarı Sınırı', helperText: 'Stok bu değere düşünce uyarı verilir', prefixIcon: const Icon(Icons.warning_amber, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: _isProcessing ? null : () async {
                if (gubreCtrl.text.trim().isEmpty) return;
                setState(() => _isProcessing = true);
                try {
                  final miktar = double.tryParse(miktarCtrl.text) ?? 0;
                  final sinir = double.tryParse(sinirCtrl.text) ?? 0;
                  if (isEdit) {
                    await _service.updateEnvanter(envanter.copyWith(miktar: miktar, uyariSiniri: sinir));
                  } else {
                    await _service.addEnvanter(GubreEnvanter(bahceId: _seciliBahceId!, bahceAdi: _seciliBahceAdi!, gubreAdi: gubreCtrl.text.trim(), miktar: miktar, birim: birim, uyariSiniri: sinir));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh();
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
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
          Text('Mevcut stok: ${_formatMiktar(item.miktar)} ${item.birimLabel}', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 14),
          TextField(
            controller: miktarCtrl, keyboardType: TextInputType.number, autofocus: true,
            decoration: InputDecoration(labelText: 'Eklenecek Miktar (${item.birimLabel})', prefixIcon: const Icon(Icons.add_box, color: Color(0xFF059669)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: _isProcessing ? null : () async {
              final ek = double.tryParse(miktarCtrl.text) ?? 0;
              if (ek <= 0) return;
              setState(() => _isProcessing = true);
              try {
                await _service.updateEnvanter(item.copyWith(miktar: item.miktar + ek));
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.gubreAdi} stoku güncellendi ✓')));
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showYaprakUygulaDialog(GubreEnvanter item) {
    final miktarCtrl = TextEditingController();
    final notCtrl = TextEditingController();
    String? seciliParselAdi;

    // Seçili bahçenin parselleri
    final bahce = _bahceler.where((b) => b.id == _seciliBahceId).firstOrNull;
    final parseller = bahce?.parseller ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.eco, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text('Yaprak Gübre: \${item.gubreAdi}', overflow: TextOverflow.ellipsis)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.inventory_2, size: 18, color: Colors.teal.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Mevcut stok: \${_formatMiktar(item.miktar)} \${item.birimLabel}', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 14),
              if (parseller.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: seciliParselAdi,
                  decoration: InputDecoration(
                    labelText: 'Uygulanan Parsel',
                    prefixIcon: const Icon(Icons.grid_view, color: Color(0xFF059669)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tüm Parseller / Genel')),
                    ...parseller.map((p) => DropdownMenuItem(value: p.ad, child: Text(p.ad))),
                  ],
                  onChanged: (v) => setDialogState(() => seciliParselAdi = v),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: miktarCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Kullanılan Miktar (\${item.birimLabel}) *',
                  prefixIcon: const Icon(Icons.scale, color: Colors.teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Uygulama Notu (opsiyonel)',
                  hintText: 'Örn: Tüm parsellere yaprak gübresi',
                  prefixIcon: const Icon(Icons.note_alt, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : () async {
                final miktar = double.tryParse(miktarCtrl.text) ?? 0;
                if (miktar <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli miktar girin')));
                  return;
                }
                if (miktar > item.miktar) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stokta yeterli miktar yok! Mevcut: \${_formatMiktar(item.miktar)} \${item.birimLabel}'), backgroundColor: Colors.red));
                  return;
                }
                setState(() => _isProcessing = true);
                try {
                  // Envanterden düş
                  await _service.envanterdenDus(item.id!, miktar);
                  // Katlama kaydı olarak kaydet (yaprak gübre uygulama kaydı)
                  final auth = context.read<AuthProvider>();
                  final user = auth.currentUser;
                  if (user != null) {
                    await _service.addKatlamaKaydi(KatlamaKaydi(
                      bahceId: _seciliBahceId!,
                      bahceAdi: _seciliBahceAdi!,
                      tankId: 'yaprak_gubre',
                      tankAdi: 'Yaprak Gübre',
                      katlama: 1,
                      kullanilanGubreler: [ReceteKalemi(gubreAdi: item.gubreAdi, miktar: miktar, birim: item.birim)],
                      yapanKullaniciId: user.id ?? '',
                      yapanKullaniciAdi: user.adSoyad,
                    ));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('\${item.gubreAdi} - \${_formatMiktar(miktar)} \${item.birimLabel} yaprak gübre uygulandı ✓'),
                      backgroundColor: Colors.teal,
                    ));
                  }
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              icon: const Icon(Icons.eco),
              label: const Text('Uygula & Envanterden Düş'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _silEnvanter(GubreEnvanter item) async {
    final onay = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Gübre Stoku Sil'),
      content: Text('"${item.gubreAdi}" envanterden silinecek. Emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
        ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Sil')),
      ],
    ));
    if (onay == true) { await _service.deleteEnvanter(item.id!); _refresh(); }
  }

  Future<void> _silTank(BuildContext sheetCtx, GubreTank tank) async {
    final onay = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Tankı Sil'),
      content: Text('Tank ${tank.ad} silinecek. Emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
        ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Sil')),
      ],
    ));
    if (onay == true) { await _service.deleteTank(tank.id!); if (sheetCtx.mounted) Navigator.pop(sheetCtx); _refresh(); }
  }

  // ═══════════════ SİLME İŞLEMLERİ ═══════════════

  Future<void> _silKatlamaKaydi(KatlamaKaydi kayit) async {
    final secim = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Katlama Kaydını Sil'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tank ${kayit.tankAdi} — ${kayit.katlama}x katlama kaydı silinecek.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text('Katlama sırasında envanterden düşülen gübreler geri yüklenebilir.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('İptal')),
          OutlinedButton(
            onPressed: () => Navigator.pop(c, 'sil'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            child: const Text('Sadece Sil'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(c, 'sil_geri_yukle'),
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Sil + Geri Yükle'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
    if (secim != null && kayit.id != null) {
      // Envanter geri yükleme
      if (secim == 'sil_geri_yukle') {
        for (final g in kayit.kullanilanGubreler) {
          final envItem = _envanter.where((e) => e.gubreAdi.toLowerCase() == g.gubreAdi.toLowerCase() && e.bahceId == kayit.bahceId).firstOrNull;
          if (envItem != null) {
            await _service.updateEnvanter(envItem.copyWith(miktar: envItem.miktar + g.miktar));
          }
        }
      }
      await _service.deleteKatlamaKaydi(kayit.id!);
      _gecmisKayitlariFuture = _service.getKatlamaKayitlari(bahceId: _seciliBahceId);
      if (secim == 'sil_geri_yukle') await _loadBahceVerileri(); // envanter güncelle
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(secim == 'sil_geri_yukle' ? 'Katlama silindi, gübreler envantere geri yüklendi ✓' : 'Katlama kaydı silindi ✓')),
        );
      }
    }
  }

  Future<void> _silReceteGecmisi(BuildContext sheetCtx, ReceteGecmisi gecmis, GubreTank tank) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reçete Geçmişini Sil'),
        content: Text('${_dateFormatShort.format(gecmis.tarih)} tarihli reçete kaydı silinecek.\n\nBu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay == true && gecmis.id != null) {
      await _service.deleteReceteGecmisi(gecmis.id!);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      // Yeniden aç
      _showReceteGecmisiDialog(tank);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reçete geçmişi silindi ✓')),
        );
      }
    }
  }

  // ═══════════════ YARDIMCI ═══════════════

  String _formatMiktar(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  String _formatHacim(double lt) {
    if (lt >= 1000) { final m3 = lt / 1000; return '${_formatMiktar(m3)} m³'; }
    return '${_formatMiktar(lt)} lt';
  }
}

/// Reçete tablo satırı yardımcı sınıfı
class _ReceteSatiri {
  final TextEditingController gubreCtrl;
  final TextEditingController miktarCtrl;
  GubreBirim birim;
  _ReceteSatiri({required this.gubreCtrl, required this.miktarCtrl, this.birim = GubreBirim.kg});
}
