import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  File? _imageFile;
  Uint8List? _imageBytes; // For web platform
  String? _imageName; // Store image name for web
  bool _isUploading = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _imageData = [];
  String _debugInfo = 'Initializing...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    print('🔥 INITSTATE CALLED');
    _testConnection();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Test connection and load initial data
  Future<void> _testConnection() async {
    print('🔥 TEST CONNECTION STARTED');
    try {
      final client = Supabase.instance.client;
      print('🔥 Client: ${client.toString()}');

      // Simple test - list bucket contents
      final files = await client.storage.from('momenku_images').list();
      print('🔥 FILES FOUND: ${files.length}');

      setState(() {
        _debugInfo = 'Connected successfully! Found ${files.length} items.';
      });

      // Auto-load images after connection test
      await _loadImages();
    } catch (e) {
      print('🔥 CONNECTION ERROR: $e');
      setState(() {
        _debugInfo = 'Connection Error: $e';
      });
    }
  }

  // Load images with detailed info
  Future<void> _loadImages() async {
    print('🔥 LOAD IMAGES STARTED');
    setState(() {
      _isLoading = true;
      _debugInfo = 'Loading images...';
    });

    try {
      final client = Supabase.instance.client;

      print('🔥 Listing uploads folder...');
      final uploadFiles = await client.storage
          .from('momenku_images')
          .list(path: 'uploads');

      print('🔥 Upload files: ${uploadFiles.length}');

      List<Map<String, dynamic>> imageData = [];
      for (var file in uploadFiles) {
        if (file.name.toLowerCase().endsWith('.jpg') ||
            file.name.toLowerCase().endsWith('.jpeg') ||
            file.name.toLowerCase().endsWith('.png') ||
            file.name.toLowerCase().endsWith('.webp')) {
          String url = client.storage
              .from('momenku_images')
              .getPublicUrl('uploads/${file.name}');

          imageData.add({
            'name': file.name,
            'url': url,
            'path': 'uploads/${file.name}',
            'size': file.metadata?['size'] ?? 0,
            'lastModified': file.metadata?['lastModified'] ?? 'Unknown',
          });

          print('🔥 Added image: ${file.name}');
        }
      }

      // Sort by name (newest first based on timestamp naming)
      imageData.sort((a, b) => b['name'].compareTo(a['name']));

      setState(() {
        _imageData = imageData;
        _isLoading = false;
        _debugInfo = 'Loaded ${imageData.length} images successfully!';
      });
    } catch (e, stackTrace) {
      print('🔥 LOAD ERROR: $e');
      print('🔥 STACK TRACE: $stackTrace');
      setState(() {
        _isLoading = false;
        _debugInfo = 'Error loading images: $e';
      });
    }
  }

  // Delete image function
  Future<void> _deleteImage(String path, String name, int index) async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _debugInfo = 'Deleting $name...';
      });

      await Supabase.instance.client.storage.from('momenku_images').remove([
        path,
      ]);

      // Remove from local list with animation
      setState(() {
        _imageData.removeAt(index);
        _debugInfo = 'Successfully deleted $name';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted $name'),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'Refresh', onPressed: _loadImages),
        ),
      );
    } catch (e) {
      print('🔥 DELETE ERROR: $e');
      setState(() {
        _debugInfo = 'Error deleting $name: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete $name: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Pick an image from the gallery - Updated for web support
  Future<void> pickImage() async {
    try {
      // Request permission only for mobile platforms
      if (!kIsWeb && Platform.isAndroid) {
        await requestPermission();
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web platform, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageName = image.name;
            _imageFile = null; // Clear file for web
          });
        } else {
          // For mobile platforms
          setState(() {
            _imageFile = File(image.path);
            _imageBytes = null; // Clear bytes for mobile
            _imageName = null;
          });
        }

        setState(() {
          _debugInfo = kIsWeb
              ? 'Image selected: $_imageName (${_formatFileSize(_imageBytes?.length ?? 0)})'
              : 'Image selected from gallery';
        });
      }
    } catch (e) {
      setState(() {
        _debugInfo = 'Error picking image: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload the selected image to Supabase storage - Updated for web support
  Future<void> uploadImage() async {
    if (kIsWeb && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!kIsWeb && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _debugInfo = 'Uploading image...';
    });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'uploads/$fileName';

      print('Uploading to path: $path');

      if (kIsWeb) {
        // Upload from bytes for web
        await Supabase.instance.client.storage
            .from('momenku_images')
            .uploadBinary(path, _imageBytes!);
      } else {
        // Upload from file for mobile
        await Supabase.instance.client.storage
            .from('momenku_images')
            .upload(path, _imageFile!);
      }

      print('Upload successful: $path');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload successful! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload images after successful upload
      await _loadImages();

      // Clear selected image
      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _imageName = null;
      });
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _debugInfo = 'Upload failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> requestPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      if (await Permission.photos.isDenied ||
          await Permission.photos.isPermanentlyDenied) {
        await Permission.photos.request();
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Helper method to get image widget for display
  Image? _buildImagePreview() {
    if (kIsWeb && _imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _imageFile != null) {
      return Image.file(
        _imageFile!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          kIsWeb ? "My Profile Gallery (Web)" : "My Profile Gallery",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadImages,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadImages,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kIsWeb ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kIsWeb
                          ? Colors.blue.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        kIsWeb ? Icons.web : Icons.phone_android,
                        color: kIsWeb
                            ? Colors.blue.shade700
                            : Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        kIsWeb
                            ? 'Running on Web Platform'
                            : 'Running on Mobile Platform',
                        style: TextStyle(
                          fontSize: 14,
                          color: kIsWeb
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.indigo.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _debugInfo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigo.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Upload Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Upload New Image',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade700,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Avatar
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.indigo.shade200,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 57,
                            backgroundColor: Colors.grey.shade100,
                            child: ClipOval(
                              child:
                                  _buildImagePreview() ??
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.indigo.shade300,
                                  ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Select'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade50,
                                foregroundColor: Colors.indigo.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isUploading ||
                                      (kIsWeb
                                          ? _imageBytes == null
                                          : _imageFile == null)
                                  ? null
                                  : uploadImage,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(
                                _isUploading ? 'Uploading...' : 'Upload',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Images Gallery Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.photo_album,
                            color: Colors.indigo.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'My Gallery (${_imageData.length})',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade700,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading images...'),
                              ],
                            ),
                          ),
                        )
                      else if (_imageData.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No images found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload your first image to get started!',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _imageData.length,
                          itemBuilder: (context, index) {
                            final imageInfo = _imageData[index];
                            return Hero(
                              tag: 'image_${imageInfo['name']}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          child: Image.network(
                                            imageInfo['url'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade100,
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  );
                                                },
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    color: Colors.grey.shade50,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Info Section
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Image ${index + 1}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatFileSize(
                                                imageInfo['size'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const Spacer(),

                                            // Action Buttons
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextButton.icon(
                                                    onPressed: () {
                                                      // View image in full screen
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              FullScreenImage(
                                                                imageUrl:
                                                                    imageInfo['url'],
                                                                imageName:
                                                                    imageInfo['name'],
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.visibility,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      'View',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.indigo,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                    ),
                                                  ),
                                                ),

                                                IconButton(
                                                  onPressed: () => _deleteImage(
                                                    imageInfo['path'],
                                                    imageInfo['name'],
                                                    index,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  color: Colors.red.shade400,
                                                  iconSize: 20,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Full screen image viewer
class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String imageName;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.imageName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(imageName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: 'image_$imageName',
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
