import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

class CameraNotesScreen extends StatefulWidget {
  const CameraNotesScreen({super.key});

  @override
  State<CameraNotesScreen> createState() => _CameraNotesScreenState();
}

class _CameraNotesScreenState extends State<CameraNotesScreen> {
  late Box<Map> _memoriesBox;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initMemoriesBox();
  }

  void _initMemoriesBox() async {
    _memoriesBox = await Hive.openBox<Map>('cameraMemoriesBox');
    setState(() {});
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: source);

      if (photo != null) {
        _showCaptionDialog(photo.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCaptionDialog(String imagePath) {
    _captionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Add Caption', style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(imagePath), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Cancel button pressed in Caption dialog');
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              debugPrint('Save Memory button pressed');
              final memory = {
                'imagePath': imagePath,
                'caption': _captionController.text,
                'createdAt': DateTime.now().toString(),
              };
              _memoriesBox.add(memory);
              Navigator.pop(context);
              _captionController.clear();
            },
            child: const Text(
              'Save Memory',
              style: TextStyle(color: Color(0xFF25D366)),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMemory(dynamic key) {
    debugPrint('Delete memory called for key: $key');
    _memoriesBox.delete(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Store Your Notes & Beautiful Memories',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: _memoriesBox.listenable(),
        builder: (context, Box<Map> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/not_found.json',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Memories Yet',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture your beautiful moments',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _capturePhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _capturePhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FB0FF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final key = box.keyAt(index);
              final memory = box.values.toList()[index];
              final imagePath = memory['imagePath'] as String?;
              final caption = memory['caption'] as String?;

              return Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GestureDetector(
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(
                          'Delete Memory?',
                          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteMemory(key);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        if (imagePath != null && File(imagePath).existsSync())
                          Image.file(File(imagePath), fit: BoxFit.cover)
                        else
                          Container(
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image),
                          ),

                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0),
                                Colors.black.withOpacity(0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                        // Caption
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (caption != null && caption.isNotEmpty)
                                  Text(
                                    caption,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  '📸 Beautiful Memory',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF25D366).withOpacity(0.2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF25D366),
                            size: 32,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _capturePhoto(ImageSource.camera);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Camera',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4FB0FF).withOpacity(0.2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.photo_library,
                            color: Color(0xFF4FB0FF),
                            size: 32,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _capturePhoto(ImageSource.gallery);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gallery',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        label: const Text('Add Memory', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
