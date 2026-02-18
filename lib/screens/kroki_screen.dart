import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/bahce.dart';
import '../services/operasyon_service.dart';

/// Bahçe krokisi çizim ekranı
/// Kullanıcı köşe noktaları ve metre bilgisi girer, Canvas üzerinde çizer.
class KrokiScreen extends StatefulWidget {
  final Bahce bahce;
  const KrokiScreen({super.key, required this.bahce});

  @override
  State<KrokiScreen> createState() => _KrokiScreenState();
}

class _KrokiScreenState extends State<KrokiScreen> {
  final OperasyonService _service = OperasyonService();
  late List<BahceKose> _koseler;
  bool _editMode = true;
  bool _isSaving = false;

  // Canvas pan & zoom
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _koseler = List<BahceKose>.from(widget.bahce.koseler);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kroki - ${widget.bahce.ad}'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          if (_koseler.length >= 3)
            IconButton(
              onPressed: _saveCroquis,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              tooltip: 'Kaydet',
            ),
          IconButton(
            onPressed: () => setState(() => _editMode = !_editMode),
            icon: Icon(_editMode ? Icons.visibility : Icons.edit),
            tooltip: _editMode ? 'Önizleme' : 'Düzenle',
          ),
        ],
      ),
      body: Column(
        children: [
          // Üst panel: köşe bilgileri
          _buildCornerPanel(),
          // Canvas alanı
          Expanded(child: _buildCanvas()),
          // Alt panel: kontroller
          if (_editMode) _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildCornerPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFFF8E1),
      child: Row(
        children: [
          Icon(Icons.crop_square, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text('${_koseler.length} köşe', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
          if (_koseler.length >= 3) ...[
            const SizedBox(width: 16),
            Icon(Icons.straighten, size: 18, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text('Çevre: ${_calculatePerimeter().toStringAsFixed(1)} m',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.orange.shade700)),
            const SizedBox(width: 16),
            Text('Alan: ${_calculateArea().toStringAsFixed(1)} m²',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.orange.shade700)),
          ],
          const Spacer(),
          if (_editMode)
            TextButton.icon(
              onPressed: _showKoseEkleDialog,
              icon: const Icon(Icons.add_location, size: 18),
              label: const Text('Köşe Ekle'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFD97706)),
            ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return GestureDetector(
      onScaleStart: (details) {},
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.3, 5.0);
          _panOffset += details.focalPointDelta;
        });
      },
      child: Container(
        color: Colors.grey.shade50,
        child: _koseler.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.map, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Köşe noktası ekleyerek başlayın', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Her köşe için x, y koordinatı ve metre bilgisi girin',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ]).animate().fadeIn(),
              )
            : ClipRect(
                child: CustomPaint(
                  painter: _KrokiPainter(
                    koseler: _koseler,
                    scale: _scale,
                    offset: _panOffset,
                    editMode: _editMode,
                    parseller: widget.bahce.parseller,
                  ),
                  size: Size.infinite,
                ),
              ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_koseler.isNotEmpty) ...[
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _koseler.length,
                itemBuilder: (context, index) => _buildKoseChip(index),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showKoseEkleDialog,
                  icon: const Icon(Icons.add_location),
                  label: const Text('Köşe Ekle'),
                ),
              ),
              const SizedBox(width: 12),
              if (_koseler.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _koseler.removeLast();
                    }),
                    icon: const Icon(Icons.undo, color: Colors.red),
                    label: const Text('Son Köşeyi Sil', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  ),
                ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() {
                  _panOffset = Offset.zero;
                  _scale = 1.0;
                }),
                child: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKoseChip(int index) {
    final kose = _koseler[index];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showKoseDuzenleDialog(index),
        onLongPress: () {
          setState(() => _koseler.removeAt(index));
        },
        child: Chip(
          backgroundColor: const Color(0xFFD97706).withOpacity(0.1),
          avatar: CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFFD97706),
            child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          label: Text(
            '(${kose.x.toStringAsFixed(1)}, ${kose.y.toStringAsFixed(1)}) ${kose.metraj > 0 ? "${kose.metraj.toStringAsFixed(1)}m" : ""}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _showKoseEkleDialog() {
    final xController = TextEditingController();
    final yController = TextEditingController();
    final metrajController = TextEditingController();

    // Öneri: son köşeden devam edecek şekilde x, y öner
    if (_koseler.isNotEmpty) {
      final last = _koseler.last;
      xController.text = last.x.toStringAsFixed(1);
      yController.text = last.y.toStringAsFixed(1);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Köşe ${_koseler.length + 1} Ekle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: xController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'X (metre)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: yController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Y (metre)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: metrajController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Kenar Uzunluğu (metre)',
              helperText: 'Bu köşeden sonraki kenara kadar',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final x = double.tryParse(xController.text.replaceAll(',', '.'));
              final y = double.tryParse(yController.text.replaceAll(',', '.'));
              final metraj = double.tryParse(metrajController.text.replaceAll(',', '.')) ?? 0;
              if (x == null || y == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('X ve Y değerlerini girin')));
                return;
              }
              setState(() => _koseler.add(BahceKose(x: x, y: y, metraj: metraj)));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showKoseDuzenleDialog(int index) {
    final kose = _koseler[index];
    final xController = TextEditingController(text: kose.x.toString());
    final yController = TextEditingController(text: kose.y.toString());
    final metrajController = TextEditingController(text: kose.metraj.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Köşe ${index + 1} Düzenle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: xController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'X (metre)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: yController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Y (metre)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: metrajController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Kenar Uzunluğu (metre)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _koseler.removeAt(index));
              Navigator.pop(ctx);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final x = double.tryParse(xController.text.replaceAll(',', '.'));
              final y = double.tryParse(yController.text.replaceAll(',', '.'));
              final metraj = double.tryParse(metrajController.text.replaceAll(',', '.')) ?? 0;
              if (x == null || y == null) return;
              setState(() {
                _koseler[index] = BahceKose(x: x, y: y, metraj: metraj);
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  double _calculatePerimeter() {
    if (_koseler.length < 2) return 0;
    double perimeter = 0;
    for (int i = 0; i < _koseler.length; i++) {
      final current = _koseler[i];
      final next = _koseler[(i + 1) % _koseler.length];
      if (current.metraj > 0) {
        perimeter += current.metraj;
      } else {
        perimeter += sqrt(pow(next.x - current.x, 2) + pow(next.y - current.y, 2));
      }
    }
    return perimeter;
  }

  /// Shoelace formula for area
  double _calculateArea() {
    if (_koseler.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < _koseler.length; i++) {
      final j = (i + 1) % _koseler.length;
      area += _koseler[i].x * _koseler[j].y;
      area -= _koseler[j].x * _koseler[i].y;
    }
    return area.abs() / 2;
  }

  Future<void> _saveCroquis() async {
    setState(() => _isSaving = true);
    try {
      await _service.updateBahce(widget.bahce.copyWith(
        koseler: _koseler,
        toplamAlan: _calculateArea(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kroki kaydedildi ✓')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
    setState(() => _isSaving = false);
  }
}

/// Canvas painter for the garden croquis
class _KrokiPainter extends CustomPainter {
  final List<BahceKose> koseler;
  final double scale;
  final Offset offset;
  final bool editMode;
  final List<Parsel> parseller;

  _KrokiPainter({
    required this.koseler,
    required this.scale,
    required this.offset,
    required this.editMode,
    required this.parseller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (koseler.isEmpty) return;

    canvas.save();

    // Center the drawing
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
    canvas.scale(scale);

    // Calculate bounds to auto-center
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final k in koseler) {
      minX = min(minX, k.x);
      maxX = max(maxX, k.x);
      minY = min(minY, k.y);
      maxY = max(maxY, k.y);
    }
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    // Pixel per meter scale factor
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final maxRange = max(rangeX, rangeY);
    final pixelsPerMeter = maxRange > 0 ? min(size.width, size.height) * 0.35 / maxRange : 40.0;

    // Transform garden coords to canvas coords
    Offset toCanvas(double x, double y) {
      return Offset((x - cx) * pixelsPerMeter, (y - cy) * pixelsPerMeter);
    }

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 0.5;
    final gridSize = maxRange > 0 ? (maxRange / 5).ceilToDouble().clamp(1, 100) : 5.0;
    for (double g = (minX - gridSize).floorToDouble(); g <= maxX + gridSize; g += gridSize) {
      final p1 = toCanvas(g, minY - gridSize);
      final p2 = toCanvas(g, maxY + gridSize);
      canvas.drawLine(p1, p2, gridPaint);
    }
    for (double g = (minY - gridSize).floorToDouble(); g <= maxY + gridSize; g += gridSize) {
      final p1 = toCanvas(minX - gridSize, g);
      final p2 = toCanvas(maxX + gridSize, g);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // Draw filled polygon
    if (koseler.length >= 3) {
      final fillPath = Path();
      final firstP = toCanvas(koseler[0].x, koseler[0].y);
      fillPath.moveTo(firstP.dx, firstP.dy);
      for (int i = 1; i < koseler.length; i++) {
        final p = toCanvas(koseler[i].x, koseler[i].y);
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.close();

      // Fill
      final fillPaint = Paint()
        ..color = const Color(0xFFD97706).withOpacity(0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // Stroke
      final strokePaint = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(fillPath, strokePaint);
    } else if (koseler.length == 2) {
      final p1 = toCanvas(koseler[0].x, koseler[0].y);
      final p2 = toCanvas(koseler[1].x, koseler[1].y);
      final linePaint = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 2.5;
      canvas.drawLine(p1, p2, linePaint);
    }

    // Draw edge lengths
    for (int i = 0; i < koseler.length; i++) {
      final current = koseler[i];
      final next = koseler[(i + 1) % koseler.length];
      final p1 = toCanvas(current.x, current.y);
      final p2 = toCanvas(next.x, next.y);
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

      final distance = current.metraj > 0
          ? current.metraj
          : sqrt(pow(next.x - current.x, 2) + pow(next.y - current.y, 2));

      if (distance > 0 && (koseler.length >= 3 || i < koseler.length - 1)) {
        // Background for text
        final textBg = Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: mid, width: 50, height: 18),
            const Radius.circular(4),
          ),
          textBg,
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${distance.toStringAsFixed(1)}m',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2));
      }
    }

    // Draw corner points & labels
    for (int i = 0; i < koseler.length; i++) {
      final p = toCanvas(koseler[i].x, koseler[i].y);

      // Outer ring
      final ringPaint = Paint()
        ..color = const Color(0xFFD97706).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(p, 10, ringPaint);

      // Point
      final pointPaint = Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 5, pointPaint);

      // Label
      final label = '${i + 1}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p.dx + 10, p.dy - 14));

      // Coordinate label in edit mode
      if (editMode) {
        final coordPainter = TextPainter(
          text: TextSpan(
            text: '(${koseler[i].x.toStringAsFixed(1)}, ${koseler[i].y.toStringAsFixed(1)})',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        );
        coordPainter.layout();
        coordPainter.paint(canvas, Offset(p.dx + 10, p.dy));
      }
    }

    // Draw compass indicator at top-right
    final compassPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final compassCenter = Offset((maxX - cx + 2) * pixelsPerMeter, (minY - cy - 2) * pixelsPerMeter);
    canvas.drawLine(compassCenter, compassCenter + const Offset(0, -20), compassPaint);
    final nPainter = TextPainter(
      text: TextSpan(text: 'K', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    nPainter.layout();
    nPainter.paint(canvas, compassCenter + Offset(-nPainter.width / 2, -32));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KrokiPainter oldDelegate) => true;
}
