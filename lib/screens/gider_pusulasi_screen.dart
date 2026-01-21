import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/gundelikci.dart';

class GiderPusulasiScreen extends StatelessWidget {
  const GiderPusulasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Pusulası'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showGundelikciDialog(context),
            tooltip: 'Çalışan Ekle',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final gundelikciler = provider.gundelikciler;

          if (gundelikciler.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Çalışan bulunamadı', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showGundelikciDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Çalışan Ekle'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Özet kartı
                _buildOzetCard(context, provider, currencyFormat),
                const SizedBox(height: 16),

                // Çalışan listesi
                ...gundelikciler.map((g) => _buildGundelikciCard(context, g, provider, currencyFormat)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOzetCard(BuildContext context, AppProvider provider, NumberFormat fmt) {
    // Gündelikçilere verilen avanslar
    final avanslar = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'gider_pusulasi')
        .toList();

    // Kesilen gider pusulaları (resmileştirmeler)
    final resmilestirmeler = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'resmilestirme')
        .toList();
    
    // Ödenen vergiler
    final vergiler = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'gider_pusulasi_vergi')
        .toList();

    double toplamAvans = avanslar.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double toplamResmilestirme = resmilestirmeler.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double toplamVergi = vergiler.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double kalanBorc = toplamAvans - toplamResmilestirme; // Gündelikçilerin bize olan borcu

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
            if (toplamVergi > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Ödenen Vergi: ${fmt.format(toplamVergi)}', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGundelikciCard(BuildContext context, Gundelikci g, AppProvider provider, NumberFormat fmt) {
    // Bu gündelikçiye verilen avanslar
    final avanslar = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'gider_pusulasi' && h.iliskiliId == g.id)
        .toList();

