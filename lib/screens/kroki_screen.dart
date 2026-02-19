import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bahce.dart';
import '../services/gps_helper.dart';
import '../services/operasyon_service.dart';

// ═══════════════════════════════════════════════════════════
// KROKİ EKRANI v3
// Akış: Bahçe Sınırı → Parseller → Sıralar → Önizleme
// GPS + Parsel Polygon + Otomatik Sıra Oluşturma
// ═══════════════════════════════════════════════════════════

enum KrokiModu { bahceSiniri, parselCizim, siraOlusturma, onizleme }

class KrokiScreen extends StatefulWidget {
  final Bahce bahce;
  const KrokiScreen({super.key, required this.bahce});

  @override
  State<KrokiScreen> createState() => _KrokiScreenState();
}

class _KrokiScreenState extends State<KrokiScreen> {
  final OperasyonService _service = OperasyonService();
  bool _isSaving = false;

  KrokiModu _mod = KrokiModu.bahceSiniri;

  // ── Bahçe sınır köşeleri (piksel ekran koordinatları) ──
  List<Offset> _bahcePoints = [];
  List<double> _bahceMetreler = [];
  List<TextEditingController> _bahceMetreCtrl = [];

  // ── GPS verileri ──
  List<GpsKonum?> _gpsPositions = [];
  List<double?> _gpsDistances = [];
  bool _gpsLoading = false;

  // ── Parseller ──
  List<_ParselData> _parseller = [];
  int _activeParselIdx = -1;

  // ── Sıra oluşturma ──
  int _siraParselIdx = -1;

  Size _canvasSize = Size.zero;

  // ── Sürükle-bırak ──
  int? _draggingBahceIdx;
  int? _draggingParselIdx;
  int? _draggingParselKoseIdx;

