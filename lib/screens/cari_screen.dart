import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/cari.dart';

class CariScreen extends StatefulWidget {
  const CariScreen({super.key});

  @override
  State<CariScreen> createState() => _CariScreenState();
}

class _CariScreenState extends State<CariScreen> {
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cariler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () => _showCariDialog(context),
            tooltip: 'Yeni Cari',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cariler = provider.cariler;

          if (cariler.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_center_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Henüz cari hesap eklenmemiş', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCariDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Cariyi Ekle'),
                  ),
                ],
              ),
            );
          }

          // Genel özet
          double toplamBorcKalan = 0;
          double toplamAlacakKalan = 0;
          for (final c in cariler) {
            if (c.netBakiye > 0) toplamBorcKalan += c.netBakiye;
            if (c.netBakiye < 0) toplamAlacakKalan += c.netBakiye.abs();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadCariler(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Özet kartı
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business_center, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text('Cari Özet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text('Kalan Borcumuz', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text(fmt.format(toplamBorcKalan), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text('Kalan Alacağımız', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text(fmt.format(toplamAlacakKalan), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cari listesi
                ...cariler.map((c) => _buildCariCard(context, c, provider, fmt)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCariCard(BuildContext context, Cari cari, AppProvider provider, NumberFormat fmt) {
    final anlasmaList = provider.cariAnlasmalari.where((a) => a.cariId == cari.id).toList();
    final islemler = provider.kasaHareketleri.where((h) =>
        h.iliskiliId == cari.id &&
        (h.islemKaynagi == 'cari_odeme' || h.islemKaynagi == 'cari_tahsilat')).toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: cari.netBakiye > 0 ? Colors.red[100] : Colors.green[100],
          child: Text(
            cari.firmaAdi.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: cari.netBakiye > 0 ? Colors.red[800] : Colors.green[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(cari.firmaAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            if (cari.netBakiye > 0) ...[
              Icon(Icons.arrow_upward, size: 14, color: Colors.red[400]),
              Text(' Borcumuz: ${fmt.format(cari.netBakiye)}', style: TextStyle(fontSize: 12, color: Colors.red[600])),
            ],
            
            if (cari.netBakiye < 0) ...[
              Icon(Icons.arrow_downward, size: 14, color: Colors.green[400]),
              Text(' Alacağımız: ${fmt.format(cari.netBakiye.abs())}', style: TextStyle(fontSize: 12, color: Colors.green[600])),
            ],
            if (cari.netBakiye == 0)
              Text('Bakiye temiz ✓', style: TextStyle(fontSize: 12, color: Colors.green[600])),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bilgiler
                if (cari.yetkiliKisi != null) _buildInfoRow(Icons.person, 'Yetkili', cari.yetkiliKisi!),
                if (cari.telefon != null) _buildInfoRow(Icons.phone, 'Telefon', cari.telefon!),
                if (cari.vergiNo != null) _buildInfoRow(Icons.badge, 'Vergi No', cari.vergiNo!),

                const Divider(height: 24),

                // Anlaşmalar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Anlaşmalar', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Yeni Anlaşma'),
                      onPressed: () => _showAnlasmaDialog(context, cari),
                    ),
                  ],
                ),
                if (anlasmaList.isEmpty)
                  Text('Henüz anlaşma eklenmemiş', style: TextStyle(fontSize: 13, color: Colors.grey[500]))
                else
                  ...anlasmaList.map((a) {
                    final color = a.tip == 'borc' ? Colors.red : Colors.green;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(a.tip == 'borc' ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 20),
                      title: Text(a.baslik, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${DateFormat('dd.MM.yyyy').format(a.tarih)} • ${a.paraBirimi}', style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(fmt.format(a.tutar), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showEditAnlasmaDialog(context, cari, a);
                              } else if (val == 'delete') {
                                _confirmDeleteAnlasma(context, cari, a, provider);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 18), title: Text('Düzenle'), dense: true, contentPadding: EdgeInsets.zero)),
                              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, size: 18, color: Colors.red[400]), title: Text('Sil', style: TextStyle(color: Colors.red[400])), dense: true, contentPadding: EdgeInsets.zero)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                const Divider(height: 24),

                // Son İşlemler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Son İşlemler', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${islemler.length} işlem', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                if (islemler.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('İşlem yok - Data ekranından "Cari Ödeme" olarak kayıt girin', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  )
                else
                  ...islemler.take(5).map((h) {
                    final isOdeme = h.islemKaynagi == 'cari_odeme';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isOdeme ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isOdeme ? Colors.red : Colors.green,
                        size: 18,
                      ),
                      title: Text(h.aciklama, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${DateFormat('dd.MM.yyyy').format(h.tarih)} • ${h.kasa ?? ""}', style: const TextStyle(fontSize: 12)),
                      trailing: Text(fmt.format(h.tlKarsiligi ?? h.tutar),
                          style: TextStyle(fontWeight: FontWeight.bold, color: isOdeme ? Colors.red : Colors.green)),
                    );
                  }),

                const SizedBox(height: 8),
                // Action buttons
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Düzenle'),
                      onPressed: () => _showCariDialog(context, cari: cari),
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.delete, size: 16, color: Colors.red[400]),
                      label: Text('Sil', style: TextStyle(color: Colors.red[400])),
                      onPressed: () => _confirmDelete(context, cari, provider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showCariDialog(BuildContext context, {Cari? cari}) {
    final isEdit = cari != null;
    final firmaController = TextEditingController(text: cari?.firmaAdi);
    final yetkiliController = TextEditingController(text: cari?.yetkiliKisi);
    final telefonController = TextEditingController(text: cari?.telefon);
    final adresController = TextEditingController(text: cari?.adres);
    final vergiNoController = TextEditingController(text: cari?.vergiNo);
    final notlarController = TextEditingController(text: cari?.notlar);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Cari Düzenle' : 'Yeni Cari'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firmaController,
                decoration: const InputDecoration(labelText: 'Firma Adı *', prefixIcon: Icon(Icons.business)),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yetkiliController,
                decoration: const InputDecoration(labelText: 'Yetkili Kişi', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonController,
                decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vergiNoController,
                decoration: const InputDecoration(labelText: 'Vergi No', prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adresController,
                decoration: const InputDecoration(labelText: 'Adres', prefixIcon: Icon(Icons.location_on)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notlarController,
                decoration: const InputDecoration(labelText: 'Notlar', prefixIcon: Icon(Icons.note)),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              if (firmaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Firma adı zorunludur'), backgroundColor: Colors.red),
                );
                return;
              }
              final provider = Provider.of<AppProvider>(context, listen: false);
              final newCari = Cari(
                id: cari?.id,
                firmaAdi: firmaController.text.trim(),
                yetkiliKisi: yetkiliController.text.trim().isEmpty ? null : yetkiliController.text.trim(),
                telefon: telefonController.text.trim().isEmpty ? null : telefonController.text.trim(),
                adres: adresController.text.trim().isEmpty ? null : adresController.text.trim(),
                vergiNo: vergiNoController.text.trim().isEmpty ? null : vergiNoController.text.trim(),
                notlar: notlarController.text.trim().isEmpty ? null : notlarController.text.trim(),
              );
              if (isEdit) {
                await provider.updateCari(newCari);
              } else {
                await provider.addCari(newCari);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Kaydet' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAnlasmaDialog(BuildContext context, Cari cari) {
    final baslikController = TextEditingController();
    final tutarController = TextEditingController();
    final notlarController = TextEditingController();
    String tip = 'borc';
    String paraBirimi = 'TL';
    DateTime tarih = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Yeni Anlaşma - ${cari.firmaAdi}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tip seçimi
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Borç (Biz ödüyoruz)'),
                        selected: tip == 'borc',
                        selectedColor: Colors.red[100],
                        onSelected: (_) => setState(() => tip = 'borc'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Alacak (Bize borçlu)'),
                        selected: tip == 'alacak',
                        selectedColor: Colors.green[100],
                        onSelected: (_) => setState(() => tip = 'alacak'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baslikController,
                  decoration: const InputDecoration(labelText: 'Anlaşma Başlığı *', prefixIcon: Icon(Icons.description)),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        value: paraBirimi,
                        decoration: const InputDecoration(labelText: 'Birim'),
                        items: const [
                          DropdownMenuItem(value: 'TL', child: Text('₺ TL')),
                          DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                        ],
                        onChanged: (v) => setState(() => paraBirimi = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: tutarController,
                        decoration: const InputDecoration(labelText: 'Tutar *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd.MM.yyyy').format(tarih)),
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
                TextField(
                  controller: notlarController,
                  decoration: const InputDecoration(labelText: 'Notlar', prefixIcon: Icon(Icons.note)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                final tutar = double.tryParse(tutarController.text.replaceAll(',', '.'));
                if (baslikController.text.trim().isEmpty || tutar == null || tutar <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Başlık ve geçerli tutar girin'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final provider = Provider.of<AppProvider>(context, listen: false);
                await provider.addCariAnlasma(CariAnlasma(
                  cariId: cari.id!,
                  baslik: baslikController.text.trim(),
                  tutar: tutar,
                  tip: tip,
                  paraBirimi: paraBirimi,
                  tarih: tarih,
                  notlar: notlarController.text.trim().isEmpty ? null : notlarController.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAnlasmaDialog(BuildContext context, Cari cari, CariAnlasma anlasma) {
    final baslikController = TextEditingController(text: anlasma.baslik);
    final tutarController = TextEditingController(text: anlasma.tutar.toStringAsFixed(2));
    final notlarController = TextEditingController(text: anlasma.notlar ?? '');
    String tip = anlasma.tip;
    String paraBirimi = anlasma.paraBirimi;
    DateTime tarih = anlasma.tarih;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Anlaşma Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Borç'),
                        selected: tip == 'borc',
                        selectedColor: Colors.red[100],
                        onSelected: (_) => setState(() => tip = 'borc'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Alacak'),
                        selected: tip == 'alacak',
                        selectedColor: Colors.green[100],
                        onSelected: (_) => setState(() => tip = 'alacak'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baslikController,
                  decoration: const InputDecoration(labelText: 'Anlaşma Başlığı *', prefixIcon: Icon(Icons.description)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        value: paraBirimi,
                        decoration: const InputDecoration(labelText: 'Birim'),
                        items: const [
                          DropdownMenuItem(value: 'TL', child: Text('₺ TL')),
                          DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                        ],
                        onChanged: (v) => setState(() => paraBirimi = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: tutarController,
                        decoration: const InputDecoration(labelText: 'Tutar *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd.MM.yyyy').format(tarih)),
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
                TextField(
                  controller: notlarController,
                  decoration: const InputDecoration(labelText: 'Notlar', prefixIcon: Icon(Icons.note)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                final tutar = double.tryParse(tutarController.text.replaceAll(',', '.'));
                if (baslikController.text.trim().isEmpty || tutar == null || tutar <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Başlık ve geçerli tutar girin'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final provider = Provider.of<AppProvider>(context, listen: false);
                final updated = anlasma.copyWith(
                  baslik: baslikController.text.trim(),
                  tutar: tutar,
                  tip: tip,
                  paraBirimi: paraBirimi,
                  tarih: tarih,
                  notlar: notlarController.text.trim().isEmpty ? null : notlarController.text.trim(),
                );
                await provider.updateCariAnlasma(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAnlasma(BuildContext context, Cari cari, CariAnlasma anlasma, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anlaşma Sil'),
        content: Text('"${anlasma.baslik}" anlaşması silinsin mi?\n\nTutar: ${anlasma.tutar.toStringAsFixed(2)} ${anlasma.paraBirimi}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteCariAnlasma(anlasma.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Cari cari, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cariyi Sil'),
        content: Text('${cari.firmaAdi} silinsin mi?\n\nNot: Mevcut kasa işlemleri silinmez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteCari(cari.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
