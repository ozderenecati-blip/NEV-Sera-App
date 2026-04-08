import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/kredi.dart';
import '../widgets/ux_components.dart';

class KrediScreen extends StatelessWidget {
  const KrediScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Krediler'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SkeletonListView(itemCount: 4);
          }
          
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Toplam Kredi Bakiyesi',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(provider.krediler.fold<double>(0, (sum, k) => sum + k.cekilenTutar) - provider.krediler.fold<double>(0, (sum, k) => sum + k.taksitler.where((t) => t.odendi).fold<double>(0, (s, t) => s + t.toplamTaksit))),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: provider.krediler.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.credit_card_off,
                        title: 'Henüz kredi yok',
                        subtitle: 'Kredi ekleyerek takip etmeye başlayın',
                        buttonText: 'Kredi Ekle',
                        onButtonPressed: () => _showAddKrediDialog(context),
                        iconColor: Colors.blue,
                      )
                    : RefreshableList(
                        onRefresh: () => provider.loadAllData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.krediler.length,
                          itemBuilder: (context, index) {
                            final kredi = provider.krediler[index];
                            return AnimatedListItem(
                              index: index,
                              child: _buildKrediCard(context, kredi, currencyFormat),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddKrediDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Yeni Kredi'),
        ),
      ),
    );
  }
  
  Widget _buildMiniInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  Widget _buildKrediCard(BuildContext context, Kredi kredi, NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showKrediDetailSheet(context, kredi, currencyFormat),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.account_balance, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kredi.krediAdi.isNotEmpty ? kredi.krediAdi : kredi.bankaAd,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${kredi.krediId} • ${kredi.bankaAd}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        Text(
                          '${kredi.taksitTipi} - ${kredi.vadeAy} Ay',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        Text(
                          'Başlangıç: ${DateFormat('dd MMM yyyy', 'tr_TR').format(kredi.baslangicTarihi)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(kredi.cekilenTutar),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '%${kredi.faizOrani.toStringAsFixed(2)} Faiz',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip('Kasa', kredi.kasa ?? '-'),
                  _buildInfoChip('Ödeme', '${kredi.odemeSikligiAy} Ayda 1'),
                  _buildInfoChip('Para Birimi', kredi.paraBirimi),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  void _showKrediDetailSheet(BuildContext context, Kredi kredi, NumberFormat currencyFormat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.account_balance, color: Colors.blue.shade700, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(kredi.krediAdi.isNotEmpty ? kredi.krediAdi : kredi.bankaAd, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('${kredi.krediId} • ${kredi.bankaAd}', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Krediyi Sil',
                            onPressed: () async {
                              final onay = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Krediyi Sil'),
                                  content: Text('${kredi.krediAdi.isNotEmpty ? kredi.krediAdi : kredi.bankaAd} kredisini ve tüm taksit planını silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
                              );
                              if (onay == true && kredi.id != null) {
                                final success = await context.read<AppProvider>().deleteKredi(kredi.id!);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kredi silindi'), backgroundColor: Colors.green),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailStat('Çekilen', currencyFormat.format(kredi.cekilenTutar)),
                            _buildDetailStat('Faiz', '%${kredi.faizOrani.toStringAsFixed(2)}'),
                            _buildDetailStat('Vade', '${kredi.vadeAy} Ay'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Başlangıç Tarihi: ${DateFormat('dd MMM yyyy', 'tr_TR').format(kredi.baslangicTarihi)}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Taksit Planı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: kredi.taksitler.isEmpty
                      ? const Center(child: Text('Taksit planı yok'))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: kredi.taksitler.length,
                          itemBuilder: (context, index) {
                            final taksit = kredi.taksitler[index];
                            final bool gecikmisMi = !taksit.odendi && taksit.vadeTarihi.isBefore(DateTime.now());
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: taksit.odendi
                                  ? Colors.green.shade50
                                  : gecikmisMi
                                      ? Colors.red.shade50
                                      : null,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: taksit.odendi
                                      ? Colors.green.shade100
                                      : gecikmisMi
                                          ? Colors.red.shade100
                                          : Colors.blue.shade100,
                                  child: taksit.odendi
                                      ? Icon(Icons.check, color: Colors.green.shade700)
                                      : Text(
                                          '${taksit.periyot}',
                                          style: TextStyle(
                                            color: gecikmisMi ? Colors.red.shade700 : Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  currencyFormat.format(taksit.toplamTaksit),
                                  style: TextStyle(
                                    decoration: taksit.odendi ? TextDecoration.lineThrough : null,
                                    color: taksit.odendi ? Colors.grey : null,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy', 'tr_TR').format(taksit.vadeTarihi),
                                      style: TextStyle(
                                        color: gecikmisMi ? Colors.red : null,
                                        fontWeight: gecikmisMi ? FontWeight.bold : null,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: taksit.vadeTarihi,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2040),
                                        );
                                        if (picked != null && context.mounted) {
                                          final provider = Provider.of<AppProvider>(context, listen: false);
                                          await provider.updateTaksitTarih(kredi.id!, taksit.id!, picked);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Taksit tarihi güncellendi'), backgroundColor: Colors.blue),
                                            );
                                          }
                                        }
                                      },
                                      child: Icon(Icons.edit_calendar, size: 18, color: Colors.blue.shade400),
                                    ),
                                    if (taksit.odendi) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('Ödendi', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                    if (gecikmisMi) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('Gecikmiş', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Text(
                                  'Kalan: ${currencyFormat.format(taksit.kalanBakiye)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Anapara:', style: TextStyle(color: Colors.grey.shade600)),
                                            Text(currencyFormat.format(taksit.anapara)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Faiz:', style: TextStyle(color: Colors.grey.shade600)),
                                            Text(currencyFormat.format(taksit.faiz)),
                                          ],
                                        ),
                                        if (taksit.kkdf > 0) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('KKDF:', style: TextStyle(color: Colors.grey.shade600)),
                                              Text(currencyFormat.format(taksit.kkdf)),
                                            ],
                                          ),
                                        ],
                                        if (taksit.bsmv > 0) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('BSMV:', style: TextStyle(color: Colors.grey.shade600)),
                                              Text(currencyFormat.format(taksit.bsmv)),
                                            ],
                                          ),
                                        ],
                                        const Divider(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Toplam:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Text(currencyFormat.format(taksit.toplamTaksit), style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        if (!taksit.odendi) ...[
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                final provider = Provider.of<AppProvider>(context, listen: false);
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Taksit Öde'),
                                                    content: Text('Taksit ${taksit.periyot} - ${currencyFormat.format(taksit.toplamTaksit)} ödensin mi?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.pop(ctx, true),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                        child: const Text('Öde', style: TextStyle(color: Colors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await provider.taksitOde(kredi.id!, taksit.id!, DateTime.now());
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Taksit ödendi ✓'), backgroundColor: Colors.green),
                                                    );
                                                    Navigator.pop(context);
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.payment, color: Colors.white),
                                              label: const Text('Taksiti Öde', style: TextStyle(color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (taksit.odendi && taksit.odemeTarihi != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Ödenme Tarihi: ${DateFormat('dd MMM yyyy', 'tr_TR').format(taksit.odemeTarihi!)}',
                                                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
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
  
  Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
  
  void _showAddKrediDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String krediId = '';
    String krediAdi = '';
    String bankaAd = '';
    DateTime baslangicTarihi = DateTime.now();
    double cekilenTutar = 0;
    double faizOrani = 0;
    int vadeAy = 12;
    String taksitTipi = 'Eşit Taksit';
    int odemeSikligiAy = 1;
    double kkdfOrani = 15.0; // Varsayılan %15
    double bsmvOrani = 10.0; // Varsayılan %10
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Yeni Kredi Ekle',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Kredi ID *',
                            prefixIcon: Icon(Icons.tag),
                            hintText: 'Örn: K-001, TEB-2026',
                          ),
                          validator: (value) => value?.trim().isEmpty ?? true ? 'Kredi ID girin' : null,
                          onSaved: (value) => krediId = value!.trim(),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Kredi Adı *',
                            prefixIcon: Icon(Icons.label_outline),
                            hintText: 'Örn: Sera Yatırım Kredisi',
                          ),
                          validator: (value) => value?.trim().isEmpty ?? true ? 'Kredi adı girin' : null,
                          onSaved: (value) => krediAdi = value!.trim(),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Banka Adı *',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Banka adı girin' : null,
                          onSaved: (value) => bankaAd = value!,
                        ),
                        const SizedBox(height: 16),
                        
                          // Başlangıç Tarihi
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: baslangicTarihi,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2040),
                              );
                              if (picked != null) {
                                setModalState(() => baslangicTarihi = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Başlangıç Tarihi *',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy', 'tr_TR').format(baslangicTarihi),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Çekilen Tutar',
                            suffixText: '₺',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Tutar girin';
                            if (double.tryParse(value!) == null) return 'Geçerli tutar girin';
                            return null;
                          },
                          onSaved: (value) => cekilenTutar = double.parse(value!),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Faiz Oranı',
                                  prefixIcon: Icon(Icons.percent),
                                  suffixText: '%',
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => faizOrani = double.tryParse(value ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: '12',
                                decoration: const InputDecoration(
                                  labelText: 'Vade (Ay)',
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => vadeAy = int.tryParse(value ?? '12') ?? 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Ödeme Sıklığı
                        DropdownButtonFormField<int>(
                          value: odemeSikligiAy,
                          decoration: const InputDecoration(
                            labelText: 'Ödeme Sıklığı',
                            prefixIcon: Icon(Icons.repeat),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Aylık')),
                            DropdownMenuItem(value: 3, child: Text('3 Ayda Bir')),
                            DropdownMenuItem(value: 6, child: Text('6 Ayda Bir')),
                            DropdownMenuItem(value: 12, child: Text('Yıllık')),
                          ],
                          onChanged: (value) => setModalState(() => odemeSikligiAy = value!),
                        ),
                        const SizedBox(height: 16),
                        
                        // KKDF ve BSMV
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: '15',
                                decoration: const InputDecoration(
                                  labelText: 'KKDF',
                                  prefixIcon: Icon(Icons.receipt),
                                  suffixText: '%',
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => kkdfOrani = double.tryParse(value ?? '15') ?? 15,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: '10',
                                decoration: const InputDecoration(
                                  labelText: 'BSMV',
                                  prefixIcon: Icon(Icons.receipt_long),
                                  suffixText: '%',
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => bsmvOrani = double.tryParse(value ?? '10') ?? 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KKDF ve BSMV faiz üzerine hesaplanır',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        
                        DropdownButtonFormField<String>(
                          value: taksitTipi,
                          decoration: const InputDecoration(
                            labelText: 'Taksit Tipi',
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: ['Eşit Taksit', 'Eşit Anapara', 'Balon Ödemeli']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => taksitTipi = value!,
                        ),
                        const SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              
                              final kredi = Kredi(
                                krediId: krediId,
                                krediAdi: krediAdi,
                                bankaAd: bankaAd,
                                cekilenTutar: cekilenTutar,
                                faizOrani: faizOrani,
                                vadeAy: vadeAy,
                                taksitTipi: taksitTipi,
                                odemeSikligiAy: odemeSikligiAy,
                                kkdfOrani: kkdfOrani,
                                bsmvOrani: bsmvOrani,
                                baslangicTarihi: baslangicTarihi,
                              );
                              
                              final success = await context.read<AppProvider>().addKredi(kredi);
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kredi eklendi'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Kaydet'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
