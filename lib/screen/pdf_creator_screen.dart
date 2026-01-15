import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfCreatorScreen extends StatefulWidget {
  const PdfCreatorScreen({super.key});

  @override
  State<PdfCreatorScreen> createState() => _PdfCreatorScreenState();
}

class _PdfCreatorScreenState extends State<PdfCreatorScreen> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isGenerating = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Configuration for image picker to optimize size/memory
  final double _maxWidth = 1800;
  final double _maxHeight = 1800;
  final int _imageQuality = 85;

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: _maxWidth,
        maxHeight: _maxHeight,
        imageQuality: _imageQuality,
      );
      
      if (!mounted) return;

      if (pickedFiles.isNotEmpty) {
        for (var xFile in pickedFiles) {
          if (!mounted) break;
          await _cropImage(File(xFile.path));
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error picking images: $e');
    }
  }

  Future<void> _pickCameraImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxWidth,
        maxHeight: _maxHeight,
        imageQuality: _imageQuality,
      );
      
      if (!mounted) return;

      if (pickedFile != null) {
        await _cropImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Scan',
            toolbarColor: const Color(0xff1E1E1E),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xff121B22),
            activeControlsWidgetColor: const Color(0xFF25D366),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Edit Scan',
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (!mounted) return;

      if (croppedFile != null) {
        setState(() {
          _images.add(File(croppedFile.path));
        });
      } else {
         setState(() {
           _images.add(imageFile);
         });
      }
    } catch (e) {
      if (!mounted) return;
      // If cropping fails, use original
      setState(() {
        _images.add(imageFile);
      });
      _showSnackBar('Could not crop image, using original.');
    }
  }
  
  Future<void> _reCropImage(int index) async {
    try {
      final originalFile = _images[index];
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: originalFile.path,
         uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Re-Edit Scan',
            toolbarColor: const Color(0xff1E1E1E),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xff121B22),
            activeControlsWidgetColor: const Color(0xFF25D366),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Re-Edit Scan',
          ),
        ],
      );
      
      if (!mounted) return;

      if (croppedFile != null) {
        setState(() {
          _images[index] = File(croppedFile.path);
        });
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error re-cropping: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }
  
  void _moveImage(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).cardColor,
    ));
  }

  Future<void> _createAndSharePdf() async {
    if (_images.isEmpty) {
      _showSnackBar('Please add at least one image');
      return;
    }

    // Ask for filename
    final String? fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempName = 'Vora_Scan_${DateTime.now().millisecondsSinceEpoch}';
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Save PDF', style: Theme.of(context).textTheme.titleLarge),
          content: TextField(
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Enter file name',
              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
            ),
            controller: TextEditingController(text: tempName),
            onChanged: (val) => tempName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempName),
              child: const Text('Save & Share', style: TextStyle(color: Color(0xFF25D366))),
            ),
          ],
        );
      }
    );

    if (fileName == null) return; // User cancelled

    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();

      // Load logo for watermark
      ByteData? logoData;
      try {
        logoData = await rootBundle.load('assets/images/logofd.png');
      } catch (e) {
        debugPrint('Logo not found for watermark: $e');
      }
      
      final logoImage = logoData != null ? pw.MemoryImage(logoData.buffer.asUint8List()) : null;

      for (var imageFile in _images) {
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        // Decode image to get dimensions for orientation
        final ui.Image decodedImage = await decodeImageFromList(imageBytes);
        final bool isLandscape = decodedImage.width > decodedImage.height;

        pdf.addPage(
          pw.Page(
            pageFormat: isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero, 
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                  if (logoImage != null)
                    pw.Positioned(
                      bottom: 20,
                      right: 20,
                      child: pw.Opacity(
                        opacity: 0.5,
                        child: pw.Image(logoImage, width: 50, height: 50),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }
      
      final finalName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: finalName,
      );
    } catch (e) {
      _showSnackBar('Error creating PDF: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Doc Scanner', style: Theme.of(context).appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_images.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    title: Text('Clear All?', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
                    content: Text('Are you sure you want to remove all pages?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))),
                      TextButton(onPressed: () {
                        setState(() => _images.clear());
                        Navigator.pop(ctx);
                      }, child: const Text('Clear', style: TextStyle(color: Colors.redAccent))),
                    ],
                  )
                );
              },
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Hint bar
          if (_images.isNotEmpty)
            Container(
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Long press to reorder • Tap image to edit',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
              ),
            ),

          // Image Grid (Reorderable)
          Expanded(
            child: _images.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.document_scanner_rounded,
                          size: 80,
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 24),
                         Text(
                          'Scan Documents',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.titleLarge?.color, 
                              fontSize: 22, 
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use camera or gallery to create PDFs',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionButton(
                              icon: Icons.camera_alt_rounded,
                              label: 'Camera',
                              color: const Color(0xFF25D366),
                              onTap: _pickCameraImage,
                            ),
                            const SizedBox(width: 30),
                            _actionButton(
                              icon: Icons.photo_library_rounded,
                              label: 'Gallery',
                              color: const Color(0xFF00D9FF),
                              onTap: _pickImages,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Theme.of(context).scaffoldBackgroundColor,
                      shadowColor: Colors.transparent,
                    ),
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _images.length + 1, 
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > _images.length) return; 
                        if (oldIndex >= _images.length) return; 
                        
                        _moveImage(oldIndex, newIndex);
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Theme.of(context).cardColor,
                          elevation: 6,
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        if (index == _images.length) {
                          // The "Add Page" button at the bottom of the list
                          return Container(
                            key: const ValueKey('add_button'),
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                   showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Theme.of(context).cardColor,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                    builder: (ctx) => _buildAddOptions(ctx),
                                  );
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text("Add More Pages"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(color: Color(0xFF25D366)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // The Document Page Item
                        return _buildPageItem(index);
                      },
                    ),
                  ),
          ),

          // Bottom Action Bar
          if (_images.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_images.length} Pages',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Ready to export',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _createAndSharePdf,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(_isGenerating ? 'Generating...' : 'Share PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageItem(int index) {
    return Container(
      key: ValueKey(_images[index].path),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: GestureDetector(
          onTap: () => _reCropImage(index), 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 80,
              child: Image.file(
                _images[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          'Page ${index + 1}',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Tap image to crop/edit',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.crop, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
              onPressed: () => _reCropImage(index),
              tooltip: 'Edit/Crop',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeImage(index),
              tooltip: 'Remove',
            ),
            const SizedBox(width: 8),
            Icon(Icons.drag_handle, color: Theme.of(context).iconTheme.color?.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOptions(BuildContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        ListTile(
          leading: Icon(Icons.camera_alt, color: Theme.of(context).iconTheme.color),
          title: Text('Take Photo', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          onTap: () {
            Navigator.pop(ctx);
            _pickCameraImage();
          },
        ),
        ListTile(
          leading: Icon(Icons.photo_library, color: Theme.of(context).iconTheme.color),
          title: Text('Choose from Gallery', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          onTap: () {
            Navigator.pop(ctx);
            _pickImages();
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
