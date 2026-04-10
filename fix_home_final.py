#!/usr/bin/env python3
"""Fix home_screen.dart - add paraBirimi/kasaFmt + fix fmt references"""

filepath = 'lib/screens/home_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Fix 1: Add paraBirimi, sembol, kasaFmt after cikis line
old1 = """                final cikis = (b['toplam_cikis'] as num?)?.toDouble() ?? 0.0;

                return Container("""

new1 = """                final cikis = (b['toplam_cikis'] as num?)?.toDouble() ?? 0.0;
                final paraBirimi = b['para_birimi'] as String? ?? 'TL';
                final sembol = paraBirimi == 'EUR' ? '\u20ac' : paraBirimi == 'USD' ? '\$' : '\u20ba';
                final kasaFmt = NumberFormat.currency(locale: 'tr_TR', symbol: sembol);

                return Container("""

assert old1 in content, 'old1 not found!'
content = content.replace(old1, new1)
print('OK 1: Added paraBirimi/sembol/kasaFmt')

# Fix 2: Change fmt.format(giris) and fmt.format(cikis) to kasaFmt
old2 = "'G: ${fmt.format(giris)} | \u00c7: ${fmt.format(cikis)}'"
new2 = "'G: ${kasaFmt.format(giris)} | \u00c7: ${kasaFmt.format(cikis)}'"
assert old2 in content, 'old2 not found!'
content = content.replace(old2, new2)
print('OK 2: Fixed giris/cikis format')

with open(filepath, 'w') as f:
    f.write(content)
print('Home screen fully fixed')
