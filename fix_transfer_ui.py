#!/usr/bin/env python3
"""
Final fix for transfer in kasa_screen.dart:
1. Replace the birim dropdown + tutar row (lines around 2037-2076) with auto-detect + manual kur
2. Submit logic is already fixed from fix_submit.py 
"""

filepath = 'lib/screens/kasa_screen.dart'
with open(filepath, 'r') as f:
    lines = f.readlines()

# Find the SECOND occurrence of "if (islemModu == 'transfer') ...[" 
# The first (line ~1736) is for kasa selection (kaynak/hedef)
# The second (line ~2037) is for birim/tutar
occurrences = []
for i, line in enumerate(lines):
    if "if (islemModu == 'transfer') ...[" in line:
        occurrences.append(i)

print(f'Found {len(occurrences)} occurrences at lines: {[o+1 for o in occurrences]}')
assert len(occurrences) >= 2, f'Expected at least 2 occurrences'

start_ui = occurrences[1]  # Second occurrence = birim/tutar section
print(f'Target start: line {start_ui+1}')

# Find the matching '],\n' closure
# Count bracket depth
depth = 0
end_ui = None
for i in range(start_ui, len(lines)):
    line = lines[i]
    # Count [...] brackets (not ones inside strings)
    for ch in line:
        if ch == '[':
            depth += 1
        elif ch == ']':
            depth -= 1
    if depth <= 0 and i > start_ui:
        end_ui = i
        break

assert end_ui is not None, f'Could not find end of transfer UI block'
print(f'Target end: line {end_ui+1}')
print(f'Replacing lines {start_ui+1} to {end_ui+1}')

# Build replacement
new_lines = """                            if (islemModu == 'transfer') ...[
                              // Kaynak ve hedef kasaların para birimlerini bul
                              Builder(builder: (context) {
                                final kaynakSetting = selectedKasa != null ? provider.getKasaSetting(selectedKasa!) : null;
                                final hedefSetting = hedefKasa != null ? provider.getKasaSetting(hedefKasa!) : null;
                                final kaynakBirim = kaynakSetting?.paraBirimi ?? 'TL';
                                final hedefBirim = hedefSetting?.paraBirimi ?? 'TL';
                                final farkliDoviz = kaynakBirim != hedefBirim;
                                final kaynakSembol = kaynakBirim == 'EUR' ? '€' : kaynakBirim == 'USD' ? '\\$' : '₺';
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
                                        labelText: 'Transfer Tutarı ($kaynakBirim) *',
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
                                              'Farklı döviz: $kaynakBirim → $hedefBirim. Lütfen kuru girin.',
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
                                        ),
                                        onChanged: (_) => setModalState(() {}),
                                      ),
                                      if (manuelKurController.text.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Builder(builder: (_) {
                                          final kur = double.tryParse(manuelKurController.text.replaceAll(',', '.')) ?? 0;
                                          final t = double.tryParse(tutarController.text.replaceAll(',', '.')) ?? 0;
                                          final hedefTutar = t * kur;
                                          final hedefSembol = hedefBirim == 'EUR' ? '€' : hedefBirim == 'USD' ? '\\$' : '₺';
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
                                                  'Hedef kasaya geçecek tutar: $hedefSembol${NumberFormat('#,##0.00', 'tr_TR').format(hedefTutar)}',
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
                            ],
"""

lines[start_ui:end_ui+1] = [new_lines]

with open(filepath, 'w') as f:
    f.writelines(lines)
print('Transfer UI replaced successfully')
