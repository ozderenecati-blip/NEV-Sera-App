import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/bahce.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/operasyon_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> _users = [];
  List<Bahce> _bahceler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await context.read<AuthProvider>().getUsers();
    final bahceler = await OperasyonService().getBahceler();
    setState(() {
      _users = users;
      _bahceler = bahceler;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: ThemeProvider.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Kullanıcı'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Henüz kullanıcı yok', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildUserCard(user, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildUserCard(AppUser user, int index) {
    final roleColor = _getRoleColor(user.rol);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: roleColor.withOpacity(0.15),
          child: Icon(_getRoleIconData(user.rol), color: roleColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.adSoyad,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: user.aktif ? null : Colors.grey,
                  decoration: user.aktif ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (!user.aktif)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pasif',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${user.kullaniciAdi}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user.rolLabel,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (user.atanmisBahceler.isNotEmpty) ...[              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: user.atanmisBahceler.map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('🌿 ${b['ad']}', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                )).toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showUserDialog(user: user);
                break;
              case 'password':
                _showChangePasswordDialog(user);
                break;
              case 'deactivate':
                _showDeactivateDialog(user);
                break;
              case 'activate':
                _showActivateDialog(user);
                break;
              case 'delete':
                _showDeleteUserDialog(user);
                break;
            }
          },
          itemBuilder: (context) {
            final currentUserId = context.read<AuthProvider>().currentUser?.id;
            final isSelf = user.id == currentUserId;
            return [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Düzenle'))),
              const PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.lock_reset), title: Text('Şifre Değiştir'))),
              if (user.aktif)
                const PopupMenuItem(value: 'deactivate', child: ListTile(leading: Icon(Icons.person_off, color: Colors.orange), title: Text('Pasif Yap', style: TextStyle(color: Colors.orange)))),
              if (!user.aktif)
                const PopupMenuItem(value: 'activate', child: ListTile(leading: Icon(Icons.person_add_alt_1, color: Color(0xFF059669)), title: Text('Aktif Yap', style: TextStyle(color: Color(0xFF059669))))),
              if (!isSelf)
                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Hesabı Sil', style: TextStyle(color: Colors.red)))),
            ];
          },
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.05, end: 0);
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF7C3AED);
      case UserRole.operasyonYoneticisi:
        return const Color(0xFFD97706);
      case UserRole.calisan:
        return const Color(0xFF2563EB);
    }
  }

  IconData _getRoleIconData(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.operasyonYoneticisi:
        return Icons.agriculture;
      case UserRole.calisan:
        return Icons.person;
    }
  }

  void _showUserDialog({AppUser? user}) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.adSoyad ?? '');
    final usernameController = TextEditingController(text: user?.kullaniciAdi ?? '');
    final passwordController = TextEditingController(text: user?.sifre ?? '');
    UserRole selectedRole = user?.rol ?? UserRole.calisan;
    List<Map<String, String>> seciliBahceler = user != null
        ? List<Map<String, String>>.from(user.atanmisBahceler)
        : [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Kullanıcıyı Düzenle' : 'Yeni Kullanıcı'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  enabled: !isEdit,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: isEdit ? 'Kullanıcı adı değiştirilemez' : null,
                  ),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: const Icon(Icons.security),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(_getRoleLabel(role)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRole = value);
                    }
                  },
                ),
                // Bahçe ataması
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Atanmış Bahçeler',
                    prefixIcon: const Icon(Icons.park, color: Color(0xFFD97706)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _bahceler.isEmpty
                      ? const Text('Henüz bahçe yok', style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _bahceler.map((b) {
                            final isSelected = seciliBahceler.any((sb) => sb['id'] == b.id);
                            return FilterChip(
                              selected: isSelected,
                              label: Text(b.ad, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : null)),
                              selectedColor: const Color(0xFFD97706),
                              checkmarkColor: Colors.white,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    seciliBahceler.add({'id': b.id ?? '', 'ad': b.ad});
                                  } else {
                                    seciliBahceler.removeWhere((sb) => sb['id'] == b.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ad Soyad ve Kullanıcı Adı zorunlu')),
                  );
                  return;
                }
                if (!isEdit && passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre zorunlu')),
                  );
                  return;
                }

                final authProvider = context.read<AuthProvider>();
                bool success;

                if (isEdit) {
                  success = await authProvider.updateUser(
                    user.copyWith(
                      adSoyad: nameController.text.trim(),
                      rol: selectedRole,
                      atanmisBahceler: seciliBahceler,
                    ),
                  );
                } else {
                  success = await authProvider.addUser(
                    AppUser(
                      kullaniciAdi: usernameController.text.trim().toLowerCase(),
                      sifre: passwordController.text.trim(),
                      adSoyad: nameController.text.trim(),
                      rol: selectedRole,
                      atanmisBahceler: seciliBahceler,
                    ),
                  );
                }

                if (success && ctx.mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Kullanıcı güncellendi' : 'Kullanıcı eklendi')),
                  );
                } else if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Güncelleme başarısız' : 'Bu kullanıcı adı zaten kullanılıyor'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeProvider.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(AppUser user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Şifre Değiştir: ${user.adSoyad}'),
        content: TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: 'Yeni Şifre',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.trim().isEmpty) return;
              final success = await context.read<AuthProvider>().changePassword(
                user.id!,
                passwordController.text.trim(),
              );
              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifre değiştirildi')),
                );
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeProvider.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Deaktif Et'),
        content: Text('${user.adSoyad} kullanıcısını deaktif etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<AuthProvider>().deactivateUser(user.id!);
              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kullanıcı deaktif edildi')),
                );
              }
            },
            child: const Text('Deaktif Et', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showActivateDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Aktif Et'),
        content: Text('${user.adSoyad} kullanıcısını tekrar aktif etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<AuthProvider>().activateUser(user.id!);
              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.adSoyad} tekrar aktif edildi ✓'), backgroundColor: const Color(0xFF059669)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            child: const Text('Aktif Et'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(AppUser user) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendinizi silemezsiniz!'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber, color: Colors.red, size: 28),
          const SizedBox(width: 8),
          const Text('Hesabı Sil'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${user.adSoyad} (@${user.kullaniciAdi}) kullanıcısını tamamen silmek istediğinize emin misiniz?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Bu işlem geri alınamaz! Kullanıcının mevcut görev ve raporları korunur.', style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<AuthProvider>().deleteUser(user.id!);
              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.adSoyad} hesabı silindi'), backgroundColor: Colors.red),
                );
              } else if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Silme işlemi başarısız'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin (Ortak)';
      case UserRole.operasyonYoneticisi:
        return 'Operasyon Yöneticisi';
      case UserRole.calisan:
        return 'Çalışan';
    }
  }
}
