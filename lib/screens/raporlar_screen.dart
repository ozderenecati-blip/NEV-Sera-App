import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';

class RaporlarScreen extends StatefulWidget {
  const RaporlarScreen({super.key});

  @override
  State<RaporlarScreen> createState() => _RaporlarScreenState();
}

class _RaporlarScreenState extends State<RaporlarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aylık', icon: Icon(Icons.timeline)),
            Tab(text: 'Kategori', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Döviz', icon: Icon(Icons.currency_exchange)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAylikRapor(),
          _buildKategoriRapor(),
          _buildDovizRapor(),
        ],
      ),
    );
  }
  
  Widget _buildAylikRapor() {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Yıl Seçici
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedYear--;
                      });
                      provider.loadAylikRapor(_selectedYear);
                    },
                  ),
                  Text(
                    '$_selectedYear',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedYear < DateTime.now().year
                        ? () {
                            setState(() {
                              _selectedYear++;
                            });
                            provider.loadAylikRapor(_selectedYear);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            
            // Grafik
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: provider.aylikRapor.isEmpty
                    ? const Center(
                        child: Text('Bu yıla ait veri yok'),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(provider.aylikRapor),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final ay = _getAyAdi(group.x.toInt());
                                final value = rod.toY;
                                final label = rodIndex == 0 ? 'Gelir' : 'Gider';
                                return BarTooltipItem(
                                  '$ay\n$label: ${currencyFormat.format(value)}',
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _getAyKisa(value.toInt()),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('');
                                  return Text(
                                    _formatCompact(value),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _getMaxY(provider.aylikRapor) / 5,
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _buildBarGroups(provider.aylikRapor),
                        ),
                      ),
              ),
            ),
            
            // Özet
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Toplam Gelir',
                    currencyFormat.format(_getTotalGelir(provider.aylikRapor)),
                    Colors.green,
                  ),
                  _buildSummaryItem(
                    'Toplam Gider',
                    currencyFormat.format(_getTotalGider(provider.aylikRapor)),
                    Colors.red,
                  ),
                  _buildSummaryItem(
                    'Net',
                    currencyFormat.format(
                      _getTotalGelir(provider.aylikRapor) - _getTotalGider(provider.aylikRapor),
                    ),
                    _getTotalGelir(provider.aylikRapor) >= _getTotalGider(provider.aylikRapor)
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildKategoriRapor() {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.kategoriRapor.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Henüz veri yok'),
              ],
            ),
          );
        }
        
        final total = provider.kategoriRapor
            .fold<double>(0, (sum, item) => sum + (item['toplam'] as num).toDouble());
        
        return Column(
          children: [
            // Pasta Grafik
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: _buildPieSections(provider.kategoriRapor, total),
                  ),
                ),
              ),
            ),
            
            // Kategori Listesi
            Expanded(
              flex: 3,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.kategoriRapor.length,
                itemBuilder: (context, index) {
                  final item = provider.kategoriRapor[index];
                  final kategori = item['kategori'] as String;
                  final toplam = (item['toplam'] as num).toDouble();
                  final yuzde = (toplam / total * 100);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getKategoriColor(index).withOpacity(0.2),
                        child: Icon(
                          _getKategoriIcon(kategori),
                          color: _getKategoriColor(index),
                          size: 20,
                        ),
                      ),
                      title: Text(kategori),
                      subtitle: LinearProgressIndicator(
                        value: yuzde / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(_getKategoriColor(index)),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(toplam),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '%${yuzde.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> data) {
    List<BarChartGroupData> groups = [];
    
    for (int i = 1; i <= 12; i++) {
      final ayData = data.firstWhere(
        (item) => int.parse(item['ay'] as String) == i,
        orElse: () => {'ay': i.toString(), 'gelir': 0, 'gider': 0},
      );
      
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (ayData['gelir'] as num).toDouble(),
              color: Colors.green,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: (ayData['gider'] as num).toDouble(),
              color: Colors.red,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }
    
    return groups;
  }
  
  List<PieChartSectionData> _buildPieSections(
    List<Map<String, dynamic>> data,
    double total,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final toplam = (item['toplam'] as num).toDouble();
      final yuzde = toplam / total * 100;
      
      return PieChartSectionData(
        color: _getKategoriColor(index),
        value: toplam,
        title: yuzde > 5 ? '%${yuzde.toStringAsFixed(0)}' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  
  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 10000;
    
    double max = 0;
    for (var item in data) {
      final gelir = (item['gelir'] as num).toDouble();
      final gider = (item['gider'] as num).toDouble();
      if (gelir > max) max = gelir;
      if (gider > max) max = gider;
    }
    
    return max * 1.2;
  }
  
  double _getTotalGelir(List<Map<String, dynamic>> data) {
    return data.fold<double>(0, (sum, item) => sum + (item['gelir'] as num).toDouble());
  }
  
  double _getTotalGider(List<Map<String, dynamic>> data) {
    return data.fold<double>(0, (sum, item) => sum + (item['gider'] as num).toDouble());
  }
  
  String _getAyAdi(int ay) {
    const aylar = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return aylar[ay - 1];
  }
  
  String _getAyKisa(int ay) {
    const aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return aylar[ay - 1];
  }
  
  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
  
  Color _getKategoriColor(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }
  
  IconData _getKategoriIcon(String kategori) {
    final iconMap = {
      'Akaryakıt Alımı': Icons.local_gas_station,
      'Akaryakıt (Mazot)': Icons.local_gas_station,
      'Avans': Icons.payments,
      'Elektrik Faturası': Icons.bolt,
      'Fide Alımı': Icons.grass,
      'Gübre Alımı': Icons.agriculture,
      'İlaç Alımı': Icons.medical_services,
      'İşçi Maaşı': Icons.people,
      'İşçi Avansı': Icons.person,
      'Kargo': Icons.local_shipping,
      'Kredi Ödemesi': Icons.credit_card,
      'Nakliye': Icons.local_shipping,
      'Satış Geliri': Icons.shopping_cart,
      'Su Faturası': Icons.water_drop,
      'Telefon Faturası': Icons.phone,
      'Yemek': Icons.restaurant,
    };
    
    return iconMap[kategori] ?? Icons.category;
  }

  Widget _buildDovizRapor() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Para birimine göre işlemleri grupla
        final hareketler = provider.kasaHareketleri;
        
        // TL, EUR, USD bazında özet
        Map<String, Map<String, double>> dovizOzet = {
          'TL': {'giris': 0, 'cikis': 0},
          'EUR': {'giris': 0, 'cikis': 0},
          'USD': {'giris': 0, 'cikis': 0},
        };
        
        // Kasa bazında döviz bakiyeleri
        Map<String, Map<String, double>> kasaDovizBakiye = {};
        
        for (var h in hareketler) {
          final pb = h.paraBirimi;
          final kasa = h.kasa ?? 'Diğer';
          
          // Döviz özet
          if (dovizOzet.containsKey(pb)) {
            if (h.islemTipi == 'Giriş') {
              dovizOzet[pb]!['giris'] = dovizOzet[pb]!['giris']! + h.tutar;
            } else {
              dovizOzet[pb]!['cikis'] = dovizOzet[pb]!['cikis']! + h.tutar;
            }
          }
          
          // Kasa bazında bakiye
          kasaDovizBakiye[kasa] ??= {'TL': 0, 'EUR': 0, 'USD': 0};
          final tutar = h.islemTipi == 'Giriş' ? h.tutar : -h.tutar;
          kasaDovizBakiye[kasa]![pb] = (kasaDovizBakiye[kasa]![pb] ?? 0) + tutar;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Genel Döviz Özeti
            const Text(
              'Genel Döviz Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // TL Kartı
            _buildDovizKart(
              'Türk Lirası',
              '₺',
              Colors.purple,
              dovizOzet['TL']!['giris']!,
              dovizOzet['TL']!['cikis']!,
            ),
            const SizedBox(height: 8),
            
            // EUR Kartı
            _buildDovizKart(
              'Euro',
              '€',
              Colors.blue,
              dovizOzet['EUR']!['giris']!,
              dovizOzet['EUR']!['cikis']!,
            ),
            const SizedBox(height: 8),
            
            // USD Kartı
            _buildDovizKart(
              'Dolar',
              '\$',
              Colors.green,
              dovizOzet['USD']!['giris']!,
              dovizOzet['USD']!['cikis']!,
            ),
            
            const SizedBox(height: 24),
            
            // Kasa Bazında Döviz Bakiyeleri
            const Text(
              'Kasa Bazında Döviz Bakiyeleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            ...kasaDovizBakiye.entries.map((entry) {
              final kasa = entry.key;
              final bakiyeler = entry.value;
              
              // Sadece bakiyesi olan para birimlerini göster
              final aktifBakiyeler = bakiyeler.entries
                  .where((e) => e.value.abs() > 0.01)
                  .toList();
              
              if (aktifBakiyeler.isEmpty) return const SizedBox.shrink();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.account_balance_wallet, color: Colors.grey),
                  ),
                  title: Text(kasa, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: aktifBakiyeler.map((e) {
                      final sembol = e.key == 'TL' ? '₺' : e.key == 'EUR' ? '€' : '\$';
                      final renk = e.value >= 0 ? Colors.green : Colors.red;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          '$sembol${NumberFormat('#,##0.00', 'tr_TR').format(e.value)}',
                          style: TextStyle(color: renk, fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildBakiyeRow('TL Bakiye', '₺', bakiyeler['TL'] ?? 0),
                          const SizedBox(height: 8),
                          _buildBakiyeRow('EUR Bakiye', '€', bakiyeler['EUR'] ?? 0),
                          const SizedBox(height: 8),
                          _buildBakiyeRow('USD Bakiye', '\$', bakiyeler['USD'] ?? 0),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDovizKart(String ad, String sembol, Color renk, double giris, double cikis) {
    final bakiye = giris - cikis;
    final fmt = NumberFormat('#,##0.00', 'tr_TR');
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [renk.withOpacity(0.8), renk],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  sembol,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ad,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Text(
                  '$sembol${fmt.format(bakiye)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Giriş', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '+$sembol${fmt.format(giris)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Çıkış', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '-$sembol${fmt.format(cikis)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBakiyeRow(String label, String sembol, double value) {
    final fmt = NumberFormat('#,##0.00', 'tr_TR');
    final renk = value >= 0 ? Colors.green : Colors.red;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          '$sembol${fmt.format(value)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: renk),
        ),
      ],
    );
  }
}

/// Ayarlar içinde gömülü olarak kullanılacak Raporlar içeriği
class RaporlarContent extends StatefulWidget {
  const RaporlarContent({super.key});

  @override
  State<RaporlarContent> createState() => _RaporlarContentState();
}

class _RaporlarContentState extends State<RaporlarContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aylık'),
            Tab(text: 'Kategori'),
            Tab(text: 'Döviz'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAylikRapor(),
              _buildKategoriRapor(),
              _buildDovizRapor(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAylikRapor() {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() => _selectedYear--);
                      provider.loadAylikRapor(_selectedYear);
                    },
                  ),
                  Text('$_selectedYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedYear < DateTime.now().year
                        ? () {
                            setState(() => _selectedYear++);
                            provider.loadAylikRapor(_selectedYear);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.aylikRapor.isEmpty
                  ? const Center(child: Text('Bu yıla ait veri yok'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.aylikRapor.length,
                      itemBuilder: (context, index) {
                        final data = provider.aylikRapor[index];
                        final ay = int.parse(data['ay'].toString());
                        final gelir = (data['gelir'] as num).toDouble();
                        final gider = (data['gider'] as num).toDouble();
                        final ayAdi = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'][ay - 1];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(ayAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Gider: ${currencyFormat.format(gider)}'),
                            trailing: Text(currencyFormat.format(gelir), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKategoriRapor() {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.kategoriRapor.isEmpty) {
          return const Center(child: Text('Kategori verisi yok'));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.kategoriRapor.length,
          itemBuilder: (context, index) {
            final data = provider.kategoriRapor[index];
            final kategori = data['kategori'] ?? 'Diğer';
            final toplam = (data['toplam'] as num).toDouble();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(currencyFormat.format(toplam), style: const TextStyle(color: Colors.red)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDovizRapor() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final bakiyeler = provider.kasaBakiyeleri;
        if (bakiyeler.isEmpty) {
          return const Center(child: Text('Kasa verisi yok'));
        }
        
        final fmt = NumberFormat('#,##0.00', 'tr_TR');
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final kasa in bakiyeler)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(kasa['kasa'] ?? 'Bilinmeyen', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Giriş: ₺${fmt.format(kasa['toplam_giris'])} | Çıkış: ₺${fmt.format(kasa['toplam_cikis'])}'),
                  trailing: Text('₺${fmt.format(kasa['bakiye'])}', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (kasa['bakiye'] as num) >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
