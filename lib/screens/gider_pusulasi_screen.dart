import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/gundelikci.dart';
import '../models/kasa_hareketi.dart';
import '../services/excel_service.dart';
import '../widgets/ux_components.dart';

class GiderPusulasiScreen extends StatefulWidget {
  const GiderPusulasiScreen({super.key});

  @override
  State<GiderPusulasiScreen> createState() => _GiderPusulasiScreenState();
}

class _GiderPusulasiScreenState extends State<GiderPusulasiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Pusulası'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showGundelikciDialog(context),
            tooltip: 'Çalışan Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportExcel(context),
            tooltip: 'Excel\'e Aktar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Çalışanlar'),
            Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalisanlarTab(),
          _buildGecmisTab(),
        ],
      ),
    );
  }

  // =================== ÇALIŞANLAR TAB ===================
  Widget _buildCalisanlarTab() {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SkeletonListView(itemCount: 4);
        }

        final gundelikciler = [...provider.gundelikciler]
          ..sort((a, b) => a.adSoyad.toLowerCase().compareTo(b.adSoyad.toLowerCase()));

        if (gundelikciler.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.person_outline,
            title: 'Çalışan bulunamadı',
            subtitle: 'Çalışanlarınızı ekleyerek gider pusulanızı yönetin',
            buttonText: 'Çalışan Ekle',
            onButtonPressed: () => _showGundelikciDialog(context),
            iconColor: Colors.orange,
          );
        }

        return RefreshableList(
          onRefresh: () => provider.loadAllData(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildOzetCard(context, provider, currencyFormat),
              const SizedBox(height: 16),
              ...gundelikciler.map((g) => _buildGundelikciCard(context, g, provider, currencyFormat)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOzetCard(BuildContext context, AppProvider provider, NumberFormat fmt) {
    final avanslar = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'gider_pusulasi')
        .toList();
    final resmilestirmeler = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'resmilestirme')
        .toList();

    double toplamAvans = avanslar.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double toplamResmilestirme = resmilestirmeler.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double kalanBorc = toplamAvans - toplamResmilestirme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.orange),
                SizedBox(width: 8),
                Text('Gider Pusulası Özeti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Verilen Avans', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(fmt.format(toplamAvans), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Kesilen Pusula', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(fmt.format(toplamResmilestirme), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Bize Borç', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(fmt.format(kalanBorc), style: TextStyle(fontWeight: FontWeight.bold, color: kalanBorc > 0 ? Colors.orange : Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGundelikciCard(BuildContext context, Gundelikci g, AppProvider provider, NumberFormat fmt) {
    final avanslar = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'gider_pusulasi' && h.iliskiliId == g.id)
        .toList();
    final resmilestirmeler = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'resmilestirme' && h.iliskiliId == g.id)
        .toList();

    double toplamAvans = avanslar.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double toplamResmilestirme = resmilestirmeler.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double kalanBorc = toplamAvans - toplamResmilestirme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: kalanBorc > 0 ? Colors.orange.shade100 : Colors.green.shade100,
          child: Icon(Icons.person, color: kalanBorc > 0 ? Colors.orange : Colors.green),
        ),
        title: Text(g.adSoyad, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          kalanBorc > 0 ? 'Bize borçlu: ${fmt.format(kalanBorc)}' : 'Borç yok ✓',
          style: TextStyle(color: kalanBorc > 0 ? Colors.orange : Colors.green),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.money_off, color: Colors.red),
              onPressed: () => _showAvansOdeDialog(context, g, provider),
              tooltip: 'Avans Öde',
            ),
            if (kalanBorc > 0)
              IconButton(
                icon: const Icon(Icons.receipt, color: Colors.purple),
                onPressed: () => _showPusulaKesDialog(context, g, kalanBorc, provider),
                tooltip: 'Pusula Kes',
              ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showGundelikciDialog(context, gundelikci: g),
              tooltip: 'Düzenle',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (g.tcNo != null && g.tcNo!.isNotEmpty) _buildInfoRow(Icons.badge, 'TC No', g.tcNo!),
                if (g.telefon != null && g.telefon!.isNotEmpty) _buildInfoRow(Icons.phone, 'Telefon', g.telefon!),
                if (g.adres != null && g.adres!.isNotEmpty) _buildInfoRow(Icons.location_on, 'Adres', g.adres!),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Verilen Avans', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        Text(fmt.format(toplamAvans), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Kesilen Pusula', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        Text(fmt.format(toplamResmilestirme), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Bize Borç', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        Text(fmt.format(kalanBorc), style: TextStyle(fontWeight: FontWeight.bold, color: kalanBorc > 0 ? Colors.orange : Colors.green)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (avanslar.isNotEmpty || resmilestirmeler.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Son İşlemler:', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('Tüm İşlemler'),
                        onPressed: () => _showIslemGecmisi(context, g, [...avanslar, ...resmilestirmeler]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...([...avanslar, ...resmilestirmeler]
                    ..sort((a, b) => b.tarih.compareTo(a.tarih)))
                    .take(5)
                    .map((h) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            h.islemKaynagi == 'gider_pusulasi' ? Icons.money_off : Icons.receipt,
                            color: h.islemKaynagi == 'gider_pusulasi' ? Colors.red : Colors.purple,
                            size: 20,
                          ),
                          title: Text(h.aciklama, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            '${DateFormat('dd.MM.yyyy').format(h.tarih)} • ${h.kasa ?? "Kayıt"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Text(
                            fmt.format(h.tlKarsiligi ?? h.tutar),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: h.islemKaynagi == 'gider_pusulasi' ? Colors.red : Colors.purple,
                            ),
                          ),
                        )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== GEÇMİŞ TAB ===================
  Widget _buildGecmisTab() {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pusulalar = provider.kasaHareketleri
            .where((h) => h.islemKaynagi == 'resmilestirme')
            .toList()
          ..sort((a, b) => b.tarih.compareTo(a.tarih));

        if (pusulalar.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Henüz gider pusulası kesilmemiş', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Toplam: ${pusulalar.length} pusula', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Tutar: ${currencyFormat.format(pusulalar.fold<double>(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar)))}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('İsim', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('TC No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tarih', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Meblağ', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    ],
                    rows: pusulalar.map((h) {
                      final gundelikci = provider.gundelikciler.cast<Gundelikci?>().firstWhere(
                        (g) => g!.id == h.iliskiliId,
                        orElse: () => null,
                      );
                      return DataRow(cells: [
                        DataCell(Text(gundelikci?.adSoyad ?? 'Bilinmiyor')),
                        DataCell(Text(gundelikci?.tcNo ?? '-')),
                        DataCell(Text(dateFormat.format(h.tarih))),
                        DataCell(Text(currencyFormat.format(h.tlKarsiligi ?? h.tutar))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =================== DIALOGS ===================
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showGundelikciDialog(BuildContext context, {Gundelikci? gundelikci}) {
    final isEdit = gundelikci != null;
    final adSoyadController = TextEditingController(text: gundelikci?.adSoyad);
    final tcNoController = TextEditingController(text: gundelikci?.tcNo);
    final adresController = TextEditingController(text: gundelikci?.adres);
    final telefonController = TextEditingController(text: gundelikci?.telefon);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Çalışan Düzenle' : 'Yeni Çalışan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adSoyadController,
                decoration: const InputDecoration(labelText: 'Ad Soyad *', prefixIcon: Icon(Icons.person)),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tcNoController,
                decoration: const InputDecoration(labelText: 'TC Kimlik No', prefixIcon: Icon(Icons.badge)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonController,
                decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adresController,
                decoration: const InputDecoration(labelText: 'Adres', prefixIcon: Icon(Icons.location_on)),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              if (adSoyadController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ad Soyad zorunludur'), backgroundColor: Colors.red),
                );
                return;
              }
              final provider = Provider.of<AppProvider>(context, listen: false);
              final newG = Gundelikci(
                id: gundelikci?.id,
                adSoyad: adSoyadController.text.trim(),
                tcNo: tcNoController.text.trim().isEmpty ? null : tcNoController.text.trim(),
                adres: adresController.text.trim().isEmpty ? null : adresController.text.trim(),
                telefon: telefonController.text.trim().isEmpty ? null : telefonController.text.trim(),
              );
              if (isEdit) {
                await provider.updateGundelikci(newG);
              } else {
                await provider.addGundelikci(newG);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(isEdit ? 'Kaydet' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAvansOdeDialog(BuildContext context, Gundelikci g, AppProvider provider) {
    final tutarController = TextEditingController();
    final aciklamaController = TextEditingController(text: 'Avans - \${g.adSoyad}');
    DateTime selectedDate = DateTime.now();
    String? selectedKasa;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Avans Öde'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '\${g.adSoyad} kişisine avans ödemesi yapılacak.\nKasadan çıkış olarak kaydedilir.',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tutarController,
                    decoration: const InputDecoration(
                      labelText: 'Tutar (₺) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedKasa,
                    decoration: const InputDecoration(
                      labelText: 'Kasa *',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: provider.kasalar.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setState(() => selectedKasa = v),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aciklamaController,
                    decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(Icons.note)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
              FilledButton.icon(
                icon: const Icon(Icons.money_off),
                onPressed: () async {
                  final tutar = double.tryParse(tutarController.text.replaceAll(',', '.'));
                  if (tutar == null || tutar <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçerli tutar girin'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (selectedKasa == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kasa seçin'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final success = await provider.gundelikciyeOdemeYap(
                    gundelikci: g,
                    tutar: tutar,
                    kasa: selectedKasa!,
                    tarih: selectedDate,
                    aciklama: aciklamaController.text.trim(),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Avans ödendi' : 'Hata oluştu'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                label: const Text('Öde'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPusulaKesDialog(BuildContext context, Gundelikci g, double kalanBorc, AppProvider provider) {
    final brutTutarController = TextEditingController(text: kalanBorc.toStringAsFixed(2));
    final aciklamaController = TextEditingController(text: 'Gider Pusulası - ${g.adSoyad}');
    DateTime selectedDate = DateTime.now();
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final brutTutar = double.tryParse(brutTutarController.text.replaceAll(',', '.')) ?? 0;

          return AlertDialog(
            title: const Text('Gider Pusulası Kes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.adSoyad, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (g.tcNo != null) Text('TC: ${g.tcNo}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('Çalışanın size olan borcu: ${currencyFormat.format(kalanBorc)}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                        const SizedBox(height: 4),
                        Text('Bu borç daha önce avans olarak ödenmiştir.\nPusula kesildiğinde kasaya etki etmez, sadece kayıt tutulur.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: brutTutarController,
                    decoration: const InputDecoration(
                      labelText: 'Brüt Tutar (₺)',
                      prefixIcon: Icon(Icons.receipt),
                      helperText: 'Çalışanın borcundan düşülecek tutar',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aciklamaController,
                    decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(Icons.note)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Resmileştirilecek:'),
                            Text(currencyFormat.format(brutTutar), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kasaya etkisi:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Yok (sadece kayıt)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
              FilledButton.icon(
                icon: const Icon(Icons.receipt),
                onPressed: () async {
                  final brutTutar = double.tryParse(brutTutarController.text.replaceAll(',', '.'));
                  if (brutTutar == null || brutTutar <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçerli tutar girin'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final success = await provider.giderPusulasiKes(
                    gundelikci: g,
                    brutTutar: brutTutar,
                    tarih: selectedDate,
                    aciklama: aciklamaController.text.trim(),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Gider pusulası kesildi' : 'Hata oluştu'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                label: const Text('Pusula Kes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showIslemGecmisi(BuildContext context, Gundelikci g, List<KasaHareketi> islemler) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    islemler.sort((a, b) => b.tarih.compareTo(a.tarih));

    double toplamAvans = 0;
    double toplamResmilestirme = 0;
    for (var h in islemler) {
      final tutar = h.tlKarsiligi ?? h.tutar;
      if (h.islemKaynagi == 'gider_pusulasi') toplamAvans += tutar;
      else if (h.islemKaynagi == 'resmilestirme') toplamResmilestirme += tutar;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.person, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.adSoyad, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${islemler.length} işlem', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          const Icon(Icons.money_off, color: Colors.red, size: 20),
                          const SizedBox(height: 4),
                          const Text('Avans', style: TextStyle(fontSize: 13)),
                          Text(currencyFormat.format(toplamAvans),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt, color: Colors.purple, size: 20),
                          const SizedBox(height: 4),
                          const Text('Pusula', style: TextStyle(fontSize: 13)),
                          Text(currencyFormat.format(toplamResmilestirme),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (toplamAvans - toplamResmilestirme) > 0 ? Colors.orange.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (toplamAvans - toplamResmilestirme) > 0 ? 'Size Borçlu: ' : 'Borç Yok: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currencyFormat.format(toplamAvans - toplamResmilestirme),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18,
                        color: (toplamAvans - toplamResmilestirme) > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: islemler.isEmpty
                  ? Center(child: Text('İşlem bulunamadı', style: TextStyle(color: Colors.grey.shade600)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: islemler.length,
                      itemBuilder: (_, i) {
                        final h = islemler[i];
                        final isAvans = h.islemKaynagi == 'gider_pusulasi';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (isAvans ? Colors.red : Colors.purple).withValues(alpha: 0.1),
                              child: Icon(isAvans ? Icons.money_off : Icons.receipt,
                                color: isAvans ? Colors.red : Colors.purple, size: 20),
                            ),
                            title: Text(isAvans ? 'Avans Ödemesi' : 'Gider Pusulası', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.aciklama, style: const TextStyle(fontSize: 12)),
                                Text(
                                  '${DateFormat('dd.MM.yyyy').format(h.tarih)} • ${h.kasa ?? "Kayıt"}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: Text(
                              currencyFormat.format(h.tlKarsiligi ?? h.tutar),
                              style: TextStyle(fontWeight: FontWeight.bold, color: isAvans ? Colors.red : Colors.purple),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== EXCEL EXPORT ===================
  Future<void> _exportExcel(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final pusulalar = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'resmilestirme')
        .toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));

    if (pusulalar.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dışa aktarılacak pusula bulunamadı'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      final excelService = ExcelService();
      await excelService.exportToExcel(pusulalar);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel dosyası indirildi ✓'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel oluşturulamadı: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
