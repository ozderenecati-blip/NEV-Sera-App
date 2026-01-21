import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';

class VergiRaporScreen extends StatefulWidget {
  const VergiRaporScreen({super.key});

  @override
  State<VergiRaporScreen> createState() => _VergiRaporScreenState();
}

class _VergiRaporScreenState extends State<VergiRaporScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vergi & Beyanname'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Stopaj'),
            Tab(icon: Icon(Icons.calculate), text: 'Vergi Özet'),
            Tab(icon: Icon(Icons.description), text: 'Beyanname'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Dönem Seçici
              _buildDonemSecici(),
              
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStopajTab(provider),
                    _buildVergiOzetTab(provider),
                    _buildBeyanTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonemSecici() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Ay',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(12, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: Text(_getAyAdi(i + 1)),
                );
              }),
              onChanged: (value) {
                if (value != null) setState(() => _selectedMonth = value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Yıl',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(5, (i) {
                final year = DateTime.now().year - 2 + i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (value) {
                if (value != null) setState(() => _selectedYear = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopajTab(AppProvider provider) {
    // Seçili dönemdeki gündelikçi ödemelerini filtrele
    final kasaHareketleri = provider.kasaHareketleri.where((h) {
      return h.tarih.year == _selectedYear && 
             h.tarih.month == _selectedMonth &&
             h.islemKaynagi == 'gundelikci_odeme';
    }).toList();
    
    // Ortak ödemelerini filtrele
    final ortakOdemeleri = provider.kasaHareketleri.where((h) {
      return h.tarih.year == _selectedYear && 
             h.tarih.month == _selectedMonth &&
             h.islemKaynagi == 'ortak_avans';
    }).toList();
    
    double toplamGundelikciOdeme = kasaHareketleri.fold(0, (sum, h) => sum + h.tutar);
    double gundelikciStopaj = toplamGundelikciOdeme * 0.10; // %10 stopaj
    
    double toplamOrtakOdeme = ortakOdemeleri.fold(0, (sum, h) => sum + h.tutar);
    double ortakStopaj = toplamOrtakOdeme * 0.15; // %15 stopaj
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gündelikçi Stopaj
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Gündelikçi Stopaj (%10)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStopajRow('Toplam Ödeme', toplamGundelikciOdeme),
                  _buildStopajRow('Stopaj Matrahı', toplamGundelikciOdeme),
                  const Divider(),
                  _buildStopajRow('Ödenecek Stopaj', gundelikciStopaj, isTotal: true),
                  const SizedBox(height: 12),
                  Text(
                    'Ödeme Sayısı: ${kasaHareketleri.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ortak Stopaj
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.handshake, color: Colors.purple.shade700),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ortak Kar Payı Stopajı (%15)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStopajRow('Toplam Kar Payı', toplamOrtakOdeme),
                  _buildStopajRow('Stopaj Matrahı', toplamOrtakOdeme),
                  const Divider(),
                  _buildStopajRow('Ödenecek Stopaj', ortakStopaj, isTotal: true),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Toplam Stopaj
          Card(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOPLAM ÖDENECEK STOPAJ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currencyFormat.format(gundelikciStopaj + ortakStopaj),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Gündelikçi Detay Listesi
          if (kasaHareketleri.isNotEmpty) ...[
            const Text(
              'Gündelikçi Ödemeleri Detayı',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...kasaHareketleri.map((h) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(h.aciklama),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(h.tarih)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_currencyFormat.format(h.tutar)),
                    Text(
                      'Stopaj: ${_currencyFormat.format(h.tutar * 0.10)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildVergiOzetTab(AppProvider provider) {
    final kasaOzet = provider.kasaOzet;
    final toplamGelir = kasaOzet['toplamGiris'] ?? 0;
    final toplamGider = kasaOzet['toplamCikis'] ?? 0;
    final netKar = toplamGelir - toplamGider;
    
    // Tahmini vergiler
    final kurumlarVergisi = netKar > 0 ? netKar * 0.25 : 0; // %25
    final kdv = toplamGelir * 0.01; // Tahmini %1 KDV farkı
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gelir-Gider Özeti
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gelir - Gider Özeti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildVergiRow('Toplam Gelir', toplamGelir, Colors.green),
                  _buildVergiRow('Toplam Gider', toplamGider, Colors.red),
                  const Divider(),
                  _buildVergiRow(
                    'Net Kar/Zarar',
                    netKar,
                    netKar >= 0 ? Colors.green : Colors.red,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tahmini Vergi Yükümlülükleri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Tahmini Vergi Yükümlülükleri',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu değerler tahmini olup, kesin hesaplama için muhasebeci ile görüşün.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  _buildVergiRow('Kurumlar Vergisi (%25)', kurumlarVergisi.toDouble(), Colors.orange),
                  _buildVergiRow('Tahmini KDV Farkı', kdv.toDouble(), Colors.orange),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Önemli Tarihler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Önemli Beyanname Tarihleri',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTarihRow('Muhtasar Beyanname', 'Her ayın 26\'sı'),
                  _buildTarihRow('KDV Beyannamesi', 'Her ayın 26\'sı'),
                  _buildTarihRow('Geçici Vergi', '3 ayda bir (Şubat, Mayıs, Ağustos, Kasım 17)'),
                  _buildTarihRow('Yıllık Gelir Vergisi', 'Mart ayı sonuna kadar'),
                  _buildTarihRow('Kurumlar Vergisi', 'Nisan ayı sonuna kadar'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeyanTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muhtasar Beyanname Hazırla
          Card(
            child: InkWell(
              onTap: () => _exportMuhtasarRapor(provider),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description, color: Colors.blue.shade700, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Muhtasar Beyanname Raporu',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stopaj ödemelerinizin detaylı listesi',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.share, color: Colors.blue),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Gündelikçi Listesi
          Card(
            child: InkWell(
              onTap: () => _exportGundelikciListesi(provider),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people, color: Colors.green.shade700, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gündelikçi Ödeme Listesi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TC No, Adres bilgileri dahil liste',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.share, color: Colors.green),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Ortak Kar Payı Listesi
          Card(
            child: InkWell(
              onTap: () => _exportOrtakKarPayi(provider),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.handshake, color: Colors.purple.shade700, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ortak Kar Payı Raporu',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ortaklara dağıtılan kar payları',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.share, color: Colors.purple),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Muhasebeci Özet Raporu
          Card(
            child: InkWell(
              onTap: () => _exportMuhasebeciRapor(provider),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.summarize, color: Colors.orange.shade700, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Muhasebeci Özet Raporu',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tüm vergi bilgilerinin özeti',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.share, color: Colors.orange),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopajRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 14,
            ),
          ),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 14,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVergiRow(String label, double value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarihRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAyAdi(int ay) {
    const aylar = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return aylar[ay - 1];
  }

  void _exportMuhtasarRapor(AppProvider provider) {
    final gundelikciOdemeleri = provider.kasaHareketleri.where((h) {
      return h.tarih.year == _selectedYear && 
             h.tarih.month == _selectedMonth &&
             h.islemKaynagi == 'gundelikci_odeme';
    }).toList();
    
    final ortakOdemeleri = provider.kasaHareketleri.where((h) {
      return h.tarih.year == _selectedYear && 
             h.tarih.month == _selectedMonth &&
             h.islemKaynagi == 'ortak_avans';
    }).toList();
    
    double toplamGundelikci = gundelikciOdemeleri.fold(0, (sum, h) => sum + h.tutar);
    double toplamOrtak = ortakOdemeleri.fold(0, (sum, h) => sum + h.tutar);
    
    final rapor = StringBuffer();
    rapor.writeln('NEV SERACILIK - MUHTASAR BEYANNAME RAPORU');
    rapor.writeln('═' * 50);
    rapor.writeln('Dönem: ${_getAyAdi(_selectedMonth)} $_selectedYear');
    rapor.writeln('Rapor Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}');
    rapor.writeln('');
    rapor.writeln('GÜNDELİKÇİ ÖDEMELERİ (Stopaj %10)');
    rapor.writeln('-' * 50);
    rapor.writeln('Toplam Ödeme: ${_currencyFormat.format(toplamGundelikci)}');
    rapor.writeln('Stopaj Tutarı: ${_currencyFormat.format(toplamGundelikci * 0.10)}');
    rapor.writeln('');
    rapor.writeln('ORTAK KAR PAYI (Stopaj %15)');
    rapor.writeln('-' * 50);
    rapor.writeln('Toplam Kar Payı: ${_currencyFormat.format(toplamOrtak)}');
    rapor.writeln('Stopaj Tutarı: ${_currencyFormat.format(toplamOrtak * 0.15)}');
    rapor.writeln('');
    rapor.writeln('═' * 50);
    rapor.writeln('TOPLAM ÖDENECEK STOPAJ: ${_currencyFormat.format(toplamGundelikci * 0.10 + toplamOrtak * 0.15)}');
    
    Share.share(rapor.toString(), subject: 'Muhtasar Beyanname Raporu - ${_getAyAdi(_selectedMonth)} $_selectedYear');
  }

  void _exportGundelikciListesi(AppProvider provider) {
    final gundelikciler = provider.gundelikciler;
    final gundelikciOdemeleri = provider.kasaHareketleri.where((h) {
      return h.tarih.year == _selectedYear && 
             h.tarih.month == _selectedMonth &&
             h.islemKaynagi == 'gundelikci_odeme';
    }).toList();
    
    final rapor = StringBuffer();
    rapor.writeln('NEV SERACILIK - GÜNDELİKÇİ LİSTESİ');
    rapor.writeln('═' * 50);
    rapor.writeln('Dönem: ${_getAyAdi(_selectedMonth)} $_selectedYear');
    rapor.writeln('');
    
    for (var g in gundelikciler.where((g) => g.aktif)) {
      final odemeler = gundelikciOdemeleri.where((h) => h.aciklama.contains(g.adSoyad));
      final toplamOdeme = odemeler.fold(0.0, (sum, h) => sum + h.tutar);
      
      if (toplamOdeme > 0) {
        rapor.writeln('Ad Soyad: ${g.adSoyad}');
        rapor.writeln('TC No: ${g.tcNo ?? "-"}');
        rapor.writeln('Adres: ${g.adres ?? "-"}');
        rapor.writeln('Toplam Ödeme: ${_currencyFormat.format(toplamOdeme)}');
        rapor.writeln('Stopaj (%10): ${_currencyFormat.format(toplamOdeme * 0.10)}');
        rapor.writeln('-' * 50);
      }
    }
    
    Share.share(rapor.toString(), subject: 'Gündelikçi Listesi - ${_getAyAdi(_selectedMonth)} $_selectedYear');
  }

  void _exportOrtakKarPayi(AppProvider provider) {
    final ortaklar = provider.ortaklar;
    
    final rapor = StringBuffer();
    rapor.writeln('NEV SERACILIK - ORTAK KAR PAYI RAPORU');
    rapor.writeln('═' * 50);
    rapor.writeln('Dönem: ${_getAyAdi(_selectedMonth)} $_selectedYear');
    rapor.writeln('');
    
    for (var o in ortaklar.where((o) => o.aktif)) {
      rapor.writeln('Ortak: ${o.adSoyad}');
      rapor.writeln('TC No: ${o.tcNo ?? "-"}');
      rapor.writeln('Stopaj Oranı: %${o.stopajOrani.toStringAsFixed(0)}');
      rapor.writeln('-' * 50);
    }
    
    Share.share(rapor.toString(), subject: 'Ortak Kar Payı - ${_getAyAdi(_selectedMonth)} $_selectedYear');
  }

  void _exportMuhasebeciRapor(AppProvider provider) {
    final kasaOzet = provider.kasaOzet;
    final gundelikciOzet = provider.gundelikciOzet;
    final krediOzet = provider.krediOzet;
    
    final rapor = StringBuffer();
    rapor.writeln('NEV SERACILIK - MUHASEBECİ ÖZET RAPORU');
    rapor.writeln('═' * 50);
    rapor.writeln('Dönem: ${_getAyAdi(_selectedMonth)} $_selectedYear');
    rapor.writeln('Rapor Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}');
    rapor.writeln('');
    rapor.writeln('KASA ÖZETİ');
    rapor.writeln('-' * 50);
    rapor.writeln('Toplam Giriş: ${_currencyFormat.format(kasaOzet['toplamGiris'] ?? 0)}');
    rapor.writeln('Toplam Çıkış: ${_currencyFormat.format(kasaOzet['toplamCikis'] ?? 0)}');
    rapor.writeln('Net Bakiye: ${_currencyFormat.format((kasaOzet['toplamGiris'] ?? 0) - (kasaOzet['toplamCikis'] ?? 0))}');
    rapor.writeln('');
    rapor.writeln('GÜNDELİKÇİ ÖZETİ');
    rapor.writeln('-' * 50);
    rapor.writeln('Toplam Ödeme: ${_currencyFormat.format(gundelikciOzet['toplamOdeme'] ?? 0)}');
    rapor.writeln('Stopaj (%10): ${_currencyFormat.format((gundelikciOzet['toplamOdeme'] ?? 0) * 0.10)}');
    rapor.writeln('');
    rapor.writeln('KREDİ ÖZETİ');
    rapor.writeln('-' * 50);
    rapor.writeln('Toplam Borç: ${_currencyFormat.format(krediOzet['toplamBorc'] ?? 0)}');
    rapor.writeln('Toplam Ödenen: ${_currencyFormat.format(krediOzet['toplamOdenen'] ?? 0)}');
    rapor.writeln('Kalan Borç: ${_currencyFormat.format(krediOzet['kalanBorc'] ?? 0)}');
    
    Share.share(rapor.toString(), subject: 'Muhasebeci Özet - ${_getAyAdi(_selectedMonth)} $_selectedYear');
  }
}
