import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/bahce.dart';
import '../providers/auth_provider.dart';
import '../services/operasyon_service.dart';
import 'kroki_screen.dart';

class BahceYonetimiScreen extends StatefulWidget {
  const BahceYonetimiScreen({super.key});

  @override
  State<BahceYonetimiScreen> createState() => _BahceYonetimiScreenState();
}

class _BahceYonetimiScreenState extends State<BahceYonetimiScreen> {
  final OperasyonService _service = OperasyonService();
  List<Bahce> _bahceler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBahceler();
  }

  Future<void> _loadBahceler() async {
    setState(() => _isLoading = true);
    _bahceler = await _service.getBahceler();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = context.read<AuthProvider>().canWriteOperasyon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bahceler.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBahceler,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _bahceler.length,
                    itemBuilder: (context, index) =>
                        _buildBahceCard(_bahceler[index], index, isDark),
                  ),
                ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => _showBahceDialog(),
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Bahçe'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.park, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text('Henüz bahçe eklenmedi',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Yeni bahçe eklemek için + butonuna tıklayın',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildBahceCard(Bahce bahce, int index, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showBahceDetay(bahce),
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
                      color: const Color(0xFFD97706).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.park, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bahce.ad, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (bahce.konum != null && bahce.konum!.isNotEmpty)
                          Text(bahce.konum!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (context.read<AuthProvider>().canWriteOperasyon)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _showBahceDialog(bahce: bahce);
                        if (value == 'delete') _deleteBahce(bahce);
                        if (value == 'parsel') _showParselDialog(bahce);
                        if (value == 'kroki') _openKroki(bahce);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'kroki', child: ListTile(leading: Icon(Icons.map, color: Color(0xFFD97706)), title: Text('Kroki Çiz'), dense: true)),
                        const PopupMenuItem(value: 'parsel', child: ListTile(leading: Icon(Icons.grid_view), title: Text('Parsel Ekle'), dense: true)),
                        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Düzenle'), dense: true)),
                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Sil', style: TextStyle(color: Colors.red)), dense: true)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip(Icons.grid_view, '${bahce.toplamParsel} Parsel', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.view_column, '${bahce.toplamSira} Sıra', const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.local_florist, '${bahce.toplamSaksi} Saksı', const Color(0xFFD97706)),
                ],
              ),
              if (bahce.parseller.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...bahce.parseller.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(p.ad, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('${p.siraSayisi}×${p.siraBasinaSaksi}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (p.cins != null && p.cins!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(p.cins!, style: const TextStyle(fontSize: 13, color: Color(0xFF059669))),
                        ),
                      ],
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideX(begin: 0.03, end: 0);
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showBahceDetay(Bahce bahce) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(bahce.ad, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (bahce.konum != null) ...[const SizedBox(height: 4), Text(bahce.konum!, style: TextStyle(color: Colors.grey.shade600))],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildSummaryCard('Parsel', '${bahce.toplamParsel}', Icons.grid_view, const Color(0xFF2563EB))),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryCard('Sıra', '${bahce.toplamSira}', Icons.view_column, const Color(0xFF059669))),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryCard('Saksı', '${bahce.toplamSaksi}', Icons.local_florist, const Color(0xFFD97706))),
              ]),
              const SizedBox(height: 20),
              if (bahce.parseller.isNotEmpty) ...[
                const Text('Parseller', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...bahce.parseller.map((p) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.grid_view, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text(p.ad, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Text('${p.toplamSaksi} saksı', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      Text('${p.siraSayisi} sıra × ${p.siraBasinaSaksi} saksı/sıra', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      if (p.cins != null && p.cins!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('🌱 ${p.cins}', style: const TextStyle(fontSize: 13, color: Color(0xFF059669))),
                        ),
                      ],
                      if (p.not != null && p.not!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(p.not!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                      ],
                    ]),
                  ),
                )),
              ],
              if (bahce.not != null && bahce.not!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Not: ${bahce.not}', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 20),
              // Kroki butonu
              if (context.read<AuthProvider>().canWriteOperasyon)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openKroki(bahce);
                  },
                  icon: const Icon(Icons.map),
                  label: Text(bahce.koseler.isNotEmpty ? 'Krokiyi Görüntüle / Düzenle' : 'Kroki Çiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              if (bahce.koseler.isNotEmpty && bahce.toplamAlan != null && bahce.toplamAlan! > 0) ...[
                const SizedBox(height: 8),
                Center(child: Text('Toplam Alan: ${bahce.toplamAlan!.toStringAsFixed(1)} m²', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ]),
    );
  }

  void _showBahceDialog({Bahce? bahce}) {
    final isEdit = bahce != null;
    final adController = TextEditingController(text: bahce?.ad ?? '');
    final konumController = TextEditingController(text: bahce?.konum ?? '');
    final notController = TextEditingController(text: bahce?.not ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Bahçe Düzenle' : 'Yeni Bahçe'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: adController, decoration: InputDecoration(labelText: 'Bahçe Adı *', prefixIcon: const Icon(Icons.park), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: konumController, decoration: InputDecoration(labelText: 'Konum', prefixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: notController, maxLines: 2, decoration: InputDecoration(labelText: 'Not', prefixIcon: const Icon(Icons.note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (adController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bahçe adı zorunlu')));
                return;
              }
              if (isEdit) {
                await _service.updateBahce(bahce.copyWith(ad: adController.text.trim(), konum: konumController.text.trim(), not: notController.text.trim()));
              } else {
                await _service.addBahce(Bahce(ad: adController.text.trim(), konum: konumController.text.trim(), not: notController.text.trim()));
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadBahceler();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: Text(isEdit ? 'Güncelle' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  void _showParselDialog(Bahce bahce) {
    final adController = TextEditingController();
    final siraSayisiController = TextEditingController();
    final saksiSayisiController = TextEditingController();
    final cinsController = TextEditingController();
    final notController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Parsel Ekle - ${bahce.ad}'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: adController, decoration: InputDecoration(labelText: 'Parsel Adı *', hintText: 'ör: A Parseli', prefixIcon: const Icon(Icons.grid_view), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: siraSayisiController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Sıra Sayısı *', prefixIcon: const Icon(Icons.view_column), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: saksiSayisiController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Sıra Başına Saksı *', prefixIcon: const Icon(Icons.local_florist), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: cinsController, decoration: InputDecoration(labelText: 'Cins (opsiyonel)', hintText: 'ör: Domates, Biber', prefixIcon: const Icon(Icons.eco), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: notController, maxLines: 2, decoration: InputDecoration(labelText: 'Not', prefixIcon: const Icon(Icons.note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final ad = adController.text.trim();
              final siraSayisi = int.tryParse(siraSayisiController.text) ?? 0;
              final saksiSayisi = int.tryParse(saksiSayisiController.text) ?? 0;
              if (ad.isEmpty || siraSayisi <= 0 || saksiSayisi <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad, sıra ve saksı sayısı zorunlu')));
                return;
              }
              final cins = cinsController.text.trim().isNotEmpty ? cinsController.text.trim() : null;
              final siralar = List.generate(siraSayisi, (i) => Sira(
                numara: i + 1, saksiSayisi: saksiSayisi, cins: cins,
                saksilar: List.generate(saksiSayisi, (j) => Saksi(numara: j + 1, cins: cins)),
              ));
              final yeniParsel = Parsel(
                ad: ad, siraSayisi: siraSayisi, siraBasinaSaksi: saksiSayisi, cins: cins, siralar: siralar,
                not: notController.text.trim().isNotEmpty ? notController.text.trim() : null,
              );
              final guncelParseller = List<Parsel>.from(bahce.parseller)..add(yeniParsel);
              await _service.updateBahce(bahce.copyWith(parseller: guncelParseller));
              if (ctx.mounted) Navigator.pop(ctx);
              _loadBahceler();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ad eklendi (${siraSayisi * saksiSayisi} saksı oluşturuldu)')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Ekle & Numaralandır'),
          ),
        ],
      ),
    );
  }

  void _openKroki(Bahce bahce) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KrokiScreen(bahce: bahce)),
    );
    if (result == true) _loadBahceler();
  }

  void _deleteBahce(Bahce bahce) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bahçeyi Sil'),
        content: Text('${bahce.ad} bahçesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              await _service.deleteBahce(bahce.id!);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadBahceler();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
