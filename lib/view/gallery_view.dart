import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wedding_online/models/gallery_model.dart';
import 'package:wedding_online/services/auth_service.dart';
import 'package:wedding_online/services/storage_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  List<GalleryModel> _galleries = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _token;
  int? _invitationId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadGalleries();
  }

  Future<void> _loadUserData() async {
    _token = await _storageService.getToken();
    final invitationIdStr = await _storageService.getInvitationID();

    // Safely parse invitation ID
    if (invitationIdStr != null &&
        invitationIdStr.isNotEmpty &&
        invitationIdStr != '0') {
      _invitationId = int.tryParse(invitationIdStr);
      if (_invitationId == null) {
        debugPrint('Warning: Could not parse invitation ID: $invitationIdStr');
      }
    }

    debugPrint(
      'Loaded user data - Token: ${_token != null ? 'Present' : 'Null'}, Invitation ID: $_invitationId',
    );
  }

  Future<void> _loadGalleries() async {
    if (_token == null || _invitationId == null) {
      _showErrorSnackBar('Data pengguna tidak ditemukan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.getGalleriesByInvitationId(
        token: _token!,
        invitationId: _invitationId!,
      );

      if (response.data != null) {
        setState(() {
          _galleries = response.data!;
          // Sort by order number
          _galleries.sort(
            (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.camera,
        Permission.storage,
        Permission.photos,
      ];

      for (Permission permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          await permission.request();
        }
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await _requestPermissions();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_token == null || _invitationId == null) {
      _showErrorSnackBar('Data pengguna tidak ditemukan');
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _showUploadDialog(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error memilih gambar: ${e.toString()}');
    }
  }

  Future<void> _showUploadDialog(File imageFile) async {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController orderController = TextEditingController(
      text: (_galleries.length + 1).toString(),
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Upload Gambar'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(imageFile, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(
                        labelText: 'Caption (Opsional)',
                        border: OutlineInputBorder(),
                        helperText: 'Deskripsi singkat untuk gambar ini',
                      ),
                      maxLines: 2,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: orderController,
                      decoration: const InputDecoration(
                        labelText: 'Urutan Tampil',
                        border: OutlineInputBorder(),
                        helperText: 'Angka untuk urutan tampilan gambar',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isUploading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () => _uploadImage(
                          imageFile,
                          captionController.text,
                          int.tryParse(orderController.text) ?? 1,
                        ),
                  child: _isUploading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Uploading...'),
                          ],
                        )
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadImage(
    File imageFile,
    String caption,
    int orderNumber,
  ) async {
    setState(() => _isUploading = true);

    try {
      final response = await _authService.createGallery(
        token: _token!,
        invitationId: _invitationId!,
        imageFile: imageFile,
        type: 'image',
        caption: caption.isEmpty ? null : caption,
        orderNumber: orderNumber,
      );

      if (response.data != null) {
        setState(() {
          _galleries.add(response.data!);
          _galleries.sort(
            (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
          );
        });

        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessSnackBar('Gambar berhasil diupload');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error upload: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteGallery(GalleryModel gallery) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (gallery.filePath != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: gallery.filePath!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              const Text('Apakah Anda yakin ingin menghapus gambar ini?'),
              if (gallery.caption != null && gallery.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '"${gallery.caption}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && gallery.id != null) {
      try {
        await _authService.deleteGallery(
          token: _token!,
          galleryId: gallery.id!,
        );

        setState(() {
          _galleries.removeWhere((g) => g.id == gallery.id);
        });

        _showSuccessSnackBar('Gambar berhasil dihapus');
      } catch (e) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _showImageDetail(GalleryModel gallery) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: gallery.filePath ?? '',
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error, size: 50),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 40,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (gallery.caption != null && gallery.caption!.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 40,
                  right: 40,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gallery.caption!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryGrid() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat galeri...'),
          ],
        ),
      );
    }

    if (_galleries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada gambar di galeri',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai tambahkan foto-foto indah Anda',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Gambar Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGalleries,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _galleries.length,
        itemBuilder: (context, index) {
          final gallery = _galleries[index];
          return GestureDetector(
            onTap: () => _showImageDetail(gallery),
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: gallery.filePath ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteGallery(gallery),
                      ),
                    ),
                  ),
                  if (gallery.orderNumber != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${gallery.orderNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (gallery.caption != null && gallery.caption!.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          gallery.caption!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galeri (${_galleries.length})'),
        backgroundColor: Colors.purple.shade100,
        elevation: 0,
        actions: [
          if (_galleries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadGalleries,
            ),
        ],
      ),
      body: _buildGalleryGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageSourceDialog,
        backgroundColor: Colors.purple.shade400,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
