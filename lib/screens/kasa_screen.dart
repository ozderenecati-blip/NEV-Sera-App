import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/kasa_hareketi.dart';
import '../models/kredi.dart';
import '../services/currency_service.dart';
import '../services/excel_service.dart';
import '../services/fis_storage_service.dart';
import '../widgets/modern_widgets.dart';

class KasaScreen extends StatefulWidget {
  const KasaScreen({super.key});

  @override
  State<KasaScreen> createState() => _KasaScreenState();
}

class _KasaScreenState extends State<KasaScreen> {
  final CurrencyService _currencyService = CurrencyService();
  final ExcelService _excelService = ExcelService();

  double _eurTryRate = 38.0;
  double _usdTryRate = 35.0;

  String? _filterKasa;
  String? _filterIslemTipi;
  String? _filterIslemKaynagi;
  String? _filterParaBirimi;
  DateTimeRange? _filterDateRange;
  String _searchQuery = '';
  bool _showFilters = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrencyRates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencyRates() async {
    final rates = await _currencyService.fetchRates();
    if (mounted) {
      setState(() {
        _eurTryRate = rates['EUR_TRY'] ?? 38.0;
        _usdTryRate = rates['USD_TRY'] ?? 35.0;
      });
    }
  }

  List<KasaHareketi> _filterHareketler(List<KasaHareketi> hareketler) {
    return hareketler.where((h) {
      // Arama
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!h.aciklama.toLowerCase().contains(query) &&
            !(h.notlar?.toLowerCase().contains(query) ?? false) &&
            !(h.kasa?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      if (_filterKasa != null && h.kasa != _filterKasa) return false;
      if (_filterIslemTipi != null && h.islemTipi != _filterIslemTipi) {
        return false;
      }
      if (_filterIslemKaynagi != null && h.islemKaynagi != _filterIslemKaynagi) {
        return false;
      }
      if (_filterParaBirimi != null && h.paraBirimi != _filterParaBirimi) {
        return false;
      }
      if (_filterDateRange != null) {
        if (h.tarih.isBefore(_filterDateRange!.start) ||
            h.tarih.isAfter(
              _filterDateRange!.end.add(const Duration(days: 1)),
            )) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _exportToExcel(List<KasaHareketi> hareketler) async {
    try {
      final filePath = await _excelService.exportToExcel(hareketler);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel dosyası oluşturuldu'),
            action: SnackBarAction(
              label: 'Paylaş',
              onPressed: () => Share.shareXFiles([XFile(filePath)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data'),
        actions: [
          // Döviz Kuru Göstergesi
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeProvider.primaryColor.withOpacity(0.1),
                  ThemeProvider.primaryLight.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ThemeProvider.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '€${_eurTryRate.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ThemeProvider.primaryColor,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 1,
                  height: 16,
                  color: ThemeProvider.primaryColor.withOpacity(0.3),
                ),
                Text(
                  '\$${_usdTryRate.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ThemeProvider.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              HapticHelper.lightTap();
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: 'Filtreler',
          ),
          Consumer<AppProvider>(
            builder:
                (context, provider, child) => PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'excel') {
                      _exportToExcel(
                        _filterHareketler(provider.kasaHareketleri),
                      );
                    } else if (value == 'refresh_rates') {
                      _loadCurrencyRates();
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart, size: 20),
                              SizedBox(width: 8),
                              Text('Excel\'e Aktar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'refresh_rates',
                          child: Row(
                            children: [
                              Icon(Icons.currency_exchange, size: 20),
                              SizedBox(width: 8),
                              Text('Kurları Güncelle'),
                            ],
                          ),
                        ),
                      ],
                ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: AnimatedFAB(
          onPressed: () => _showAddEditDialog(context),
          icon: Icons.add,
          label: 'Yeni İşlem',
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SkeletonListLoader(itemCount: 5);
          }

          final filteredHareketler = _filterHareketler(
            provider.kasaHareketleri,
          );

          return Column(
            children: [
              // Arama Çubuğu
              ModernSearchBar(
                controller: _searchController,
                hintText: 'Açıklama, not veya kasa ara...',
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() => _searchQuery = ''),
              ),

              // Filtreler
              if (_showFilters) _buildFilterPanel(provider)
                  .animate().fadeIn().slideY(begin: -0.1, end: 0),

              // İşlem Listesi
              Expanded(
                child:
                    filteredHareketler.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.receipt_long_outlined,
                            title: 'İşlem bulunamadı',
                            subtitle: 'Yeni işlem eklemek için aşağıdaki butonu kullanın',
                            buttonText: 'İşlem Ekle',
                            onButtonPressed: () => _showAddEditDialog(context),
                          )
                        : PullToRefreshWrapper(
                          onRefresh: () => provider.loadKasaHareketleri(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            itemCount: filteredHareketler.length,
                            itemBuilder:
                                (context, index) => AnimatedListItem(
                                  index: index,
                                  child: _buildHareketCard(
                                    context,
                                    filteredHareketler[index],
                                    currencyFormat,
                                    provider,
                                  ),
                                ),
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(AppProvider provider) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterKasa,
                  isDense: true,
                  decoration: const InputDecoration(
                      labelText: 'Kasa',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...provider.kasalar.map(
                        (k) => DropdownMenuItem(value: k, child: Text(k)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filterKasa = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterIslemTipi,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Tip',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tümü')),
                      DropdownMenuItem(value: 'Giriş', child: Text('Giriş')),
                      DropdownMenuItem(value: 'Çıkış', child: Text('Çıkış')),
                    ],
                    onChanged: (v) => setState(() => _filterIslemTipi = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterIslemKaynagi,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Kaynak',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tümü')),
                      DropdownMenuItem(value: 'kasa', child: Text('Normal')),
                      DropdownMenuItem(
                        value: 'gider_pusulasi',
                        child: Text('Avans'),
                      ),
                      DropdownMenuItem(
                        value: 'resmilestirme',
                        child: Text('G. Pusulası'),
                      ),
                      DropdownMenuItem(
                        value: 'gider_pusulasi_vergi',
                        child: Text('G.P. Vergisi'),
                      ),
                      DropdownMenuItem(
                        value: 'kredi_odeme',
                        child: Text('Kredi'),
                      ),
                      DropdownMenuItem(
                        value: 'doviz_bozdurma',
                        child: Text('Döviz Bozd.'),
                      ),
                      DropdownMenuItem(
                        value: 'kasa_transfer',
                        child: Text('Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'islem_ucreti',
                        child: Text('İşlem Ücreti'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filterIslemKaynagi = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterParaBirimi,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Para Birimi',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tümü')),
                      DropdownMenuItem(value: 'TL', child: Text('₺ TL')),
                      DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                      DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                    ],
                    onChanged: (v) => setState(() => _filterParaBirimi = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: _filterDateRange,
                      );
                      if (range != null) {
                        setState(() => _filterDateRange = range);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tarih Aralığı',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _filterDateRange == null
                                  ? 'Seçiniz'
                                  : '${DateFormat('dd/MM').format(_filterDateRange!.start)} - ${DateFormat('dd/MM').format(_filterDateRange!.end)}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_filterDateRange != null)
                            GestureDetector(
                              onTap:
                                  () => setState(() => _filterDateRange = null),
                              child: const Icon(Icons.clear, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterKasa = null;
                      _filterIslemTipi = null;
                      _filterIslemKaynagi = null;
                      _filterParaBirimi = null;
                      _filterDateRange = null;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Temizle'),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildHareketCard(
    BuildContext context,
    KasaHareketi h,
    NumberFormat fmt,
    AppProvider provider,
  ) {
    final isGiris = h.islemTipi == 'Giriş';
    final color = isGiris ? Colors.green : Colors.red;
    final tlFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Dismissible(
      key: Key('h_${h.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showAddEditDialog(context, hareket: h);
          return false;
        }
        return await showDialog<bool>(
              context: context,
              builder:
                  (c) => AlertDialog(
                    title: const Text('Silme Onayı'),
                    content: const Text(
                      'Bu kaydı silmek istediğinize emin misiniz?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text(
                          'Sil',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            ) ??
            false;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final success = await provider.deleteKasaHareketi(h.id!);
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('İşlem silindi'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Yeni Ekle',
                  textColor: Colors.white,
                  onPressed: () => _showAddEditDialog(context),
                ),
              ),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _showIslemDetay(context, h),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGiris ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              h.aciklama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (h.islemKaynagi != 'kasa')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getKaynagiColor(
                                  h.islemKaynagi ?? '',
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                h.islemKaynagiLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getKaynagiColor(h.islemKaynagi ?? ''),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (h.kasa != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  h.kasa!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(h.tarih),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          if (h.odemeBicimi != null)
                            Text(
                              h.odemeBicimiLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isGiris ? '+' : '-'}${h.paraBirimiSembol}${NumberFormat('#,##0.00', 'tr_TR').format(h.tutar)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                    if (h.paraBirimi != 'TL' && h.tlKarsiligi != null)
                      Text(
                        '≈ ${tlFmt.format(h.tlKarsiligi)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getKaynagiColor(String k) => switch (k) {
    'gider_pusulasi' => Colors.orange,
    'resmilestirme' => Colors.purple,
    'gider_pusulasi_vergi' => Colors.deepOrange,
    'kredi_odeme' => Colors.blue,
    'doviz_bozdurma' => Colors.teal,
    'islem_ucreti' => Colors.brown,
    _ => Colors.grey,
  };

  /// İşlem detay bottom sheet - fiş ekleme özelliği burada
  void _showIslemDetay(BuildContext context, KasaHareketi hareket) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');
    final isGiris = hareket.islemTipi == 'Giriş';
    final color = isGiris ? Colors.green : Colors.red;
    final fisService = FisStorageService();
    final picker = ImagePicker();
    
    String? currentFisUrl = hareket.fisUrl;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGiris ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hareket.aciklama,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            hareket.islemKaynagiLabel,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
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
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tutar
                      _buildDetayRow(
                        'Tutar',
                        '${isGiris ? '+' : '-'}${hareket.paraBirimiSembol}${hareket.tutar.toStringAsFixed(2)}',
                        color: color,
                        isBold: true,
                        fontSize: 24,
                      ),
                      
                      if (hareket.tlKarsiligi != null && hareket.paraBirimi != 'TL')
                        _buildDetayRow(
                          'TL Karşılığı',
                          currencyFormat.format(hareket.tlKarsiligi),
                          color: Colors.grey.shade700,
                        ),
                      
                      const SizedBox(height: 16),
                      
                      _buildDetayRow('Tarih', dateFormat.format(hareket.tarih)),
                      _buildDetayRow('Kasa', hareket.kasa ?? '-'),
                      _buildDetayRow('Ödeme Şekli', hareket.odemeBicimi ?? '-'),
                      
                      if (hareket.notlar != null && hareket.notlar!.isNotEmpty)
                        _buildDetayRow('Notlar', hareket.notlar!),
                      
                      const SizedBox(height: 24),
                      
                      // Fiş Görseli Bölümü
                      const Text(
                        'Fiş / Fatura Görseli',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      if (isUploading)
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Yükleniyor...'),
                              ],
                            ),
                          ),
                        )
                      else if (currentFisUrl != null)
                        GestureDetector(
                          onTap: () => _showFullImage(ctx, currentFisUrl!),
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(currentFisUrl!, fit: BoxFit.cover),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        _buildFisActionButton(
                                          Icons.fullscreen,
                                          'Büyüt',
                                          () => _showFullImage(ctx, currentFisUrl!),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFisActionButton(
                                          Icons.delete,
                                          'Kaldır',
                                          () async {
                                            setModalState(() => isUploading = true);
                                            // URL'yi kaldır
                                            final updated = hareket.copyWith(fisUrl: null);
                                            await provider.updateKasaHareketi(updated);
                                            setModalState(() {
                                              currentFisUrl = null;
                                              isUploading = false;
                                            });
                                          },
                                          isDestructive: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _showFisEkleMenu(ctx, picker, fisService, hareket, provider, (url) {
                            setModalState(() {
                              currentFisUrl = url;
                            });
                          }, (loading) {
                            setModalState(() => isUploading = loading);
                          }),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade500),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fiş / Fatura Ekle',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kamera veya galeriden seçin',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Bottom actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddEditDialog(context, hareket: hareket);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Düzenle'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check),
                        label: const Text('Tamam'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetayRow(String label, String value, {Color? color, bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFisActionButton(IconData icon, String tooltip, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red : Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(tooltip, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFisEkleMenu(
    BuildContext context,
    ImagePicker picker,
    FisStorageService fisService,
    KasaHareketi hareket,
    AppProvider provider,
    Function(String?) onUrlChanged,
    Function(bool) onLoadingChanged,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera ile Çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadFis(ImageSource.camera, picker, fisService, hareket, provider, onUrlChanged, onLoadingChanged);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadFis(ImageSource.gallery, picker, fisService, hareket, provider, onUrlChanged, onLoadingChanged);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFis(
    ImageSource source,
    ImagePicker picker,
    FisStorageService fisService,
    KasaHareketi hareket,
    AppProvider provider,
    Function(String?) onUrlChanged,
    Function(bool) onLoadingChanged,
  ) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 80,
      );
      
      if (image == null) return;
      
      onLoadingChanged(true);
      
      final bytes = await image.readAsBytes();
      final url = await fisService.uploadFisGorseli(bytes, fileName: image.name);
      
      if (url != null) {
        // Hareketi güncelle
        final updated = hareket.copyWith(fisUrl: url);
        await provider.updateKasaHareketi(updated);
        onUrlChanged(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fiş yüklenemedi')),
          );
        }
      }
      
      onLoadingChanged(false);
    } catch (e) {
      onLoadingChanged(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _showAddEditDialog(BuildContext context, {KasaHareketi? hareket}) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEdit = hareket != null;

    final tutarController = TextEditingController(
      text: hareket?.tutar.toStringAsFixed(2) ?? '',
    );
    final aciklamaController = TextEditingController(
      text: hareket?.aciklama ?? '',
    );
    final notlarController = TextEditingController(text: hareket?.notlar ?? '');
    final islemUcretiController = TextEditingController(text: '0');

    // İşlem modu: 'giris', 'cikis', 'doviz', 'transfer'
    String islemModu = 'cikis';
    if (hareket != null) {
      if (hareket.islemKaynagi == 'doviz_bozdurma') {
        islemModu = 'doviz';
      } else if (hareket.islemKaynagi == 'transfer') {
        islemModu = 'transfer';
      } else if (hareket.islemTipi == 'Giriş') {
        islemModu = 'giris';
      } else {
        islemModu = 'cikis';
      }
    }

    String islemTipi = hareket?.islemTipi ?? 'Çıkış';
    // Sistem tarafından oluşturulan kayıtları düzenlerken normal kasa işlemi olarak aç
    final sistemKaynaklari = [
      'resmilestirme',
      'gider_pusulasi_vergi',
      'doviz_bozdurma',
      'islem_ucreti',
    ];
    String islemKaynagi =
        sistemKaynaklari.contains(hareket?.islemKaynagi)
            ? 'kasa'
            : (hareket?.islemKaynagi ?? 'kasa');
    String? selectedKasa =
        hareket?.kasa ??
        (provider.kasalar.isNotEmpty ? provider.kasalar.first : null);
    String? hedefKasa; // Transfer için hedef kasa
    String? selectedOdemeBicimi = hareket?.odemeBicimi;
    String selectedParaBirimi = hareket?.paraBirimi ?? 'TL';
    String hedefParaBirimi = 'TL'; // Döviz bozdurma için
    int? selectedGundelikciId = hareket?.iliskiliId;
    int? selectedKrediId; // Kredi ödemesi için
    int? selectedTaksitId; // Kredi taksiti için
    DateTime selectedDate = hareket?.tarih ?? DateTime.now();
    bool islemUcretiAktif = false;
    String? fisUrl = hareket?.fisUrl; // Fiş görseli URL'si
    bool fisYukleniyor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) {
              double? calculatedTlKarsiligi;
              if (selectedParaBirimi != 'TL') {
                final tutar =
                    double.tryParse(
                      tutarController.text.replaceAll(',', '.'),
                    ) ??
                    0;
                final kur =
                    selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate;
                calculatedTlKarsiligi = tutar * kur;
              }

              // Seçili kredi ve taksitler
              final krediler = provider.krediler;
              List<KrediTaksit> taksitler = [];
              if (selectedKrediId != null) {
                final kredi = krediler.firstWhere(
                  (k) => k.id == selectedKrediId,
                );
                taksitler = kredi.taksitler.where((t) => !t.odendi).toList();
              }

              return Container(
                height: MediaQuery.of(ctx).size.height * 0.9,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            isEdit ? 'İşlemi Düzenle' : 'Yeni İşlem',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 4'lü İşlem Modu Seçici
                            const Text(
                              'İşlem Türü',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setModalState(() {
                                          islemModu = 'giris';
                                          islemTipi = 'Giriş';
                                          islemKaynagi = 'kasa';
                                        }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            islemModu == 'giris'
                                                ? Colors.green
                                                : Colors.grey.shade200,
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              left: Radius.circular(12),
                                            ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.arrow_downward,
                                            color:
                                                islemModu == 'giris'
                                                    ? Colors.white
                                                    : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Giriş',
                                            style: TextStyle(
                                              color:
                                                  islemModu == 'giris'
                                                      ? Colors.white
                                                      : Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setModalState(() {
                                          islemModu = 'cikis';
                                          islemTipi = 'Çıkış';
                                          islemKaynagi = 'kasa';
                                        }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            islemModu == 'cikis'
                                                ? Colors.red
                                                : Colors.grey.shade200,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.arrow_upward,
                                            color:
                                                islemModu == 'cikis'
                                                    ? Colors.white
                                                    : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Çıkış',
                                            style: TextStyle(
                                              color:
                                                  islemModu == 'cikis'
                                                      ? Colors.white
                                                      : Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setModalState(() {
                                          islemModu = 'doviz';
                                          islemKaynagi = 'doviz_bozdurma';
                                          selectedParaBirimi = 'EUR';
                                          hedefParaBirimi = 'TL';
                                        }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            islemModu == 'doviz'
                                                ? Colors.orange
                                                : Colors.grey.shade200,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.currency_exchange,
                                            color:
                                                islemModu == 'doviz'
                                                    ? Colors.white
                                                    : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Döviz',
                                            style: TextStyle(
                                              color:
                                                  islemModu == 'doviz'
                                                      ? Colors.white
                                                      : Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setModalState(() {
                                          islemModu = 'transfer';
                                          islemKaynagi = 'transfer';
                                        }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            islemModu == 'transfer'
                                                ? Colors.purple
                                                : Colors.grey.shade200,
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              right: Radius.circular(12),
                                            ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.swap_horiz,
                                            color:
                                                islemModu == 'transfer'
                                                    ? Colors.white
                                                    : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Transfer',
                                            style: TextStyle(
                                              color:
                                                  islemModu == 'transfer'
                                                      ? Colors.white
                                                      : Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Normal Giriş/Çıkış modunda İşlem Kaynağı
                            if (islemModu == 'giris' ||
                                islemModu == 'cikis') ...[
                              DropdownButtonFormField<String>(
                                initialValue: islemKaynagi,
                                decoration: const InputDecoration(
                                  labelText: 'İşlem Kaynağı',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'kasa',
                                    child: Text('Normal İşlem'),
                                  ),
                                  if (islemModu == 'cikis') ...[
                                    const DropdownMenuItem(
                                      value: 'gider_pusulasi',
                                      child: Text('Çalışan Ödemesi'),
                                    ),
                                    const DropdownMenuItem(
                                      value: 'kredi_odeme',
                                      child: Text('Kredi Taksit Ödemesi'),
                                    ),
                                  ],
                                ],
                                onChanged:
                                    (v) => setModalState(() {
                                      islemKaynagi = v!;
                                      if (v == 'gider_pusulasi') {
                                        islemTipi = 'Çıkış';
                                      }
                                      if (v == 'kredi_odeme') {
                                        islemTipi = 'Çıkış';
                                        selectedKrediId = null;
                                        selectedTaksitId = null;
                                      }
                                    }),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Gündelikçi seçimi
                            if (islemKaynagi == 'gider_pusulasi') ...[
                              DropdownButtonFormField<int>(
                                initialValue: selectedGundelikciId,
                                decoration: const InputDecoration(
                                  labelText: 'Çalışan *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items:
                                    provider.gundelikciler
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g.id,
                                            child: Text(g.adSoyad),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => setModalState(() {
                                      selectedGundelikciId = v;
                                      aciklamaController.text =
                                          'Gündelik ücreti - ${provider.gundelikciler.firstWhere((g) => g.id == v).adSoyad}';
                                    }),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Kredi ve Taksit Seçimi
                            if (islemKaynagi == 'kredi_odeme') ...[
                              DropdownButtonFormField<int>(
                                initialValue: selectedKrediId,
                                decoration: const InputDecoration(
                                  labelText: 'Kredi Seçin *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.credit_card),
                                ),
                                items:
                                    krediler
                                        .map(
                                          (k) => DropdownMenuItem(
                                            value: k.id,
                                            child: Text(
                                              '${k.bankaAd} - ${k.krediId}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => setModalState(() {
                                      selectedKrediId = v;
                                      selectedTaksitId = null;
                                    }),
                              ),
                              const SizedBox(height: 16),

                              if (selectedKrediId != null &&
                                  taksitler.isNotEmpty) ...[
                                const Text(
                                  'Ödenecek Taksit',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.builder(
                                    itemCount: taksitler.length,
                                    itemBuilder: (context, index) {
                                      final t = taksitler[index];
                                      final isSelected =
                                          selectedTaksitId == t.id;
                                      final vadeTarihi = t.vadeTarihi;
                                      final gecikmisMi = vadeTarihi.isBefore(
                                        DateTime.now(),
                                      );

                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: Colors.blue.shade50,
                                        leading: Radio<int>(
                                          value: t.id!,
                                          groupValue: selectedTaksitId,
                                          onChanged:
                                              (v) => setModalState(() {
                                                selectedTaksitId = v;
                                                tutarController.text = t
                                                    .toplamTaksit
                                                    .toStringAsFixed(2);
                                                final kredi = krediler
                                                    .firstWhere(
                                                      (k) =>
                                                          k.id ==
                                                          selectedKrediId,
                                                    );
                                                aciklamaController.text =
                                                    '${kredi.bankaAd} - Taksit ${t.periyot}';
                                              }),
                                        ),
                                        title: Text(
                                          'Taksit ${t.periyot} - ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(t.toplamTaksit)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                gecikmisMi ? Colors.red : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Vade: ${DateFormat('dd.MM.yyyy').format(vadeTarihi)}${gecikmisMi ? ' (Gecikmiş!)' : ''}',
                                          style: TextStyle(
                                            color:
                                                gecikmisMi ? Colors.red : null,
                                          ),
                                        ),
                                        onTap:
                                            () => setModalState(() {
                                              selectedTaksitId = t.id;
                                              tutarController.text = t
                                                  .toplamTaksit
                                                  .toStringAsFixed(2);
                                              final kredi = krediler.firstWhere(
                                                (k) => k.id == selectedKrediId,
                                              );
                                              aciklamaController.text =
                                                  '${kredi.bankaAd} - Taksit ${t.periyot}';
                                            }),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (selectedKrediId != null && taksitler.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Bu kredinin tüm taksitleri ödenmiş!',
                                      ),
                                    ],
                                  ),
                                ),
                            ],

                            // Transfer modu için kasalar
                            if (islemModu == 'transfer') ...[
                              if (provider.kasalar.length < 2)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Transfer için en az 2 kasa tanımlanmalıdır. Ayarlar > Kasa bölümünden ekleyin.',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: selectedKasa,
                                        decoration: const InputDecoration(
                                          labelText: 'Kaynak Kasa *',
                                          border: OutlineInputBorder(),
                                        ),
                                        items:
                                            provider.kasalar
                                                .map(
                                                  (k) => DropdownMenuItem(
                                                    value: k,
                                                    child: Text(k),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged:
                                            (v) => setModalState(
                                              () => selectedKasa = v,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: hedefKasa,
                                        decoration: const InputDecoration(
                                          labelText: 'Hedef Kasa *',
                                          border: OutlineInputBorder(),
                                        ),
                                        items:
                                            provider.kasalar
                                                .where((k) => k != selectedKasa)
                                                .map(
                                                  (k) => DropdownMenuItem(
                                                    value: k,
                                                    child: Text(k),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged:
                                            (v) => setModalState(
                                              () => hedefKasa = v,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                            ],

                            // Döviz modu için para birimleri
                            if (islemModu == 'doviz') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedParaBirimi,
                                      decoration: const InputDecoration(
                                        labelText: 'Satılacak',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'EUR',
                                          child: Text('€ EUR'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'USD',
                                          child: Text('\$ USD'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'TL',
                                          child: Text('₺ TL'),
                                        ),
                                      ],
                                      onChanged:
                                          (v) => setModalState(
                                            () => selectedParaBirimi = v!,
                                          ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.swap_horiz,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: hedefParaBirimi,
                                      decoration: const InputDecoration(
                                        labelText: 'Alınacak',
                                        border: OutlineInputBorder(),
                                      ),
                                      items:
                                          ['TL', 'EUR', 'USD']
                                              .where(
                                                (p) => p != selectedParaBirimi,
                                              )
                                              .map(
                                                (p) => DropdownMenuItem(
                                                  value: p,
                                                  child: Text(
                                                    p == 'TL'
                                                        ? '₺ TL'
                                                        : p == 'EUR'
                                                        ? '€ EUR'
                                                        : '\$ USD',
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (v) => setModalState(
                                            () => hedefParaBirimi = v!,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Güncel Kur: 1 EUR = ${_eurTryRate.toStringAsFixed(2)} TL, 1 USD = ${_usdTryRate.toStringAsFixed(2)} TL',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Normal modlarda kasa seçimi
                            if (islemModu != 'transfer') ...[
                              // Para Birimi ve Tutar
                              Row(
                                children: [
                                  if (islemModu != 'doviz')
                                    SizedBox(
                                      width: 110,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedParaBirimi,
                                        decoration: const InputDecoration(
                                          labelText: 'Birim',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 16,
                                          ),
                                        ),
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'TL',
                                            child: Text('₺ TL'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'EUR',
                                            child: Text('€ EUR'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'USD',
                                            child: Text('\$ USD'),
                                          ),
                                        ],
                                        onChanged:
                                            (v) => setModalState(
                                              () => selectedParaBirimi = v!,
                                            ),
                                      ),
                                    ),
                                  if (islemModu != 'doviz')
                                    const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: tutarController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText:
                                            islemModu == 'doviz'
                                                ? 'Satılacak Miktar *'
                                                : 'Tutar *',
                                        border: const OutlineInputBorder(),
                                        prefixText:
                                            islemModu == 'doviz'
                                                ? (selectedParaBirimi == 'EUR'
                                                    ? '€ '
                                                    : selectedParaBirimi ==
                                                        'USD'
                                                    ? '\$ '
                                                    : '₺ ')
                                                : null,
                                      ),
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Transfer modunda tutar
                            if (islemModu == 'transfer') ...[
                              TextField(
                                controller: tutarController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Transfer Tutarı *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ],

                            // TL Karşılığı göster
                            if (islemModu != 'doviz' &&
                                selectedParaBirimi != 'TL' &&
                                calculatedTlKarsiligi != null &&
                                calculatedTlKarsiligi > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TL Karşılığı: ₺${NumberFormat('#,##0.00', 'tr_TR').format(calculatedTlKarsiligi)} (Kur: ${selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate})',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Normal modlarda kasa seçimi (transfer hariç)
                            if (islemModu != 'transfer')
                              provider.kasalar.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Lütfen önce Ayarlar > Kasa bölümünden kasa tanımlayın.',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: selectedKasa,
                                      decoration: const InputDecoration(
                                        labelText: 'Kasa *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.account_balance_wallet,
                                        ),
                                      ),
                                      items:
                                          provider.kasalar
                                              .map(
                                                (k) => DropdownMenuItem(
                                                  value: k,
                                                  child: Text(k),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (v) =>
                                              setModalState(() => selectedKasa = v),
                                    ),

                            const SizedBox(height: 16),

                            // Ödeme Şekli (döviz ve transfer hariç)
                            if (islemModu != 'doviz' &&
                                islemModu != 'transfer') ...[
                              const Text(
                                'Ödeme Şekli',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildOdemeChip(
                                    'Nakit',
                                    '💵',
                                    selectedOdemeBicimi,
                                    (v) => setModalState(
                                      () => selectedOdemeBicimi = v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildOdemeChip(
                                    'Kart',
                                    '💳',
                                    selectedOdemeBicimi,
                                    (v) => setModalState(
                                      () => selectedOdemeBicimi = v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildOdemeChip(
                                    'Havale',
                                    '🏦',
                                    selectedOdemeBicimi,
                                    (v) => setModalState(
                                      () => selectedOdemeBicimi = v,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // İşlem Ücreti
                              Row(
                                children: [
                                  Checkbox(
                                    value: islemUcretiAktif,
                                    onChanged:
                                        (v) => setModalState(
                                          () => islemUcretiAktif = v ?? false,
                                        ),
                                  ),
                                  const Text('İşlem ücreti var'),
                                  if (islemUcretiAktif) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: islemUcretiController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Ücret (TL)',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Açıklama
                            TextField(
                              controller: aciklamaController,
                              decoration: const InputDecoration(
                                labelText: 'Açıklama *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Tarih
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setModalState(() => selectedDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tarih *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                    'tr_TR',
                                  ).format(selectedDate),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Notlar
                            TextField(
                              controller: notlarController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Notlar',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Fiş Görseli Ekleme
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long, color: Colors.teal.shade600),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Fiş / Fatura Görseli',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      if (fisUrl != null && fisUrl!.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () {
                                            setModalState(() => fisUrl = null);
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (fisYukleniyor)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (fisUrl != null && fisUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        fisUrl!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Container(
                                          height: 100,
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(Icons.broken_image, size: 40),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              final picker = ImagePicker();
                                              final image = await picker.pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 1200,
                                                imageQuality: 80,
                                              );
                                              if (image != null) {
                                                setModalState(() => fisYukleniyor = true);
                                                try {
                                                  final bytes = await image.readAsBytes();
                                                  final fisService = FisStorageService();
                                                  final url = await fisService.uploadFisGorseli(bytes, fileName: image.name);
                                                  setModalState(() {
                                                    fisUrl = url;
                                                    fisYukleniyor = false;
                                                  });
                                                } catch (e) {
                                                  setModalState(() => fisYukleniyor = false);
                                                  if (ctx.mounted) {
                                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                                      SnackBar(content: Text('Yükleme hatası: $e')),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.camera_alt),
                                            label: const Text('Kamera'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              final picker = ImagePicker();
                                              final image = await picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1200,
                                                imageQuality: 80,
                                              );
                                              if (image != null) {
                                                setModalState(() => fisYukleniyor = true);
                                                try {
                                                  final bytes = await image.readAsBytes();
                                                  final fisService = FisStorageService();
                                                  final url = await fisService.uploadFisGorseli(bytes, fileName: image.name);
                                                  setModalState(() {
                                                    fisUrl = url;
                                                    fisYukleniyor = false;
                                                  });
                                                } catch (e) {
                                                  setModalState(() => fisYukleniyor = false);
                                                  if (ctx.mounted) {
                                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                                      SnackBar(content: Text('Yükleme hatası: $e')),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.photo_library),
                                            label: const Text('Galeri'),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Kaydet
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed:
                                    () => _handleSaveIslem(
                                      ctx: ctx,
                                      provider: provider,
                                      isEdit: isEdit,
                                      hareket: hareket,
                                      islemModu: islemModu,
                                      islemTipi: islemTipi,
                                      islemKaynagi: islemKaynagi,
                                      tutarController: tutarController,
                                      aciklamaController: aciklamaController,
                                      notlarController: notlarController,
                                      islemUcretiController:
                                          islemUcretiController,
                                      selectedKasa: selectedKasa,
                                      hedefKasa: hedefKasa,
                                      selectedParaBirimi: selectedParaBirimi,
                                      hedefParaBirimi: hedefParaBirimi,
                                      selectedOdemeBicimi: selectedOdemeBicimi,
                                      selectedGundelikciId:
                                          selectedGundelikciId,
                                      selectedKrediId: selectedKrediId,
                                      selectedTaksitId: selectedTaksitId,
                                      selectedDate: selectedDate,
                                      islemUcretiAktif: islemUcretiAktif,
                                      fisUrl: fisUrl,
                                    ),
                                child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Future<void> _handleSaveIslem({
    required BuildContext ctx,
    required AppProvider provider,
    required bool isEdit,
    KasaHareketi? hareket,
    required String islemModu,
    required String islemTipi,
    required String islemKaynagi,
    required TextEditingController tutarController,
    required TextEditingController aciklamaController,
    required TextEditingController notlarController,
    required TextEditingController islemUcretiController,
    String? selectedKasa,
    String? hedefKasa,
    required String selectedParaBirimi,
    required String hedefParaBirimi,
    String? selectedOdemeBicimi,
    int? selectedGundelikciId,
    int? selectedKrediId,
    int? selectedTaksitId,
    required DateTime selectedDate,
    required bool islemUcretiAktif,
    String? fisUrl,
  }) async {
    final tutar = double.tryParse(tutarController.text.replaceAll(',', '.'));

    // Validasyonlar
    if (tutar == null || tutar <= 0) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Geçerli tutar girin')));
      return;
    }
    if (aciklamaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Açıklama girin')));
      return;
    }
    // Kasa boşsa engelle (transfer hariç diğer modlar için)
    if (islemModu != 'transfer' && selectedKasa == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Lütfen önce Ayarlar bölümünden kasa tanımlayın')),
      );
      return;
    }
    if (islemModu == 'transfer') {
      if (selectedKasa == null || hedefKasa == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Kaynak ve hedef kasa seçin')),
        );
        return;
      }
      if (selectedKasa == hedefKasa) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Kaynak ve hedef kasa aynı olamaz')),
        );
        return;
      }
    } else if (selectedKasa == null) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Kasa seçin')));
      return;
    }
    if (islemKaynagi == 'gider_pusulasi' && selectedGundelikciId == null) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Çalışan seçin')));
      return;
    }
    if (islemKaynagi == 'kredi_odeme' &&
        (selectedKrediId == null || selectedTaksitId == null)) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Kredi ve taksit seçin')));
      return;
    }

    double? tlKarsiligi;
    double? dovizKuru;
    if (selectedParaBirimi != 'TL') {
      dovizKuru = selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate;
      tlKarsiligi = tutar * dovizKuru;
    }

    // Transfer işlemi
    if (islemModu == 'transfer') {
      // Çıkış kaydı
      final cikis = KasaHareketi(
        tarih: selectedDate,
        islemTipi: 'Çıkış',
        tutar: tutar,
        aciklama:
            '${aciklamaController.text.trim().isEmpty ? 'Transfer' : aciklamaController.text.trim()} → $hedefKasa',
        kasa: selectedKasa,
        notlar:
            notlarController.text.trim().isEmpty
                ? null
                : notlarController.text.trim(),
        paraBirimi: 'TL',
        islemKaynagi: 'transfer',
      );
      await provider.addKasaHareketi(cikis);

      // Giriş kaydı
      final giris = KasaHareketi(
        tarih: selectedDate,
        islemTipi: 'Giriş',
        tutar: tutar,
        aciklama:
            '${aciklamaController.text.trim().isEmpty ? 'Transfer' : aciklamaController.text.trim()} ← $selectedKasa',
        kasa: hedefKasa,
        notlar:
            notlarController.text.trim().isEmpty
                ? null
                : notlarController.text.trim(),
        paraBirimi: 'TL',
        islemKaynagi: 'transfer',
      );
      await provider.addKasaHareketi(giris);

      if (ctx.mounted) Navigator.pop(ctx);
      return;
    }

    // Döviz bozdurma işlemi
    if (islemModu == 'doviz') {
      final kur = selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate;
      final hedefKur =
          hedefParaBirimi == 'EUR'
              ? _eurTryRate
              : hedefParaBirimi == 'USD'
              ? _usdTryRate
              : 1.0;
      final tlTutar = tutar * kur;
      final hedefTutar = tlTutar / hedefKur;

      // Çıkış (satılan döviz)
      final cikis = KasaHareketi(
        tarih: selectedDate,
        islemTipi: 'Çıkış',
        tutar: tutar,
        aciklama: 'Döviz Bozdurma: $selectedParaBirimi → $hedefParaBirimi',
        kasa: selectedKasa,
        paraBirimi: selectedParaBirimi,
        dovizKuru: kur,
        tlKarsiligi: tlTutar,
        islemKaynagi: 'doviz_bozdurma',
      );
      await provider.addKasaHareketi(cikis);

      // Giriş (alınan para)
      final giris = KasaHareketi(
        tarih: selectedDate,
        islemTipi: 'Giriş',
        tutar: hedefTutar,
        aciklama: 'Döviz Bozdurma: $selectedParaBirimi → $hedefParaBirimi',
        kasa: selectedKasa,
        paraBirimi: hedefParaBirimi,
        dovizKuru: hedefKur,
        tlKarsiligi: tlTutar,
        islemKaynagi: 'doviz_bozdurma',
      );
      await provider.addKasaHareketi(giris);

      if (ctx.mounted) Navigator.pop(ctx);
      return;
    }

    // Normal işlem veya kredi ödemesi
    final newHareket = KasaHareketi(
      id: hareket?.id,
      tarih: selectedDate,
      islemTipi: islemModu == 'giris' ? 'Giriş' : 'Çıkış',
      tutar: tutar,
      aciklama: aciklamaController.text.trim(),
      kasa: selectedKasa,
      odemeBicimi: selectedOdemeBicimi,
      notlar:
          notlarController.text.trim().isEmpty
              ? null
              : notlarController.text.trim(),
      paraBirimi: selectedParaBirimi,
      dovizKuru: dovizKuru,
      tlKarsiligi: tlKarsiligi,
      islemKaynagi: islemKaynagi,
      iliskiliId:
          islemKaynagi == 'gider_pusulasi'
              ? selectedGundelikciId
              : (islemKaynagi == 'kredi_odeme' ? selectedTaksitId : null),
      fisUrl: fisUrl,
    );

    if (isEdit) {
      await provider.updateKasaHareketi(newHareket);
    } else {
      await provider.addKasaHareketi(newHareket);
    }

    // Kredi taksiti ödendi olarak işaretle
    if (islemKaynagi == 'kredi_odeme' && selectedTaksitId != null && !isEdit) {
      await provider.taksitOde(
        selectedKrediId!,
        selectedTaksitId,
        selectedDate,
      );
    }

    // İşlem ücreti kaydı
    if (islemUcretiAktif && !isEdit) {
      final islemUcreti =
          double.tryParse(islemUcretiController.text.replaceAll(',', '.')) ?? 0;
      if (islemUcreti > 0) {
        final ucretKaydi = KasaHareketi(
          tarih: selectedDate,
          islemTipi: 'Çıkış',
          tutar: islemUcreti,
          aciklama: 'İşlem Ücreti: ${aciklamaController.text.trim()}',
          kasa: selectedKasa,
          paraBirimi: 'TL',
          islemKaynagi: 'islem_ucreti',
        );
        await provider.addKasaHareketi(ucretKaydi);
      }
    }

    if (ctx.mounted) Navigator.pop(ctx);
  }

  Widget _buildOdemeChip(
    String label,
    String emoji,
    String? selected,
    Function(String?) onTap,
  ) {
    final isSelected = selected == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(isSelected ? null : label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
