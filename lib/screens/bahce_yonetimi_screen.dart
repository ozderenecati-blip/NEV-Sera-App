import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/bahce.dart';
import '../providers/auth_provider.dart';
import '../services/operasyon_service.dart';
import 'bahce_detay_screen.dart';

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
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Yeni bahçe eklemek için + butonuna tıklayın',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildBahceCard(Bahce bahce, int index, bool isDark) {
    // Tüm sıralardaki cinsleri ve adetlerini topla
    final cinsSaksi = <String, int>{};
    for (final p in bahce.parseller) {
      for (final s in p.siralar) {
        if (s.cins != null && s.cins!.isNotEmpty) {
          cinsSaksi[s.cins!] = (cinsSaksi[s.cins!] ?? 0) + s.saksiSayisi;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openBahceDetay(bahce),
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
                        Text(bahce.ad,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (bahce.konum != null && bahce.konum!.isNotEmpty)
                          Text(bahce.konum!,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (context.read<AuthProvider>().canWriteOperasyon)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _showBahceDialog(bahce: bahce);
                        if (value == 'delete') _deleteBahce(bahce);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Düzenle'),
                                dense: true)),
                        const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Sil', style: TextStyle(color: Colors.red)),
                                dense: true)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip(Icons.grid_view,
                      '${bahce.toplamParsel} Parsel', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.view_column,
                      '${bahce.toplamSira} Sıra', const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.local_florist,
                      '${bahce.toplamSaksi} Saksı', const Color(0xFFD97706)),
                ],
              ),
              // Parsel alt-listesi
              if (bahce.parseller.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...bahce.parseller.map((p) {
                  final pCins = <String>{};
                  for (final s in p.siralar) {
                    if (s.cins != null && s.cins!.isNotEmpty) pCins.add(s.cins!);
                  }
                  final topSaksi =
                      p.siralar.fold<int>(0, (sum, s) => sum + s.saksiSayisi);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right,
                            size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Text(p.ad,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text('${p.siraSayisi} sıra • $topSaksi saksı',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        if (pCins.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color:
                                    const Color(0xFF059669).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                pCins.length <= 2
                                    ? pCins.join(', ')
                                    : '${pCins.length} çeşit',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF059669))),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
              // Cins dağılımı (adetli)
              if (cinsSaksi.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: cinsSaksi.entries
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('🌱 ${e.key}: ${e.value}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: 80 * index))
        .slideX(begin: 0.03, end: 0);
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
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

  // ─────────────── Bahçe Detay Ekranına Git ───────────────

  void _openBahceDetay(Bahce bahce) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BahceDetayScreen(bahce: bahce)),
    );
    _loadBahceler();
  }

  // ─────────────── Bahçe Ekle / Düzenle Dialog ───────────────

  void _showBahceDialog({Bahce? bahce}) {
    final isEdit = bahce != null;
    final adController = TextEditingController(text: bahce?.ad ?? '');
    final konumController = TextEditingController(text: bahce?.konum ?? '');
    final notController = TextEditingController(text: bahce?.not ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Bahçe Düzenle' : 'Yeni Bahçe'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: adController,
                decoration: InputDecoration(
                    labelText: 'Bahçe Adı *',
                    prefixIcon: const Icon(Icons.park),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(
                controller: konumController,
                decoration: InputDecoration(
                    labelText: 'Konum',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(
                controller: notController,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: 'Not',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
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
                    const SnackBar(content: Text('Bahçe adı zorunlu')));
                return;
              }
              if (isEdit) {
                await _service.updateBahce(bahce.copyWith(
                    ad: adController.text.trim(),
                    konum: konumController.text.trim(),
                    not: notController.text.trim()));
              } else {
                await _service.addBahce(Bahce(
                    ad: adController.text.trim(),
                    konum: konumController.text.trim(),
                    not: notController.text.trim()));
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadBahceler();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white),
            child: Text(isEdit ? 'Güncelle' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  // ─────────────── Bahçe Sil ───────────────

  void _deleteBahce(Bahce bahce) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bahçeyi Sil'),
        content: Text(
            '${bahce.ad} bahçesini silmek istediğinize emin misiniz?\nTüm parseller ve sıralar silinecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
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
