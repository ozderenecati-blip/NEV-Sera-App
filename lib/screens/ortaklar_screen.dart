import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/ortak.dart';
import '../models/kasa_hareketi.dart';
import '../models/settings.dart';
import '../services/database_service.dart';

class OrtaklarScreen extends StatefulWidget {
  const OrtaklarScreen({super.key});

  @override
  State<OrtaklarScreen> createState() => _OrtaklarScreenState();
}

class _OrtaklarScreenState extends State<OrtaklarScreen> {
  final _numberFormat = NumberFormat('#,##0.00', 'tr_TR');
  List<KasaHareketi> _ortakIslemleri = [];
  List<AppSettings> _kasalar = [];
  int? _selectedOrtakId;

  @override
  void initState() {
    super.initState();
    _loadOrtakIslemleri();
    _loadKasalar();
  }

  Future<void> _loadOrtakIslemleri() async {
    final db = DatabaseService();
    final hareketler = await db.getKasaHareketleri();
    setState(() {
      _ortakIslemleri = hareketler.where((h) => 
        h.islemKaynagi == 'ortak_avans' || 
        h.islemKaynagi == 'ortak_geri_odeme' ||
        h.islemKaynagi == 'ortak_stopaj'
      ).toList();
    });
  }

  Future<void> _loadKasalar() async {
    final db = DatabaseService();
    final kasalar = await db.getSettings('kasa');
    setState(() {
      _kasalar = kasalar;
    });
  }

