#!/usr/bin/env python3
"""Fix home_screen.dart _buildKasaBakiyeleri to show per-kasa currency symbols"""

filepath = 'lib/screens/home_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Fix: Add currency helper and update _buildKasaBakiyeleri
old_widget = """            ...bakiyeler.map((b) {
                  final kasa = b['kasa'] as String? ?? 'Bilinmiyor';
                  final bakiye = (b['bakiye'] as num?)?.toDouble() ?? 0.0;
                  final giris = (b['toplam_giris'] as num?)?.toDouble() ?? 0.0;
                  final cikis = (b['toplam_cikis'] as num?)?.toDouble() ?? 0.0;"""

new_widget = """            ...bakiyeler.map((b) {
                  final kasa = b['kasa'] as String? ?? 'Bilinmiyor';
                  final bakiye = (b['bakiye'] as num?)?.toDouble() ?? 0.0;
                  final giris = (b['toplam_giris'] as num?)?.toDouble() ?? 0.0;
                  final cikis = (b['toplam_cikis'] as num?)?.toDouble() ?? 0.0;
                  final paraBirimi = b['para_birimi'] as String? ?? 'TL';
                  final sembol = paraBirimi == 'EUR' ? '\u20ac' : paraBirimi == 'USD' ? '\$' : '\u20ba';
                  final kasaFmt = NumberFormat.currency(locale: 'tr_TR', symbol: sembol);"""

assert old_widget in content, 'old_widget not found!'
content = content.replace(old_widget, new_widget)
print('OK: Added paraBirimi/sembol/kasaFmt variables')

# Fix fmt.format references in the kasa bakiyeleri widget
# Change: 'G: ${fmt.format(giris)} | \u00c7: ${fmt.format(cikis)}'
old_fmt_line = "'G: \${fmt.format(giris)} | \u00c7: \${fmt.format(cikis)}'"
new_fmt_line = "'G: \${kasaFmt.format(giris)} | \u00c7: \${kasaFmt.format(cikis)}'"
assert old_fmt_line in content, f'old_fmt_line not found!'
content = content.replace(old_fmt_line, new_fmt_line)
print('OK: Fixed giris/cikis format')

# Change: fmt.format(bakiye) in the bakiye display
old_bakiye_fmt = """                        Text(
                          fmt.format(bakiye),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: bakiye >= 0 ? Colors.green : Colors.red,
                          ),
                        ),"""

new_bakiye_fmt = """                        Text(
                          kasaFmt.format(bakiye),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: bakiye >= 0 ? Colors.green : Colors.red,
                          ),
                        ),"""

assert old_bakiye_fmt in content, 'old_bakiye_fmt not found!'
content = content.replace(old_bakiye_fmt, new_bakiye_fmt)
print('OK: Fixed bakiye format')

with open(filepath, 'w') as f:
    f.write(content)
print('Home screen fixes applied successfully')
