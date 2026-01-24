import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/fis_storage_service.dart';

/// Fiş görseli ekleme/görüntüleme widget'ı
class FisGorseliWidget extends StatefulWidget {
  final String? initialUrl;
  final Function(String?) onUrlChanged;
  final bool isEditing;

  const FisGorseliWidget({
    super.key,
    this.initialUrl,
    required this.onUrlChanged,
    this.isEditing = true,
  });

  @override
  State<FisGorseliWidget> createState() => _FisGorseliWidgetState();
}

class _FisGorseliWidgetState extends State<FisGorseliWidget> {
  final FisStorageService _storageService = FisStorageService();
  final ImagePicker _picker = ImagePicker();
  
  String? _currentUrl;
  bool _isUploading = false;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 80,
      );
      
      if (image == null) return;
      
      setState(() => _isUploading = true);
      
      final bytes = await image.readAsBytes();
      setState(() => _previewBytes = bytes);
      
      final url = await _storageService.uploadFisGorseli(
        bytes,
        fileName: image.name,
      );
      
      if (url != null) {
        setState(() {
          _currentUrl = url;
          _isUploading = false;
        });
        widget.onUrlChanged(url);
      } else {
        setState(() {
          _isUploading = false;
          _previewBytes = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fiş yüklenemedi')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _previewBytes = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            if (_currentUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Fişi Kaldır', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _currentUrl = null;
      _previewBytes = null;
    });
    widget.onUrlChanged(null);
  }

  void _showFullImage() {
    if (_currentUrl == null && _previewBytes == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: _previewBytes != null
                    ? Image.memory(_previewBytes!)
                    : Image.network(_currentUrl!),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _currentUrl != null || _previewBytes != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Fiş/Fatura Görseli',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            if (hasImage)
              TextButton.icon(
                onPressed: _showFullImage,
                icon: const Icon(Icons.fullscreen, size: 18),
                label: const Text('Büyüt'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_isUploading)
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Yükleniyor...'),
                ],
              ),
            ),
          )
        else if (hasImage)
          GestureDetector(
            onTap: widget.isEditing ? _showImageSourceDialog : _showFullImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _previewBytes != null
                        ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                        : Image.network(_currentUrl!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Fiş Eklendi', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    if (widget.isEditing)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, size: 16, color: Colors.grey.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
        else if (widget.isEditing)
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey.shade500),
                    const SizedBox(height: 8),
                    Text(
                      'Fiş/Fatura Ekle (Opsiyonel)',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text('Fiş eklenmemiş', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
      ],
    );
  }
}
