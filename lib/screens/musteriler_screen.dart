import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/musteri.dart';
import '../models/satis.dart';

class MusterilerScreen extends StatefulWidget {
  const MusterilerScreen({super.key});

  @override
  State<MusterilerScreen> createState() => _MusterilerScreenState();
}

class _MusterilerScreenState extends State<MusterilerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadMusteriler();
      context.read<AppProvider>().loadSatislar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler & Satışlar'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Müşteriler'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Satışlar'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Tahsilatlar'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMusterilerTab(provider, isDark, primaryColor),
              _buildSatislarTab(provider, isDark, primaryColor),
              _buildTahsilatlarTab(provider, isDark, primaryColor),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMusterilerTab(AppProvider provider, bool isDark, Color primaryColor) {
    final musteriler = provider.musteriler;
    final cariOzet = provider.cariOzet;

    return Column(
      children: [
        // Özet Kartları
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildOzetCard(
                  'Toplam Müşteri',
                  '${cariOzet['musteriSayisi'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOzetCard(
                  'Toplam Alacak',
                  _currencyFormat.format(cariOzet['toplamAlacak'] ?? 0),
                  Icons.account_balance,
                  Colors.orange,
                  isDark,
                ),
              ),
            ],
          ),
        ),

        // Müşteri Listesi
        Expanded(
          child: musteriler.isEmpty
              ? _buildEmptyState('Henüz müşteri eklenmemiş', Icons.people_outline)
              : ListView.builder(
                  itemCount: musteriler.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<Map<String, double>>(
                      future: provider.getMusteriBakiye(musteriler[index].id!),
                      builder: (context, snapshot) {
                        final bakiye = snapshot.data ?? {'bakiye': 0.0};
                        return _buildMusteriCard(
                          musteriler[index],
                          bakiye['bakiye'] ?? 0,
                          isDark,
                          primaryColor,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSatislarTab(AppProvider provider, bool isDark, Color primaryColor) {
    final satislar = provider.satislar;
    final cariOzet = provider.cariOzet;

    return Column(
      children: [
        // Özet
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildOzetCard(
                  'Toplam Satış',
                  _currencyFormat.format(cariOzet['toplamSatis'] ?? 0),
                  Icons.trending_up,
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOzetCard(
                  'Tahsil Edilen',
                  _currencyFormat.format(cariOzet['toplamTahsilat'] ?? 0),
                  Icons.check_circle,
                  Colors.teal,
                  isDark,
                ),
              ),
            ],
          ),
        ),

        // Satış Listesi
        Expanded(
          child: satislar.isEmpty
              ? _buildEmptyState('Henüz satış kaydı yok', Icons.shopping_cart_outlined)
              : ListView.builder(
                  itemCount: satislar.length,
                  itemBuilder: (context, index) {
                    return _buildSatisCard(satislar[index], isDark, primaryColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTahsilatlarTab(AppProvider provider, bool isDark, Color primaryColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getTahsilatlar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tahsilatlar = snapshot.data ?? [];

        if (tahsilatlar.isEmpty) {
          return _buildEmptyState('Henüz tahsilat kaydı yok', Icons.account_balance_wallet_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tahsilatlar.length,
          itemBuilder: (context, index) {
            final t = tahsilatlar[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  child: const Icon(Icons.payments, color: Colors.green),
                ),
                title: Text(t['musteri_unvan'] ?? 'Bilinmeyen'),
                subtitle: Text(
                  DateFormat('dd.MM.yyyy').format(DateTime.parse(t['tarih'])),
                ),
                trailing: Text(
                  _currencyFormat.format(t['tutar']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOzetCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusteriCard(Musteri musteri, double bakiye, bool isDark, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.2),
          child: Text(
            musteri.unvan.isNotEmpty ? musteri.unvan[0].toUpperCase() : '?',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(musteri.unvan),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (musteri.yetkiliKisi != null && musteri.yetkiliKisi!.isNotEmpty)
              Text(musteri.yetkiliKisi!, style: const TextStyle(fontSize: 12)),
            if (musteri.telefon != null && musteri.telefon!.isNotEmpty)
              Text(musteri.telefon!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              bakiye >= 0 ? 'Alacak' : 'Borç',
              style: TextStyle(
                fontSize: 11,
                color: bakiye >= 0 ? Colors.orange : Colors.green,
              ),
            ),
            Text(
              _currencyFormat.format(bakiye.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: bakiye >= 0 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
        onTap: () => _showMusteriDetay(musteri),
      ),
    );
  }

  Widget _buildSatisCard(Satis satis, bool isDark, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.2),
          child: const Icon(Icons.receipt, color: Colors.green),
        ),
        title: Text(satis.musteriUnvan ?? 'Bilinmeyen Müşteri'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(satis.urunAdi),
            Text(
              '${satis.miktar} ${satis.birim} x ${_currencyFormat.format(satis.birimFiyat)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('dd.MM.yyyy').format(satis.tarih),
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              _currencyFormat.format(satis.toplamTutar),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onTap: () => _showSatisDetay(satis),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final currentTab = _tabController.index;
    if (currentTab == 0) {
      _showMusteriEkleDialog();
    } else if (currentTab == 1) {
      _showSatisEkleDialog();
    } else {
      _showTahsilatEkleDialog();
    }
  }

  void _showMusteriEkleDialog({Musteri? musteri}) {
    final isEdit = musteri != null;
    final unvanController = TextEditingController(text: musteri?.unvan ?? '');
    String musteriTipi = musteri?.musteriTipi ?? 'bireysel';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Müşteri Düzenle' : 'Yeni Müşteri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Müşteri Tipi
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'bireysel', label: Text('Bireysel')),
                    ButtonSegment(value: 'kurumsal', label: Text('Kurumsal')),
                  ],
                  selected: {musteriTipi},
                  onSelectionChanged: (value) {
                    setState(() => musteriTipi = value.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unvanController,
                  decoration: InputDecoration(
                    labelText: musteriTipi == 'bireysel' ? 'İsim Soyisim *' : 'Şirket İsmi *',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(musteriTipi == 'bireysel' ? Icons.person : Icons.business),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (unvanController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İsim/Şirket adı zorunludur')),
                  );
                  return;
                }

                final yeniMusteri = Musteri(
                  id: musteri?.id,
                  unvan: unvanController.text.trim(),
                  musteriTipi: musteriTipi,
                );

                bool success;
                if (isEdit) {
                  success = await context.read<AppProvider>().updateMusteri(yeniMusteri);
                } else {
                  success = await context.read<AppProvider>().addMusteri(yeniMusteri);
                }

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Müşteri güncellendi' : 'Müşteri eklendi')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSatisEkleDialog({Satis? satis}) {
    final provider = context.read<AppProvider>();
    final musteriler = provider.musteriler;

    if (musteriler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce müşteri eklemelisiniz')),
      );
      return;
    }

    final isEdit = satis != null;
    int? selectedMusteriId = satis?.musteriId ?? musteriler.first.id;
    final urunController = TextEditingController(text: satis?.urunAdi ?? '');
    final miktarController = TextEditingController(text: satis?.miktar.toString() ?? '');
    final fiyatController = TextEditingController(text: satis?.birimFiyat.toString() ?? '');
    final aciklamaController = TextEditingController(text: satis?.aciklama ?? '');
    String birim = satis?.birim ?? 'kg';
    DateTime tarih = satis?.tarih ?? DateTime.now();
    DateTime? vadeTarihi = satis?.vadeTarihi;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Satış Düzenle' : 'Yeni Satış'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Müşteri Seçimi
                DropdownButtonFormField<int>(
                  initialValue: selectedMusteriId,
                  decoration: const InputDecoration(
                    labelText: 'Müşteri *',
                    border: OutlineInputBorder(),
                  ),
                  items: musteriler.map((m) {
                    return DropdownMenuItem(value: m.id, child: Text(m.unvan));
                  }).toList(),
                  onChanged: (value) => selectedMusteriId = value,
                ),
                const SizedBox(height: 12),
                
                // Tarih
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarih'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(tarih)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tarih,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => tarih = picked);
                  },
                ),
                const Divider(),
                
                TextField(
                  controller: urunController,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Adı *',
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
                        decoration: const InputDecoration(
                          labelText: 'Miktar *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
                        items: ['kg', 'adet', 'kasa', 'ton', 'lt'].map((b) {
                          return DropdownMenuItem(value: b, child: Text(b));
                        }).toList(),
                        onChanged: (value) => birim = value ?? 'kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: fiyatController,
                  decoration: const InputDecoration(
                    labelText: 'Birim Fiyat (₺) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                
                // Vade Tarihi
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vade Tarihi'),
                  subtitle: Text(vadeTarihi != null 
                      ? DateFormat('dd.MM.yyyy').format(vadeTarihi!)
                      : 'Seçilmedi (Peşin)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vadeTarihi != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => vadeTarihi = null),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: vadeTarihi ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => vadeTarihi = picked);
                  },
                ),
                const Divider(),
                
                TextField(
                  controller: aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedMusteriId == null ||
                    urunController.text.isEmpty ||
                    miktarController.text.isEmpty ||
                    fiyatController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zorunlu alanları doldurun')),
                  );
                  return;
                }

                final miktar = double.tryParse(miktarController.text) ?? 0;
                final birimFiyat = double.tryParse(fiyatController.text) ?? 0;

                final yeniSatis = Satis(
                  id: satis?.id,
                  musteriId: selectedMusteriId!,
                  tarih: tarih,
                  urunAdi: urunController.text,
                  miktar: miktar,
                  birim: birim,
                  birimFiyat: birimFiyat,
                  toplamTutar: miktar * birimFiyat,
                  vadeTarihi: vadeTarihi,
                  aciklama: aciklamaController.text.isEmpty ? null : aciklamaController.text,
                );

                if (isEdit) {
                  await context.read<AppProvider>().updateSatis(yeniSatis);
                } else {
                  await context.read<AppProvider>().addSatis(yeniSatis);
                }

                if (mounted) Navigator.pop(context);
              },
              child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTahsilatEkleDialog({int? musteriId}) {
    final provider = context.read<AppProvider>();
    final musteriler = provider.musteriler;
    final kasalar = provider.kasalar;

    if (musteriler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce müşteri eklemelisiniz')),
      );
      return;
    }

    int? selectedMusteriId = musteriId ?? musteriler.first.id;
    final tutarController = TextEditingController();
    final aciklamaController = TextEditingController();
    DateTime tarih = DateTime.now();
    String odemeSekli = 'nakit';
    String? selectedKasa = kasalar.isNotEmpty ? kasalar.first : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tahsilat Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Müşteri Seçimi
                DropdownButtonFormField<int>(
                  initialValue: selectedMusteriId,
                  decoration: const InputDecoration(
                    labelText: 'Müşteri *',
                    border: OutlineInputBorder(),
                  ),
                  items: musteriler.map((m) {
                    return DropdownMenuItem(value: m.id, child: Text(m.unvan));
                  }).toList(),
                  onChanged: (value) => selectedMusteriId = value,
                ),
                const SizedBox(height: 12),
                
                // Tarih
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarih'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(tarih)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tarih,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => tarih = picked);
                  },
                ),
                const Divider(),
                
                TextField(
                  controller: tutarController,
                  decoration: const InputDecoration(
                    labelText: 'Tutar (₺) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                
                // Ödeme Şekli
                DropdownButtonFormField<String>(
                  initialValue: odemeSekli,
                  decoration: const InputDecoration(
                    labelText: 'Ödeme Şekli',
                    border: OutlineInputBorder(),
                  ),
                  items: ['nakit', 'havale', 'eft', 'kredi kartı', 'çek', 'senet'].map((o) {
                    return DropdownMenuItem(value: o, child: Text(o.toUpperCase()));
                  }).toList(),
                  onChanged: (value) => setState(() => odemeSekli = value ?? 'nakit'),
                ),
                const SizedBox(height: 12),
                
                // Kasa Seçimi
                if (kasalar.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedKasa,
                    decoration: const InputDecoration(
                      labelText: 'Kasa',
                      border: OutlineInputBorder(),
                    ),
                    items: kasalar.map((k) {
                      return DropdownMenuItem(value: k, child: Text(k));
                    }).toList(),
                    onChanged: (value) => selectedKasa = value,
                  ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedMusteriId == null || tutarController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zorunlu alanları doldurun')),
                  );
                  return;
                }

                final tutar = double.tryParse(tutarController.text) ?? 0;

                await context.read<AppProvider>().addTahsilat(
                  musteriId: selectedMusteriId!,
                  tarih: tarih,
                  tutar: tutar,
                  odemeSekli: odemeSekli,
                  kasaAdi: selectedKasa,
                  aciklama: aciklamaController.text.isEmpty ? null : aciklamaController.text,
                );

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMusteriDetay(Musteri musteri) {
    final provider = context.read<AppProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      musteri.unvan[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musteri.unvan,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (musteri.yetkiliKisi != null)
                          Text(musteri.yetkiliKisi!, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _showMusteriEkleDialog(musteri: musteri);
                    },
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Bakiye Bilgisi
            FutureBuilder<Map<String, double>>(
              future: provider.getMusteriBakiye(musteri.id!),
              builder: (context, snapshot) {
                final bakiye = snapshot.data ?? {};
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile('Toplam Satış', _currencyFormat.format(bakiye['toplamSatis'] ?? 0)),
                      ),
                      Expanded(
                        child: _buildInfoTile('Tahsilat', _currencyFormat.format(bakiye['toplamTahsilat'] ?? 0)),
                      ),
                      Expanded(
                        child: _buildInfoTile(
                          'Bakiye',
                          _currencyFormat.format(bakiye['bakiye'] ?? 0),
                          color: (bakiye['bakiye'] ?? 0) > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const Divider(),
            
            // İletişim Bilgileri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (musteri.telefon != null)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(musteri.telefon!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (musteri.email != null)
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(musteri.email!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (musteri.adres != null)
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(musteri.adres!),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Aksiyonlar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _tabController.animateTo(1);
                        _showSatisEkleDialog();
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Satış Ekle'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showTahsilatEkleDialog(musteriId: musteri.id);
                      },
                      icon: const Icon(Icons.payments),
                      label: const Text('Tahsilat Al'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, {Color? color}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showSatisDetay(Satis satis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Satış Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detayRow('Müşteri', satis.musteriUnvan ?? '-'),
            _detayRow('Tarih', DateFormat('dd.MM.yyyy').format(satis.tarih)),
            _detayRow('Ürün', satis.urunAdi),
            _detayRow('Miktar', '${satis.miktar} ${satis.birim}'),
            _detayRow('Birim Fiyat', _currencyFormat.format(satis.birimFiyat)),
            _detayRow('Toplam', _currencyFormat.format(satis.toplamTutar)),
            if (satis.vadeTarihi != null)
              _detayRow('Vade', DateFormat('dd.MM.yyyy').format(satis.vadeTarihi!)),
            if (satis.aciklama != null && satis.aciklama!.isNotEmpty)
              _detayRow('Açıklama', satis.aciklama!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSatisEkleDialog(satis: satis);
            },
            child: const Text('Düzenle'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Satışı Sil'),
                  content: const Text('Bu satış kaydını silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await context.read<AppProvider>().deleteSatis(satis.id!);
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _detayRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