    // Bu gündelikçi için kesilen pusulalar
    final resmilestirmeler = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'resmilestirme' && h.iliskiliId == g.id)
        .toList();
    
    // Bu gündelikçi için ödenen vergiler
    final vergiler = provider.kasaHareketleri
        .where((h) => h.islemKaynagi == 'gider_pusulasi_vergi' && h.iliskiliId == g.id)
        .toList();

    double toplamAvans = avanslar.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double toplamResmilestirme = resmilestirmeler.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double toplamVergi = vergiler.fold(0, (sum, h) => sum + (h.tlKarsiligi ?? h.tutar));
    double kalanBorc = toplamAvans - toplamResmilestirme; // Gündelikçinin bize olan borcu

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
                // Bilgiler
                if (g.tcNo != null && g.tcNo!.isNotEmpty) _buildInfoRow(Icons.badge, 'TC No', g.tcNo!),
                if (g.telefon != null && g.telefon!.isNotEmpty) _buildInfoRow(Icons.phone, 'Telefon', g.telefon!),
                if (g.adres != null && g.adres!.isNotEmpty) _buildInfoRow(Icons.location_on, 'Adres', g.adres!),

                const Divider(height: 24),

                // Özet
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
                
                if (toplamVergi > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('Ödenen Vergi: ${fmt.format(toplamVergi)}', 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Son işlemler
                if (avanslar.isNotEmpty || resmilestirmeler.isNotEmpty || vergiler.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Son İşlemler:', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('Tüm İşlemler'),
                        onPressed: () => _showIslemGecmisi(context, g, [...avanslar, ...resmilestirmeler, ...vergiler]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...([...avanslar, ...resmilestirmeler, ...vergiler]
                    ..sort((a, b) => b.tarih.compareTo(a.tarih)))
                    .take(5)
                    .map((h) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            h.islemKaynagi == 'gider_pusulasi' ? Icons.money_off : 
                            h.islemKaynagi == 'resmilestirme' ? Icons.receipt :
                            Icons.account_balance,
                            color: h.islemKaynagi == 'gider_pusulasi' ? Colors.red : 
                            h.islemKaynagi == 'resmilestirme' ? Colors.purple :
                            Colors.orange,
                            size: 20,
                          ),
                          title: Text(h.aciklama, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            '${DateFormat('dd.MM.yyyy').format(h.tarih)} • ${h.kasa ?? "Kayıt"}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            fmt.format(h.tlKarsiligi ?? h.tutar),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: h.islemKaynagi == 'gider_pusulasi' ? Colors.red : 
                              h.islemKaynagi == 'resmilestirme' ? Colors.purple :
                              Colors.orange,
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

  void _showPusulaKesDialog(BuildContext context, Gundelikci g, double kalanBorc, AppProvider provider) {
    final brutTutarController = TextEditingController(text: kalanBorc.toStringAsFixed(2));
    final vergiOraniController = TextEditingController(text: '20'); // Varsayılan %20
    final aciklamaController = TextEditingController(text: 'Gider Pusulası - ${g.adSoyad}');
    DateTime selectedDate = DateTime.now();
    String? selectedKasa = provider.kasalar.isNotEmpty ? provider.kasalar.first : null;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    double hesaplananVergi = 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Vergi hesapla
          final brutTutar = double.tryParse(brutTutarController.text.replaceAll(',', '.')) ?? 0;
          final vergiOrani = double.tryParse(vergiOraniController.text.replaceAll(',', '.')) ?? 0;
          hesaplananVergi = brutTutar * (vergiOrani / 100);
          
          return AlertDialog(
            title: const Text('Gider Pusulası Kes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgilendirme
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
                        const SizedBox(height: 4),
                        Text('Çalışanın size olan borcu: ${currencyFormat.format(kalanBorc)}', 
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                        const SizedBox(height: 4),
                        Text('Bu borç daha önce avans olarak ödenmiştir.', 
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Brüt Tutar
                  TextField(
                    controller: brutTutarController,
                    decoration: const InputDecoration(
                      labelText: 'Resmileştirilecek Tutar (₺)',
                      prefixIcon: Icon(Icons.receipt),
                      helperText: 'Çalışanın borcundan düşülecek',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Vergi Oranı
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vergiOraniController,
                          decoration: const InputDecoration(
                            labelText: 'Stopaj Oranı (%)',
                            prefixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text('Ödenecek Vergi', style: TextStyle(fontSize: 11)),
                              Text(
                                currencyFormat.format(hesaplananVergi),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Vergi için Kasa seçimi
                  DropdownButtonFormField<String>(
                    initialValue: selectedKasa,
                    decoration: const InputDecoration(
                      labelText: 'Vergi Ödenecek Kasa *',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: provider.kasalar.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setState(() => selectedKasa = v),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tarih
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
                  
                  // Açıklama
                  TextField(
                    controller: aciklamaController,
                    decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(Icons.note)),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Özet
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
                            const Text('Resmileştirilen:'),
                            Text(currencyFormat.format(brutTutar), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Stopaj Vergisi:'),
                            Text(currencyFormat.format(hesaplananVergi), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kasadan Çıkacak:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(currencyFormat.format(hesaplananVergi), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
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
                  if (selectedKasa == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kasa seçin'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final success = await provider.giderPusulasiKes(
                    gundelikci: g,
                    brutTutar: brutTutar,
                    vergiTutari: hesaplananVergi,
                    tarih: selectedDate,
                    aciklama: aciklamaController.text.trim(),
                    kasa: selectedKasa,
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

  void _showIslemGecmisi(BuildContext context, Gundelikci g, List islemler) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    // Tarihe göre sırala (en yeni en üstte)
    islemler.sort((a, b) => b.tarih.compareTo(a.tarih));
    
    // Toplamları hesapla
    double toplamAvans = 0;
    double toplamResmilestirme = 0;
    double toplamVergi = 0;
    
    for (var h in islemler) {
      final tutar = h.tlKarsiligi ?? h.tutar;
      if (h.islemKaynagi == 'gider_pusulasi') {
        toplamAvans += tutar;
      } else if (h.islemKaynagi == 'resmilestirme') {
        toplamResmilestirme += tutar;
      } else if (h.islemKaynagi == 'gider_pusulasi_vergi') {
        toplamVergi += tutar;
      }
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
            // Header
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            
            // Özet kartları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.money_off, color: Colors.red, size: 20),
                          const SizedBox(height: 4),
                          const Text('Avans', style: TextStyle(fontSize: 11)),
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
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt, color: Colors.purple, size: 20),
                          const SizedBox(height: 4),
                          const Text('Pusula', style: TextStyle(fontSize: 11)),
                          Text(currencyFormat.format(toplamResmilestirme), 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance, color: Colors.orange, size: 20),
                          const SizedBox(height: 4),
                          const Text('Vergi', style: TextStyle(fontSize: 11)),
                          Text(currencyFormat.format(toplamVergi), 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Bakiye
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
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: (toplamAvans - toplamResmilestirme) > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // İşlem listesi
            Expanded(
              child: islemler.isEmpty
                  ? Center(child: Text('İşlem bulunamadı', style: TextStyle(color: Colors.grey.shade600)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: islemler.length,
                      itemBuilder: (_, i) {
                        final h = islemler[i];
                        IconData icon;
                        Color color;
                        String tip;
                        
                        if (h.islemKaynagi == 'gider_pusulasi') {
                          icon = Icons.money_off;
                          color = Colors.red;
                          tip = 'Avans Ödemesi';
                        } else if (h.islemKaynagi == 'resmilestirme') {
                          icon = Icons.receipt;
                          color = Colors.purple;
                          tip = 'Gider Pusulası';
                        } else {
                          icon = Icons.account_balance;
                          color = Colors.orange;
                          tip = 'Vergi Ödemesi';
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Text(tip, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.aciklama, style: const TextStyle(fontSize: 12)),
                                Text(
                                  '${DateFormat('dd.MM.yyyy').format(h.tarih)} • ${h.kasa ?? "Kayıt"}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: Text(
                              currencyFormat.format(h.tlKarsiligi ?? h.tutar),
                              style: TextStyle(fontWeight: FontWeight.bold, color: color),
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
}
