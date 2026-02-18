import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/bahce.dart';
import '../services/operasyon_service.dart';

/// Kroki aşamaları
enum KrokiAsama { cizim, duzeltme, metreGirisi }

/// Bahçe krokisi çizim ekranı — 3 aşamalı:
/// 1) Çizim: Kullanıcı parmağıyla/mouse ile köşe köşe dokunarak çizer
/// 2) Düzeltme: Sistem çizimi temizler, kullanıcı köşeleri sürükleyerek düzeltir
/// 3) Metre Girişi: Her kenarın gerçek uzunluğunu girer
class KrokiScreen extends StatefulWidget {
  final Bahce bahce;
  const KrokiScreen({super.key, required this.bahce});

  @override
  State<KrokiScreen> createState() => _KrokiScreenState();
}

class _KrokiScreenState extends State<KrokiScreen> {
  final OperasyonService _service = OperasyonService();
  bool _isSaving = false;

  // Aşama kontrolü
  KrokiAsama _asama = KrokiAsama.cizim;

  // Çizim aşaması: ekran pikseli olarak noktalar
  List<Offset> _rawPoints = [];

  // Düzeltme aşaması: temizlenmiş noktalar (piksel)
  List<Offset> _cleanPoints = [];
  int? _draggingIndex; // sürüklenen köşe indeksi

  // Metre girişi aşaması
  List<double> _kenarMetreleri = [];
  List<TextEditingController> _metreControllers = [];