  List<AppSettings> _getOrtakKasalari(int ortakId) {
    return _kasalar.where((k) => k.ortakId == ortakId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ortaklar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showOrtakDialog(context),
            tooltip: 'Yeni Ortak',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadOrtaklar();
              await _loadOrtakIslemleri();
              await _loadKasalar();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genel Özet Kartı
                  _buildOzetCard(provider, isDark),
                  const SizedBox(height: 16),
                  
                  // Ortaklar Listesi
                  ...provider.ortaklar.map((ortak) => 
                    _buildOrtakCard(context, ortak, provider, isDark)
                  ),
                  
                  if (provider.ortaklar.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz ortak eklenmemiş',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOzetCard(AppProvider provider, bool isDark) {
    final ozet = provider.ortakOzet;
    final toplamVerilen = ozet['toplam_verilen'] ?? 0;
    final toplamGeriOdenen = ozet['toplam_geri_odenen'] ?? 0;
    final toplamStopaj = ozet['toplam_stopaj'] ?? 0;
    final kalanBorc = ozet['kalan_borc'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Ortaklara Borç Özeti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildOzetRow('Ortakların Verdiği', toplamVerilen, Colors.green),
            _buildOzetRow('Geri Ödenen', toplamGeriOdenen, Colors.orange),
            _buildOzetRow('Kesilen Stopaj', toplamStopaj, Colors.purple),
            const Divider(height: 16),
            _buildOzetRow(
              'Kalan Borç',
              kalanBorc,
              kalanBorc > 0 ? Colors.red : Colors.green,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOzetRow(String label, double tutar, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₺${_numberFormat.format(tutar)}',
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrtakCard(BuildContext context, Ortak ortak, AppProvider provider, bool isDark) {
    final isSelected = _selectedOrtakId == ortak.id;
    final ortakIslemleri = _ortakIslemleri.where((h) => h.iliskiliId == ortak.id).toList();
    final ortakKasalari = _getOrtakKasalari(ortak.id!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Column(
        children: [
          // Ortak Başlık
          InkWell(
            onTap: () {
              setState(() {
                _selectedOrtakId = isSelected ? null : ortak.id;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          ortak.adSoyad.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ortak.adSoyad,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Stopaj: ${ortak.stopajOraniStr}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (ortakKasalari.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.account_balance_wallet, size: 12, color: Colors.blue[400]),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      ortakKasalari.map((k) => k.deger).join(', '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Bakiye
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Kalan Borç',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          Text(
                            '₺${_numberFormat.format(ortak.kalanBorc)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ortak.kalanBorc > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  // Özet satırı
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _buildMiniStat('Verilen', ortak.toplamVerilen, Colors.green),
                      _buildMiniStat('Ödenen', ortak.toplamGeriOdenen, Colors.orange),
                      _buildMiniStat('Stopaj', ortak.toplamStopaj, Colors.purple),
                    ],
                  ),
                  
                  // Bağlı kasalar uyarısı
                  if (ortakKasalari.isEmpty && ortak.kalanBorc == 0)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Bu ortağa kasa atanmamış. Ayarlar > Kasalar\'dan atayabilirsiniz.',
                              style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Genişletilmiş Detay
          if (isSelected) ...[
            const Divider(height: 1),
            // İşlem Butonları
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAvansDialog(context, ortak, provider),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: const Text('Avans Al'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: ortak.kalanBorc > 0 
                        ? () => _showGeriOdemeDialog(context, ortak, provider)
                        : null,
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: const Text('Geri Öde'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: ortak.kalanBorc > 0
                        ? () => _showResmilestirDialog(context, ortak, provider)
                        : null,
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Resmileştir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Son İşlemler
            if (ortakIslemleri.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Son İşlemler',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Tümünü Gör'),
                          onPressed: () => _showOrtakIslemGecmisi(context, ortak, ortakIslemleri),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...ortakIslemleri.take(5).map((h) => _buildIslemRow(h)),
                  ],
                ),
              ),
            ],
            
            // Düzenle/Sil Butonları
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showOrtakDialog(context, ortak: ortak),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Düzenle'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ortak, provider),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Sil', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ₺${_numberFormat.format(value)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildIslemRow(KasaHareketi hareket) {
    final isAvans = hareket.islemKaynagi == 'ortak_avans';
    final isStopaj = hareket.islemKaynagi == 'ortak_stopaj';
    
    IconData icon;
    Color color;
    String tip;
    
    if (isAvans) {
      icon = Icons.arrow_downward;
      color = Colors.green;
      tip = 'Avans';
    } else if (isStopaj) {
      icon = Icons.receipt;
      color = Colors.purple;
      tip = 'Stopaj';
    } else {
      icon = Icons.arrow_upward;
      color = Colors.orange;
      tip = 'Geri Ödeme';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$tip - ${DateFormat('dd.MM.yyyy').format(hareket.tarih)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${hareket.paraBirimi == 'TL' ? '₺' : hareket.paraBirimi} ${_numberFormat.format(hareket.tutar)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrtakDialog(BuildContext context, {Ortak? ortak}) {
    final isEdit = ortak != null;
    final formKey = GlobalKey<FormState>();
    final adSoyadController = TextEditingController(text: ortak?.adSoyad ?? '');
    final tcNoController = TextEditingController(text: ortak?.tcNo ?? '');
    final telefonController = TextEditingController(text: ortak?.telefon ?? '');
    final adresController = TextEditingController(text: ortak?.adres ?? '');
    final notlarController = TextEditingController(text: ortak?.notlar ?? '');
    double stopajOrani = ortak?.stopajOrani ?? 15.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Ortak Düzenle' : 'Yeni Ortak'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: adSoyadController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tcNoController,
                    decoration: const InputDecoration(
                      labelText: 'TC No',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefonController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adresController,
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Icon(Icons.percent, color: Colors.grey),
                      const Text('Stopaj Oranı:'),
                      ChoiceChip(
                        label: const Text('%15'),
                        selected: stopajOrani == 15.0,
                        onSelected: (s) => setDialogState(() => stopajOrani = 15.0),
                      ),
                      ChoiceChip(
                        label: const Text('%20'),
                        selected: stopajOrani == 20.0,
                        onSelected: (s) => setDialogState(() => stopajOrani = 20.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notlarController,
                    decoration: const InputDecoration(
                      labelText: 'Notlar',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final provider = Provider.of<AppProvider>(context, listen: false);
                final yeniOrtak = Ortak(
                  id: ortak?.id,
                  adSoyad: adSoyadController.text.trim(),
                  tcNo: tcNoController.text.trim().isEmpty ? null : tcNoController.text.trim(),
                  telefon: telefonController.text.trim().isEmpty ? null : telefonController.text.trim(),
                  adres: adresController.text.trim().isEmpty ? null : adresController.text.trim(),
                  stopajOrani: stopajOrani,
                  notlar: notlarController.text.trim().isEmpty ? null : notlarController.text.trim(),
                );
                
                bool success;
                if (isEdit) {
                  success = await provider.updateOrtak(yeniOrtak);
                } else {
                  success = await provider.addOrtak(yeniOrtak);
                }
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Ortak güncellendi' : 'Ortak eklendi')),
                  );
                }
              },
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvansDialog(BuildContext context, Ortak ortak, AppProvider provider) {
    final formKey = GlobalKey<FormState>();
    final tutarController = TextEditingController();
    final aciklamaController = TextEditingController();
    DateTime secilenTarih = DateTime.now();
    String paraBirimi = 'TL';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Avans Al - ${ortak.adSoyad}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ortağın şirkete vereceği parayı girin.\nBorç olarak kaydedilir.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tutarController,
                    decoration: const InputDecoration(
                      labelText: 'Tutar *',
                      prefixIcon: Icon(Icons.money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Zorunlu';
                      if (double.tryParse(v!.replaceAll(',', '.')) == null) return 'Geçersiz';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paraBirimi,
                    decoration: const InputDecoration(
                      labelText: 'Para Birimi',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: ['TL', 'USD', 'EUR'].map((pb) => 
                      DropdownMenuItem(value: pb, child: Text(pb))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => paraBirimi = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('dd.MM.yyyy').format(secilenTarih)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: secilenTarih,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => secilenTarih = picked);
                      }
                    },
                  ),
                  TextFormField(
                    controller: aciklamaController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final tutar = double.parse(tutarController.text.replaceAll(',', '.'));
                
                final success = await provider.ortakAvansiAl(
                  ortak: ortak,
                  tutar: tutar,
                  tarih: secilenTarih,
                  paraBirimi: paraBirimi,
                  aciklama: aciklamaController.text.trim().isEmpty 
                      ? null 
                      : aciklamaController.text.trim(),
                );
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  await _loadOrtakIslemleri();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avans kaydedildi')),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeriOdemeDialog(BuildContext context, Ortak ortak, AppProvider provider) {
    final formKey = GlobalKey<FormState>();
    final tutarController = TextEditingController();
    final aciklamaController = TextEditingController();
    String secilenKasa = provider.kasalar.isNotEmpty ? provider.kasalar.first : '';
    DateTime secilenTarih = DateTime.now();
    String paraBirimi = 'TL';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Geri Ödeme - ${ortak.adSoyad}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kalan Borç: ₺${_numberFormat.format(ortak.kalanBorc)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tutarController,
                    decoration: const InputDecoration(
                      labelText: 'Ödenecek Tutar *',
                      prefixIcon: Icon(Icons.money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Zorunlu';
                      final tutar = double.tryParse(v!.replaceAll(',', '.'));
                      if (tutar == null) return 'Geçersiz';
                      if (tutar > ortak.kalanBorc) return 'Borçtan fazla olamaz';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paraBirimi,
                    decoration: const InputDecoration(
                      labelText: 'Para Birimi',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: ['TL', 'USD', 'EUR'].map((pb) => 
                      DropdownMenuItem(value: pb, child: Text(pb))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => paraBirimi = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: secilenKasa,
                    decoration: const InputDecoration(
                      labelText: 'Çıkış Kasası *',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: provider.kasalar.map((k) => 
                      DropdownMenuItem(value: k, child: Text(k))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => secilenKasa = v!),
                    validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('dd.MM.yyyy').format(secilenTarih)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: secilenTarih,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => secilenTarih = picked);
                      }
                    },
                  ),
                  TextFormField(
                    controller: aciklamaController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final tutar = double.parse(tutarController.text.replaceAll(',', '.'));
                
                final success = await provider.ortakGeriOdeme(
                  ortak: ortak,
                  tutar: tutar,
                  kasa: secilenKasa,
                  tarih: secilenTarih,
                  paraBirimi: paraBirimi,
                  aciklama: aciklamaController.text.trim().isEmpty 
                      ? null 
                      : aciklamaController.text.trim(),
                );
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  await _loadOrtakIslemleri();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geri ödeme kaydedildi')),
                  );
                }
              },
              child: const Text('Öde'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResmilestirDialog(BuildContext context, Ortak ortak, AppProvider provider) {
    final formKey = GlobalKey<FormState>();
    final brutTutarController = TextEditingController();
    String secilenKasa = provider.kasalar.isNotEmpty ? provider.kasalar.first : '';
    DateTime secilenTarih = DateTime.now();
    String paraBirimi = 'TL';
    
    double stopajTutari = 0;
    double netOdeme = 0;

    void hesapla(StateSetter setDialogState) {
      final brut = double.tryParse(brutTutarController.text.replaceAll(',', '.')) ?? 0;
      stopajTutari = brut * ortak.stopajOrani / 100;
      netOdeme = brut - stopajTutari;
      setDialogState(() {});
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Resmileştir - ${ortak.adSoyad}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.purple[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Kalan Borç: ₺${_numberFormat.format(ortak.kalanBorc)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stopaj Oranı: ${ortak.stopajOraniStr}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Brüt tutar girin, stopaj otomatik hesaplanır.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: brutTutarController,
                    decoration: const InputDecoration(
                      labelText: 'Brüt Tutar *',
                      prefixIcon: Icon(Icons.money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => hesapla(setDialogState),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Zorunlu';
                      final tutar = double.tryParse(v!.replaceAll(',', '.'));
                      if (tutar == null) return 'Geçersiz';
                      if (tutar > ortak.kalanBorc) return 'Borçtan fazla olamaz';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Hesaplama Özeti
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        _buildHesapRow('Brüt Tutar', double.tryParse(brutTutarController.text.replaceAll(',', '.')) ?? 0),
                        _buildHesapRow('Stopaj (${ortak.stopajOraniStr})', stopajTutari, color: Colors.purple),
                        const Divider(),
                        _buildHesapRow('Net Ödeme', netOdeme, isBold: true, color: Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paraBirimi,
                    decoration: const InputDecoration(
                      labelText: 'Para Birimi',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: ['TL', 'USD', 'EUR'].map((pb) => 
                      DropdownMenuItem(value: pb, child: Text(pb))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => paraBirimi = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: secilenKasa,
                    decoration: const InputDecoration(
                      labelText: 'Çıkış Kasası *',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: provider.kasalar.map((k) => 
                      DropdownMenuItem(value: k, child: Text(k))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => secilenKasa = v!),
                    validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('dd.MM.yyyy').format(secilenTarih)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: secilenTarih,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => secilenTarih = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final brutTutar = double.parse(brutTutarController.text.replaceAll(',', '.'));
                
                final success = await provider.ortakOdemesiResmilestir(
                  ortak: ortak,
                  brutTutar: brutTutar,
                  stopajTutari: stopajTutari,
                  netOdeme: netOdeme,
                  kasa: secilenKasa,
                  tarih: secilenTarih,
                  paraBirimi: paraBirimi,
                );
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  await _loadOrtakIslemleri();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Resmileştirildi! Net ₺${_numberFormat.format(netOdeme)} ödendi, '
                        '₺${_numberFormat.format(stopajTutari)} stopaj kesildi.'
                      ),
                    ),
                  );
                }
              },
              child: const Text('Resmileştir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHesapRow(String label, double tutar, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₺${_numberFormat.format(tutar)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Ortak ortak, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ortağı Sil'),
        content: Text('${ortak.adSoyad} silinsin mi?\n\nNot: İlişkili işlemler silinmez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.deleteOrtak(ortak.id!);
              if (success && context.mounted) {
                Navigator.pop(context);
                setState(() => _selectedOrtakId = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ortak silindi')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showOrtakIslemGecmisi(BuildContext context, Ortak ortak, List<KasaHareketi> islemler) {
    // Tarihe göre sırala (en yeni en üstte)
    final siraliIslemler = List<KasaHareketi>.from(islemler);
    siraliIslemler.sort((a, b) => b.tarih.compareTo(a.tarih));
    
    // Toplamları hesapla
    double toplamAvans = 0;
    double toplamGeriOdeme = 0;
    double toplamStopaj = 0;
    
    for (var h in siraliIslemler) {
      final tutar = h.tlKarsiligi ?? h.tutar;
      if (h.islemKaynagi == 'ortak_avans') {
        toplamAvans += tutar;
      } else if (h.islemKaynagi == 'ortak_geri_odeme') {
        toplamGeriOdeme += tutar;
      } else if (h.islemKaynagi == 'ortak_stopaj') {
        toplamStopaj += tutar;
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
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      ortak.adSoyad.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ortak.adSoyad, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${siraliIslemler.length} işlem • Stopaj: ${ortak.stopajOraniStr}', 
                          style: TextStyle(color: Colors.grey[600])),
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
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                          const SizedBox(height: 4),
                          const Text('Avans', style: TextStyle(fontSize: 11)),
                          Text('₺${_numberFormat.format(toplamAvans)}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
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
                          const Icon(Icons.arrow_upward, color: Colors.orange, size: 20),
                          const SizedBox(height: 4),
                          const Text('Geri Ödeme', style: TextStyle(fontSize: 11)),
                          Text('₺${_numberFormat.format(toplamGeriOdeme)}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
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
                          const Text('Stopaj', style: TextStyle(fontSize: 11)),
                          Text('₺${_numberFormat.format(toplamStopaj)}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12)),
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
                  color: ortak.kalanBorc > 0 ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ortak.kalanBorc > 0 ? 'Şirketin Borcu: ' : 'Borç Yok: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₺${_numberFormat.format(ortak.kalanBorc)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: ortak.kalanBorc > 0 ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // İşlem listesi
            Expanded(
              child: siraliIslemler.isEmpty
                  ? Center(child: Text('İşlem bulunamadı', style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: siraliIslemler.length,
                      itemBuilder: (_, i) {
                        final h = siraliIslemler[i];
                        final isAvans = h.islemKaynagi == 'ortak_avans';
                        final isStopaj = h.islemKaynagi == 'ortak_stopaj';
                        
                        IconData icon;
                        Color color;
                        String tip;
                        
                        if (isAvans) {
                          icon = Icons.arrow_downward;
                          color = Colors.green;
                          tip = 'Ortak Avansı';
                        } else if (isStopaj) {
                          icon = Icons.receipt;
                          color = Colors.purple;
                          tip = 'Stopaj Kesintisi';
                        } else {
                          icon = Icons.arrow_upward;
                          color = Colors.orange;
                          tip = 'Geri Ödeme';
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
                                if (h.aciklama.isNotEmpty)
                                  Text(h.aciklama, style: const TextStyle(fontSize: 12)),
                                Text(
                                  '${DateFormat('dd.MM.yyyy').format(h.tarih)} • ${h.kasa ?? "Kayıt"} • ${h.paraBirimi}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${h.paraBirimi == 'TL' ? '₺' : h.paraBirimi} ${_numberFormat.format(h.tutar)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                ),
                                if (h.tlKarsiligi != null && h.paraBirimi != 'TL')
                                  Text(
                                    '≈ ₺${_numberFormat.format(h.tlKarsiligi)}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                  ),
                              ],
                            ),
                            isThreeLine: h.aciklama.isNotEmpty,
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
