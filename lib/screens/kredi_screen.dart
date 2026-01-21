import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/kredi.dart';

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
            return const Center(child: CircularProgressIndicator());
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
                      currencyFormat.format(provider.krediOzet['toplam_bakiye'] ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniInfo('Aktif Kredi', '${(provider.krediOzet['aktif_kredi'] ?? 0).toInt()}', Icons.credit_card),
                        Container(height: 40, width: 1, color: Colors.white24),
                        _buildMiniInfo('Aylık Taksit', currencyFormat.format(provider.krediOzet['aylik_taksit'] ?? 0), Icons.calendar_month),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: provider.krediler.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Henüz kredi yok', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.krediler.length,
                        itemBuilder: (context, index) {
                          final kredi = provider.krediler[index];
                          return _buildKrediCard(context, kredi, currencyFormat);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddKrediDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kredi'),
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
                          kredi.bankaAd,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${kredi.taksitTipi} - ${kredi.vadeAy} Ay',
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
                  _buildInfoChip('Para Birimi', kredi.paraBirimi ?? 'TL'),
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
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
                                Text(kredi.bankaAd, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('Kredi ID: ${kredi.krediId}', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    '${taksit.periyot}',
                                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(currencyFormat.format(taksit.toplamTaksit)),
                                subtitle: Text(DateFormat('dd MMM yyyy', 'tr_TR').format(taksit.vadeTarihi)),
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
    String bankaAd = '';
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
                            labelText: 'Banka Adı',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Banka adı girin' : null,
                          onSaved: (value) => bankaAd = value!,
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
                          initialValue: odemeSikligiAy,
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
                          initialValue: taksitTipi,
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
                                krediId: 'K${DateTime.now().millisecondsSinceEpoch}',
                                bankaAd: bankaAd,
                                cekilenTutar: cekilenTutar,
                                faizOrani: faizOrani,
                                vadeAy: vadeAy,
                                taksitTipi: taksitTipi,
                                odemeSikligiAy: odemeSikligiAy,
                                kkdfOrani: kkdfOrani,
                                bsmvOrani: bsmvOrani,
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
