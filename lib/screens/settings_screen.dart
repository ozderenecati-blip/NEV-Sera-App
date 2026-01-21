import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/settings.dart';
import '../models/ortak.dart';
import 'raporlar_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
        title: const Text('Ayarlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Kasalar', icon: Icon(Icons.account_balance)),
            Tab(text: 'Raporlar', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Genel', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKasalarTab(),
          const RaporlarContent(),
          _buildGeneralTab(),
        ],
      ),
    );
  }
  
  Widget _buildKasalarTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<List<AppSettings>>(
          future: provider.getSettingsList('kasa'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final items = snapshot.data!;
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('${items.length} Kasa', style: TextStyle(color: Colors.grey.shade600)),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Kasa'),
                        onPressed: () => _showAddKasaDialog(),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('Henüz Kasa eklenmedi', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(item.deger),
                            subtitle: item.ortakId != null 
                                ? _buildOrtakSubtitle(provider, item.ortakId!)
                                : const Text('Şahıs atanmadı', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditKasaDialog(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteConfirmation(item, provider),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildGeneralTab() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Tema'),
                    subtitle: Text(themeProvider.themeMode == ThemeMode.system 
                        ? 'Sistem' 
                        : themeProvider.themeMode == ThemeMode.dark ? 'Koyu' : 'Açık'),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto)),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (Set<ThemeMode> selected) {
                        themeProvider.setTheme(selected.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Uygulama Hakkında'),
                    subtitle: Text('NEV Seracılık v1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Veri Yedekleme'),
                    subtitle: const Text('Veritabanını yedekle'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yedekleme özelliği yakında eklenecek')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Veri Geri Yükleme'),
                    subtitle: const Text('Yedekten geri yükle'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Geri yükleme özelliği yakında eklenecek')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade700),
                title: Text('Çıkış Yap', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                subtitle: Text('Oturumu kapat', style: TextStyle(color: Colors.red.shade400)),
                trailing: Icon(Icons.chevron_right, color: Colors.red.shade700),
                onTap: () => _showLogoutDialog(),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('rememberMe');
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showAddKasaDialog() {
    final controller = TextEditingController();
    int? selectedOrtakId;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final ortaklar = provider.ortaklar;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Yeni Kasa Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Kasa Adı',
                  hintText: 'Örn: Necati, AveA, Nev Seracılık',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: selectedOrtakId,
                decoration: const InputDecoration(
                  labelText: 'Bağlı Ortak/Şahıs',
                  prefixIcon: Icon(Icons.person),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Seçiniz (Şirket kasası)'),
                  ),
                  ...ortaklar.map((ortak) => DropdownMenuItem<int?>(
                    value: ortak.id,
                    child: Text(ortak.adSoyad),
                  )),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedOrtakId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await provider.addSettingWithOrtak('kasa', controller.text.trim(), selectedOrtakId);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    setState(() {});
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditKasaDialog(AppSettings item) {
    final controller = TextEditingController(text: item.deger);
    int? selectedOrtakId = item.ortakId;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final ortaklar = provider.ortaklar;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kasa Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Kasa Adı'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: selectedOrtakId,
                decoration: const InputDecoration(
                  labelText: 'Bağlı Ortak/Şahıs',
                  prefixIcon: Icon(Icons.person),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Seçiniz (Şirket kasası)'),
                  ),
                  ...ortaklar.map((ortak) => DropdownMenuItem<int?>(
                    value: ortak.id,
                    child: Text(ortak.adSoyad),
                  )),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedOrtakId = value;
                  });
                },
              ),
              if (selectedOrtakId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Bu kasadaki bakiye bu ortağa ait olarak işaretlenecek.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  final updatedSetting = AppSettings(
                    id: item.id,
                    tip: item.tip,
                    deger: controller.text.trim(),
                    ortakId: selectedOrtakId,
                  );
                  await provider.updateSetting(updatedSetting);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    setState(() {});
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(AppSettings item, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text('"${item.deger}" öğesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteSetting(item.id!);
              if (context.mounted) {
                Navigator.of(context).pop();
                setState(() {});
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrtakSubtitle(AppProvider provider, int ortakId) {
    final ortak = provider.ortaklar.where((o) => o.id == ortakId).firstOrNull;
    if (ortak == null) {
      return const Text('Ortak bulunamadı', style: TextStyle(color: Colors.orange, fontSize: 12));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person, size: 14, color: Colors.blue),
        const SizedBox(width: 4),
        Text(ortak.adSoyad, style: const TextStyle(color: Colors.blue, fontSize: 12)),
      ],
    );
  }
}
