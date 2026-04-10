#!/usr/bin/env python3
"""Fix transfer mode in kasa_screen.dart using line-based approach"""

filepath = 'lib/screens/kasa_screen.dart'
with open(filepath, 'r') as f:
    lines = f.readlines()

# ======================================================================
# FIX A: Transfer UI (lines 2037-2076, 0-indexed 2036-2075)
# Replace the birim dropdown + tutar row with auto-detect + manual kur
# ======================================================================

# Find the exact line range
start_ui = None
end_ui = None
for i, line in enumerate(lines):
    if "if (islemModu == 'transfer') ...[" in line and start_ui is None:
        # This is the one around line 2037 area (after the kasa selection rows)
        # Make sure it's the transfer birim/tutar section, not the kasa dropdown section
        # Check if next line has 'Row(' or 'Builder'
        if i+1 < len(lines) and 'Row(' in lines[i+1]:
            start_ui = i
    if start_ui is not None and end_ui is None:
        # Find the closing '],\n' at the same indentation level
        if line.strip() == '],' and i > start_ui + 5:
            # Check indentation matches: "                            ],"
            if lines[start_ui].split('if')[0] == line.split(']')[0]:
                end_ui = i
                break

assert start_ui is not None, 'Transfer UI start not found!'
assert end_ui is not None, 'Transfer UI end not found!'
print(f'Found transfer UI at lines {start_ui+1}-{end_ui+1}')

indent = '                            '  # 28 spaces
indent2 = indent + '  '  # 30 spaces

new_transfer_ui = f"""{indent}if (islemModu == 'transfer') ...[
{indent2}// Kaynak ve hedef kasaların para birimlerini bul
{indent2}Builder(builder: (context) {{
{indent2}  final kaynakSetting = selectedKasa != null ? provider.getKasaSetting(selectedKasa!) : null;
{indent2}  final hedefSetting = hedefKasa != null ? provider.getKasaSetting(hedefKasa!) : null;
{indent2}  final kaynakBirim = kaynakSetting?.paraBirimi ?? 'TL';
{indent2}  final hedefBirim = hedefSetting?.paraBirimi ?? 'TL';
{indent2}  final farkliDoviz = kaynakBirim != hedefBirim;
{indent2}  final kaynakSembol = kaynakBirim == 'EUR' ? '€' : kaynakBirim == 'USD' ? '\\$' : '₺';
{indent2}  // selectedParaBirimi'yi kaynak kasadan oto ayarla
{indent2}  if (selectedParaBirimi != kaynakBirim) {{
{indent2}    WidgetsBinding.instance.addPostFrameCallback((_) {{
{indent2}      setModalState(() => selectedParaBirimi = kaynakBirim);
{indent2}    }});
{indent2}  }}
{indent2}  return Column(
{indent2}    crossAxisAlignment: CrossAxisAlignment.start,
{indent2}    children: [
{indent2}      TextField(
{indent2}        controller: tutarController,
{indent2}        keyboardType: const TextInputType.numberWithOptions(decimal: true),
{indent2}        decoration: InputDecoration(
{indent2}          labelText: 'Transfer Tutarı ($kaynakBirim) *',
{indent2}          border: const OutlineInputBorder(),
{indent2}          prefixIcon: const Icon(Icons.attach_money),
{indent2}          suffixText: kaynakSembol,
{indent2}        ),
{indent2}        onChanged: (_) => setModalState(() {{}}),
{indent2}      ),
{indent2}      if (farkliDoviz) ...[
{indent2}        const SizedBox(height: 12),
{indent2}        Container(
{indent2}          padding: const EdgeInsets.all(10),
{indent2}          decoration: BoxDecoration(
{indent2}            color: Colors.orange.shade50,
{indent2}            borderRadius: BorderRadius.circular(8),
{indent2}            border: Border.all(color: Colors.orange.shade300),
{indent2}          ),
{indent2}          child: Row(
{indent2}            children: [
{indent2}              Icon(Icons.currency_exchange, color: Colors.orange.shade700, size: 20),
{indent2}              const SizedBox(width: 8),
{indent2}              Expanded(child: Text(
{indent2}                'Farklı döviz: $kaynakBirim → $hedefBirim. Lütfen kuru girin.',
{indent2}                style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
{indent2}              )),
{indent2}            ],
{indent2}          ),
{indent2}        ),
{indent2}        const SizedBox(height: 12),
{indent2}        TextField(
{indent2}          controller: manuelKurController,
{indent2}          keyboardType: const TextInputType.numberWithOptions(decimal: true),
{indent2}          decoration: InputDecoration(
{indent2}            labelText: '1 $kaynakBirim = ? $hedefBirim (Manuel Kur)',
{indent2}            border: const OutlineInputBorder(),
{indent2}            prefixIcon: const Icon(Icons.price_change),
{indent2}          ),
{indent2}          onChanged: (_) => setModalState(() {{}}),
{indent2}        ),
{indent2}        if (manuelKurController.text.isNotEmpty) ...[
{indent2}          const SizedBox(height: 8),
{indent2}          Builder(builder: (_) {{
{indent2}            final kur = double.tryParse(manuelKurController.text.replaceAll(',', '.')) ?? 0;
{indent2}            final t = double.tryParse(tutarController.text.replaceAll(',', '.')) ?? 0;
{indent2}            final hedefTutar = t * kur;
{indent2}            final hedefSembol = hedefBirim == 'EUR' ? '€' : hedefBirim == 'USD' ? '\\$' : '₺';
{indent2}            return Container(
{indent2}              padding: const EdgeInsets.all(10),
{indent2}              decoration: BoxDecoration(
{indent2}                color: Colors.green.shade50,
{indent2}                borderRadius: BorderRadius.circular(8),
{indent2}              ),
{indent2}              child: Row(
{indent2}                children: [
{indent2}                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
{indent2}                  const SizedBox(width: 8),
{indent2}                  Expanded(child: Text(
{indent2}                    'Hedef kasaya geçecek tutar: $hedefSembol${{NumberFormat('#,##0.00', 'tr_TR').format(hedefTutar)}}',
{indent2}                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
{indent2}                  )),
{indent2}                ],
{indent2}              ),
{indent2}            );
{indent2}          }}),
{indent2}        ],
{indent2}      ],
{indent2}    ],
{indent2}  );
{indent2}}}),
{indent}],
"""

