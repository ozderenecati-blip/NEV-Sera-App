import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/daily_work_report.dart';
import '../models/bahce.dart';
import '../providers/auth_provider.dart';
import '../services/operasyon_service.dart';

class DailyWorkReportScreen extends StatefulWidget {
  const DailyWorkReportScreen({super.key});

  @override
  State<DailyWorkReportScreen> createState() => _DailyWorkReportScreenState();
}

class _DailyWorkReportScreenState extends State<DailyWorkReportScreen> {
  final OperasyonService _service = OperasyonService();
  List<DailyWorkReport> _raporlar = [];
  List<Bahce> _bahceler = [];
  bool _isLoading = true;
  final _dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');

  String? _seciliBahceId; // null = Tümü

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    _bahceler = await _service.getBahceler();

    if (auth.canVerifyDailyReport) {
      _raporlar = await _service.getDailyReports();
    } else {
      _raporlar = await _service.getKullaniciRaporlari(user.id ?? '');
    }
    setState(() => _isLoading = false);
  }

  List<DailyWorkReport> get _filtrelenmisRaporlar {
    if (_seciliBahceId == null) return _raporlar;
    return _raporlar.where((r) => r.bahceId == _seciliBahceId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final raporlar = _filtrelenmisRaporlar;

    return Scaffold(
      body: Column(
        children: [
          // Bahçe filtre çipleri
          if (_bahceler.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildFilterChip(null, 'Tümü (${_raporlar.length})'),
                  ..._bahceler.map((b) {
                    final count = _raporlar.where((r) => r.bahceId == b.id).length;
                    return _buildFilterChip(b.id, '${b.ad} ($count)');
                  }),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : raporlar.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: raporlar.length,
                          itemBuilder: (context, index) => _buildRaporCard(raporlar[index], index),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showYeniRaporDialog(),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Rapor'),
      ),
    );
  }

  Widget _buildFilterChip(String? bahceId, String label) {
    final isSelected = _seciliBahceId == bahceId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : null)),
        selectedColor: const Color(0xFFD97706),
        checkmarkColor: Colors.white,
        onSelected: (_) => setState(() => _seciliBahceId = bahceId),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.assignment, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Henüz rapor yok', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Günlük iş raporunuzu ekleyin', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    ).animate().fadeIn();
  }

  Widget _buildRaporCard(DailyWorkReport rapor, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showRaporDetay(rapor),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: rapor.onaylandi ? Colors.green.withOpacity(0.1) : const Color(0xFFD97706).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      rapor.onaylandi ? Icons.verified : Icons.assignment,
                      color: rapor.onaylandi ? Colors.green : const Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_dateFormat.format(rapor.tarih), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(rapor.kullaniciAdi, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      if (rapor.bahceAdi != null)
                        Text('🌿 ${rapor.bahceAdi}', style: TextStyle(color: const Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: rapor.onaylandi ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rapor.onaylandi ? '✓ Onaylı' : 'Beklemede',
                        style: TextStyle(fontSize: 13, color: rapor.onaylandi ? Colors.green : Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${rapor.isler.length} iş', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                ],
              ),
              if (rapor.isler.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...rapor.isler.take(3).map((is_) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Expanded(child: Text(is_.aciklama, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                    if (is_.kategori != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(is_.kategori!, style: const TextStyle(fontSize: 12, color: Color(0xFF059669))),
                      ),
                  ]),
                )),
                if (rapor.isler.length > 3)
                  Text('+${rapor.isler.length - 3} daha...', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(begin: 0.03, end: 0);
  }

  void _showRaporDetay(DailyWorkReport rapor) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text('${_dateFormat.format(rapor.tarih)} - ${rapor.kullaniciAdi}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                if (rapor.onaylandi)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      const Text('Onaylı', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
              ]),
              if (rapor.bahceAdi != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.park, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  Text(rapor.bahceAdi!, style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ],
              if (rapor.onaylandi && rapor.onaylayanAdi != null) ...[
                const SizedBox(height: 4),
                Text('Onaylayan: ${rapor.onaylayanAdi} • ${rapor.onayTarihi != null ? _dateFormat.format(rapor.onayTarihi!) : ""}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
              const SizedBox(height: 20),
              Text('Yapılan İşler (${rapor.isler.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...rapor.isler.asMap().entries.map((entry) {
                final idx = entry.key;
                final is_ = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 14, backgroundColor: const Color(0xFFD97706).withOpacity(0.1),
                            child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(is_.aciklama, style: const TextStyle(fontWeight: FontWeight.w500))),
                        if (!rapor.onaylandi && rapor.kullaniciId == auth.currentUser?.id) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Color(0xFFD97706)),
                            tooltip: 'Düzenle',
                            onPressed: () { Navigator.pop(ctx); _showIsKalemiDuzenle(rapor, idx); },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            tooltip: 'Sil',
                            onPressed: () async {
                              final onay = await showDialog<bool>(
                                context: ctx,
                                builder: (c) => AlertDialog(
                                  title: const Text('İş Kalemi Sil'),
                                  content: Text('"${is_.aciklama}" silinsin mi?'),
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
                              if (onay == true) {
                                final guncelIsler = List<IsKalemi>.from(rapor.isler)..removeAt(idx);
                                await _service.updateDailyReport(rapor.copyWith(isler: guncelIsler));
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadData();
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İş kalemi silindi')));
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ]),
                      if (is_.kategori != null || is_.bahceAdi != null || is_.parselAdi != null || is_.sure != null) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          if (is_.kategori != null) _buildMiniTag(is_.kategori!, const Color(0xFF059669)),
                          if (is_.bahceAdi != null) _buildMiniTag('🌿 ${is_.bahceAdi}', const Color(0xFFD97706)),
                          if (is_.parselAdi != null) _buildMiniTag('📍 ${is_.parselAdi}', Colors.blueGrey),
                          if (is_.sure != null) _buildMiniTag('⏱ ${is_.sure!.toStringAsFixed(1)} saat', Colors.purple),
                        ]),
                      ],
                      if (is_.fotograflar.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: is_.fotograflar.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(is_.fotograflar[i], width: 80, height: 80, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, color: Colors.grey))),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                );
              }),
              if (rapor.genelNot != null && rapor.genelNot!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Genel Not: ${rapor.genelNot}', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 16),
              if (!rapor.onaylandi && auth.canVerifyDailyReport)
                ElevatedButton.icon(
                  onPressed: () async {
                    final user = auth.currentUser!;
                    await _service.approveReport(rapor.id!, user.id!, user.adSoyad);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor onaylandı ve kilitlendi ✓')));
                  },
                  icon: const Icon(Icons.verified),
                  label: const Text('Onayla & Kilitle'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
                ),
              if (!rapor.onaylandi && rapor.kullaniciId == auth.currentUser?.id)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _showIsEkleDialog(rapor); },
                    icon: const Icon(Icons.add),
                    label: const Text('İş Kalemi Ekle'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                ),
              if (!rapor.onaylandi && rapor.kullaniciId == auth.currentUser?.id)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final onay = await showDialog<bool>(
                        context: ctx,
                        builder: (c) => AlertDialog(
                          title: const Text('Raporu Sil'),
                          content: const Text('Bu rapor tamamen silinecek. Emin misiniz?'),
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
                      if (onay == true) {
                        await _service.deleteDailyReport(rapor.id!);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor silindi')));
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('Raporu Sil', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
    );
  }

  void _showYeniRaporDialog() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    DateTime tarih = DateTime.now();
    final genelNotController = TextEditingController();
    List<IsKalemi> isler = [];

    // Bahçe seçimi
    String? seciliBahceId;
    String? seciliBahceAdi;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni Günlük Rapor'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Bahçe seçimi
            DropdownButtonFormField<String?>(
              value: seciliBahceId,
              decoration: InputDecoration(
                labelText: 'Bahçe *',
                prefixIcon: const Icon(Icons.park, color: Color(0xFFD97706)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _bahceler.map((b) => DropdownMenuItem(value: b.id, child: Text(b.ad))).toList(),
              onChanged: (v) {
                setDialogState(() {
                  seciliBahceId = v;
                  seciliBahceAdi = v != null ? _bahceler.firstWhere((b) => b.id == v).ad : null;
                });
              },
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Color(0xFFD97706)),
              title: Text('Tarih: ${_dateFormat.format(tarih)}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: tarih, firstDate: DateTime(2024), lastDate: DateTime.now());
                if (picked != null) setDialogState(() => tarih = picked);
              },
            ),
            const Divider(),
            if (isler.isNotEmpty) ...[
              ...isler.asMap().entries.map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 14, backgroundColor: const Color(0xFFD97706).withOpacity(0.1),
                    child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706)))),
                title: Text(entry.value.aciklama, style: const TextStyle(fontSize: 14)),
                subtitle: Wrap(spacing: 6, children: [
                  if (entry.value.kategori != null) Text(entry.value.kategori!, style: const TextStyle(fontSize: 13)),
                  if (entry.value.bahceAdi != null) Text('🌿 ${entry.value.bahceAdi}', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                  if (entry.value.parselAdi != null) Text('📍 ${entry.value.parselAdi}', style: const TextStyle(fontSize: 12)),
                ]),
                trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                    onPressed: () => setDialogState(() => isler.removeAt(entry.key))),
              )),
              const Divider(),
            ],
            TextButton.icon(
              onPressed: () {
                // Seçili bahçeyi iş kalemine ilet
                final bahce = seciliBahceId != null
                    ? _bahceler.where((b) => b.id == seciliBahceId).firstOrNull
                    : null;
                _showIsKalemiQuickAdd(ctx, bahce, (isKalemi) {
                  setDialogState(() => isler.add(isKalemi));
                });
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFFD97706)),
              label: const Text('İş Kalemi Ekle', style: TextStyle(color: Color(0xFFD97706))),
            ),
            const SizedBox(height: 10),
            TextField(controller: genelNotController, maxLines: 2, decoration: InputDecoration(labelText: 'Genel Not', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (seciliBahceId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bahçe seçin')));
                  return;
                }
                if (isler.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az 1 iş kalemi ekleyin')));
                  return;
                }
                await _service.addDailyReport(DailyWorkReport(
                  kullaniciId: user.id ?? '',
                  kullaniciAdi: user.adSoyad,
                  tarih: tarih,
                  bahceId: seciliBahceId,
                  bahceAdi: seciliBahceAdi,
                  isler: isler,
                  genelNot: genelNotController.text.trim().isNotEmpty ? genelNotController.text.trim() : null,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor kaydedildi ✓')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  static const _kategoriler = ['Sulama', 'Budama', 'İlaçlama', 'Dikim', 'Hasat', 'Bakım', 'Temizlik', 'Diğer'];

  void _showIsKalemiQuickAdd(BuildContext parentCtx, Bahce? bahce, Function(IsKalemi) onAdd) {
    final aciklamaController = TextEditingController();
    String? kategori;
    final sureController = TextEditingController();
    String? parselAdi;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('İş Kalemi'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: aciklamaController, decoration: InputDecoration(labelText: 'Açıklama *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 14),
            // Parsel seçimi (bahçe seçiliyse)
            if (bahce != null && bahce.parseller.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: parselAdi,
                decoration: InputDecoration(
                  labelText: 'Parsel',
                  prefixIcon: const Icon(Icons.grid_view, color: Color(0xFF059669)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Genel')),
                  ...bahce.parseller.map((p) => DropdownMenuItem(value: p.ad, child: Text(p.ad))),
                ],
                onChanged: (v) => setDialogState(() => parselAdi = v),
              ),
              const SizedBox(height: 14),
            ],
            DropdownButtonFormField<String>(
              value: kategori,
              decoration: InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: _kategoriler.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (v) => setDialogState(() => kategori = v),
            ),
            const SizedBox(height: 14),
            TextField(controller: sureController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Süre (saat)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (aciklamaController.text.trim().isEmpty) return;
                onAdd(IsKalemi(
                  aciklama: aciklamaController.text.trim(),
                  bahceAdi: bahce?.ad,
                  parselAdi: parselAdi,
                  kategori: kategori,
                  sure: double.tryParse(sureController.text),
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIsKalemiDuzenle(DailyWorkReport rapor, int idx) {
    final is_ = rapor.isler[idx];
    final aciklamaCtrl = TextEditingController(text: is_.aciklama);
    String? kategori = is_.kategori;
    final sureCtrl = TextEditingController(text: is_.sure?.toStringAsFixed(1) ?? '');
    String? parselAdi = is_.parselAdi;

    // Rapordaki bahçeyi bul
    final bahce = rapor.bahceId != null
        ? _bahceler.where((b) => b.id == rapor.bahceId).firstOrNull
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('İş Kalemi Düzenle (#${idx + 1})'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: aciklamaCtrl, decoration: InputDecoration(labelText: 'Açıklama *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 14),
            if (bahce != null && bahce.parseller.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: parselAdi,
                decoration: InputDecoration(
                  labelText: 'Parsel',
                  prefixIcon: const Icon(Icons.grid_view, color: Color(0xFF059669)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Genel')),
                  ...bahce.parseller.map((p) => DropdownMenuItem(value: p.ad, child: Text(p.ad))),
                ],
                onChanged: (v) => setDialogState(() => parselAdi = v),
              ),
              const SizedBox(height: 14),
            ],
            DropdownButtonFormField<String>(
              value: kategori,
              decoration: InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: _kategoriler.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (v) => setDialogState(() => kategori = v),
            ),
            const SizedBox(height: 14),
            TextField(controller: sureCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Süre (saat)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (aciklamaCtrl.text.trim().isEmpty) return;
                final guncelIsler = List<IsKalemi>.from(rapor.isler);
                guncelIsler[idx] = IsKalemi(
                  aciklama: aciklamaCtrl.text.trim(),
                  kategori: kategori,
                  sure: double.tryParse(sureCtrl.text.replaceAll(',', '.')),
                  bahceAdi: is_.bahceAdi,
                  parselAdi: parselAdi,
                  fotograflar: is_.fotograflar,
                );
                await _service.updateDailyReport(rapor.copyWith(isler: guncelIsler));
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İş kalemi güncellendi ✓')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIsEkleDialog(DailyWorkReport rapor) {
    final bahce = rapor.bahceId != null
        ? _bahceler.where((b) => b.id == rapor.bahceId).firstOrNull
        : null;
    _showIsKalemiQuickAdd(context, bahce, (isKalemi) async {
      final guncelIsler = List<IsKalemi>.from(rapor.isler)..add(isKalemi);
      await _service.updateDailyReport(rapor.copyWith(isler: guncelIsler));
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İş kalemi eklendi')));
    });
  }
}
