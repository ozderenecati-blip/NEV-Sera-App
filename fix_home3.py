#!/usr/bin/env python3
"""Fix remaining bakiye format in home_screen.dart"""

filepath = 'lib/screens/home_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# The exact text with correct indentation (22 spaces before fmt)
old = "                      Text(\n                        fmt.format(bakiye),\n                        style: TextStyle(\n                          fontSize: 16,"
new = "                      Text(\n                        kasaFmt.format(bakiye),\n                        style: TextStyle(\n                          fontSize: 16,"

assert old in content, 'old not found!'
content = content.replace(old, new)
print('OK: Fixed bakiye format')

with open(filepath, 'w') as f:
    f.write(content)
print('Done')
