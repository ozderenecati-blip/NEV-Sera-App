import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/app_user.dart';
import '../widgets/modern_widgets.dart';
import 'home_screen.dart';
import 'operasyon_home_screen.dart';
import 'login_screen.dart';
import 'user_management_screen.dart';

class ModuleSelectionScreen extends StatelessWidget {
  const ModuleSelectionScreen({super.key});

  void _showSettingsSheet(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.settings, color: ThemeProvider.primaryColor),
                    const SizedBox(width: 10),
                    Text('Ayarlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : null)),
                  ],
                ),
                const SizedBox(height: 24),
                // Tema seçimi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tema', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : null)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildThemeChip(ctx, themeProvider, ThemeMode.light, 'Açık', Icons.light_mode, setModalState),
                    const SizedBox(width: 8),
                    _buildThemeChip(ctx, themeProvider, ThemeMode.dark, 'Koyu', Icons.dark_mode, setModalState),
                    const SizedBox(width: 8),
                    _buildThemeChip(ctx, themeProvider, ThemeMode.system, 'Sistem', Icons.settings_suggest, setModalState),
                  ],
                ),
                const SizedBox(height: 24),
                // Yazı boyutu
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Yazı Boyutu: ${(themeProvider.textScale * 100).round()}%',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : null),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Expanded(
                      child: Slider(
                        value: themeProvider.textScale,
                        min: 0.8,
                        max: 1.3,
                        divisions: 10,
                        activeColor: ThemeProvider.primaryColor,
                        label: '${(themeProvider.textScale * 100).round()}%',
                        onChanged: (v) {
                          themeProvider.setTextScale(v);
                          setModalState(() {});
                        },
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Örnek metin — Bu yazının boyutunu ayarlayabilirsiniz',
                    style: TextStyle(fontSize: 14 * themeProvider.textScale, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeChip(BuildContext context, ThemeProvider provider, ThemeMode mode, String label, IconData icon, StateSetter setModalState) {
    final selected = provider.themeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          provider.setTheme(mode);
          setModalState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? ThemeProvider.primaryColor.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF374151) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? ThemeProvider.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? ThemeProvider.primaryColor : (isDark ? Colors.grey.shade400 : Colors.grey.shade500), size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? ThemeProvider.primaryColor : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeProvider.primaryColor,
              ThemeProvider.primaryDark,
              const Color(0xFF065F46),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, user),
              const SizedBox(height: 20),
              Expanded(
                child: _buildModuleGrid(context, user, authProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.adSoyad.isNotEmpty ? user.adSoyad[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş Geldin, ${user.adSoyad}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.rolLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSettingsSheet(context),
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Ayarlar',
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Oturumunuzu kapatmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildModuleGrid(BuildContext context, AppUser user, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modüller',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),

          // Finans Modülü (sadece admin)
          if (authProvider.canAccessFinans)
            _buildModuleCard(
              context: context,
              title: 'Finans',
              subtitle: 'Kasa, Kredi, Gider Pusulası,\nOrtaklar, Müşteriler, Raporlar',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF059669),
              delay: 300,
              onTap: () {
                HapticHelper.mediumTap();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const HomeScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
            ),

          if (authProvider.canAccessFinans) const SizedBox(height: 16),

          // Operasyon Modülü (herkes erişebilir)
          if (authProvider.canAccessOperasyon)
            _buildModuleCard(
              context: context,
              title: 'Operasyon',
              subtitle: 'Bahçe Yönetimi, Görevler,\nGünlük İş Raporları',
              icon: Icons.agriculture,
              color: const Color(0xFFD97706),
              delay: 500,
              onTap: () {
                HapticHelper.mediumTap();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const OperasyonHomeScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
            ),

          // Admin: Kullanıcı Yönetimi
          if (authProvider.canManageUsers) ...[
            const SizedBox(height: 16),
            _buildModuleCard(
              context: context,
              title: 'Kullanıcı Yönetimi',
              subtitle: 'Kullanıcı ekle, düzenle,\nşifre değiştir, rol ata',
              icon: Icons.admin_panel_settings,
              color: const Color(0xFF7C3AED),
              delay: 700,
              onTap: () {
                HapticHelper.mediumTap();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.1, end: 0);
  }
}