lines[start_ui:end_ui+1] = [new_transfer_ui]
print('OK 1: Transfer UI replaced')

# Now re-read to find the submit logic
content = ''.join(lines)

# ======================================================================
# FIX B: Transfer submit logic
# ======================================================================
old_submit = """      // Transfer işlemi
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
          paraBirimi: selectedParaBirimi,
          dovizKuru: selectedParaBirimi != 'TL' ? (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          tlKarsiligi: selectedParaBirimi != 'TL' ? tutar * (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          islemKaynagi: 'kasa_transfer',
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
          paraBirimi: selectedParaBirimi,
          dovizKuru: selectedParaBirimi != 'TL' ? (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          tlKarsiligi: selectedParaBirimi != 'TL' ? tutar * (selectedParaBirimi == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          islemKaynagi: 'kasa_transfer',
        );
        await provider.addKasaHareketi(giris);

        if (ctx.mounted) Navigator.pop(ctx);
        return;
      }"""

new_submit = """      // Transfer işlemi
      if (islemModu == 'transfer') {
        // Kaynak ve hedef kasa para birimlerini bul
        final kaynakSetting = selectedKasa != null ? provider.getKasaSetting(selectedKasa!) : null;
        final hedefSettingT = hedefKasa != null ? provider.getKasaSetting(hedefKasa!) : null;
        final kaynakBirim = kaynakSetting?.paraBirimi ?? 'TL';
        final hedefBirim = hedefSettingT?.paraBirimi ?? 'TL';
        final farkliDoviz = kaynakBirim != hedefBirim;
        
        double hedefTutar = tutar;
        double? manuelKur;
        
        if (farkliDoviz) {
          // Farklı döviz - kullanıcının girdiği kur gerekli
          manuelKur = double.tryParse(manuelKurController.text.replaceAll(',', '.'));
          if (manuelKur == null || manuelKur <= 0) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Farklı döviz transferi için geçerli bir kur girin')),
            );
            return;
          }
          hedefTutar = tutar * manuelKur;
        }
        
        final aciklama = aciklamaController.text.trim().isEmpty ? 'Transfer' : aciklamaController.text.trim();
        final kurNotu = farkliDoviz ? ' (Kur: \${manuelKur!.toStringAsFixed(4)})' : '';
        
        // Çıkış kaydı (kaynak kasadan, kaynak birim cinsinden)
        final cikis = KasaHareketi(
          tarih: selectedDate,
          islemTipi: 'Çıkış',
          tutar: tutar,
          aciklama: '\$aciklama → \$hedefKasa\$kurNotu',
          kasa: selectedKasa,
          notlar: notlarController.text.trim().isEmpty ? null : notlarController.text.trim(),
          paraBirimi: kaynakBirim,
          dovizKuru: farkliDoviz ? manuelKur : (kaynakBirim != 'TL' ? (kaynakBirim == 'EUR' ? _eurTryRate : _usdTryRate) : null),
          tlKarsiligi: kaynakBirim != 'TL' ? tutar * (kaynakBirim == 'EUR' ? _eurTryRate : _usdTryRate) : null,
          islemKaynagi: 'kasa_transfer',
        );
        await provider.addKasaHareketi(cikis);

        // Giriş kaydı (hedef kasaya, hedef birim cinsinden)
        final giris = KasaHareketi(
          tarih: selectedDate,
          islemTipi: 'Giriş',
          tutar: hedefTutar,
          aciklama: '\$aciklama ← \$selectedKasa\$kurNotu',
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

assert old_submit in content, 'old_submit not found!'
content = content.replace(old_submit, new_submit)
print('OK 2: Transfer submit logic fixed')

with open(filepath, 'w') as f:
    f.write(content)
print('All kasa_screen.dart fixes applied successfully')