  // Canvas boyutu (build'den yakalanır)
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // Eğer bahçede zaten köşeler varsa, onları yükle
    if (widget.bahce.koseler.isNotEmpty) {
      _asama = KrokiAsama.metreGirisi;
      // Köşeleri ekran koordinatına çevirme initState'de yapılmaz,
      // ilk build'de canvas boyutuna göre yapılacak
    }
  }

  @override
  void dispose() {
    for (final c in _metreControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Bahçedeki mevcut köşeleri ekrana yerleştir
  void _loadExistingCorners() {
    if (widget.bahce.koseler.isEmpty || _canvasSize == Size.zero) return;
    final koseler = widget.bahce.koseler;

    // Bounds hesapla
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final k in koseler) {
      minX = min(minX, k.x);
      maxX = max(maxX, k.x);
      minY = min(minY, k.y);
      maxY = max(maxY, k.y);
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final maxRange = max(rangeX, rangeY);
    final padding = 60.0;
    final usableW = _canvasSize.width - padding * 2;
    final usableH = _canvasSize.height - padding * 2;
    final scale = maxRange > 0 ? min(usableW, usableH) / maxRange : 1.0;

    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    _cleanPoints = koseler.map((k) {
      return Offset(
        (k.x - cx) * scale + _canvasSize.width / 2,
        (k.y - cy) * scale + _canvasSize.height / 2,
      );
    }).toList();

    _kenarMetreleri = List.generate(koseler.length, (i) => koseler[i].metraj);
    _initMetreControllers();
  }

  void _initMetreControllers() {
    for (final c in _metreControllers) {
      c.dispose();
    }
    _metreControllers = List.generate(_kenarMetreleri.length, (i) {
      return TextEditingController(
        text: _kenarMetreleri[i] > 0 ? _kenarMetreleri[i].toStringAsFixed(1) : '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kroki - ${widget.bahce.ad}'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          if (_asama == KrokiAsama.metreGirisi && _cleanPoints.length >= 3)
            IconButton(
              onPressed: _isSaving ? null : _saveCroquis,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              tooltip: 'Kaydet',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildAsamaBar(),
          Expanded(child: _buildBody()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ─── Üst: Aşama göstergesi ─────────────────────────────
  Widget _buildAsamaBar() {
    final labels = ['1. Çiz', '2. Düzelt', '3. Metre Gir'];
    final icons = [Icons.gesture, Icons.auto_fix_high, Icons.straighten];
    final currentIdx = _asama.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFFFFF8E1),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == currentIdx;
          final isDone = i < currentIdx;
          return Expanded(
            child: Row(
              children: [
                if (i > 0) Expanded(child: Container(height: 2, color: isDone ? const Color(0xFFD97706) : Colors.grey.shade300)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFD97706) : isDone ? const Color(0xFFD97706).withOpacity(0.2) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isDone ? Icons.check : icons[i], size: 16, color: isActive ? Colors.white : isDone ? const Color(0xFFD97706) : Colors.grey),
                    const SizedBox(width: 4),
                    Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : isDone ? const Color(0xFFD97706) : Colors.grey.shade600)),
                  ]),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Ana gövde ──────────────────────────────────────────
  Widget _buildBody() {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

      // Mevcut köşeleri yükle (ilk kez)
      if (widget.bahce.koseler.isNotEmpty && _cleanPoints.isEmpty && _asama == KrokiAsama.metreGirisi) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadExistingCorners();
          setState(() {});
        });
      }

      switch (_asama) {
        case KrokiAsama.cizim:
          return _buildCizimCanvas();
        case KrokiAsama.duzeltme:
          return _buildDuzeltmeCanvas();
        case KrokiAsama.metreGirisi:
          return _buildMetreGirisiView();
      }
    });
  }

  // ─── AŞAMA 1: Serbest çizim ────────────────────────────
  Widget _buildCizimCanvas() {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _rawPoints.add(details.localPosition);
        });
      },
      child: Container(
        color: Colors.grey.shade50,
        child: CustomPaint(
          painter: _CizimPainter(points: _rawPoints),
          size: Size.infinite,
          child: _rawPoints.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.touch_app, size: 64, color: Color(0xFFD97706)),
                    const SizedBox(height: 16),
                    Text('Bahçenin köşelerine tıklayın', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Her tıklama bir köşe noktası oluşturur\nSırayla köşe köşe ilerleyin',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  ]).animate().fadeIn(),
                )
              : null,
        ),
      ),
    );
  }

  // ─── AŞAMA 2: Düzeltme (sürükle-bırak) ─────────────────
  Widget _buildDuzeltmeCanvas() {
    return GestureDetector(
      onPanStart: (details) {
        // En yakın noktayı bul
        final pos = details.localPosition;
        double minDist = 40; // dokunma yarıçapı
        int? closest;
        for (int i = 0; i < _cleanPoints.length; i++) {
          final d = (_cleanPoints[i] - pos).distance;
          if (d < minDist) {
            minDist = d;
            closest = i;
          }
        }
        setState(() => _draggingIndex = closest);
      },
      onPanUpdate: (details) {
        if (_draggingIndex != null) {
          setState(() {
            _cleanPoints[_draggingIndex!] = details.localPosition;
          });
        }
      },
      onPanEnd: (_) {
        setState(() => _draggingIndex = null);
      },
      // Uzun basınca köşe sil
      onLongPressStart: (details) {
        final pos = details.localPosition;
        double minDist = 40;
        int? closest;
        for (int i = 0; i < _cleanPoints.length; i++) {
          final d = (_cleanPoints[i] - pos).distance;
          if (d < minDist) {
            minDist = d;
            closest = i;
          }
        }
        if (closest != null && _cleanPoints.length > 3) {
          setState(() => _cleanPoints.removeAt(closest!));
        }
      },
      // Çift tıkla yeni köşe ekle
      onDoubleTapDown: (details) {
        // En yakın kenarın ortasına ekle
        final pos = details.localPosition;
        int insertIdx = _cleanPoints.length; // sona
        double minDist = double.infinity;

        for (int i = 0; i < _cleanPoints.length; i++) {
          final j = (i + 1) % _cleanPoints.length;
          final mid = (_cleanPoints[i] + _cleanPoints[j]) / 2;
          final d = (mid - pos).distance;
          if (d < minDist) {
            minDist = d;
            insertIdx = j;
          }
        }
        setState(() => _cleanPoints.insert(insertIdx, pos));
      },
      child: Container(
        color: Colors.grey.shade50,
        child: CustomPaint(
          painter: _DuzeltmePainter(points: _cleanPoints, draggingIndex: _draggingIndex),
          size: Size.infinite,
          child: _cleanPoints.isEmpty ? const Center(child: CircularProgressIndicator()) : null,
        ),
      ),
    );
  }

  // ─── AŞAMA 3: Metre girişi ──────────────────────────────
  Widget _buildMetreGirisiView() {
    return Column(
      children: [
        // Üst: Canvas
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey.shade50,
            child: CustomPaint(
              painter: _MetrePainter(points: _cleanPoints, metreler: _kenarMetreleri),
              size: Size.infinite,
            ),
          ),
        ),
        const Divider(height: 1),
        // Alt: Kenar metre listesi
        Expanded(
          flex: 2,
          child: _metreControllers.isEmpty
              ? Center(child: Text('Köşeler yükleniyor...', style: TextStyle(color: Colors.grey.shade400)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _cleanPoints.length,
                  itemBuilder: (context, i) {
                    final j = (i + 1) % _cleanPoints.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Kenar etiketi
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Kenar ${i + 1}→${j + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Metre input
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _metreControllers[i],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'metre',
                                  suffixText: 'm',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFD97706), width: 2),
                                  ),
                                ),
                                onChanged: (val) {
                                  final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                                  _kenarMetreleri[i] = parsed;
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Alt buton bar ──────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Sol butonlar
            if (_asama != KrokiAsama.cizim)
              OutlinedButton.icon(
                onPressed: _geriDon,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Geri'),
              ),
            if (_asama == KrokiAsama.cizim && _rawPoints.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _rawPoints.removeLast();
                }),
                icon: const Icon(Icons.undo, size: 18, color: Colors.red),
                label: const Text('Geri Al', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            if (_asama == KrokiAsama.cizim && _rawPoints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _rawPoints.clear();
                  }),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Temizle', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            const Spacer(),
            // Bilgi
            if (_asama == KrokiAsama.cizim)
              Text('${_rawPoints.length} köşe', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            if (_asama == KrokiAsama.duzeltme)
              Text('${_cleanPoints.length} köşe', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            if (_asama == KrokiAsama.metreGirisi)
              Text(
                'Alan: ${_calculateArea().toStringAsFixed(1)} m²',
                style: const TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            const SizedBox(width: 12),
            // İleri butonu
            if (_asama != KrokiAsama.metreGirisi)
              ElevatedButton.icon(
                onPressed: _canAdvance() ? _ileriGit : null,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(_asama == KrokiAsama.cizim ? 'Düzelt' : 'Metre Gir'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              ),
            if (_asama == KrokiAsama.metreGirisi)
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCroquis,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  bool _canAdvance() {
    if (_asama == KrokiAsama.cizim) return _rawPoints.length >= 3;
    if (_asama == KrokiAsama.duzeltme) return _cleanPoints.length >= 3;
    return false;
  }

  void _ileriGit() {
    if (_asama == KrokiAsama.cizim) {
      // Çizim → Düzeltme: noktaları kopyala
      _cleanPoints = List<Offset>.from(_rawPoints);
      _simplifyPoints();
      setState(() => _asama = KrokiAsama.duzeltme);
    } else if (_asama == KrokiAsama.duzeltme) {
      // Düzeltme → Metre Girişi
      _kenarMetreleri = List.filled(_cleanPoints.length, 0.0);
      _initMetreControllers();
      setState(() => _asama = KrokiAsama.metreGirisi);
    }
  }

  void _geriDon() {
    if (_asama == KrokiAsama.duzeltme) {
      setState(() => _asama = KrokiAsama.cizim);
    } else if (_asama == KrokiAsama.metreGirisi) {
      setState(() => _asama = KrokiAsama.duzeltme);
    }
  }

  /// Douglas-Peucker benzeri basitleştirme — çok yakın noktaları ele
  void _simplifyPoints() {
    if (_cleanPoints.length <= 3) return;

    final simplified = <Offset>[_cleanPoints.first];
    const minDistance = 25.0; // minimum 25px aralık

    for (int i = 1; i < _cleanPoints.length; i++) {
      if ((_cleanPoints[i] - simplified.last).distance >= minDistance) {
        simplified.add(_cleanPoints[i]);
      }
    }

    // Son nokta ile ilk nokta çok yakınsa sondakini çıkar
    if (simplified.length > 3 && (simplified.last - simplified.first).distance < minDistance) {
      simplified.removeLast();
    }

    if (simplified.length >= 3) {
      _cleanPoints = simplified;
    }
  }

  /// Piksel noktalardan metrik BahceKose listesi oluştur
  List<BahceKose> _buildKoseler() {
    // Piksel koordinatları normalize et (sol-üst 0,0 referans, metre oranıyla)
    if (_cleanPoints.isEmpty) return [];

    // Tüm metrelerin ortalaması ile piksel↔metre oranı bul
    double totalPixelPerimeter = 0;
    double totalMetrePerimeter = 0;

    for (int i = 0; i < _cleanPoints.length; i++) {
      final j = (i + 1) % _cleanPoints.length;
      totalPixelPerimeter += (_cleanPoints[j] - _cleanPoints[i]).distance;
      totalMetrePerimeter += _kenarMetreleri[i];
    }

    // Eğer metre girilmemişse, piksel = metre say
    final pixelToMetre = totalMetrePerimeter > 0 ? totalMetrePerimeter / totalPixelPerimeter : 0.1;

    // Min x,y bul
    double minX = double.infinity, minY = double.infinity;
    for (final p in _cleanPoints) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
    }

    return List.generate(_cleanPoints.length, (i) {
      return BahceKose(
        x: (_cleanPoints[i].dx - minX) * pixelToMetre,
        y: (_cleanPoints[i].dy - minY) * pixelToMetre,
        metraj: _kenarMetreleri[i],
      );
    });
  }

  double _calculateArea() {
    final koseler = _buildKoseler();
    if (koseler.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < koseler.length; i++) {
      final j = (i + 1) % koseler.length;
      area += koseler[i].x * koseler[j].y;
      area -= koseler[j].x * koseler[i].y;
    }
    return area.abs() / 2;
  }

  Future<void> _saveCroquis() async {
    setState(() => _isSaving = true);
    try {
      final koseler = _buildKoseler();
      await _service.updateBahce(widget.bahce.copyWith(
        koseler: koseler,
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

// ═══════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════

/// Aşama 1: Çizim — noktalar ve çizgiler
class _CizimPainter extends CustomPainter {
  final List<Offset> points;
  _CizimPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Çizgiler
    final linePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      // Kapatma çizgisi (şeffaf)
      if (points.length >= 3) {
        final closePaint = Paint()
          ..color = const Color(0xFFD97706).withOpacity(0.3)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(points.last, points.first, closePaint);

        // İçini hafif doldur
        final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
        for (final p in points.skip(1)) {
          fillPath.lineTo(p.dx, p.dy);
        }
        fillPath.close();
        canvas.drawPath(fillPath, Paint()..color = const Color(0xFFD97706).withOpacity(0.06));
      }
      canvas.drawPath(path, linePaint);
    }

    // Noktalar
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 8, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 8, Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      canvas.drawCircle(points[i], 4, Paint()..color = const Color(0xFFD97706));

      // Numara
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, points[i] + const Offset(12, -16));
    }
  }

  @override
  bool shouldRepaint(covariant _CizimPainter old) => true;
}

/// Aşama 2: Düzeltme — sürüklenebilir köşeler
class _DuzeltmePainter extends CustomPainter {
  final List<Offset> points;
  final int? draggingIndex;
  _DuzeltmePainter({required this.points, this.draggingIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // İçini doldur
    if (points.length >= 3) {
      final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.close();
      canvas.drawPath(fillPath, Paint()..color = const Color(0xFFD97706).withOpacity(0.08));
      canvas.drawPath(fillPath, Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round);
    }

    // Noktalar (büyük, sürüklenebilir görünüm)
    for (int i = 0; i < points.length; i++) {
      final isDragging = i == draggingIndex;
      final radius = isDragging ? 14.0 : 10.0;

      // Dış halka
      canvas.drawCircle(points[i], radius + 4, Paint()..color = const Color(0xFFD97706).withOpacity(0.15));
      // Beyaz dolgu
      canvas.drawCircle(points[i], radius, Paint()..color = Colors.white);
      // Turuncu kenar
      canvas.drawCircle(points[i], radius, Paint()
        ..color = isDragging ? Colors.deepOrange : const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      // İç nokta
      canvas.drawCircle(points[i], 4, Paint()..color = isDragging ? Colors.deepOrange : const Color(0xFFD97706));

      // Numara
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: TextStyle(
          color: isDragging ? Colors.deepOrange : const Color(0xFFD97706),
          fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, points[i] + Offset(radius + 4, -16));
    }

    // İpucu yazısı
    final hintPainter = TextPainter(
      text: TextSpan(
        text: '👆 Köşeleri sürükleyin  •  2× tıkla: yeni köşe  •  Uzun bas: sil',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 32);
    hintPainter.paint(canvas, Offset((size.width - hintPainter.width) / 2, size.height - 30));
  }

  @override
  bool shouldRepaint(covariant _DuzeltmePainter old) => true;
}

/// Aşama 3: Metre gösterimi
class _MetrePainter extends CustomPainter {
  final List<Offset> points;
  final List<double> metreler;
  _MetrePainter({required this.points, required this.metreler});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) return;

    // İçini doldur
    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = const Color(0xFFD97706).withOpacity(0.08));
    canvas.drawPath(fillPath, Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke);

    // Kenar bilgileri
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      final mid = (points[i] + points[j]) / 2;
      final metre = metreler.length > i ? metreler[i] : 0.0;
      final label = metre > 0 ? '${metre.toStringAsFixed(1)}m' : '?';

      // Arka plan
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: mid, width: 52, height: 20), const Radius.circular(5)),
        Paint()..color = metre > 0 ? Colors.white.withOpacity(0.9) : Colors.orange.shade50.withOpacity(0.9),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: mid, width: 52, height: 20), const Radius.circular(5)),
        Paint()..color = metre > 0 ? const Color(0xFFD97706).withOpacity(0.3) : Colors.red.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1,
      );

      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(
          color: metre > 0 ? const Color(0xFFD97706) : Colors.red, fontSize: 11, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
    }

    // Köşe noktaları
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 6, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 6, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 2);

      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, points[i] + const Offset(10, -14));
    }
  }

  @override
  bool shouldRepaint(covariant _MetrePainter old) => true;
}
