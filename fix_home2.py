#!/usr/bin/env python3
"""Fix home_screen.dart _buildKasaBakiyeleri to show per-kasa currency symbols"""

filepath = 'lib/screens/home_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Fix 1: After cikis variable, add paraBirimi/sembol/kasaFmt
old1 = "                final cikis = (b['toplam_cikis'] as num?)?.toDouble() ?? 0.0;\n\n                return Container("
new1 = """                final cikis = (b['toplam_cikis'] as num?)?.toDouble() ?? 0.0;
                final paraBirimi = b['para_birimi'] as String? ?? 'TL';
                final sembol = paraBirimi == 'EUR' ? '\u20ac' : paraBirimi == 'USD' ? '\$' : '\u20ba';
                final kasaFmt = NumberFormat.currency(locale: 'tr_TR', symbol: sembol);

                return Container("""

assert old1 in content, f'old1 not found!'
content = content.replace(old1, new1)
print('OK: Added paraBirimi/sembol/kasaFmt')

# Fix 2: Change fmt.format to kasaFmt.format for giris/cikis line
old2 = "fmt.format(giris)} | \u00c7: ${fmt.format(cikis)}"
new2 = "kasaFmt.format(giris)} | \u00c7: ${kasaFmt.format(cikis)}"
assert old2 in content, f'old2 not found!'
content = content.replace(old2, new2)
print('OK: Fixed giris/cikis format')

# Fix 3: Change fmt.format(bakiye) to kasaFmt.format(bakiye)
# Need to be specific - only the one in kasa bakiyeleri section
old3 = "                          fmt.format(bakiye),\n                          style: TextStyle(\n                            fontSize: 16,"
new3 = "                          kasaFmt.format(bakiye),\n                          style: TextStyle(\n                            fontSize: 16,"
assert old3 in content, f'old3 not found!'
content = content.replace(old3, new3)
print('OK: Fixed bakiye format')

with open(filepath, 'w') as f:
    f.write(content)
print('Home screen fixes applied successfully')