  bool _existingLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkGps();
    _loadExistingParseller();
  }

  @override
  void dispose() {
    _zoomCtrl.dispose();
    for (final c in _bahceMetreCtrl) {
      c.dispose();
    }
    for (final p in _parseller) {
      for (final c in p.metreCtrl) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _loadExistingParseller() {
    if (widget.bahce.parseller.isNotEmpty) {
      for (final p in widget.bahce.parseller) {
        _parseller.add(_ParselData(
          ad: p.ad,
          cins: p.cins,
          siraAraligi: p.siraAraligi,
          saksiAraligi: p.saksiAraligi,
          siraAcisi: p.siraAcisi,
          siralar: p.siralar,
        ));
      }
    }
    if (widget.bahce.koseler.isNotEmpty) {
      _mod = KrokiModu.onizleme;
    }
  }

  Future<void> _checkGps() async {
    // GPS artık her zaman kullanılabilir — hata varsa buton'a basınca gösterilir
  }

  Future<void> _getGpsPosition(int index) async {
    setState(() => _gpsLoading = true);
    try {
      final pos = await getCurrentGpsPosition();

      while (_gpsPositions.length <= index) {
        _gpsPositions.add(null);
      }
      _gpsPositions[index] = pos;

      while (_gpsDistances.length <= index) {
        _gpsDistances.add(null);
      }
      // GPS mesafesi: önceki köşeye
      if (index > 0 && _gpsPositions[index - 1] != null) {
        final prev = _gpsPositions[index - 1]!;
        final dist = gpsDistanceBetween(
          prev.latitude,
          prev.longitude,
          pos.latitude,
          pos.longitude,
        );
        _gpsDistances[index - 1] = dist;
      }
      // Son→İlk kapama
      if (index == _bahcePoints.length - 1 &&
          _bahcePoints.length >= 3 &&
          _gpsPositions.isNotEmpty &&
          _gpsPositions[0] != null) {
        final first = _gpsPositions[0]!;
        final dist = gpsDistanceBetween(
          pos.latitude,
          pos.longitude,
          first.latitude,
          first.longitude,
        );
        _gpsDistances[index] = dist;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📍 GPS alındı: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('GPS hatası: $e')));
      }
    }
    setState(() => _gpsLoading = false);
  }

  Future<void> _getParselGpsPosition(int parselIdx, int pointIdx) async {
    if (parselIdx < 0 || parselIdx >= _parseller.length) return;
    setState(() => _gpsLoading = true);
    try {
      final pos = await getCurrentGpsPosition();
      final p = _parseller[parselIdx];

      while (p.gpsPositions.length <= pointIdx) {
        p.gpsPositions.add(null);
      }
      p.gpsPositions[pointIdx] = pos;

      // GPS mesafesini metre alanına yaz (varsa önceki köşeye mesafe)
      if (pointIdx > 0 && p.gpsPositions[pointIdx - 1] != null) {
        final prev = p.gpsPositions[pointIdx - 1]!;
        final dist = gpsDistanceBetween(
          prev.latitude, prev.longitude,
          pos.latitude, pos.longitude,
        );
        if (pointIdx - 1 < p.metreler.length) {
          p.metreler[pointIdx - 1] = dist;
          p.initMetreCtrl();
        }
      }
      // Kapanış (son→ilk)
      if (pointIdx == p.points.length - 1 &&
          p.points.length >= 3 &&
          p.gpsPositions.isNotEmpty &&
          p.gpsPositions[0] != null) {
        final first = p.gpsPositions[0]!;
        final dist = gpsDistanceBetween(
          pos.latitude, pos.longitude,
          first.latitude, first.longitude,
        );
        if (pointIdx < p.metreler.length) {
          p.metreler[pointIdx] = dist;
          p.initMetreCtrl();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📍 Parsel GPS alındı: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('GPS hatası: $e')));
      }
    }
    setState(() => _gpsLoading = false);
  }

  // ─── Mevcut köşeleri piksel'e yükle ───
  void _loadBahcePointsFromModel() {
    final koseler = widget.bahce.koseler;
    if (koseler.isEmpty || _canvasSize == Size.zero) return;

    // Tüm noktaların (bahçe + parsel) global bounding box'ını bul
    final allKoseler = <BahceKose>[...koseler];
    for (final p in widget.bahce.parseller) {
      allKoseler.addAll(p.koseler);
    }
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final k in allKoseler) {
      minX = min(minX, k.x);
      maxX = max(maxX, k.x);
      minY = min(minY, k.y);
      maxY = max(maxY, k.y);
    }
    const padding = 80.0;
    final targetW = _canvasSize.width - padding * 2;
    final targetH = _canvasSize.height - padding * 2;
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final maxRange = max(rangeX, rangeY);
    // Kaydetme sırasında pxPerMetre kullanıldı.
    // Yüklerken aynı oranla geri çevirmeliyiz.
    // Metre/piksel oranını bahçe kenar metreleri + metre koordinatlarından hesapla
    // pxPerMetre_save = toplamPiksel / toplamMetre idi
    // metre_koordinat = (piksel - centroid) / pxPerMetre_save
    // Geri: piksel = metre_koordinat * pxPerMetre_load + screenCenter
    // pxPerMetre_load = min(targetW, targetH) / maxRange (fit-to-screen)
    final pxPerMetre =
        maxRange > 0 ? min(targetW, targetH) / maxRange : 1.0;
    final centerX = _canvasSize.width / 2;
    final centerY = _canvasSize.height / 2;

    // Tüm koordinatlar bahçe centroid'e göre kaydedildi (centroid = 0,0)
    // px = x * pxPerMetre + screenCenter
    _bahcePoints = koseler
        .map((k) => Offset(
              k.x * pxPerMetre + centerX,
              k.y * pxPerMetre + centerY,
            ))
        .toList();
    _bahceMetreler = koseler.map((k) => k.metraj).toList();
    _initBahceMetreCtrl();

    // Parsel köşelerini AYNI pxPerMetre ve AYNI centerX/Y ile yükle
    // (parseller de bahçe centroid'e göre kaydedildi)
    for (int pi = 0;
        pi < _parseller.length && pi < widget.bahce.parseller.length;
        pi++) {
      final pKoseler = widget.bahce.parseller[pi].koseler;
      if (pKoseler.isNotEmpty) {
        _parseller[pi].points = pKoseler
            .map((k) => Offset(
                  k.x * pxPerMetre + centerX,
                  k.y * pxPerMetre + centerY,
                ))
            .toList();
        _parseller[pi].metreler =
            pKoseler.map((k) => k.metraj).toList();
        _parseller[pi].initMetreCtrl();
      }
    }
    _existingLoaded = true;
  }

  void _initBahceMetreCtrl() {
    for (final c in _bahceMetreCtrl) {
      c.dispose();
    }
    _bahceMetreCtrl = List.generate(
      _bahceMetreler.length,
      (i) => TextEditingController(
        text: _bahceMetreler[i] > 0
            ? _bahceMetreler[i].toStringAsFixed(1)
            : '',
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kroki — ${widget.bahce.ad}'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          if (_bahcePoints.length >= 3)
            IconButton(
              onPressed: _shareKroki,
              icon: const Icon(Icons.share),
              tooltip: 'Krokiyi Paylaş',
            ),
          if (_mod == KrokiModu.onizleme ||
              _parseller.any((p) => p.siralar.isNotEmpty))
            IconButton(
              onPressed: _isSaving ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              tooltip: 'Tümünü Kaydet',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildModBar(),
          Expanded(child: _buildBody()),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  // ─── MOD BAR ────────────────────────────────────────────
  Widget _buildModBar() {
    final items = [
      ('Bahçe Sınırı', Icons.crop_free),
      ('Parseller', Icons.grid_view),
      ('Sıralar', Icons.view_column),
      ('Önizleme', Icons.visibility),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFFFFF8E1),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == _mod.index;
          final isDone = i < _mod.index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0 ||
                    (i == 1 && _bahcePoints.length >= 3) ||
                    (i == 2 && _parseller.isNotEmpty) ||
                    (i == 3)) {
                  setState(() => _mod = KrokiModu.values[i]);
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFD97706)
                      : isDone
                          ? const Color(0xFFD97706).withOpacity(0.15)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : items[i].$2,
                      size: 18,
                      color: isActive
                          ? Colors.white
                          : isDone
                              ? const Color(0xFFD97706)
                              : Colors.grey,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : isDone
                                ? const Color(0xFFD97706)
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Parsel alan hesabı (Shoelace formülü, piksel → m²)
  double _calcParselAlan(_ParselData p) {
    if (p.points.length < 3) return 0;
    final pxPerM = _calcParselPxPerMetre(p);
    if (pxPerM <= 0) return 0;
    double area = 0;
    for (int i = 0; i < p.points.length; i++) {
      final j = (i + 1) % p.points.length;
      area += p.points[i].dx * p.points[j].dy;
      area -= p.points[j].dx * p.points[i].dy;
    }
    final pxArea = area.abs() / 2;
    return pxArea / (pxPerM * pxPerM);
  }

  /// Bahçe toplam alan (piksel → m²)
  double _calcBahceAlan() {
    if (_bahcePoints.length < 3) return 0;
    final pxPerM = _calcGlobalPxPerMetre();
    if (pxPerM <= 0) return 0;
    double area = 0;
    for (int i = 0; i < _bahcePoints.length; i++) {
      final j = (i + 1) % _bahcePoints.length;
      area += _bahcePoints[i].dx * _bahcePoints[j].dy;
      area -= _bahcePoints[j].dx * _bahcePoints[i].dy;
    }
    return area.abs() / 2 / (pxPerM * pxPerM);
  }

  /// Krokiyi resim olarak paylaş
  Future<void> _shareKroki() async {
    try {
      // Tüm noktaların bounding box'ını bul
      final allPoints = <Offset>[..._bahcePoints];
      for (final p in _parseller) {
        allPoints.addAll(p.points);
      }
      if (allPoints.isEmpty) return;

      double minX = double.infinity, maxX = -double.infinity;
      double minY = double.infinity, maxY = -double.infinity;
      for (final pt in allPoints) {
        minX = min(minX, pt.dx);
        maxX = max(maxX, pt.dx);
        minY = min(minY, pt.dy);
        maxY = max(maxY, pt.dy);
      }

      const margin = 60.0;
      final w = (maxX - minX + margin * 2).clamp(400.0, 2000.0);
      final h = (maxY - minY + margin * 2).clamp(400.0, 2000.0);

      // Canvas'a çiz
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Beyaz arka plan
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Colors.white,
      );

      // Koordinatları kaydır
      canvas.translate(-minX + margin, -minY + margin);

      // Painter ile çiz
      final painter = _OnizlemePainter(
        bahcePoints: _bahcePoints,
        parseller: _parseller,
        pxPerMetre: _calcGlobalPxPerMetre(),
        bahceMetreler: _bahceMetreler,
      );
      painter.paint(canvas, Size(w, h));

      // Başlık ekle
      canvas.translate(minX - margin, minY - margin);
      final titleTp = TextPainter(
        text: TextSpan(
          text: '${widget.bahce.ad} — Kroki',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      titleTp.paint(canvas, const Offset(16, 12));

      // Alan bilgisi
      final bahceAlan = _calcBahceAlan();
      final parselInfo = _parseller
          .where((p) => p.points.length >= 3)
          .map((p) => '${p.ad}: ${_calcParselAlan(p).toStringAsFixed(1)} m²')
          .join(' | ');
      final infoTp = TextPainter(
        text: TextSpan(
          text: 'Toplam: ${bahceAlan.toStringAsFixed(1)} m²  •  $parselInfo',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      infoTp.paint(canvas, Offset(16, h - 24));

      // Resme dönüştür
      final picture = recorder.endRecording();
      final img = await picture.toImage(w.toInt(), h.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Paylaş
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: '${widget.bahce.ad}_kroki.png')],
          text: '${widget.bahce.ad} — Kroki (${bahceAlan.toStringAsFixed(0)} m²)',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Paylaşma hatası: $e')));
      }
    }
  }

  // ─── BODY ───────────────────────────────────────────────
  Widget _buildBody() {
    return LayoutBuilder(builder: (ctx, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

      // Mevcut bahçe köşelerini piksel olarak yükle (bir kez)
      if (widget.bahce.koseler.isNotEmpty &&
          _bahcePoints.isEmpty &&
          !_existingLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadBahcePointsFromModel();
          if (mounted) setState(() {});
        });
      }

      switch (_mod) {
        case KrokiModu.bahceSiniri:
          return _buildBahceSiniriView();
        case KrokiModu.parselCizim:
          return _buildParselCizimView();
        case KrokiModu.siraOlusturma:
          return _buildSiraOlusturmaView();
        case KrokiModu.onizleme:
          return _buildOnizlemeView();
      }
    });
  }

  // ═══════════════════════════════════════════════════════
  // 1) BAHÇE SINIRI
  // ═══════════════════════════════════════════════════════
  // ── Zoom kontrolcüler ──
  final TransformationController _zoomCtrl = TransformationController();

  Widget _buildBahceSiniriView() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: InteractiveViewer(
            transformationController: _zoomCtrl,
            minScale: 0.3,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(300),
            panEnabled: _draggingBahceIdx == null, // drag sırasında kaydırma kapalı
            child: GestureDetector(
              onTapDown: (d) {
                final pos = d.localPosition;
                // Yakın köşe var mı kontrol et (sürüklemek için)
                final hitIdx = _findNearBahceKose(pos);
                if (hitIdx >= 0) return; // drag'da handle edilecek
                setState(() {
                  _bahcePoints.add(pos);
                  _bahceMetreler.add(0);
                  _gpsPositions.add(null);
                  _gpsDistances.add(null);
                  _initBahceMetreCtrl();
                });
              },
              onLongPressStart: (d) {
                final idx = _findNearBahceKose(d.localPosition);
                if (idx >= 0) {
                  setState(() => _draggingBahceIdx = idx);
                }
              },
              onLongPressMoveUpdate: (d) {
                if (_draggingBahceIdx != null) {
                  setState(() {
                    _bahcePoints[_draggingBahceIdx!] = d.localPosition;
                  });
                }
              },
              onLongPressEnd: (_) {
                if (_draggingBahceIdx != null) {
                  setState(() => _draggingBahceIdx = null);
                }
              },
              onDoubleTapDown: (d) {
                final idx = _findNearBahceKose(d.localPosition);
                if (idx >= 0 && _bahcePoints.length > 1) {
                  _showKoseSilDialog(idx, isBahce: true);
                }
              },
              child: Container(
                width: 2000,
                height: 2000,
                color: Colors.grey.shade50,
                child: CustomPaint(
                  painter: _BahceSinirPainter(
                    points: _bahcePoints,
                    dragging: _draggingBahceIdx,
                    metreler: _bahceMetreler,
                  ),
                  size: const Size(2000, 2000),
                  child: _bahcePoints.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 56,
                              color: const Color(0xFFD97706),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Köşeye tıklayın veya GPS ile işaretleyin',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sırası ile köşe noktalarını belirleyin',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ).animate().fadeIn())
                      : null,
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // Kenar metreleri listesi
        if (_bahcePoints.length >= 2)
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _bahcePoints.length,
              itemBuilder: (ctx, i) {
                final j = (i + 1) % _bahcePoints.length;
                final gpsDist = i < _gpsDistances.length
                    ? _gpsDistances[i]
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${i + 1}→${j + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            controller: _bahceMetreCtrl[i],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'metre',
                              suffixText: 'm',
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 2),
                              ),
                            ),
                            onChanged: (v) {
                              _bahceMetreler[i] =
                                  double.tryParse(
                                          v.replaceAll(',', '.')) ??
                                      0;
                              _rescaleBahcePoints();
                            },
                          ),
                        ),
                      ),
                      if (gpsDist != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '📍${gpsDist.toStringAsFixed(1)}m',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 38,
                        width: 68,
                        child: ElevatedButton(
                          onPressed: _gpsLoading
                              ? null
                              : () => _getGpsPosition(i),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (i < _gpsPositions.length && _gpsPositions[i] != null)
                                ? Colors.green
                                : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (i < _gpsPositions.length && _gpsPositions[i] != null)
                                    ? Icons.gps_fixed
                                    : Icons.gps_not_fixed,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                (i < _gpsPositions.length && _gpsPositions[i] != null)
                                    ? 'GPS✓'
                                    : 'GPS',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
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

  // ═══════════════════════════════════════════════════════
  // 2) PARSEL ÇİZİMİ
  // ═══════════════════════════════════════════════════════
  Widget _buildParselCizimView() {
    return Column(
      children: [
        // Üst: parsel sekmeleri
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._parseller.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(
                        right: 6, top: 6, bottom: 6),
                    child: ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.value.ad, style: const TextStyle(fontSize: 12)),
                          if (e.value.cins != null && e.value.cins!.isNotEmpty)
                            Text(e.value.cins!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      selected: _activeParselIdx == e.key,
                      selectedColor:
                          const Color(0xFF059669).withOpacity(0.2),
                      onSelected: (_) =>
                          setState(() => _activeParselIdx = e.key),
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ActionChip(
                  avatar: const Icon(Icons.add,
                      size: 16, color: Color(0xFF059669)),
                  label: const Text('Parsel Ekle',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF059669))),
                  onPressed: _addNewParsel,
                ),
              ),
            ],
          ),
        ),
        // Canvas
        Expanded(
          flex: 3,
          child: InteractiveViewer(
            transformationController: _zoomCtrl,
            minScale: 0.3,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(300),
            panEnabled: _draggingParselKoseIdx == null,
            child: GestureDetector(
              onTapDown: (d) {
                if (_activeParselIdx >= 0 &&
                    _activeParselIdx < _parseller.length) {
                  final pos = d.localPosition;
                  // Yakın köşe var mı kontrol et
                  final hitIdx = _findNearParselKose(pos, _activeParselIdx);
                  if (hitIdx >= 0) return;
                  setState(() {
                    _parseller[_activeParselIdx].points.add(pos);
                    _parseller[_activeParselIdx].metreler.add(0);
                    _parseller[_activeParselIdx].initMetreCtrl();
                  });
                }
              },
              onLongPressStart: (d) {
                if (_activeParselIdx >= 0 && _activeParselIdx < _parseller.length) {
                  final idx = _findNearParselKose(d.localPosition, _activeParselIdx);
                  if (idx >= 0) {
                    setState(() {
                      _draggingParselIdx = _activeParselIdx;
                      _draggingParselKoseIdx = idx;
                    });
                  }
                }
              },
              onLongPressMoveUpdate: (d) {
                if (_draggingParselIdx != null && _draggingParselKoseIdx != null) {
                  setState(() {
                    _parseller[_draggingParselIdx!].points[_draggingParselKoseIdx!] = d.localPosition;
                  });
                }
              },
              onLongPressEnd: (_) {
                setState(() {
                  _draggingParselIdx = null;
                  _draggingParselKoseIdx = null;
                });
              },
              onDoubleTapDown: (d) {
                if (_activeParselIdx >= 0 && _activeParselIdx < _parseller.length) {
                  final idx = _findNearParselKose(d.localPosition, _activeParselIdx);
                  if (idx >= 0 && _parseller[_activeParselIdx].points.length > 1) {
                    _showKoseSilDialog(idx, isBahce: false, parselIdx: _activeParselIdx);
                  }
                }
              },
              child: Container(
                width: 2000,
                height: 2000,
                color: Colors.grey.shade50,
                child: CustomPaint(
                  painter: _ParselCizimPainter(
                    bahcePoints: _bahcePoints,
                    parseller: _parseller,
                    activeIdx: _activeParselIdx,
                    draggingParselIdx: _draggingParselIdx,
                    draggingKoseIdx: _draggingParselKoseIdx,
                  ),
                  size: const Size(2000, 2000),
                  child: _parseller.isEmpty || _activeParselIdx < 0
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grid_view,
                                  size: 48,
                                  color: Color(0xFF059669)),
                              const SizedBox(height: 10),
                              Text(
                                'Önce parsel ekleyin, sonra köşe tıklayın',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // Alt: aktif parsel metre listesi
        if (_activeParselIdx >= 0 &&
            _activeParselIdx < _parseller.length &&
            _parseller[_activeParselIdx].points.length >= 2)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Parsel silme
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        _parseller[_activeParselIdx].ad,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669)),
                      ),
                      if (_parseller[_activeParselIdx].points.length >= 3) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_calcParselAlan(_parseller[_activeParselIdx]).toStringAsFixed(1)} m²',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _parseller.removeAt(_activeParselIdx);
                          _activeParselIdx = _parseller.isEmpty
                              ? -1
                              : max(0, _activeParselIdx - 1);
                        }),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.red),
                        label: const Text('Sil',
                            style: TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    itemCount:
                        _parseller[_activeParselIdx].points.length,
                    itemBuilder: (ctx, i) {
                      final p = _parseller[_activeParselIdx];
                      final j = (i + 1) % p.points.length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${i + 1}→${j + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: TextField(
                                  controller: p.metreCtrl[i],
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'metre',
                                    suffixText: 'm',
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF059669),
                                          width: 2),
                                    ),
                                  ),
                                  onChanged: (v) {
                                    p.metreler[i] =
                                        double.tryParse(
                                                v.replaceAll(',', '.')) ??
                                            0;
                                    _rescaleParselPoints(_activeParselIdx);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 38,
                              width: 60,
                              child: ElevatedButton(
                                onPressed: _gpsLoading
                                    ? null
                                    : () => _getParselGpsPosition(_activeParselIdx, i),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (i < p.gpsPositions.length && p.gpsPositions[i] != null)
                                      ? Colors.green
                                      : const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (i < p.gpsPositions.length && p.gpsPositions[i] != null)
                                          ? Icons.gps_fixed
                                          : Icons.gps_not_fixed,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      (i < p.gpsPositions.length && p.gpsPositions[i] != null)
                                          ? '✓'
                                          : 'GPS',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
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
            ),
          ),
      ],
    );
  }

  void _addNewParsel() {
    final nameCtrl =
        TextEditingController(text: 'P-${_parseller.length + 1}');
    final cinsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Parsel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Parsel Adı',
                hintText: 'ör: O_07',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cinsCtrl,
              decoration: InputDecoration(
                labelText: 'Fidan Cinsi',
                hintText: 'ör: Domates, Biber, Çilek...',
                prefixIcon: const Icon(Icons.eco, color: Color(0xFF059669)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                _parseller.add(_ParselData(
                  ad: nameCtrl.text.trim(),
                  cins: cinsCtrl.text.trim().isNotEmpty
                      ? cinsCtrl.text.trim()
                      : null,
                ));
                _activeParselIdx = _parseller.length - 1;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 3) SIRA OLUŞTURMA
  // ═══════════════════════════════════════════════════════
  Widget _buildSiraOlusturmaView() {
    return Column(
      children: [
        // Parsel seçim sekmeleri
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._parseller.asMap().entries.map((e) {
                final hasSira = e.value.siralar.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(
                      right: 6, top: 6, bottom: 6),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.value.ad,
                            style: const TextStyle(fontSize: 12)),
                        if (hasSira) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check,
                              size: 14,
                              color: Colors.green.shade700),
                        ],
                      ],
                    ),
                    selected: _siraParselIdx == e.key,
                    selectedColor: Colors.purple.withOpacity(0.2),
                    onSelected: (_) =>
                        setState(() => _siraParselIdx = e.key),
                  ),
                );
              }),
            ],
          ),
        ),
        // Canvas
        Expanded(
          flex: 3,
          child: InteractiveViewer(
            transformationController: _zoomCtrl,
            minScale: 0.3,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(300),
            child: Container(
              width: 2000,
              height: 2000,
              color: Colors.grey.shade50,
              child: CustomPaint(
                painter: _SiraPainter(
                  bahcePoints: _bahcePoints,
                  parseller: _parseller,
                  activeParselIdx: _siraParselIdx,
                  pxPerMetre: _calcGlobalPxPerMetre(),
                ),
                size: const Size(2000, 2000),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // Alt: sıra ayarları
        if (_siraParselIdx >= 0 && _siraParselIdx < _parseller.length)
          Expanded(
            flex: 2,
            child: _buildSiraAyarPanel(),
          ),
      ],
    );
  }

  Widget _buildSiraAyarPanel() {
    final p = _parseller[_siraParselIdx];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${p.ad} — Sıra Ayarları',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              if (p.points.length >= 3) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_calcParselAlan(p).toStringAsFixed(1)} m²',
                    style: const TextStyle(fontSize: 13, color: Colors.purple, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Sıra Aralığı (m)',
                  p.siraAraligi,
                  (v) => setState(() => p.siraAraligi = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  'Saksı Aralığı (m)',
                  p.saksiAraligi,
                  (v) => setState(() => p.saksiAraligi = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Sıra Yönü — Hangi kenara paralel?',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          if (p.points.length >= 3)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(p.points.length, (ki) {
                final kj = (ki + 1) % p.points.length;
                final selected = p.seciliKenarIdx == ki;
                return ChoiceChip(
                  label: Text('Kenar ${ki + 1}→${kj + 1}', style: const TextStyle(fontSize: 13)),
                  selected: selected,
                  selectedColor: Colors.purple.withOpacity(0.25),
                  avatar: selected ? const Icon(Icons.check, size: 14, color: Colors.purple) : null,
                  onSelected: (_) {
                    setState(() {
                      p.seciliKenarIdx = ki;
                      // Kenarın açısını hesapla
                      final a = p.points[ki];
                      final b = p.points[kj];
                      p.siraAcisi = atan2(b.dy - a.dy, b.dx - a.dx) * 180 / pi;
                    });
                  },
                );
              }),
            )
          else
            Text('Parsel çiziminde en az 3 köşe gerekli',
                style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                p.points.length >= 3 && p.seciliKenarIdx != null && p.siraAraligi > 0
                    ? () => _generateRows(p)
                    : null,
            icon: const Icon(Icons.auto_fix_high),
            label: Text(p.seciliKenarIdx == null
                ? 'Önce kenar seçin'
                : 'Sıraları Otomatik Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
          if (p.siralar.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.siralar.length} sıra oluşturuldu',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 6),
                  ...p.siralar.take(10).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'Sıra ${s.numara}: ${s.uzunluk.toStringAsFixed(1)}m — ${s.saksiSayisi} saksı',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700),
                        ),
                      )),
                  if (p.siralar.length > 10)
                    Text(
                      '... +${p.siralar.length - 10} daha',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Toplam: ${p.siralar.fold<int>(0, (s, r) => s + r.saksiSayisi)} saksı',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.purple),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberField(
      String label, double value, Function(double) onChanged) {
    final ctrl = TextEditingController(
        text: value > 0 ? value.toStringAsFixed(2) : '');
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'm',
        hintText: '0,50',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      onChanged: (v) {
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  // ── Yakın köşe bul (sürükle-bırak için) ──
  int _findNearBahceKose(Offset pos, {double threshold = 30}) {
    for (int i = 0; i < _bahcePoints.length; i++) {
      if ((_bahcePoints[i] - pos).distance < threshold) return i;
    }
    return -1;
  }

  int _findNearParselKose(Offset pos, int parselIdx, {double threshold = 30}) {
    if (parselIdx < 0 || parselIdx >= _parseller.length) return -1;
    final pts = _parseller[parselIdx].points;
    for (int i = 0; i < pts.length; i++) {
      if ((pts[i] - pos).distance < threshold) return i;
    }
    return -1;
  }

  void _showKoseSilDialog(int koseIdx, {required bool isBahce, int parselIdx = -1}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Köşeyi Sil'),
        content: Text('${koseIdx + 1}. köşeyi silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (isBahce) {
                  _bahcePoints.removeAt(koseIdx);
                  if (koseIdx < _bahceMetreler.length) _bahceMetreler.removeAt(koseIdx);
                  if (koseIdx < _gpsPositions.length) _gpsPositions.removeAt(koseIdx);
                  if (koseIdx < _gpsDistances.length) _gpsDistances.removeAt(koseIdx);
                  _initBahceMetreCtrl();
                } else if (parselIdx >= 0 && parselIdx < _parseller.length) {
                  _parseller[parselIdx].points.removeAt(koseIdx);
                  if (koseIdx < _parseller[parselIdx].metreler.length) {
                    _parseller[parselIdx].metreler.removeAt(koseIdx);
                  }
                  _parseller[parselIdx].initMetreCtrl();
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // ── Kenar uzunluklarına göre noktaları oranla ──
  void _rescaleBahcePoints() {
    if (_bahcePoints.length < 2) return;
    // En az 2 kenarın metre değeri girilmiş olmalı
    final enteredCount = _bahceMetreler.where((m) => m > 0).length;
    if (enteredCount == 0) return;

    // Merkez hesapla
    final center = _bahcePoints.reduce((a, b) => a + b) /
        _bahcePoints.length.toDouble();

    // Her kenarın mevcut piksel uzunluğunu ve hedef metre uzunluğunu karşılaştır
    // İlk girilen metre değerinden pxPerMetre hesapla
    double pxPerMetre = 0;
    for (int i = 0; i < _bahcePoints.length; i++) {
      if (i < _bahceMetreler.length && _bahceMetreler[i] > 0) {
        final j = (i + 1) % _bahcePoints.length;
        final pxDist = (_bahcePoints[j] - _bahcePoints[i]).distance;
        if (pxDist > 0) {
          pxPerMetre = pxDist / _bahceMetreler[i];
          break;
        }
      }
    }
    if (pxPerMetre <= 0) return;

    // Her köşeyi merkezden yönünü koruyarak, kenar uzunluklarını oranla
    // Basit yaklaşım: tüm kenarların oranını ilk kenardan alınan pxPerMetre ile scale et
    // Daha gelişmiş: her kenarı bağımsız ölçekle (ama bu poligon bozar)
    // En doğru: tüm kenarlardan ortalama pxPerMetre hesapla, sonra tüm noktaları scale et
    double totalPx = 0, totalM = 0;
    for (int i = 0; i < _bahcePoints.length; i++) {
      final j = (i + 1) % _bahcePoints.length;
      totalPx += (_bahcePoints[j] - _bahcePoints[i]).distance;
      totalM += (i < _bahceMetreler.length && _bahceMetreler[i] > 0)
          ? _bahceMetreler[i]
          : 0;
    }
    if (totalM <= 0 || totalPx <= 0) return;

    final currentPxPerM = totalPx / totalM;
    // Hedef: tüm kenarların toplamı (metre olarak girilenlerin toplamını) tüm piksel toplamına oranla
    // Her girilmemiş kenarı mevcut piksel oranıyla tahmin et
    double hedefToplam = 0;
    for (int i = 0; i < _bahcePoints.length; i++) {
      final j = (i + 1) % _bahcePoints.length;
      final pxDist = (_bahcePoints[j] - _bahcePoints[i]).distance;
      if (i < _bahceMetreler.length && _bahceMetreler[i] > 0) {
        hedefToplam += _bahceMetreler[i];
      } else {
        hedefToplam += pxDist / currentPxPerM;
      }
    }
    // Yeni ölçek
    final newPxPerM = totalPx / hedefToplam;
    // Scale farkı? Değişen yok, pxPerMetre zaten dinamik hesaplanıyor.
    // Aslında metre değeri piksel oranını ETKİLİYOR, köşeler değişmez.
    // setState ile painter tekrar çizilir ve doğru metre etiketi gösterilir.
    setState(() {});
  }

  void _rescaleParselPoints(int parselIdx) {
    if (parselIdx < 0 || parselIdx >= _parseller.length) return;
    // Sadece setState ile repaint tetikle — metre değerleri pxPerMetre hesabını etkiler
    setState(() {});
  }

  // ── Piksel/metre oran hesaplama ──
  double _calcGlobalPxPerMetre() {
    // Önce bahçe kenarlarından hesapla
    double totalPx = 0, totalM = 0;
    for (int i = 0; i < _bahcePoints.length; i++) {
      final j = (i + 1) % _bahcePoints.length;
      totalPx += (_bahcePoints[j] - _bahcePoints[i]).distance;
      totalM += (i < _bahceMetreler.length) ? _bahceMetreler[i] : 0;
    }
    if (totalM > 0) return totalPx / totalM;
    return 1.0;
  }

  double _calcParselPxPerMetre(_ParselData p) {
    double totalPx = 0, totalM = 0;
    for (int i = 0; i < p.points.length; i++) {
      final j = (i + 1) % p.points.length;
      totalPx += (p.points[j] - p.points[i]).distance;
      totalM += (i < p.metreler.length) ? p.metreler[i] : 0;
    }
    if (totalM > 0) return totalPx / totalM;
    return _calcGlobalPxPerMetre();
  }

  /// Paralel sıraları otomatik oluştur
  void _generateRows(_ParselData p) {
    if (p.points.length < 3 || p.siraAraligi <= 0 || p.seciliKenarIdx == null) return;

    // Seçili kenardan açı hesapla (piksel koordinatlarından)
    final ki = p.seciliKenarIdx!;
    final kj = (ki + 1) % p.points.length;
    final acisi = atan2(
      p.points[kj].dy - p.points[ki].dy,
      p.points[kj].dx - p.points[ki].dx,
    );
    final dirX = cos(acisi);
    final dirY = sin(acisi);
    // Dik yön (sıraların ilerleyeceği yön)
    final perpX = -dirY;
    final perpY = dirX;

    // Tüm noktaları dik eksen üzerine projeksiyonla min/max bul
    double minProj = double.infinity, maxProj = -double.infinity;
    for (final pt in p.points) {
      final proj = pt.dx * perpX + pt.dy * perpY;
      minProj = min(minProj, proj);
      maxProj = max(maxProj, proj);
    }

    final pxPerMetre = _calcParselPxPerMetre(p);
    final siraAralikPx = p.siraAraligi * pxPerMetre;
    final saksiAralikPx = p.saksiAraligi * pxPerMetre;
    if (siraAralikPx <= 0) return;

    final siralar = <Sira>[];
    int siraNo = 1;

    for (double proj = minProj + siraAralikPx / 2;
        proj <= maxProj - siraAralikPx / 2;
        proj += siraAralikPx) {
      // Bu paralel çizginin parsel polygonu ile kesişim noktalarını bul
      final intersections = <double>[];

      for (int i = 0; i < p.points.length; i++) {
        final j = (i + 1) % p.points.length;
        final a = p.points[i];
        final b = p.points[j];

        final projA = a.dx * perpX + a.dy * perpY;
        final projB = b.dx * perpX + b.dy * perpY;

        if ((projA <= proj && projB >= proj) ||
            (projA >= proj && projB <= proj)) {
          if ((projB - projA).abs() < 0.001) continue;
          final t = (proj - projA) / (projB - projA);
          final ix = a.dx + t * (b.dx - a.dx);
          final iy = a.dy + t * (b.dy - a.dy);
          final lineProj = ix * dirX + iy * dirY;
          intersections.add(lineProj);
        }
      }

      if (intersections.length >= 2) {
        intersections.sort();
        final siraStart = intersections.first;
        final siraEnd = intersections.last;
        final uzunlukPx = siraEnd - siraStart;
        final uzunlukM = uzunlukPx / pxPerMetre;

        if (uzunlukM < 0.1) continue;

        final saksiSayisi = saksiAralikPx > 0
            ? (uzunlukPx / saksiAralikPx).floor()
            : 0;

        siralar.add(Sira(
          numara: siraNo,
          saksiSayisi: max(1, saksiSayisi),
          uzunluk: uzunlukM,
        ));
        siraNo++;
      }
    }

    setState(() {
      p.siralar = siralar;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${siralar.length} sıra oluşturuldu, toplam ${siralar.fold<int>(0, (s, r) => s + r.saksiSayisi)} saksı'),
      ));
    }
  }

  // ═══════════════════════════════════════════════════════
  // 4) ÖNİZLEME
  // ═══════════════════════════════════════════════════════
  Widget _buildOnizlemeView() {
    return InteractiveViewer(
      transformationController: _zoomCtrl,
      minScale: 0.3,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(300),
      child: Container(
        width: 2000,
        height: 2000,
        color: Colors.grey.shade50,
        child: CustomPaint(
          painter: _OnizlemePainter(
            bahcePoints: _bahcePoints,
            parseller: _parseller,
            pxPerMetre: _calcGlobalPxPerMetre(),
            bahceMetreler: _bahceMetreler,
          ),
          size: const Size(2000, 2000),
          child: _bahcePoints.isEmpty
              ? Center(
                  child: Text(
                    'Henüz kroki çizilmedi',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ─── ALT PANEL ──────────────────────────────────────────
  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Sol butonlar
            if (_mod == KrokiModu.bahceSiniri &&
                _bahcePoints.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _bahcePoints.removeLast();
                  if (_bahceMetreler.isNotEmpty) {
                    _bahceMetreler.removeLast();
                  }
                  if (_gpsPositions.isNotEmpty) {
                    _gpsPositions.removeLast();
                  }
                  if (_gpsDistances.isNotEmpty) {
                    _gpsDistances.removeLast();
                  }
                  _initBahceMetreCtrl();
                }),
                icon: const Icon(Icons.undo,
                    size: 16, color: Colors.red),
                label: const Text('Geri Al',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            // GPS ile nokta ekle (bahçe)
            if (_mod == KrokiModu.bahceSiniri) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _gpsLoading
                    ? null
                    : () async {
                        // Canvas merkezine bir nokta ekle, sonra GPS konumunu al
                        final center = Offset(
                          _canvasSize.width / 2 + (_bahcePoints.length * 40),
                          _canvasSize.height / 2 + (_bahcePoints.length * 30),
                        );
                        setState(() {
                          _bahcePoints.add(center);
                          _bahceMetreler.add(0);
                          _gpsPositions.add(null);
                          _gpsDistances.add(null);
                          _initBahceMetreCtrl();
                        });
                        await _getGpsPosition(_bahcePoints.length - 1);
                      },
                icon: Icon(
                  _gpsLoading ? Icons.hourglass_top : Icons.add_location_alt,
                  size: 16,
                ),
                label: const Text('GPS Nokta', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
            if (_mod == KrokiModu.parselCizim &&
                _activeParselIdx >= 0 &&
                _activeParselIdx < _parseller.length &&
                _parseller[_activeParselIdx].points.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _parseller[_activeParselIdx].points.removeLast();
                  if (_parseller[_activeParselIdx]
                      .metreler
                      .isNotEmpty) {
                    _parseller[_activeParselIdx].metreler.removeLast();
                  }
                  _parseller[_activeParselIdx].initMetreCtrl();
                }),
                icon: const Icon(Icons.undo,
                    size: 16, color: Colors.red),
                label: const Text('Geri Al',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            // GPS ile nokta ekle (parsel)
            if (_mod == KrokiModu.parselCizim &&
                _activeParselIdx >= 0 &&
                _activeParselIdx < _parseller.length) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _gpsLoading
                    ? null
                    : () async {
                        final p = _parseller[_activeParselIdx];
                        final center = Offset(
                          _canvasSize.width / 2 + (p.points.length * 40),
                          _canvasSize.height / 2 + (p.points.length * 30),
                        );
                        setState(() {
                          p.points.add(center);
                          p.metreler.add(0);
                          p.initMetreCtrl();
                        });
                        await _getParselGpsPosition(_activeParselIdx, p.points.length - 1);
                      },
                icon: Icon(
                  _gpsLoading ? Icons.hourglass_top : Icons.add_location_alt,
                  size: 16,
                ),
                label: const Text('GPS Nokta', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
            const Spacer(),
            // Bilgi
            if (_mod == KrokiModu.bahceSiniri)
              Text('${_bahcePoints.length} köşe',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            if (_mod == KrokiModu.parselCizim)
              Text('${_parseller.length} parsel',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(width: 12),
            // İleri butonları
            if (_mod == KrokiModu.bahceSiniri &&
                _bahcePoints.length >= 3)
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _mod = KrokiModu.parselCizim),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Parseller'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white),
              ),
            if (_mod == KrokiModu.parselCizim &&
                _parseller.any((p) => p.points.length >= 3))
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _siraParselIdx = 0;
                  _mod = KrokiModu.siraOlusturma;
                }),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Sıralar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white),
              ),
            if (_mod == KrokiModu.siraOlusturma &&
                _parseller.any((p) => p.siralar.isNotEmpty))
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _mod = KrokiModu.onizleme),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Önizle'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white),
              ),
            if (_mod == KrokiModu.onizleme) ...[
              if (_bahcePoints.length >= 3)
                ElevatedButton.icon(
                  onPressed: _shareKroki,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Paylaş'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAll,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── KAYDET ─────────────────────────────────────────────
  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      final pxPerMetre = _calcGlobalPxPerMetre();
      final centroid = _bahceCentroid();

      // Bahçe köşeleri
      final bahceKoseler = _buildKoselerFromPoints(
          _bahcePoints, _bahceMetreler, pxPerMetre, centroid,
          includeGps: true);

      // Parseller
      final parseller = <Parsel>[];
      for (final p in _parseller) {
        final parselPxPerMetre = _calcParselPxPerMetre(p);
        final parselKoseler = _buildKoselerFromPoints(
            p.points, p.metreler, parselPxPerMetre > 0 ? parselPxPerMetre : pxPerMetre, centroid);
        // Sıra cinsini parsel cinsinden ata
        final siralarWithCins = p.siralar.map((s) => s.copyWith(cins: s.cins ?? p.cins)).toList();
        parseller.add(Parsel(
          ad: p.ad,
          siraSayisi: p.siralar.length,
          siraBasinaSaksi:
              p.siralar.isNotEmpty ? p.siralar.first.saksiSayisi : 0,
          cins: p.cins,
          siralar: siralarWithCins,
          koseler: parselKoseler,
          siraAraligi: p.siraAraligi,
          saksiAraligi: p.saksiAraligi,
          siraAcisi: p.siraAcisi,
        ));
      }

      // Alan hesapla (Shoelace formülü)
      double alan = 0;
      if (bahceKoseler.length >= 3) {
        for (int i = 0; i < bahceKoseler.length; i++) {
          final j = (i + 1) % bahceKoseler.length;
          alan += bahceKoseler[i].x * bahceKoseler[j].y;
          alan -= bahceKoseler[j].x * bahceKoseler[i].y;
        }
        alan = alan.abs() / 2;
      }

      await _service.updateBahce(widget.bahce.copyWith(
        koseler: bahceKoseler,
        parseller: parseller,
        toplamAlan: alan,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kroki ve parseller kaydedildi ✓')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
    setState(() => _isSaving = false);
  }

  /// Bahçe centroid (tüm koordinatlar buna göre kaydedilir)
  Offset _bahceCentroid() {
    if (_bahcePoints.isEmpty) return Offset.zero;
    double sx = 0, sy = 0;
    for (final p in _bahcePoints) {
      sx += p.dx;
      sy += p.dy;
    }
    return Offset(sx / _bahcePoints.length, sy / _bahcePoints.length);
  }

  List<BahceKose> _buildKoselerFromPoints(
      List<Offset> points, List<double> metreler, double pxPerMetre,
      Offset globalCentroid,
      {bool includeGps = false}) {
    if (points.isEmpty) return [];

    return List.generate(points.length, (i) {
      final gpsPos =
          includeGps && i < _gpsPositions.length ? _gpsPositions[i] : null;
      return BahceKose(
        x: (points[i].dx - globalCentroid.dx) / pxPerMetre,
        y: (points[i].dy - globalCentroid.dy) / pxPerMetre,
        metraj: i < metreler.length ? metreler[i] : 0,
        lat: gpsPos?.latitude,
        lng: gpsPos?.longitude,
        gpsMetraj:
            includeGps && i < _gpsDistances.length ? _gpsDistances[i] : null,
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════
// PARSEL DATA (çalışma belleği)
// ═══════════════════════════════════════════════════════════

class _ParselData {
  String ad;
  String? cins;
  List<Offset> points = [];
  List<double> metreler = [];
  List<TextEditingController> metreCtrl = [];
  List<GpsKonum?> gpsPositions = [];
  double siraAraligi;
  double saksiAraligi;
  double? siraAcisi;
  int? seciliKenarIdx; // sıraların paralel olacağı kenar indeksi
  List<Sira> siralar;

  _ParselData({
    required this.ad,
    this.cins,
    this.siraAraligi = 1.0,
    this.saksiAraligi = 0.4,
    this.siraAcisi,
    this.seciliKenarIdx,
    List<Sira>? siralar,
  }) : siralar = siralar ?? [];

  void initMetreCtrl() {
    for (final c in metreCtrl) {
      c.dispose();
    }
    metreCtrl = List.generate(
      metreler.length,
      (i) => TextEditingController(
        text: metreler[i] > 0 ? metreler[i].toStringAsFixed(1) : '',
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════

/// 1) Bahçe sınırı çizim painter
class _BahceSinirPainter extends CustomPainter {
  final List<Offset> points;
  final int? dragging;
  final List<double> metreler;
  _BahceSinirPainter({required this.points, this.dragging, this.metreler = const []});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Polygon dolgu + kenar
    if (points.length >= 3) {
      final path = Path()
        ..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
          path, Paint()..color = Colors.red.withOpacity(0.05));
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.red
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round);
    } else if (points.length == 2) {
      canvas.drawLine(
          points[0],
          points[1],
          Paint()
            ..color = Colors.red
            ..strokeWidth = 2.5);
    }

    // Kapama çizgisi (şeffaf)
    if (points.length >= 3) {
      canvas.drawLine(
          points.last,
          points.first,
          Paint()
            ..color = Colors.red.withOpacity(0.3)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }

    // Köşeler
    for (int i = 0; i < points.length; i++) {
      final isDrag = i == dragging;
      final r = isDrag ? 14.0 : 10.0;
      canvas.drawCircle(
          points[i], r + 4, Paint()..color = Colors.red.withOpacity(0.12));
      canvas.drawCircle(points[i], r, Paint()..color = Colors.white);
      canvas.drawCircle(
          points[i],
          r,
          Paint()
            ..color = isDrag ? Colors.deepOrange : Colors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawCircle(points[i], 4, Paint()..color = Colors.red);
      _drawLabel(
          canvas, points[i] + Offset(r + 4, -14), '${i + 1}', Colors.red);
    }

    // Kenar metre etiketleri
    if (points.length >= 2) {
      for (int i = 0; i < points.length; i++) {
        final j = (i + 1) % points.length;
        if (j == 0 && points.length < 3) continue;
        final mid = (points[i] + points[j]) / 2;
        // piksel uzunluk
        final pxDist = (points[j] - points[i]).distance;
        final metre = i < metreler.length && metreler[i] > 0
            ? metreler[i]
            : 0.0;
        final label = metre > 0
            ? '${metre.toStringAsFixed(1)}m'
            : '${pxDist.toStringAsFixed(0)}px';
        final bg = Paint()..color = Colors.white.withOpacity(0.9);
        final tp = TextPainter(
          text: TextSpan(
              text: label,
              style: TextStyle(
                  color: metre > 0 ? Colors.red : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: mid,
                width: tp.width + 8,
                height: tp.height + 4),
            const Radius.circular(4),
          ),
          bg,
        );
        tp.paint(canvas,
            Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _BahceSinirPainter old) => true;
}

/// 2) Parsel çizim painter
class _ParselCizimPainter extends CustomPainter {
  final List<Offset> bahcePoints;
  final List<_ParselData> parseller;
  final int activeIdx;
  final int? draggingParselIdx;
  final int? draggingKoseIdx;

  _ParselCizimPainter({
    required this.bahcePoints,
    required this.parseller,
    required this.activeIdx,
    this.draggingParselIdx,
    this.draggingKoseIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bahçe sınırı (soluk)
    if (bahcePoints.length >= 3) {
      final path = Path()
        ..moveTo(bahcePoints.first.dx, bahcePoints.first.dy);
      for (final p in bahcePoints.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
          path, Paint()..color = Colors.red.withOpacity(0.04));
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.red.withOpacity(0.4)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }

    // Parseller
    for (int pi = 0; pi < parseller.length; pi++) {
      final p = parseller[pi];
      if (p.points.length < 2) continue;
      final isActive = pi == activeIdx;
      final color = isActive
          ? const Color(0xFF059669)
          : const Color(0xFF059669).withOpacity(0.4);

      if (p.points.length >= 3) {
        final path = Path()
          ..moveTo(p.points.first.dx, p.points.first.dy);
        for (final pt in p.points.skip(1)) {
          path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        canvas.drawPath(
            path, Paint()..color = color.withOpacity(0.06));
        canvas.drawPath(
            path,
            Paint()
              ..color = color
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round);
      } else {
        canvas.drawLine(
            p.points[0],
            p.points[1],
            Paint()
              ..color = color
              ..strokeWidth = 2);
      }

      // Köşeler + numaraları
      for (int ki = 0; ki < p.points.length; ki++) {
        final isDrag =
            pi == draggingParselIdx && ki == draggingKoseIdx;
        final r = isDrag ? 12.0 : 8.0;
        canvas.drawCircle(
            p.points[ki], r, Paint()..color = Colors.white);
        canvas.drawCircle(
            p.points[ki],
            r,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        canvas.drawCircle(
            p.points[ki], 3, Paint()..color = color);

        // Köşe numarası
        if (isActive) {
          final numTp = TextPainter(
            text: TextSpan(
                text: '${ki + 1}',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr,
          )..layout();
          // Arka plan
          canvas.drawCircle(
              p.points[ki] + Offset(r + 8, -r - 4),
              9,
              Paint()..color = Colors.white.withOpacity(0.9));
          numTp.paint(canvas,
              p.points[ki] + Offset(r + 8 - numTp.width / 2, -r - 4 - numTp.height / 2));
        }
      }

      // Kenar etiketleri (kenar ortasında) — metre dahil
      if (isActive && p.points.length >= 2) {
        for (int ki = 0; ki < p.points.length; ki++) {
          final kj = (ki + 1) % p.points.length;
          if (kj == 0 && p.points.length < 3) continue;
          final mid = (p.points[ki] + p.points[kj]) / 2;
          final metre = ki < p.metreler.length && p.metreler[ki] > 0
              ? p.metreler[ki]
              : 0.0;
          final label = metre > 0
              ? '${ki + 1}→${kj + 1} ${metre.toStringAsFixed(1)}m'
              : '${ki + 1}→${kj + 1}';
          final tp = TextPainter(
            text: TextSpan(
                text: label,
                style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
            textDirection: TextDirection.ltr,
          )..layout();
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: mid,
                  width: tp.width + 8,
                  height: tp.height + 4),
              const Radius.circular(4),
            ),
            Paint()..color = Colors.white.withOpacity(0.85),
          );
          tp.paint(canvas,
              Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
        }
      }

      // Parsel adı
      if (p.points.length >= 3) {
        final center = p.points.reduce((a, b) => a + b) /
            p.points.length.toDouble();
        final nameTp = TextPainter(
          text: TextSpan(
              text: p.ad,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center,
                width: nameTp.width + 10,
                height: nameTp.height + 4),
            const Radius.circular(6),
          ),
          Paint()..color = Colors.white.withOpacity(0.8),
        );
        nameTp.paint(canvas,
            Offset(center.dx - nameTp.width / 2, center.dy - nameTp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParselCizimPainter old) => true;
}

/// 3) Sıra painter — parseller + paralel sıra çizgileri
class _SiraPainter extends CustomPainter {
  final List<Offset> bahcePoints;
  final List<_ParselData> parseller;
  final int activeParselIdx;
  final double pxPerMetre;

  _SiraPainter({
    required this.bahcePoints,
    required this.parseller,
    required this.activeParselIdx,
    required this.pxPerMetre,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bahçe sınırı
    if (bahcePoints.length >= 3) {
      final path = Path()
        ..moveTo(bahcePoints.first.dx, bahcePoints.first.dy);
      for (final p in bahcePoints.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
          path, Paint()..color = Colors.red.withOpacity(0.03));
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.red.withOpacity(0.3)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
    }

    // Parseller ve sıraları
    for (int pi = 0; pi < parseller.length; pi++) {
      final p = parseller[pi];
      if (p.points.length < 3) continue;
      final isActive = pi == activeParselIdx;
      final parselColor = isActive
          ? const Color(0xFF059669)
          : const Color(0xFF059669).withOpacity(0.3);

      // Parsel sınırı
      final path = Path()
        ..moveTo(p.points.first.dx, p.points.first.dy);
      for (final pt in p.points.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(
          path, Paint()..color = parselColor.withOpacity(0.04));
      canvas.drawPath(
          path,
          Paint()
            ..color = parselColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);

      // Sıraları çiz
      if (p.siralar.isNotEmpty) {
        _drawRows(canvas, p, isActive);
      }

      // Parsel adı
      final center = p.points.reduce((a, b) => a + b) /
          p.points.length.toDouble();
      final tp = TextPainter(
        text: TextSpan(
            text: p.ad,
            style: TextStyle(
                color: parselColor,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(center.dx - tp.width / 2,
              center.dy - tp.height / 2 - 10));
    }
  }

  void _drawRows(Canvas canvas, _ParselData p, bool highlight) {
    final acisi = (p.siraAcisi ?? 0) * pi / 180;
    final dirX = cos(acisi);
    final dirY = sin(acisi);
    final perpX = -dirY;
    final perpY = dirX;

    double minProj = double.infinity, maxProj = -double.infinity;
    for (final pt in p.points) {
      final proj = pt.dx * perpX + pt.dy * perpY;
      minProj = min(minProj, proj);
      maxProj = max(maxProj, proj);
    }

    // pxPerM
    double totalPx = 0, totalM = 0;
    for (int i = 0; i < p.points.length; i++) {
      final j = (i + 1) % p.points.length;
      totalPx += (p.points[j] - p.points[i]).distance;
      totalM += (i < p.metreler.length) ? p.metreler[i] : 0;
    }
    final pxPerM = totalM > 0 ? totalPx / totalM : pxPerMetre;
    final aralPx = p.siraAraligi * pxPerM;
    if (aralPx <= 0) return;

    final rowPaint = Paint()
      ..color = highlight
          ? Colors.purple
          : Colors.purple.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    int siraNo = 1;
    for (double proj = minProj + aralPx / 2;
        proj <= maxProj - aralPx / 2;
        proj += aralPx) {
      final intersections = <Offset>[];
      for (int i = 0; i < p.points.length; i++) {
        final jj = (i + 1) % p.points.length;
        final a = p.points[i];
        final b = p.points[jj];
        final projA = a.dx * perpX + a.dy * perpY;
        final projB = b.dx * perpX + b.dy * perpY;
        if ((projA <= proj && projB >= proj) ||
            (projA >= proj && projB <= proj)) {
          if ((projB - projA).abs() < 0.001) continue;
          final t = (proj - projA) / (projB - projA);
          intersections.add(Offset(
              a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy)));
        }
      }
      if (intersections.length >= 2) {
        intersections.sort((a, b) =>
            (a.dx * dirX + a.dy * dirY)
                .compareTo(b.dx * dirX + b.dy * dirY));
        canvas.drawLine(
            intersections.first, intersections.last, rowPaint);

        // Sıra numarası
        if (highlight) {
          final mid =
              (intersections.first + intersections.last) / 2;
          final tp = TextPainter(
            text: TextSpan(
                text: '$siraNo',
                style: TextStyle(
                    color: Colors.purple.withOpacity(0.6),
                    fontSize: 8)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas,
              Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
        }
        siraNo++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SiraPainter old) => true;
}

/// 4) Önizleme — tüm katmanlar
class _OnizlemePainter extends CustomPainter {
  final List<Offset> bahcePoints;
  final List<_ParselData> parseller;
  final double pxPerMetre;
  final List<double> bahceMetreler;

  _OnizlemePainter({
    required this.bahcePoints,
    required this.parseller,
    required this.pxPerMetre,
    required this.bahceMetreler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bahçe sınırı — kırmızı
    if (bahcePoints.length >= 3) {
      final path = Path()
        ..moveTo(bahcePoints.first.dx, bahcePoints.first.dy);
      for (final p in bahcePoints.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
          path, Paint()..color = Colors.red.withOpacity(0.04));
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.red
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round);

      // Kenar metre etiketleri
      for (int i = 0; i < bahcePoints.length; i++) {
        final j = (i + 1) % bahcePoints.length;
        final mid = (bahcePoints[i] + bahcePoints[j]) / 2;
        final metre =
            i < bahceMetreler.length ? bahceMetreler[i] : 0.0;
        if (metre > 0) {
          final bg = Paint()..color = Colors.white.withOpacity(0.9);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: mid, width: 50, height: 18),
              const Radius.circular(4),
            ),
            bg,
          );
          final tp = TextPainter(
            text: TextSpan(
                text: '${metre.toStringAsFixed(1)}m',
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas,
              Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
        }
      }

      // Köşeler
      for (int i = 0; i < bahcePoints.length; i++) {
        canvas.drawCircle(
            bahcePoints[i], 5, Paint()..color = Colors.white);
        canvas.drawCircle(
            bahcePoints[i],
            5,
            Paint()
              ..color = Colors.red
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }

    // Parseller — yeşil + sıralar — mor
    for (final p in parseller) {
      if (p.points.length < 3) continue;

      // Parsel kenarları
      final path = Path()
        ..moveTo(p.points.first.dx, p.points.first.dy);
      for (final pt in p.points.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path,
          Paint()..color = const Color(0xFF059669).withOpacity(0.06));
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF059669)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);

      // Parsel adı + alan
      final center = p.points.reduce((a, b) => a + b) /
          p.points.length.toDouble();

      // Alan hesabı (piksel → m²)
      double parselAlan = 0;
      if (p.points.length >= 3) {
        double totalPxP = 0, totalMP = 0;
        for (int ei = 0; ei < p.points.length; ei++) {
          final ej = (ei + 1) % p.points.length;
          totalPxP += (p.points[ej] - p.points[ei]).distance;
          totalMP += (ei < p.metreler.length) ? p.metreler[ei] : 0;
        }
        final pxPerM = totalMP > 0 ? totalPxP / totalMP : pxPerMetre;
        if (pxPerM > 0) {
          double areaSum = 0;
          for (int ai = 0; ai < p.points.length; ai++) {
            final aj = (ai + 1) % p.points.length;
            areaSum += p.points[ai].dx * p.points[aj].dy;
            areaSum -= p.points[aj].dx * p.points[ai].dy;
          }
          parselAlan = areaSum.abs() / 2 / (pxPerM * pxPerM);
        }
      }

      // Cins + sıra özeti
      final cinsText = p.cins != null ? ' (${p.cins})' : '';
      final alanText = parselAlan > 0 ? '\n${parselAlan.toStringAsFixed(1)} m²' : '';
      final siraText = p.siralar.isNotEmpty
          ? '\n${p.siralar.length} sıra • ${p.siralar.fold<int>(0, (s, r) => s + r.saksiSayisi)} saksı'
          : '';
      final labelText = '${p.ad}$cinsText$alanText$siraText';

      final nameTp = TextPainter(
        text: TextSpan(
            text: labelText,
            style: const TextStyle(
                color: Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.3)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: center,
              width: nameTp.width + 16,
              height: nameTp.height + 10),
          const Radius.circular(8),
        ),
        Paint()..color = Colors.white.withOpacity(0.9),
      );
      nameTp.paint(
          canvas,
          Offset(center.dx - nameTp.width / 2,
              center.dy - nameTp.height / 2));

      // Sıralar
      if (p.siralar.isNotEmpty) {
        _drawSiralar(canvas, p);
      }
    }
  }

  void _drawSiralar(Canvas canvas, _ParselData p) {
    final acisi = (p.siraAcisi ?? 0) * pi / 180;
    final dirX = cos(acisi);
    final dirY = sin(acisi);
    final perpX = -dirY;
    final perpY = dirX;

    double minProj = double.infinity, maxProj = -double.infinity;
    for (final pt in p.points) {
      final proj = pt.dx * perpX + pt.dy * perpY;
      minProj = min(minProj, proj);
      maxProj = max(maxProj, proj);
    }

    double totalPx = 0, totalM = 0;
    for (int i = 0; i < p.points.length; i++) {
      final j = (i + 1) % p.points.length;
      totalPx += (p.points[j] - p.points[i]).distance;
      totalM += (i < p.metreler.length) ? p.metreler[i] : 0;
    }
    final pxPerM = totalM > 0 ? totalPx / totalM : pxPerMetre;
    final aralPx = p.siraAraligi * pxPerM;
    if (aralPx <= 0) return;

    final rowPaint = Paint()
      ..color = Colors.purple.withOpacity(0.5)
      ..strokeWidth = 1;

    for (double proj = minProj + aralPx / 2;
        proj <= maxProj - aralPx / 2;
        proj += aralPx) {
      final intersections = <Offset>[];
      for (int i = 0; i < p.points.length; i++) {
        final jj = (i + 1) % p.points.length;
        final a = p.points[i];
        final b = p.points[jj];
        final projA = a.dx * perpX + a.dy * perpY;
        final projB = b.dx * perpX + b.dy * perpY;
        if ((projA <= proj && projB >= proj) ||
            (projA >= proj && projB <= proj)) {
          if ((projB - projA).abs() < 0.001) continue;
          final t = (proj - projA) / (projB - projA);
          intersections.add(Offset(
              a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy)));
        }
      }
      if (intersections.length >= 2) {
        intersections.sort((a, b) =>
            (a.dx * dirX + a.dy * dirY)
                .compareTo(b.dx * dirX + b.dy * dirY));
        canvas.drawLine(
            intersections.first, intersections.last, rowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OnizlemePainter old) => true;
}
