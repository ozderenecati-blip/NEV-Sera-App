import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/yaklasan_odeme.dart';
import '../models/kasa_hareketi.dart';
import '../widgets/modern_widgets.dart';
import 'kasa_screen.dart';
import 'kredi_screen.dart';
import 'raporlar_screen.dart';
import 'settings_screen.dart';
import 'gider_pusulasi_screen.dart';
import 'ortaklar_screen.dart';
import 'musteriler_screen.dart';
import 'vergi_rapor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardTab(onNavigateToData: () => _navigateToTab(2)),
      const KrediScreen(),
      const KasaScreen(),
      const GiderPusulasiScreen(),
      const OrtaklarScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? ThemeProvider.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              HapticHelper.lightTap();
              setState(() {
                _selectedIndex = index;
              });
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 70,
            backgroundColor: Colors.transparent,
            indicatorColor: ThemeProvider.primaryColor.withOpacity(0.15),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined, size: 24),
                selectedIcon: Icon(Icons.dashboard, size: 24, color: ThemeProvider.primaryColor),
                label: 'Özet',
              ),
              NavigationDestination(
                icon: const Icon(Icons.credit_card_outlined, size: 24),
                selectedIcon: Icon(Icons.credit_card, size: 24, color: ThemeProvider.primaryColor),
                label: 'Krediler',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ThemeProvider.primaryColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet, size: 24, color: Colors.white),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ThemeProvider.primaryColor.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet, size: 24, color: Colors.white),
                ),
                label: 'Data',
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined, size: 24),
                selectedIcon: Icon(Icons.receipt_long, size: 24, color: ThemeProvider.primaryColor),
                label: 'G. Pusulası',
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outlined, size: 24),
                selectedIcon: Icon(Icons.people, size: 24, color: ThemeProvider.primaryColor),
                label: 'Ortaklar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final VoidCallback onNavigateToData;

  const DashboardTab({super.key, required this.onNavigateToData});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco,
                color: ThemeProvider.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('NEV Seracılık'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticHelper.lightTap();
              context.read<AppProvider>().loadAllData();
            },
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: () {
              HapticHelper.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MusterilerScreen()),
              );
            },
            tooltip: 'Müşteriler',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              HapticHelper.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VergiRaporScreen()),
              );
            },
            tooltip: 'Vergi & Beyanname',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              HapticHelper.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SkeletonListLoader(itemCount: 4);
          }

          return PullToRefreshWrapper(
            onRefresh: () => provider.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // YAKLAŞAN ÖDEMELER
                  _buildYaklasanOdemeler(context, provider, currencyFormat)
                      .animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 12),

                  // KASA BAKİYELERİ
                  _buildKasaBakiyeleri(context, provider, currencyFormat)
                      .animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.05, end: 0),

                  const SizedBox(height: 12),

                  // GİDER PUSULASI ÖZET
                  _buildGiderPusulasiOzet(context, provider, currencyFormat)
                      .animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 12),

                  // KREDİ ÖZET
                  _buildKrediOzet(context, provider, currencyFormat)
                      .animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.05, end: 0),

                  const SizedBox(height: 12),

                  // CARİ / ALACAK ÖZET
                  _buildCariOzet(context, provider, currencyFormat)
                      .animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 12),

                  // SON İŞLEMLER
                  _buildSonIslemler(context, provider, currencyFormat)
                      .animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYaklasanOdemeler(
    BuildContext context,
    AppProvider provider,
    NumberFormat fmt,
  ) {
    final bekleyenler = provider.bekleyenOdemeler;
    final yakinOdemeler =
        bekleyenler.where((o) => o.vadeKalanGun <= 7).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm, color: Colors.red),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Yaklaşan Ödemeler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _showAddOdemeDialog(context),
                  tooltip: 'Yeni Ödeme Ekle',
                ),
              ],
            ),
            if (yakinOdemeler.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '7 gün içinde ödeme yok',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...yakinOdemeler
                  .take(5)
                  .map((odeme) => _buildOdemeItem(context, odeme, fmt)),
            if (bekleyenler.length > 5)
              TextButton(
                onPressed: () => _showAllOdemeler(context, bekleyenler, fmt),
                child: Text('Tümünü Gör (${bekleyenler.length})'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOdemeItem(
    BuildContext context,
    YaklasanOdeme odeme,
    NumberFormat fmt,
  ) {
    Color bgColor;
    Color textColor;

    if (odeme.gecikmisMi) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
    } else if (odeme.bugunMu) {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
    } else if (odeme.yakinMi) {
      bgColor = Colors.yellow.shade100;
      textColor = Colors.orange.shade800;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  odeme.alacakli,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
                if (odeme.aciklama != null && odeme.aciklama!.isNotEmpty)
                  Text(
                    odeme.aciklama!,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                Text(
                  odeme.vadeDurumu,
                  style: TextStyle(fontSize: 11, color: textColor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${odeme.paraBirimiSembol}${fmt.format(odeme.tutar).replaceAll('₺', '').trim()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 13,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showOdemeKapatDialog(context, odeme),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _showEditOdemeDialog(context, odeme),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddOdemeDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final alacakliController = TextEditingController();
    final tutarController = TextEditingController();
    final aciklamaController = TextEditingController();
    String paraBirimi = 'TL';
    DateTime vadeTarihi = DateTime.now().add(const Duration(days: 7));
    int alarmGunOnce = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Container(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Yeni Ödeme Ekle',
                                style: TextStyle(
                                  fontSize: 18,
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
                          const SizedBox(height: 16),
                          TextField(
                            controller: alacakliController,
                            decoration: const InputDecoration(
                              labelText: 'Alacaklı (Kime ödenecek) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: DropdownButtonFormField<String>(
                                  initialValue: paraBirimi,
                                  decoration: const InputDecoration(
                                    labelText: 'Birim',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'TL',
                                      child: Text('₺'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'EUR',
                                      child: Text('€'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'USD',
                                      child: Text('\$'),
                                    ),
                                  ],
                                  onChanged:
                                      (v) =>
                                          setModalState(() => paraBirimi = v!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: tutarController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Tutar *',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: vadeTarihi,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setModalState(() => vadeTarihi = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Vade Tarihi *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                  'tr_TR',
                                ).format(vadeTarihi),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: aciklamaController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Açıklama / Not',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: alarmGunOnce,
                            decoration: const InputDecoration(
                              labelText: 'Hatırlatma',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Vade günü'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('1 gün önce'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('3 gün önce'),
                              ),
                              DropdownMenuItem(
                                value: 7,
                                child: Text('1 hafta önce'),
                              ),
                            ],
                            onChanged:
                                (v) => setModalState(() => alarmGunOnce = v!),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: () async {
                                final tutar = double.tryParse(
                                  tutarController.text.replaceAll(',', '.'),
                                );
                                if (alacakliController.text.trim().isEmpty ||
                                    tutar == null ||
                                    tutar <= 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Alacaklı ve tutar zorunlu',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final odeme = YaklasanOdeme(
                                  alacakli: alacakliController.text.trim(),
                                  tutar: tutar,
                                  paraBirimi: paraBirimi,
                                  vadeTarihi: vadeTarihi,
                                  aciklama:
                                      aciklamaController.text.trim().isEmpty
                                          ? null
                                          : aciklamaController.text.trim(),
                                  alarmGunOnce: alarmGunOnce,
                                );

                                await provider.addYaklasanOdeme(odeme);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Kaydet'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showEditOdemeDialog(BuildContext context, YaklasanOdeme odeme) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final alacakliController = TextEditingController(text: odeme.alacakli);
    final tutarController = TextEditingController(
      text: odeme.tutar.toStringAsFixed(2),
    );
    final aciklamaController = TextEditingController(
      text: odeme.aciklama ?? '',
    );
    String paraBirimi = odeme.paraBirimi;
    DateTime vadeTarihi = odeme.vadeTarihi;
    int alarmGunOnce = odeme.alarmGunOnce ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Container(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Ödeme Düzenle',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: ctx,
                                    builder:
                                        (c) => AlertDialog(
                                          title: const Text('Sil'),
                                          content: const Text(
                                            'Bu ödeme silinsin mi?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(c, false),
                                              child: const Text('İptal'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(c, true),
                                              child: const Text(
                                                'Sil',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    await provider.deleteYaklasanOdeme(
                                      odeme.id!,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: alacakliController,
                            decoration: const InputDecoration(
                              labelText: 'Alacaklı *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: DropdownButtonFormField<String>(
                                  initialValue: paraBirimi,
                                  decoration: const InputDecoration(
                                    labelText: 'Birim',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'TL',
                                      child: Text('₺'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'EUR',
                                      child: Text('€'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'USD',
                                      child: Text('\$'),
                                    ),
                                  ],
                                  onChanged:
                                      (v) =>
                                          setModalState(() => paraBirimi = v!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: tutarController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Tutar *',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: vadeTarihi,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setModalState(() => vadeTarihi = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Vade Tarihi *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                  'tr_TR',
                                ).format(vadeTarihi),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: aciklamaController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Açıklama / Not',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: alarmGunOnce,
                            decoration: const InputDecoration(
                              labelText: 'Hatırlatma',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Vade günü'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('1 gün önce'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('3 gün önce'),
                              ),
                              DropdownMenuItem(
                                value: 7,
                                child: Text('1 hafta önce'),
                              ),
                            ],
                            onChanged:
                                (v) => setModalState(() => alarmGunOnce = v!),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: () async {
                                final tutar = double.tryParse(
                                  tutarController.text.replaceAll(',', '.'),
                                );
                                if (alacakliController.text.trim().isEmpty ||
                                    tutar == null ||
                                    tutar <= 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Alacaklı ve tutar zorunlu',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final updated = odeme.copyWith(
                                  alacakli: alacakliController.text.trim(),
                                  tutar: tutar,
                                  paraBirimi: paraBirimi,
                                  vadeTarihi: vadeTarihi,
                                  aciklama:
                                      aciklamaController.text.trim().isEmpty
                                          ? null
                                          : aciklamaController.text.trim(),
                                  alarmGunOnce: alarmGunOnce,
                                );

                                await provider.updateYaklasanOdeme(updated);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Güncelle'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showOdemeKapatDialog(BuildContext context, YaklasanOdeme odeme) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    bool kasaKaydiOlustur = true;
    String? selectedKasa =
        provider.kasalar.isNotEmpty ? provider.kasalar.first : null;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Ödemeyi Kapat'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${odeme.alacakli} - ${odeme.paraBirimiSembol}${odeme.tutar.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: kasaKaydiOlustur,
                        onChanged:
                            (v) => setDialogState(
                              () => kasaKaydiOlustur = v ?? true,
                            ),
                        title: const Text('Kasa kaydı oluştur'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (kasaKaydiOlustur && provider.kasalar.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: selectedKasa,
                          decoration: const InputDecoration(
                            labelText: 'Kasa',
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
                              (v) => setDialogState(() => selectedKasa = v),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('İptal'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        KasaHareketi? kasaHareketi;
                        if (kasaKaydiOlustur && selectedKasa != null) {
                          kasaHareketi = KasaHareketi(
                            tarih: DateTime.now(),
                            islemTipi: 'Çıkış',
                            tutar: odeme.tutar,
                            paraBirimi: odeme.paraBirimi,
                            aciklama:
                                'Ödeme: ${odeme.alacakli}${odeme.aciklama != null ? ' - ${odeme.aciklama}' : ''}',
                            kasa: selectedKasa,
                            islemKaynagi: 'kasa',
                          );
                        }
                        await provider.odemeyiKapat(
                          odeme.id!,
                          kasaHareketi: kasaHareketi,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAllOdemeler(
    BuildContext context,
    List<YaklasanOdeme> odemeler,
    NumberFormat fmt,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            height: MediaQuery.of(ctx).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Tüm Bekleyen Ödemeler',
                        style: TextStyle(
                          fontSize: 18,
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: odemeler.length,
                    itemBuilder:
                        (_, i) => _buildOdemeItem(context, odemeler[i], fmt),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildKasaBakiyeleri(
    BuildContext context,
    AppProvider provider,
    NumberFormat fmt,
  ) {
    final bakiyeler = provider.kasaBakiyeleri;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Kasa Bakiyeleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onNavigateToData,
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bakiyeler.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Henüz işlem yok',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...bakiyeler.map((b) {
                final kasa = b['kasa'] as String? ?? 'Bilinmiyor';
                final bakiye = (b['bakiye'] as num?)?.toDouble() ?? 0.0;
                final giris = (b['toplam_giris'] as num?)?.toDouble() ?? 0.0;
                final cikis = (b['toplam_cikis'] as num?)?.toDouble() ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        bakiye >= 0
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          bakiye >= 0
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            bakiye >= 0
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                        child: Icon(
                          Icons.person,
                          color: bakiye >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kasa,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'G: ${fmt.format(giris)} | Ç: ${fmt.format(cikis)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fmt.format(bakiye),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: bakiye >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildGiderPusulasiOzet(
    BuildContext context,
    AppProvider provider,
    NumberFormat fmt,
  ) {
    final ozet = provider.gundelikciOzet;
    final toplamOdeme = ozet['toplam_odeme'] ?? 0.0;
    final kalanBorc = ozet['kalan_borc'] ?? 0.0;

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
                Text(
                  'Gider Pusulası',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Gündelikçi Ödemeleri',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(toplamOdeme),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Resmileştirilecek',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(kalanBorc),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kalanBorc > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
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

  Widget _buildOrtaklarOzet(
    BuildContext context,
    AppProvider provider,
    NumberFormat fmt,
  ) {
    final ozet = provider.ortakOzet;
    final toplamVerilen = ozet['toplam_verilen'] ?? 0.0;
    final kalanBorc = ozet['kalan_borc'] ?? 0.0;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrtaklarScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ortaklar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Ortakların Verdiği',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(toplamVerilen),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Kalan Borç',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(kalanBorc),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kalanBorc > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKrediOzet(
    BuildContext context,
    AppProvider provider,
    NumberFormat fmt,
  ) {
    final ozet = provider.krediOzet;
    final aktifKredi = (ozet['aktif_kredi'] ?? 0).toInt();
    final toplamBakiye = ozet['toplam_bakiye'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Krediler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Aktif Kredi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$aktifKredi',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Toplam Bakiye',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(toplamBakiye),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildSonIslemler(
    BuildContext context,
    AppProvider provider,
    NumberFormat fmt,
  ) {
    final sonIslemler = provider.kasaHareketleri.take(5).toList();
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Son İşlemler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onNavigateToData,
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sonIslemler.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Henüz işlem yok',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...sonIslemler.map(
                (h) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        h.islemTipi == 'Giriş'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    child: Icon(
                      h.islemTipi == 'Giriş'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: h.islemTipi == 'Giriş' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    h.aciklama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${dateFormat.format(h.tarih)} • ${h.kasa ?? ""} ${h.islemKaynagiLabel}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Text(
                    '${h.islemTipi == 'Giriş' ? '+' : '-'}${fmt.format(h.tutar)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: h.islemTipi == 'Giriş' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCariOzet(
    BuildContext context,
    AppProvider provider,
    NumberFormat fmt,
  ) {
    final cariOzet = provider.cariOzet;
    final toplamAlacak = (cariOzet['toplamAlacak'] as num?)?.toDouble() ?? 0;
    final musteriSayisi = cariOzet['musteriSayisi'] ?? 0;
    final toplamSatis = (cariOzet['toplamSatis'] as num?)?.toDouble() ?? 0;
    final toplamTahsilat = (cariOzet['toplamTahsilat'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.storefront, color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cari / Alacaklar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MusterilerScreen()),
                    );
                  },
                  child: const Text('Detay →'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Alacak',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(toplamAlacak),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: toplamAlacak > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Müşteri Sayısı',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$musteriSayisi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar gösterimi
            if (toplamSatis > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tahsilat Oranı',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${((toplamTahsilat / toplamSatis) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: toplamSatis > 0 ? toplamTahsilat / toplamSatis : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
