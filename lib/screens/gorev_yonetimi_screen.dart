import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gorev.dart';
import '../providers/auth_provider.dart';
import '../services/operasyon_service.dart';

class GorevYonetimiScreen extends StatefulWidget {
  const GorevYonetimiScreen({super.key});

  @override
  State<GorevYonetimiScreen> createState() => _GorevYonetimiScreenState();
}

class _GorevYonetimiScreenState extends State<GorevYonetimiScreen> with SingleTickerProviderStateMixin {
  final OperasyonService _service = OperasyonService();
  List<Gorev> _gorevler = [];
  bool _isLoading = true;
  late TabController _tabController;
  final _dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGorevler();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGorevler() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    if (auth.canAssignTask) {
      _gorevler = await _service.getGorevler();
    } else {
      _gorevler = await _service.getKullaniciGorevleri(user.id ?? '');
    }
    setState(() => _isLoading = false);
  }

  List<Gorev> get _aktifGorevler => _gorevler.where((g) => g.durum == GorevDurum.beklemede || g.durum == GorevDurum.devamEdiyor).toList();
  List<Gorev> get _tamamlananGorevler => _gorevler.where((g) => g.durum == GorevDurum.tamamlandi).toList();
  List<Gorev> get _yaklasanGorevler => _gorevler.where((g) => g.yaklasan || g.gecmis).toList();

  @override
  Widget build(BuildContext context) {
    final canAssign = context.read<AuthProvider>().canAssignTask;

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFD97706),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFD97706),
            tabs: [
              Tab(text: 'Aktif (${_aktifGorevler.length})'),
              Tab(text: 'Yaklaşan (${_yaklasanGorevler.length})'),
              Tab(text: 'Tamamlanan (${_tamamlananGorevler.length})'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGorevList(_aktifGorevler, 'Aktif görev yok'),
                      _buildGorevList(_yaklasanGorevler, 'Yaklaşan görev yok'),
                      _buildGorevList(_tamamlananGorevler, 'Tamamlanan görev yok'),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: canAssign
          ? FloatingActionButton.extended(
              onPressed: () => _showGorevDialog(),
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task),
              label: const Text('Yeni Görev'),
            )
          : null,
    );
  }

  Widget _buildGorevList(List<Gorev> gorevler, String emptyText) {
    if (gorevler.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.task_alt, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(emptyText, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ]),
      ).animate().fadeIn();
    }

    return RefreshIndicator(
      onRefresh: _loadGorevler,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: gorevler.length,
        itemBuilder: (context, index) => _buildGorevCard(gorevler[index], index),
      ),
    );
  }

  Widget _buildGorevCard(Gorev gorev, int index) {
    final oncelikColor = switch (gorev.oncelik) {
      GorevOncelik.acil => Colors.red,
      GorevOncelik.normal => Colors.orange,
      GorevOncelik.dusuk => Colors.green,
    };

    final durumColor = switch (gorev.durum) {
      GorevDurum.beklemede => Colors.blue,
      GorevDurum.devamEdiyor => Colors.orange,
      GorevDurum.tamamlandi => Colors.green,
      GorevDurum.iptalEdildi => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showGorevDetay(gorev),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 40,
                    decoration: BoxDecoration(color: oncelikColor, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(gorev.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (gorev.aciklama != null && gorev.aciklama!.isNotEmpty)
                        Text(gorev.aciklama!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: durumColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(gorev.durumLabel, style: TextStyle(fontSize: 13, color: durumColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildTag(Icons.calendar_today, _dateFormat.format(gorev.baslangicTarihi), Colors.blueGrey),
                  _buildTag(Icons.flag, gorev.oncelikLabel, oncelikColor),
                  _buildTag(Icons.repeat, gorev.tekrarLabel, Colors.purple),
                  if (gorev.atananKullaniciAdi != null)
                    _buildTag(Icons.person, gorev.atananKullaniciAdi!, Colors.teal),
                  if (gorev.bahceAdi != null)
                    _buildTag(Icons.park, gorev.bahceAdi!, const Color(0xFFD97706)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(begin: 0.03, end: 0);
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _showGorevDetay(Gorev gorev) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(gorev.baslik, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (gorev.aciklama != null) ...[const SizedBox(height: 8), Text(gorev.aciklama!, style: TextStyle(color: Colors.grey.shade600))],
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _buildDetailChip('Öncelik', gorev.oncelikLabel),
            _buildDetailChip('Tekrar', gorev.tekrarLabel),
            _buildDetailChip('Durum', gorev.durumLabel),
            _buildDetailChip('Tarih', _dateFormat.format(gorev.baslangicTarihi)),
            if (gorev.atananKullaniciAdi != null) _buildDetailChip('Atanan', gorev.atananKullaniciAdi!),
            if (gorev.bahceAdi != null) _buildDetailChip('Bahçe', gorev.bahceAdi!),
            if (gorev.atayan != null) _buildDetailChip('Atayan', gorev.atayan!),
          ]),
          if (gorev.tamamlayanNot != null) ...[
            const SizedBox(height: 12),
            Text('Tamamlama Notu: ${gorev.tamamlayanNot}', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 20),
          // Aksiyon butonları
          if (gorev.durum != GorevDurum.tamamlandi && gorev.durum != GorevDurum.iptalEdildi)
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _tamamlaGorev(gorev, ctx),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Tamamla'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              if (auth.canAssignTask) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _showGorevDialog(gorev: gorev); },
                    icon: const Icon(Icons.edit),
                    label: const Text('Düzenle'),
                  ),
                ),
              ],
            ]),
        ]),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _tamamlaGorev(Gorev gorev, BuildContext sheetContext) async {
    final notController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Görevi Tamamla'),
        content: TextField(
          controller: notController,
          maxLines: 3,
          decoration: InputDecoration(labelText: 'Tamamlama Notu (opsiyonel)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _service.gorevTamamla(gorev.id!, not: notController.text.trim().isNotEmpty ? notController.text.trim() : null);
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      _loadGorevler();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görev tamamlandı ✓')));
    }
  }

  void _showGorevDialog({Gorev? gorev}) async {
    final isEdit = gorev != null;
    final baslikController = TextEditingController(text: gorev?.baslik ?? '');
    final aciklamaController = TextEditingController(text: gorev?.aciklama ?? '');
    GorevOncelik oncelik = gorev?.oncelik ?? GorevOncelik.normal;
    GorevTekrar tekrar = gorev?.tekrar ?? GorevTekrar.tekSefer;
    DateTime baslangic = gorev?.baslangicTarihi ?? DateTime.now();
    String? atananId = gorev?.atananKullaniciId;
    String? atananAdi = gorev?.atananKullaniciAdi;

    // Çalışanları yükle
    final calisanlar = await context.read<AuthProvider>().getCalisanlar();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Görev Düzenle' : 'Yeni Görev'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: baslikController, decoration: InputDecoration(labelText: 'Görev Başlığı *', prefixIcon: const Icon(Icons.task), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 14),
            TextField(controller: aciklamaController, maxLines: 2, decoration: InputDecoration(labelText: 'Açıklama', prefixIcon: const Icon(Icons.description), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 14),
            DropdownButtonFormField<GorevOncelik>(
              value: oncelik,
              decoration: InputDecoration(labelText: 'Öncelik', prefixIcon: const Icon(Icons.flag), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: GorevOncelik.values.map((o) => DropdownMenuItem(value: o, child: Text(switch (o) { GorevOncelik.acil => '🔴 Acil', GorevOncelik.normal => '🟡 Normal', GorevOncelik.dusuk => '🟢 Düşük' }))).toList(),
              onChanged: (v) => setDialogState(() => oncelik = v!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<GorevTekrar>(
              value: tekrar,
              decoration: InputDecoration(labelText: 'Tekrar', prefixIcon: const Icon(Icons.repeat), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: GorevTekrar.values.map((t) => DropdownMenuItem(value: t, child: Text(switch (t) { GorevTekrar.tekSefer => 'Tek Sefer', GorevTekrar.gunluk => 'Günlük', GorevTekrar.haftalik => 'Haftalık', GorevTekrar.aylik => 'Aylık' }))).toList(),
              onChanged: (v) => setDialogState(() => tekrar = v!),
            ),
            const SizedBox(height: 14),
            // Atanan kişi
            DropdownButtonFormField<String?>(
              value: atananId,
              decoration: InputDecoration(labelText: 'Atanan Kişi', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Seçilmedi')),
                ...calisanlar.map((c) => DropdownMenuItem(value: c.id, child: Text(c.adSoyad))),
              ],
              onChanged: (v) {
                setDialogState(() {
                  atananId = v;
                  atananAdi = v != null ? calisanlar.firstWhere((c) => c.id == v).adSoyad : null;
                });
              },
            ),
            const SizedBox(height: 14),
            // Tarih
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Color(0xFFD97706)),
              title: Text('Başlangıç: ${_dateFormat.format(baslangic)}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: baslangic, firstDate: DateTime(2024), lastDate: DateTime(2030));
                if (picked != null) setDialogState(() => baslangic = picked);
              },
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (baslikController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık zorunlu')));
                  return;
                }
                final auth = context.read<AuthProvider>();
                if (isEdit) {
                  await _service.updateGorev(gorev.copyWith(
                    baslik: baslikController.text.trim(),
                    aciklama: aciklamaController.text.trim(),
                    oncelik: oncelik, tekrar: tekrar,
                    atananKullaniciId: atananId, atananKullaniciAdi: atananAdi,
                    baslangicTarihi: baslangic,
                  ));
                } else {
                  await _service.addGorev(Gorev(
                    baslik: baslikController.text.trim(),
                    aciklama: aciklamaController.text.trim().isNotEmpty ? aciklamaController.text.trim() : null,
                    oncelik: oncelik, tekrar: tekrar,
                    atananKullaniciId: atananId, atananKullaniciAdi: atananAdi,
                    atayan: auth.currentUser?.adSoyad,
                    baslangicTarihi: baslangic,
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadGorevler();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
