#!/usr/bin/env python3
"""Fix nullable manuelKurController access in transfer submit"""
filepath = 'lib/screens/kasa_screen.dart'
with open(filepath, 'r') as f:
    lines = f.readlines()

# Line 2592 (0-indexed 2591) - add ! operator
for i, line in enumerate(lines):
    if 'manuelKur = double.tryParse(manuelKurController.text.replaceAll' in line:
        lines[i] = line.replace('manuelKurController.text', 'manuelKurController!.text')
        print(f'Fixed line {i+1}')
        break

with open(filepath, 'w') as f:
    f.writelines(lines)
print('Done')
