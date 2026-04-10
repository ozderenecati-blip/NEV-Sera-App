#!/usr/bin/env python3
"""Fix transfer submit logic in kasa_screen.dart - line-based approach"""

filepath = 'lib/screens/kasa_screen.dart'
with open(filepath, 'r') as f:
    lines = f.readlines()

# Find line range: "    // Transfer işlemi" through "    }" before "    // Döviz bozdurma"
start = None
end = None
for i, line in enumerate(lines):
    if '// Transfer işlemi' in line and start is None:
        start = i
    if start is not None and '// Döviz bozdurma' in line:
        # end is the line before this (should be empty line)
        end = i  # exclusive
        break

assert start is not None, 'Transfer submit start not found!'
assert end is not None, 'Transfer submit end not found!'
print(f'Found transfer submit at lines {start+1}-{end}')

new_submit = """    // Transfer işlemi
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
      final kurNotu = farkliDoviz ? ' (Kur: ${manuelKur!.toStringAsFixed(4)})' : '';
      
      // Çıkış kaydı (kaynak kasadan, kaynak birim cinsinden)
      final cikis = KasaHareketi(
        tarih: selectedDate,
        islemTipi: 'Çıkış',
        tutar: tutar,
        aciklama: '$aciklama → $hedefKasa$kurNotu',
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
        aciklama: '$aciklama ← $selectedKasa$kurNotu',
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
    }

"""

lines[start:end] = [new_submit]
print('OK: Transfer submit logic replaced')

with open(filepath, 'w') as f:
    f.writelines(lines)
print('Done')
