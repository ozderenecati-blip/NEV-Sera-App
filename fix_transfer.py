#!/usr/bin/env python3
"""
Fix transfer mode in kasa_screen.dart:
1. Transfer UI: Remove manual birim dropdown, auto-detect from kasa settings.
   If kasalar have different currencies, show manual kur input.
2. Transfer submit: Use proper currencies from kasalar, not API rate.
"""

filepath = 'lib/screens/kasa_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

changes = 0

# ======================================================================
# FIX A: Transfer UI - Replace birim dropdown + tutar row with 
#        auto-detect from kasa para birimi + show kur field if different
# ======================================================================

old_transfer_ui = """                            if (islemModu == 'transfer') ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: DropdownButtonFormField<String>(
                                        value: selectedParaBirimi,
                                        decoration: const InputDecoration(
                                          labelText: 'Birim',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                        ),
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'TL', child: Text('\u20ba TL')),
                                          DropdownMenuItem(value: 'EUR', child: Text('\u20ac EUR')),
                                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                                        ],
                                        onChanged: (v) => setModalState(() => selectedParaBirimi = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: tutarController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Transfer Tutar\u0131 *',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.attach_money),
                                        ),
                                        onChanged: (_) => setModalState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],"""

new_transfer_ui = """                            if (islemModu == 'transfer') ...[
                                // Kaynak ve hedef kasalar\u0131n para birimlerini bul
                                Builder(builder: (context) {
                                  final kaynakSetting = selectedKasa != null ? provider.getKasaSetting(selectedKasa!) : null;
                                  final hedefSetting = hedefKasa != null ? provider.getKasaSetting(hedefKasa!) : null;
                                  final kaynakBirim = kaynakSetting?.paraBirimi ?? 'TL';
                                  final hedefBirim = hedefSetting?.paraBirimi ?? 'TL';
                                  final farkliDoviz = kaynakBirim != hedefBirim;
                                  final kaynakSembol = kaynakBirim == 'EUR' ? '\u20ac' : kaynakBirim == 'USD' ? '\$' : '\u20ba';
                                  // selectedParaBirimi'yi kaynak kasadan oto ayarla
                                  if (selectedParaBirimi != kaynakBirim) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      setModalState(() => selectedParaBirimi = kaynakBirim);
                                    });
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: tutarController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Transfer Tutar\u0131 ($kaynakBirim) *',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.attach_money),
                                          suffixText: kaynakSembol,
                                        ),
                                        onChanged: (_) => setModalState(() {}),
                                      ),
                                      if (farkliDoviz) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.currency_exchange, color: Colors.orange.shade700, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(
                                                'Farkl\u0131 d\u00f6viz: $kaynakBirim \u2192 $hedefBirim. L\u00fctfen kuru girin.',
                                                style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                                              )),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: manuelKurController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: '1 $kaynakBirim = ? $hedefBirim (Manuel Kur)',
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.price_change),
                                            hintText: '\u00d6rn: ${kaynakBirim == "EUR" ? "38.50" : kaynakBirim == "USD" ? "36.20" : "0.028"}',
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                        if (manuelKurController.text.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Builder(builder: (_) {
                                            final kur = double.tryParse(manuelKurController.text.replaceAll(',', '.')) ?? 0;
                                            final tutar = double.tryParse(tutarController.text.replaceAll(',', '.')) ?? 0;
                                            final hedefTutar = tutar * kur;
                                            final hedefSembol = hedefBirim == 'EUR' ? '\u20ac' : hedefBirim == 'USD' ? '\$' : '\u20ba';
                                            return Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text(
                                                    'Hedef kasaya ge\u00e7ecek tutar: $hedefSembol${NumberFormat('#,##0.00', 'tr_TR').format(hedefTutar)}',
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                                  )),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ],
                                    ],
                                  );
                                }),
                              ],"""

assert old_transfer_ui in content, 'old_transfer_ui not found!'
content = content.replace(old_transfer_ui, new_transfer_ui)
changes += 1
print(f'OK {changes}: Transfer UI replaced with auto-detect + manual kur')

# ======================================================================
# FIX B: Transfer submit logic - Use kasa para birimleri + manual kur
# ======================================================================

old_transfer_submit = """    // Transfer i\u015flemi
      if (islemModu == 'transfer') {
        // \u00c7\u0131k\u0131\u015f kayd\u0131
        final cikis = KasaHareketi(
          tarih: selectedDate,
          islemTipi: '\u00c7\u0131k\u0131\u015f',
          tutar: tutar,
          aciklama:
              '${aciklamaController.text.trim().isEmpty ? 'Transfer' : aciklamaController.text.trim()} \u2192 $hedefKasa',
          kasa: selectedKasa,
          notlar:
              notlarController.text.trim().isEmpty
                  ? null
                  : notlarController.text.trim(),
          paraBirimi: selectedParaBirimi,
          dovizKuru: selectedParaBirimi != 'TL' ? (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          tlKarsiligi: selectedParaBirimi != 'TL' ? tutar * (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          islemKaynagi: 'kasa_transfer',
        );
        await provider.addKasaHareketi(cikis);

        // Giri\u015f kayd\u0131
        final giris = KasaHareketi(
          tarih: selectedDate,
          islemTipi: 'Giri\u015f',
          tutar: tutar,
          aciklama:
              '${aciklamaController.text.trim().isEmpty ? 'Transfer' : aciklamaController.text.trim()} \u2190 $selectedKasa',
          kasa: hedefKasa,
          notlar:
              notlarController.text.trim().isEmpty
                  ? null
                  : notlarController.text.trim(),
          paraBirimi: selectedParaBirimi,
          dovizKuru: selectedParaBirimi != 'TL' ? (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          tlKarsiligi: selectedParaBirimi != 'TL' ? tutar * (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          islemKaynagi: 'kasa_transfer',
        );
        await provider.addKasaHareketi(giris);

        if (ctx.mounted) Navigator.pop(ctx);
        return;
      }"""

new_transfer_submit = """    // Transfer i\u015flemi
      if (islemModu == 'transfer') {
        // Kaynak ve hedef kasa para birimlerini bul
        final kaynakSetting = selectedKasa != null ? provider.getKasaSetting(selectedKasa!) : null;
        final hedefSetting = hedefKasa != null ? provider.getKasaSetting(hedefKasa!) : null;
        final kaynakBirim = kaynakSetting?.paraBirimi ?? 'TL';
        final hedefBirim = hedefSetting?.paraBirimi ?? 'TL';
        final farkliDoviz = kaynakBirim != hedefBirim;
        
        double hedefTutar = tutar;
        double? manuelKur;
        
        if (farkliDoviz) {
          // Farkl\u0131 d\u00f6viz - kullan\u0131c\u0131n\u0131n girdi\u011fi kur gerekli
          manuelKur = double.tryParse(manuelKurController.text.replaceAll(',', '.'));
          if (manuelKur == null || manuelKur <= 0) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Farkl\u0131 d\u00f6viz transferi i\u00e7in ge\u00e7erli bir kur girin')),
            );
            return;
          }
          hedefTutar = tutar * manuelKur;
        }
        
        final aciklama = aciklamaController.text.trim().isEmpty ? 'Transfer' : aciklamaController.text.trim();
        final kurNotu = farkliDoviz ? ' (Kur: ${manuelKur!.toStringAsFixed(4)})' : '';
        
        // \u00c7\u0131k\u0131\u015f kayd\u0131 (kaynak kasadan, kaynak birim cinsinden)
        final cikis = KasaHareketi(
          tarih: selectedDate,
          islemTipi: '\u00c7\u0131k\u0131\u015f',
          tutar: tutar,
          aciklama: '$aciklama \u2192 $hedefKasa$kurNotu',
          kasa: selectedKasa,
          notlar: notlarController.text.trim().isEmpty ? null : notlarController.text.trim(),
          paraBirimi: kaynakBirim,
          dovizKuru: farkliDoviz ? manuelKur : (kaynakBirim != 'TL' ? (kaynakBirim == 'EUR' ? _eurTryRate : _usdTryRate) : null),
          tlKarsiligi: kaynakBirim != 'TL' ? tutar * (kaynakBirim == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          islemKaynagi: 'kasa_transfer',
        );
        await provider.addKasaHareketi(cikis);

        // Giri\u015f kayd\u0131 (hedef kasaya, hedef birim cinsinden)
        final giris = KasaHareketi(
          tarih: selectedDate,
          islemTipi: 'Giri\u015f',
          tutar: hedefTutar,
          aciklama: '$aciklama \u2190 $selectedKasa$kurNotu',
          kasa: hedefKasa,
          notlar: notlarController.text.trim().isEmpty ? null : notlarController.text.trim(),
          paraBirimi: hedefBirim,
          dovizKuru: farkliDoviz ? manuelKur : (hedefBirim != 'TL' ? (hedefBirim == 'EUR' ? _eurTryRate : _usdTryRate) : null),
          tlKarsiligi: hedefBirim != 'TL' ? hedefTutar * (hedefBirim == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          islemKaynagi: 'kasa_transfer',
        );
        await provider.addKasaHareketi(giris);

        if (ctx.mounted) Navigator.pop(ctx);
        return;
      }"""

assert old_transfer_submit in content, 'old_transfer_submit not found!'
content = content.replace(old_transfer_submit, new_transfer_submit)
changes += 1
print(f'OK {changes}: Transfer submit logic fixed with manual kur support')

with open(filepath, 'w') as f:
    f.write(content)
print(f'All {changes} kasa_screen fixes applied successfully')
