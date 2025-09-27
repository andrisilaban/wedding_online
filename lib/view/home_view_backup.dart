import 'dart:io';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_online/constants/styles.dart';
import 'package:wedding_online/models/event_load_model.dart';
import 'package:wedding_online/models/gallery_model.dart';
import 'package:wedding_online/models/invitation_model.dart';
import 'package:wedding_online/models/theme_model.dart';
import 'package:wedding_online/models/wish_model.dart';
import 'package:wedding_online/services/auth_service.dart';
import 'package:wedding_online/services/music_service.dart';
import 'package:wedding_online/services/storage_service.dart';
import 'package:wedding_online/services/theme_service.dart';
import 'package:wedding_online/view/countdown_timer.dart';
import 'package:wedding_online/view/event_view.dart';
import 'dart:async';

import 'package:wedding_online/view/invitation_view.dart';
import 'package:wedding_online/view/music_view.dart';
import 'package:wedding_online/view/package_view.dart';
import 'package:wedding_online/view/theme_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  WeddingTheme _currentTheme = ThemeService.availableThemes.first;
  final MusicService _musicService = MusicService();
  final ThemeService _themeService = ThemeService();
  bool _isThemeLoading = true;
  bool _hasRedirected = false;

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  late Future<List<InvitationModel>> _invitationsFuture;

  InvitationModel? _selectedInvitation;
  List<InvitationModel> _allInvitations = [];

  List<EventLoadModel> _events = [];
  bool _isLoading = true;
  EventLoadModel defaultEvent = EventLoadModel(
    id: '1',
    invitationId: '1',
    name: 'Akad Nikah',
    venueName: 'Gedung Pernikahan Bahagia',
    venueAddress: 'Jl. Kebahagian No. 123, Jakarta',
    date: '2026-12-15',
    startTime: '09:00:00',
    endTime: '11:00:00',
    description: 'Acara akad nikah yang dihadiri keluarga dan kerabat dekat',
    orderNumber: '1',
  );

  String? selectedValue;
  int _attendingCount = 0;
  bool _showBankDetails = false;
  String groomBrideTitle = 'Pernikahan Ahmad & Siti';
  String groomFullName = 'Ahmad';
  String brideFullName = 'Siti';
  String groomFatherName = 'Hadi';
  String groomMotherName = 'Aminah';
  String brideFatherName = 'Joko';
  String brideMotherName = 'Sarah';
  EventLoadModel tempEvent = EventLoadModel();

  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<String> options = ["Hadir", "Tidak Hadir", "Mungkin"];

  List<WishModel> _wishes = [];
  bool _isLoadingWishes = true;
  bool _isSubmittingWish = false;

  List<GalleryModel> _galleries = [];
  bool _isLoadingGallery = false;
  bool _isDeletingGallery = false;
  int? _deletingGalleryItemId;
  final ImagePicker _picker = ImagePicker();

  final List<String> galleryImages = [
    'assets/images/couple.jpg',
    'assets/images/gallery1.jpeg',
    'assets/images/gallery2.jpeg',
    'assets/images/gallery3.jpeg',
  ];

  final List<Map<String, dynamic>> comments = [
    {
      'name': 'Rendy',
      'date': '2025-02-08 18:48:33',
      'message': 'Semoga acaranya berjalan dengan lancar dan sesuai rencana',
      'attendance': 'Hadir',
    },
  ];
  Future<void> _initializeApp() async {
    try {
      await _loadCurrentTheme();

      await _musicService.loadSavedTrack();

      Future.delayed(const Duration(milliseconds: 800), () {
        _confettiController.play();
      });

      _invitationsFuture = _loadInvitations();
      _getEventsByInvitationId();
    } catch (e) {
      debugPrint('Error initializing app: $e');

      setState(() {
        _currentTheme = ThemeService.availableThemes.first;
        _isThemeLoading = false;
      });
    }
  }

  Future<void> _loadCurrentTheme() async {
    try {
      final theme = await _themeService.getCurrentTheme();
      if (mounted) {
        setState(() {
          _currentTheme = theme;
          _isThemeLoading = false;
        });
      }
      debugPrint('Theme loaded: ${theme.name}');
    } catch (e) {
      debugPrint('Error loading theme: $e');
      if (mounted) {
        setState(() {
          _currentTheme = ThemeService.availableThemes.first;
          _isThemeLoading = false;
        });
      }
    }
  }

  Future<void> _changeTheme(WeddingTheme newTheme) async {
    try {
      if (mounted) {
        setState(() {
          _isThemeLoading = true;
        });
      }

      await _themeService.saveTheme(newTheme.id);

      if (mounted) {
        setState(() {
          _currentTheme = newTheme;
          _isThemeLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(newTheme.decorativeIcons.first),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Tema "${newTheme.name}" berhasil diterapkan!'),
                ),
              ],
            ),
            backgroundColor: newTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      debugPrint('Theme changed to: ${newTheme.name}');
    } catch (e) {
      debugPrint('Error changing theme: $e');
      if (mounted) {
        setState(() {
          _isThemeLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah tema: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeView(
        currentTheme: _currentTheme,
        onThemeSelected: (theme) async {
          await _changeTheme(theme);
        },
      ),
    );
  }

  InvitationModel get _currentInvitation {
    return _selectedInvitation ??
        InvitationModel(
          title: groomBrideTitle,
          groomFullName: groomFullName,
          brideFullName: brideFullName,
          groomFatherName: groomFatherName,
          groomMotherName: groomMotherName,
          brideFatherName: brideFatherName,
          brideMotherName: brideMotherName,
        );
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatEventDate(String? dateString) {
    if (dateString == null || dateString.isEmpty)
      return 'Tanggal belum ditentukan';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _loadGalleries() async {
    if (_selectedInvitation?.id == null) {
      debugPrint('No invitation selected, skip load galleries');
      setState(() {
        _galleries = [];
        _isLoadingGallery = false;
      });
      return;
    }

    final token = await _storageService.getToken();
    if (token == null) {
      debugPrint('No token found for gallery loading');
      return;
    }

    setState(() {
      _isLoadingGallery = true;
    });

    try {
      // Parse the invitation ID to int
      int invitationId = int.parse(_selectedInvitation!.id.toString());

      final response = await _authService.getGalleriesByInvitationId(
        token: token,
        invitationId: invitationId,
      );

      if (response.data != null) {
        setState(() {
          _galleries = response.data!;
          _galleries.sort(
            (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading galleries: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memuat galeri: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingGallery = false;
      });
    }
  }

  // Add this method for requesting permissions
  Future<void> _requestGalleryPermissions() async {
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

  // Add this method to show image source dialog
  Future<void> _showImageSourceDialog() async {
    await _requestGalleryPermissions();

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

  // Add this method to pick image
  Future<void> _pickImage(ImageSource source) async {
    final token = await _storageService.getToken();
    final invitationId = _selectedInvitation?.id;

    if (token == null || invitationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pengguna tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this method to show upload dialog
  Future<void> _showUploadDialog(File imageFile) async {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController orderController = TextEditingController(
      text: (_galleries.length + 1).toString(),
    );

    bool isUploading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return WillPopScope(
              onWillPop: () async => !isUploading,
              child: AlertDialog(
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
                      if (isUploading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text(
                          'Sedang mengupload gambar...',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                      ] else ...[
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
                          enabled: !isUploading,
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
                          enabled: !isUploading,
                        ),
                      ],
                    ],
                  ),
                ),
                actions: <Widget>[
                  if (!isUploading)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            setDialogState(() {
                              isUploading = true;
                            });

                            try {
                              final token = await _storageService.getToken();
                              final invitationId = _selectedInvitation?.id;

                              if (token == null || invitationId == null) {
                                throw Exception(
                                  'Token atau invitation ID tidak valid',
                                );
                              }

                              // Parse invitation ID to int
                              int parsedInvitationId = int.parse(
                                invitationId.toString(),
                              );

                              final response = await _authService.createGallery(
                                token: token,
                                invitationId: parsedInvitationId,
                                imageFile: imageFile,
                                type: 'image',
                                caption: captionController.text.isEmpty
                                    ? null
                                    : captionController.text,
                                orderNumber:
                                    int.tryParse(orderController.text) ?? 1,
                              );

                              if (response.status == 200 ||
                                  response.status == 201) {
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Gambar berhasil diupload',
                                      ),
                                      backgroundColor:
                                          _currentTheme.primaryColor,
                                    ),
                                  );
                                  await _loadGalleries(); // Refresh gallery
                                }
                              } else {
                                setDialogState(() {
                                  isUploading = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Upload gagal: ${response.message ?? "Unknown error"}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              setDialogState(() {
                                isUploading = false;
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error upload: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: isUploading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Uploading...'),
                            ],
                          )
                        : const Text('Upload'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Add this method to delete gallery
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
      setState(() {
        _isDeletingGallery = true;
        _deletingGalleryItemId = gallery.id;
      });

      try {
        final token = await _storageService.getToken();
        if (token == null) {
          throw Exception('Token tidak valid');
        }

        await _authService.deleteGallery(token: token, galleryId: gallery.id!);

        setState(() {
          _galleries.removeWhere((g) => g.id == gallery.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gambar berhasil dihapus'),
            backgroundColor: _currentTheme.primaryColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isDeletingGallery = false;
          _deletingGalleryItemId = null;
        });
      }
    }
  }

  // Add this method to show image detail
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

  Widget _buildEventListTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Acara',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _currentTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                ? _buildEmptyEventState()
                : _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada acara',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan tambah acara baru untuk undangan ini',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_events.isEmpty) {
      return _buildEmptyEventState();
    }

    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        if (index >= _events.length) {
          return const SizedBox.shrink();
        }

        final event = _events[index];
        return _buildEventCard(event, index);
      },
    );
  }

  Widget _buildEventCard(EventLoadModel event, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name ?? 'Nama Acara',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.venueName ?? 'Nama Venue',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: _currentTheme.primaryColor,
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await _storageService.saveEventId(event.id!);
                        _showEditEventDialog(event);
                        break;
                      case 'delete':
                        _showDeleteEventDialog(event);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 20,
                            color: _currentTheme.primaryColor,
                          ),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildEventDetail(
              Icons.location_on,
              event.venueAddress ?? 'Alamat venue',
            ),
            const SizedBox(height: 8),
            _buildEventDetail(
              Icons.calendar_today,
              _formatEventDate(event.date),
            ),
            const SizedBox(height: 8),
            _buildEventDetail(
              Icons.access_time,
              '${event.startTime ?? '00:00'} - ${event.endTime ?? '00:00'} WIB',
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildEventDetail(Icons.description, event.description!),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _currentTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Urutan: ${event.orderNumber ?? '1'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _currentTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: _currentTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  void _showDeleteEventDialog(EventLoadModel event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Acara'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apakah Anda yakin ingin menghapus acara ini?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name ?? 'Nama Acara',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${event.venueName}'),
                    Text(_formatEventDate(event.date)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final token = await _storageService.getToken();

                  if (token == null) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _handleTokenErrorOnce('Token tidak valid');
                    return;
                  }

                  final response = await _authService.deleteEventById(
                    token: token,
                    eventId: int.parse(event.id!),
                  );

                  Navigator.pop(context);

                  if (response.status == 200) {
                    Navigator.pop(context);

                    setState(() {
                      _events.removeWhere((e) => e.id == event.id);

                      if (tempEvent.id == event.id) {
                        tempEvent = _events.isNotEmpty
                            ? _events.first
                            : EventLoadModel();
                      }

                      _isLoading = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Acara berhasil dihapus!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        _getEventsByInvitationId();
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menghapus acara'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> requestPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      if (await Permission.photos.isDenied ||
          await Permission.photos.isPermanentlyDenied) {
        await Permission.photos.request();
      }
    }
  }

  Future<List<InvitationModel>> _loadInvitations() async {
    try {
      final token = await _storageService.getToken();

      if (token == null) {
        debugPrint('No token found, redirecting to login');
        _handleTokenErrorOnce('Session expired. Please login again.');
        return [];
      }

      debugPrint('Token retrieved successfully, making API call');

      final response = await _authService.getInvitations(token);

      debugPrint('API call successful');
      final list = response.data ?? [];

      setState(() {
        _allInvitations = list;
        if (_selectedInvitation == null && list.isNotEmpty) {
          _selectedInvitation = list.first;
          _storageService.saveInvitationId(_selectedInvitation!.id.toString());
        }
      });

      if (list.isNotEmpty && list.last.id != null) {
        _getEventsByInvitationId();
      }

      return list;
    } catch (e) {
      debugPrint('Error loading invitations: $e');

      if (e.toString().contains('Token tidak valid')) {
        debugPrint('Invalid token detected, clearing storage and redirecting');
        _handleTokenErrorOnce('Your session has expired. Please login again.');
      } else {
        debugPrint('Other error occurred: $e');
        _handleTokenErrorOnce('Unable to load data. Please try again.');
      }

      setState(() {
        _allInvitations = [];
        _selectedInvitation = null;
      });

      return [];
    }
  }

  void _refreshInvitations() {
    setState(() {
      _invitationsFuture = _loadInvitations();
    });
  }

  void _handleTokenErrorOnce(String error) {
    if (_hasRedirected) return;

    _hasRedirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );

        await _storageService.clearAll();
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (e) {
        debugPrint('Error in _handleTokenErrorOnce: $e');
        // Fallback navigation
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    });
  }

  Future<void> _loadWishesByInvitationId() async {
    try {
      setState(() {
        _isLoadingWishes = true;
      });

      String? invitationId = _selectedInvitation?.id?.toString();

      if (invitationId == null ||
          invitationId.isEmpty ||
          invitationId == '0' ||
          invitationId == '999999999') {
        debugPrint('Invitation ID tidak tersedia, skip load wishes');
        setState(() {
          _wishes = [];
          _isLoadingWishes = false;
        });
        return;
      }

      final response = await _authService.getWishesByInvitationId(
        int.parse(invitationId),
      );

      setState(() {
        _wishes = response.data ?? [];
        _isLoadingWishes = false;
        _calculateAttendingCount();
      });

      debugPrint('Loaded ${_wishes.length} wishes');
    } catch (e) {
      debugPrint('Error loading wishes: $e');
      setState(() {
        _wishes = [];
        _isLoadingWishes = false;
      });
    }
  }

  Future<void> _submitWish() async {
    if (_nameController.text.isEmpty ||
        _messageController.text.isEmpty ||
        selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon lengkapi semua data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? invitationId = _selectedInvitation?.id?.toString();

    if (invitationId == null ||
        invitationId.isEmpty ||
        invitationId == '0' ||
        invitationId == '999999999') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation ID tidak tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingWish = true;
    });

    try {
      String attendanceStatus = selectedValue!.toLowerCase().replaceAll(
        ' ',
        '_',
      );

      final response = await _authService.createWish(
        invitationId: int.parse(invitationId),
        guestName: _nameController.text,
        attendanceStatus: attendanceStatus,
        message: _messageController.text,
      );

      if (response.status == 201) {
        _nameController.clear();
        _messageController.clear();
        selectedValue = null;

        _confettiController.play();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terima kasih atas ucapannya!'),
            backgroundColor: _currentTheme.primaryColor,
          ),
        );

        await _loadWishesByInvitationId();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ucapan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting wish: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingWish = false;
      });
    }
  }

  void _calculateAttendingCount() {
    _attendingCount = _wishes
        .where((wish) => wish.attendanceStatus?.toLowerCase() == 'hadir')
        .length;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();

    Future.delayed(const Duration(milliseconds: 800), () {
      _confettiController.play();
    });

    _invitationsFuture = _loadInvitations();
    _getEventsByInvitationId();

    _loadWishesByInvitationId();
  }

  void _getEventsByInvitationId() async {
    try {
      final token = await _storageService.getToken();
      String? invitationId = _selectedInvitation?.id?.toString();

      debugPrint('------');
      debugPrint('load event invitation id: $invitationId');

      if (token == null) {
        _handleTokenErrorOnce('Token tidak valid');
        return;
      }

      if (invitationId == null ||
          invitationId.isEmpty ||
          invitationId == '0' ||
          invitationId == '999999999') {
        debugPrint('Invitation ID tidak tersedia, skip load events');
        setState(() {
          _events = [];
          tempEvent = EventLoadModel();
          _isLoading = false;
        });
        return;
      }

      final response = await _authService.getEventsByInvitationId(
        token: token,
        invitationId: int.parse(invitationId),
      );

      setState(() {
        _events = response.data ?? [];
        if (response.data != null && response.data!.isNotEmpty) {
          List<EventLoadModel> sortedEvents = List.from(response.data!);
          sortedEvents.sort((a, b) {
            int orderA = int.tryParse(a.orderNumber ?? '1') ?? 1;
            int orderB = int.tryParse(b.orderNumber ?? '1') ?? 1;
            return orderA.compareTo(orderB);
          });
          tempEvent = (response.data != null && response.data!.isNotEmpty)
              ? response.data!.first
              : EventLoadModel();
        } else {
          tempEvent = EventLoadModel();
        }
        _isLoading = false;
      });

      await _loadWishesByInvitationId();
    } catch (e) {
      debugPrint('Gagal load events: $e');
      setState(() {
        _events = [];
        tempEvent = EventLoadModel();
        _isLoading = false;
      });
      _handleTokenErrorOnce(e.toString());
    }
  }

  String _formatAttendanceStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'tidak_hadir':
        return 'Tidak Hadir';
      case 'mungkin':
        return 'Mungkin';
      default:
        return 'Belum Konfirmasi';
    }
  }

  void _logout() async {
    try {
      // Prevent multiple logout attempts
      if (_hasRedirected) return;
      _hasRedirected = true;

      // Stop any ongoing operations
      _confettiController.stop();

      // Clear storage first
      await _storageService.clearAllExceptTheme();

      // Check if widget is still mounted before showing snackbar
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Berhasil logout. Tema Anda akan tetap tersimpan.',
          ),
          backgroundColor: _currentTheme.primaryColor,
          duration: const Duration(seconds: 1),
        ),
      );

      // Wait a moment, then navigate
      await Future.delayed(const Duration(milliseconds: 800));

      // Final mounted check before navigation
      if (!mounted) return;

      // Navigate to login and clear all previous routes
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } catch (e) {
      debugPrint('Error during logout: $e');

      // Fallback: direct navigation
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    }
  }

  void _showEditMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 8, // Changed from 7 to 8
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 16),
                labelColor: _currentTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: _currentTheme.primaryColor,
                labelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.card_giftcard), text: "Undangan"),
                  Tab(icon: Icon(Icons.event), text: "Acara"),
                  Tab(icon: Icon(Icons.folder_open), text: "Daftar Undangan"),
                  Tab(icon: Icon(Icons.folder_open), text: "Daftar Acara"),
                  Tab(icon: Icon(Icons.palette), text: "Tema"),
                  Tab(icon: Icon(Icons.music_note), text: "Musik"),
                  Tab(icon: Icon(Icons.card_membership), text: "Paket"),
                  Tab(
                    icon: Icon(Icons.photo_library),
                    text: "Galeri",
                  ), // New Gallery tab
                ],
              ),
              SizedBox(
                height: 450,
                child: TabBarView(
                  children: [
                    InvitationView(
                      currentTheme: _currentTheme,
                      onSuccess: _refreshInvitations,
                    ),
                    EventView(
                      currentTheme: _currentTheme,
                      onSuccess: _refreshInvitations,
                    ),
                    _buildInvitationListTab(),
                    _buildEventListTab(),
                    _buildThemeTab(),
                    _buildMusicTab(),
                    _buildPackageTab(),
                    _buildGalleryTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, color: _currentTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Pilih Tema Undangan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _currentTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _currentTheme.decorativeIcons.first,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tema saat ini: ${_currentTheme.name}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _currentTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: ThemeService.availableThemes.length,
              itemBuilder: (context, index) {
                final theme = ThemeService.availableThemes[index];
                final isSelected = theme.id == _currentTheme.id;

                return GestureDetector(
                  onTap: () async {
                    if (!isSelected) {
                      await _changeTheme(theme);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: theme.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          spreadRadius: isSelected ? 3 : 1,
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              theme.decorativeIcons.first,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              theme.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                theme.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: theme.primaryColor,
                                size: 16,
                              ),
                            ),
                          ),

                        if (_isThemeLoading && isSelected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _changeTheme(ThemeService.availableThemes.first);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _currentTheme.primaryColor,
                      side: BorderSide(color: _currentTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Tutup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicTab() {
    return MusicPlayerWidget(currentTheme: _currentTheme);
  }

  Widget _buildPackageTab() {
    return PackageView(currentTheme: _currentTheme);
  }

  void _showEditInvitationDialog(InvitationModel invitation) {
    final groomFullNameController = TextEditingController(
      text: invitation.groomFullName,
    );
    final groomNickNameController = TextEditingController(
      text: invitation.groomNickName,
    );
    final groomFatherNameController = TextEditingController(
      text: invitation.groomFatherName,
    );
    final groomMotherNameController = TextEditingController(
      text: invitation.groomMotherName,
    );
    final brideFullNameController = TextEditingController(
      text: invitation.brideFullName,
    );
    final brideNickNameController = TextEditingController(
      text: invitation.brideNickName,
    );
    final brideFatherNameController = TextEditingController(
      text: invitation.brideFatherName,
    );
    final brideMotherNameController = TextEditingController(
      text: invitation.brideMotherName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Undangan',
            style: TextStyle(color: _currentTheme.primaryColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: groomFullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pria',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
                TextField(
                  controller: groomNickNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Singkatan Pria',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
                TextField(
                  controller: groomFatherNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Bapak Pria',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
                TextField(
                  controller: groomMotherNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Ibu Pria',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
                TextField(
                  controller: brideFullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Wanita',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
                TextField(
                  controller: brideNickNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Singkatan Wanita',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
                TextField(
                  controller: brideFatherNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Bapak Wanita',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
                TextField(
                  controller: brideMotherNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Ibu Wanita',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  String token = await StorageService().getToken() ?? '';
                  final authService = AuthService();

                  final data = {
                    "title":
                        "Pernikahan ${groomFullNameController.text} & ${brideFullNameController.text}",
                    "theme_id": 1,
                    "pre_wedding_text":
                        "Dengan hormat mengundang Bapak/Ibu/Saudara/i untuk menghadiri acara pernikahan kami",
                    "groom_full_name": groomFullNameController.text,
                    "groom_nick_name": groomNickNameController.text,
                    "groom_title": "Putra dari",
                    "groom_father_name": groomFatherNameController.text,
                    "groom_mother_name": groomMotherNameController.text,
                    "bride_full_name": brideFullNameController.text,
                    "bride_nick_name": brideNickNameController.text,
                    "bride_title": "Putri dari",
                    "bride_father_name": brideFatherNameController.text,
                    "bride_mother_name": brideMotherNameController.text,
                  };

                  final result = await authService.updateInvitation(
                    token,
                    data,
                    invitation.id!,
                  );

                  Navigator.pop(context);

                  if (result.status == 200) {
                    Navigator.pop(context);

                    final updatedInvitation = InvitationModel(
                      id: invitation.id,
                      title: data["title"] as String?,
                      groomFullName: data["groom_full_name"] as String?,
                      groomNickName: data["groom_nick_name"] as String?,
                      groomFatherName: data["groom_father_name"] as String?,
                      groomMotherName: data["groom_mother_name"] as String?,
                      brideFullName: data["bride_full_name"] as String?,
                      brideNickName: data["bride_nick_name"] as String?,
                      brideFatherName: data["bride_father_name"] as String?,
                      brideMotherName: data["bride_mother_name"] as String?,
                    );

                    setState(() {
                      int index = _allInvitations.indexWhere(
                        (inv) => inv.id == invitation.id,
                      );
                      if (index != -1) {
                        _allInvitations[index] = updatedInvitation;
                      }

                      if (_selectedInvitation?.id == invitation.id) {
                        _selectedInvitation = updatedInvitation;
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Berhasil memperbarui undangan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditEventDialog(EventLoadModel event) {
    final nameController = TextEditingController(text: event.name);
    final venueNameController = TextEditingController(text: event.venueName);
    final venueAddressController = TextEditingController(
      text: event.venueAddress,
    );
    final dateController = TextEditingController(text: event.date);
    final startTimeController = TextEditingController(text: event.startTime);
    final endTimeController = TextEditingController(text: event.endTime);
    final descriptionController = TextEditingController(
      text: event.description,
    );
    final orderNumberController = TextEditingController(
      text: event.orderNumber,
    );

    DateTime? selectedDate = event.date != null
        ? DateTime.tryParse(event.date!)
        : null;
    TimeOfDay? selectedStartTime = event.startTime != null
        ? _parseTimeOfDay(event.startTime!)
        : null;
    TimeOfDay? selectedEndTime = event.endTime != null
        ? _parseTimeOfDay(event.endTime!)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Acara'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Acara',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: venueNameController,
                  decoration: InputDecoration(
                    labelText: 'Tempat',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),

                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: venueAddressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),

                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),

                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    selectedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (selectedDate != null) {
                      dateController.text =
                          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Jam Mulai',
                          labelStyle: TextStyle(
                            color: _currentTheme.primaryColor,
                          ),

                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        onTap: () async {
                          selectedStartTime = await showTimePicker(
                            context: context,
                            initialTime:
                                selectedStartTime ??
                                const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (selectedStartTime != null) {
                            startTimeController.text =
                                "${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}:00";
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Jam Selesai',
                          labelStyle: TextStyle(
                            color: _currentTheme.primaryColor,
                          ),

                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        onTap: () async {
                          selectedEndTime = await showTimePicker(
                            context: context,
                            initialTime:
                                selectedEndTime ??
                                const TimeOfDay(hour: 11, minute: 0),
                          );
                          if (selectedEndTime != null) {
                            endTimeController.text =
                                "${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}:00";
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),

                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderNumberController,
                  decoration: InputDecoration(
                    labelText: 'Urutan',
                    labelStyle: TextStyle(color: _currentTheme.primaryColor),

                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final token = await _storageService.getToken();
                  final invitationId = await _storageService.getInvitationID();

                  if (token == null || invitationId == null) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _handleTokenErrorOnce(
                      'Token atau Invitation ID tidak valid',
                    );
                    return;
                  }

                  final response = await _authService.updateEventById(
                    token: token,
                    eventId: int.parse(event.id!),
                    invitationId: int.parse(invitationId),
                    name: nameController.text,
                    venueName: venueNameController.text,
                    venueAddress: venueAddressController.text,
                    date: dateController.text,
                    startTime: startTimeController.text,
                    endTime: endTimeController.text,
                    description: descriptionController.text,
                    orderNumber: int.tryParse(orderNumberController.text) ?? 1,
                  );

                  Navigator.pop(context);

                  if (response.status == 200) {
                    Navigator.pop(context);

                    final updatedEvent = EventLoadModel(
                      id: event.id,
                      invitationId: event.invitationId,
                      name: nameController.text,
                      venueName: venueNameController.text,
                      venueAddress: venueAddressController.text,
                      date: dateController.text,
                      startTime: startTimeController.text,
                      endTime: endTimeController.text,
                      description: descriptionController.text,
                      orderNumber: orderNumberController.text,
                    );

                    setState(() {
                      int index = _events.indexWhere((e) => e.id == event.id);
                      if (index != -1) {
                        _events[index] = updatedEvent;
                      }

                      if (tempEvent.id == event.id) {
                        tempEvent = updatedEvent;
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Acara berhasil diperbarui!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    await _storageService.clearEventId();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal memperbarui acara'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteInvitationDialog(InvitationModel invitation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Undangan'),
          content: Text(
            'Apakah Anda yakin ingin menghapus undangan "${invitation.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final token = await _storageService.getToken();
                  if (token == null) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _handleTokenErrorOnce('Token tidak valid');
                    return;
                  }

                  final result = await _authService.deleteInvitation(
                    token,
                    invitation.id!,
                  );

                  Navigator.pop(context);

                  if (result.status == 200) {
                    Navigator.pop(context);

                    if (_selectedInvitation?.id == invitation.id) {
                      setState(() {
                        _selectedInvitation = null;
                        _events = [];
                        tempEvent = EventLoadModel();
                      });
                      await _storageService.saveInvitationId('0');
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Undangan berhasil dihapus!'),
                      ),
                    );

                    setState(() {
                      _invitationsFuture = _loadInvitations();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menghapus undangan'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void showCreateInvitationPopup(BuildContext context) {
    final groomFullNameController = TextEditingController();
    final groomNickNameController = TextEditingController();
    final groomFatherNameController = TextEditingController();
    final groomMotherNameController = TextEditingController();
    final brideFullNameController = TextEditingController();
    final brideNickNameController = TextEditingController();
    final brideFatherNameController = TextEditingController();
    final brideMotherNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Data Diri'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: groomFullNameController,
                  decoration: InputDecoration(labelText: 'Nama Pria'),
                ),
                TextField(
                  controller: groomNickNameController,
                  decoration: InputDecoration(labelText: 'Nama Singkatan Pria'),
                ),
                TextField(
                  controller: groomFatherNameController,
                  decoration: InputDecoration(labelText: 'Nama Bapak Pria'),
                ),
                TextField(
                  controller: groomMotherNameController,
                  decoration: InputDecoration(labelText: 'Nama Ibu Pria'),
                ),
                TextField(
                  controller: brideFullNameController,
                  decoration: InputDecoration(labelText: 'Nama Wanita'),
                ),
                TextField(
                  controller: brideNickNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Singkatan Wanita',
                  ),
                ),
                TextField(
                  controller: brideFatherNameController,
                  decoration: InputDecoration(labelText: 'Nama Bapak Wanita'),
                ),
                TextField(
                  controller: brideMotherNameController,
                  decoration: InputDecoration(labelText: 'Nama Ibu Wanita'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                String token = await StorageService().getToken() ?? '';
                final authService = AuthService();

                final data = {
                  "title":
                      "Pernikahan ${groomFullNameController.text} & ${brideFullNameController.text}",
                  "theme_id": 1,
                  "pre_wedding_text":
                      "Dengan hormat mengundang Bapak/Ibu/Saudara/i untuk menghadiri acara pernikahan kami",
                  "groom_full_name": groomFullNameController.text,
                  "groom_nick_name": groomNickNameController.text,
                  "groom_title": "Putra dari",
                  "groom_father_name": groomFatherNameController.text,
                  "groom_mother_name": groomMotherNameController.text,
                  "bride_full_name": brideFullNameController.text,
                  "bride_nick_name": brideNickNameController.text,
                  "bride_title": "Putri dari",
                  "bride_father_name": brideFatherNameController.text,
                  "bride_mother_name": brideMotherNameController.text,
                };

                final result = await authService.createInvitation(token, data);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Undangan berhasil dibuat!')),
                );

                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                setState(() {
                  _invitationsFuture = _loadInvitations();
                });
              },
              child: Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      _confettiController.dispose();
      _nameController.dispose();
      _messageController.dispose();
      _musicService.dispose();
    } catch (e) {
      debugPrint('Error in dispose: $e');
    }
    super.dispose();
  }

  void logOut() {
    _storageService.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_isThemeLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _currentTheme.gradientColors,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Memuat tema...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _currentTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: "Ubah Tema",
            onPressed: _showThemeSelector,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
            onPressed: () => _showEditMenu(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<InvitationModel>>(
        future: _invitationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _handleTokenErrorOnce(snapshot.error.toString());
          }

          final invitations = snapshot.data ?? [];

          if (invitations.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _currentTheme.gradientColors,
                ),
              ),

              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    sh16,
                    _buildWeddingInfoCard(groomBrideTitle),
                    sh32,
                    _buildPresentationCard(),
                    sh32,
                    _buildDateSection(tempEvent),
                    sh32,
                    _buildCoupleSection(
                      groomFullName: groomFullName,
                      brideFullName: brideFullName,
                      groomFatherName: groomFatherName,
                      groomMotherName: groomMotherName,
                      brideFatherName: brideFatherName,
                      brideMotherName: brideMotherName,
                    ),
                    sh32,
                    _buildEventSchedule(defaultEvent: defaultEvent),
                    sh32,
                    _buildGallerySection(),
                    sh32,
                    _buildLiveStreamSection(),
                    sh32,
                    _buildAttendanceSection(),
                    sh32,
                    _buildCommentsSection(),
                    sh32,
                    _buildGiftSection(),
                    sh32,
                    _buildThankYouSection(),
                    const SizedBox(height: 40),
                    _buildMomenkuSection(),
                  ],
                ),
              ),
            );
          }

          final currentInvitation = _currentInvitation;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _currentTheme.gradientColors,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  sh16,
                  _buildWeddingInfoCard(currentInvitation.title),
                  sh32,
                  _buildPresentationCard(),
                  sh32,
                  _buildDateSection(tempEvent),
                  sh32,
                  _buildCoupleSection(
                    groomFullName:
                        currentInvitation.groomFullName ?? groomFullName,
                    brideFullName:
                        currentInvitation.brideFullName ?? brideFullName,
                    groomFatherName:
                        currentInvitation.groomFatherName ?? groomFatherName,
                    groomMotherName:
                        currentInvitation.groomMotherName ?? groomMotherName,
                    brideFatherName:
                        currentInvitation.brideFatherName ?? brideFatherName,
                    brideMotherName:
                        currentInvitation.brideMotherName ?? brideMotherName,
                  ),
                  sh32,
                  _buildEventSchedule(defaultEvent: tempEvent),
                  sh32,
                  _buildGallerySection(),
                  sh32,
                  _buildLiveStreamSection(),
                  sh32,
                  _buildAttendanceSection(),
                  sh32,
                  _buildCommentsSection(),
                  sh32,
                  _buildGiftSection(),
                  sh32,
                  _buildThankYouSection(),
                  const SizedBox(height: 40),
                  _buildMomenkuSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeddingInfoCard(String? title) {
    String newTitle =
        title
            ?.replaceAll(RegExp(r'\bpernikahan\b', caseSensitive: false), '')
            .trim() ??
        'Pria & Wanita';
    return Stack(
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.2,
          colors: const [
            Colors.orange,
            Colors.purple,
            Colors.blue,
            Colors.amber,
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _currentTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _currentTheme.primaryColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  decoration: circleImageDecoration.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: _currentTheme.primaryColor.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/couple.jpg',
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "The Wedding of",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: _currentTheme.fontFamily,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: _currentTheme.primaryColor,
                  ),
                ),
                Text(
                  newTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontFamily: _currentTheme.fontFamily,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: _currentTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: _currentTheme.secondaryColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(
                        Icons.favorite,
                        color: _currentTheme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: Divider(color: _currentTheme.secondaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Cinta yang sejati bukanlah tentang menemukan seseorang yang sempurna "
                  "tetapi tentang melihat kesempurnaan dalam ketidaksempurnaan.",
                  textAlign: TextAlign.center,
                  style: italicTextStyle.copyWith(
                    fontSize: 16,
                    fontFamily: _currentTheme.fontFamily,
                    letterSpacing: 0.5,
                    wordSpacing: 1.2,
                    color: _currentTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresentationCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Assalamualaikum Wr. Wb.",
            style: headerTextStyle.copyWith(
              fontSize: 24,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Dengan memohon rahmat dan ridho Allah SWT, kami bermaksud menyelenggarakan acara pernikahan kami:",
            textAlign: TextAlign.center,
            style: italicTextStyle.copyWith(
              fontSize: 16,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 0.5,
              wordSpacing: 1.2,
              color: _currentTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(EventLoadModel tempEvent) {
    DateTime parsedDate =
        DateTime.tryParse(tempEvent.date ?? '') ?? DateTime(2025, 1, 1);

    String formattedDate = DateFormat(
      'EEEE, d MMMM y',
      'id_ID',
    ).format(parsedDate);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Save The Date",
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          CountdownTimer(
            eventDate: tempEvent.date,
            currentTheme: _currentTheme,
          ),
          const SizedBox(height: 20),
          Text(
            formattedDate,
            style: headerTextStyle.copyWith(
              fontSize: 24,
              fontFamily: _currentTheme.fontFamily,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Pukul ${tempEvent.startTime ?? '13:30'} - ${tempEvent.endTime ?? '20:00'} WIB",
            style: bodyTextStyle.copyWith(
              fontSize: 18,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tempEvent.venueAddress ?? 'Golden Ballroom - Grand Palace Hotel',
            style: bodyTextStyle.copyWith(
              fontSize: 18,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
              color: _currentTheme.primaryColor,
            ),
          ),
          Text(
            tempEvent.venueName ?? 'Jl. Raya Utama No. 123, Jakarta',
            style: bodyTextStyle.copyWith(
              fontSize: 18,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              Uri url = Uri.parse(
                'https://maps.google.com?q=Lokasi+Pernikahan',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(Icons.location_on),
            label: const Text("Lihat Lokasi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleSection({
    required String groomFullName,
    required String brideFullName,
    required String groomFatherName,
    required String groomMotherName,
    required String brideFatherName,
    required String brideMotherName,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Bride & Groom",
            style: TextStyle(
              fontSize: 28,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _currentTheme.primaryColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/gallery1.jpeg',
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            groomFullName,
            style: TextStyle(
              fontSize: 28,
              fontFamily: _currentTheme.fontFamily,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Putra pertama dari pasangan\n"
            "Bapak $groomFatherName & Ibu $groomMotherName\n"
            "Jakarta",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: _currentTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          Icon(Icons.favorite, color: _currentTheme.accentColor, size: 32),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _currentTheme.primaryColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/gallery1.jpeg',
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            brideFullName,
            style: TextStyle(
              fontSize: 28,
              fontFamily: _currentTheme.fontFamily,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Putri pertama dari pasangan\n"
            "Bapak $brideFatherName & Ibu $brideMotherName\n"
            "Bandung",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: _currentTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSchedule({required EventLoadModel defaultEvent}) {
    List<EventLoadModel> sortedEvents = List.from(_events);
    sortedEvents.sort((a, b) {
      int orderA = int.tryParse(a.orderNumber ?? '999') ?? 999;
      int orderB = int.tryParse(b.orderNumber ?? '999') ?? 999;
      return orderA.compareTo(orderB);
    });

    if (sortedEvents.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _currentTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _currentTheme.primaryColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Susunan Acara',
              style: TextStyle(
                fontSize: 25,
                fontFamily: _currentTheme.fontFamily,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: _currentTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _currentTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _currentTheme.secondaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 48,
                    color: _currentTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada acara',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _currentTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan tambah acara melalui menu edit',
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Susunan Acara',
            style: TextStyle(
              fontSize: 25,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ...sortedEvents.asMap().entries.map((entry) {
            int index = entry.key;
            EventLoadModel event = entry.value;

            return Column(
              children: [
                _buildScheduleItem(
                  icon: _getEventIcon(event.name ?? '', index),
                  title: event.name ?? 'Acara ${index + 1}',
                  time: _formatEventTime(event.startTime, event.endTime),
                  description:
                      event.description ??
                      'Acara ${event.name ?? 'pernikahan'}',
                  venue: '${event.venueName ?? ''} ${event.venueAddress ?? ''}'
                      .trim(),
                  orderNumber: event.orderNumber,
                ),
                if (index < sortedEvents.length - 1) const SizedBox(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required IconData icon,
    required String title,
    required String time,
    required String description,
    String? venue,
    String? orderNumber,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _currentTheme.primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _currentTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentTheme.primaryColor,
                          fontFamily: _currentTheme.fontFamily,
                        ),
                      ),
                    ),
                    if (orderNumber != null && orderNumber.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _currentTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _currentTheme.accentColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '#$orderNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _currentTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: _currentTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _currentTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (venue != null && venue.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: _currentTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venue,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _currentTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _currentTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String eventName, int index) {
    String name = eventName.toLowerCase();

    if (name.contains('akad') ||
        name.contains('nikah') ||
        name.contains('ijab')) {
      return Icons.mosque;
    } else if (name.contains('resepsi') || name.contains('reception')) {
      return Icons.celebration;
    } else if (name.contains('pemberkatan') || name.contains('blessing')) {
      return Icons.church;
    } else if (name.contains('siraman') || name.contains('mitoni')) {
      return Icons.water_drop;
    } else if (name.contains('foto') || name.contains('photo')) {
      return Icons.photo_camera;
    } else if (name.contains('dinner') || name.contains('makan')) {
      return Icons.restaurant;
    } else if (name.contains('dance') || name.contains('tari')) {
      return Icons.music_note;
    } else {
      List<IconData> defaultIcons = [
        Icons.favorite,
        Icons.celebration,
        Icons.local_florist,
        Icons.cake,
        Icons.music_note,
        Icons.photo_camera,
      ];
      return defaultIcons[index % defaultIcons.length];
    }
  }

  String _formatEventTime(String? startTime, String? endTime) {
    if (startTime == null && endTime == null) {
      return 'Waktu belum ditentukan';
    }

    String start = startTime != null ? _formatTime(startTime) : '00:00';
    String end = endTime != null ? _formatTime(endTime) : '00:00';

    return '$start - $end WIB';
  }

  String _formatTime(String timeString) {
    try {
      List<String> parts = timeString.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  Widget _buildGallerySection() {
    return Column(
      children: [
        _buildSectionHeader("Our Gallery"),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _currentTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _currentTheme.primaryColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Show gallery images if available, otherwise show default images
              if (_galleries.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _galleries.take(4).length, // Show max 4 images
                  itemBuilder: (context, index) {
                    final gallery = _galleries[index];
                    return GestureDetector(
                      onTap: () => _showImageDetail(gallery),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _currentTheme.primaryColor.withOpacity(
                                0.2,
                              ),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: gallery.filePath ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
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
                              if (gallery.caption != null &&
                                  gallery.caption!.isNotEmpty)
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
                      ),
                    );
                  },
                ),
                if (_galleries.length > 4) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Dan ${_galleries.length - 4} foto lainnya...',
                    style: TextStyle(
                      color: _currentTheme.textSecondary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ] else ...[
                // Show default gallery if no uploaded images
                GridView.count(
                  crossAxisCount: 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: galleryImages.asMap().entries.map((entry) {
                    String image = entry.value;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _currentTheme.primaryColor.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(image, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                '"Cinta adalah perjalanan yang indah ketika didasari oleh kesetiaan dan komitmen yang tulus."',
                textAlign: TextAlign.center,
                style: italicTextStyle.copyWith(
                  fontSize: 16,
                  fontFamily: _currentTheme.fontFamily,
                  letterSpacing: 0.5,
                  wordSpacing: 1.2,
                  color: _currentTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add this method to build the gallery tab
  Widget _buildGalleryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Galeri Foto (${_galleries.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _currentTheme.primaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingGallery
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat galeri...'),
                      ],
                    ),
                  )
                : _galleries.isEmpty
                ? Center(
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Upload Gambar Pertama'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGalleries,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: _galleries.length,
                      itemBuilder: (context, index) {
                        final gallery = _galleries[index];
                        final isBeingDeleted =
                            _isDeletingGallery &&
                            _deletingGalleryItemId == gallery.id;

                        return GestureDetector(
                          onTap: isBeingDeleted
                              ? null
                              : () => _showImageDetail(gallery),
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
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),

                                if (isBeingDeleted)
                                  Container(
                                    color: Colors.black.withOpacity(0.7),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Menghapus...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
                                      icon: Icon(
                                        isBeingDeleted
                                            ? Icons.hourglass_empty
                                            : Icons.delete,
                                        color: isBeingDeleted
                                            ? Colors.grey
                                            : Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: isBeingDeleted
                                          ? null
                                          : () => _deleteGallery(gallery),
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
                                        color: _currentTheme.primaryColor
                                            .withOpacity(0.8),
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

                                if (gallery.caption != null &&
                                    gallery.caption!.isNotEmpty)
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool withDivider = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          if (withDivider)
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    title,
                    style: headerTextStyle.copyWith(
                      fontSize: 24,
                      fontFamily: _currentTheme.fontFamily,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white)),
              ],
            )
          else
            Text(
              title,
              style: headerTextStyle.copyWith(
                fontFamily: 'Cormorant',
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStreamSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Livestream",
            style: TextStyle(
              fontSize: 28,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _currentTheme.secondaryColor),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam,
                    size: 50,
                    color: _currentTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Live Streaming akan dimulai pada hari-H",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: _currentTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              Uri url = Uri.parse(
                'https://maps.google.com?q=Lokasi+Pernikahan',
              );

              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(Icons.play_circle_filled),
            label: const Text("Tonton di YouTube"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Konfirmasi Kehadiran",
            style: TextStyle(
              fontSize: 28,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            enabled: !_isSubmittingWish,
            decoration: InputDecoration(
              labelText: "Nama",
              labelStyle: TextStyle(
                fontSize: 14,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w500,
                color: _currentTheme.primaryColor,
                fontFamily: _currentTheme.fontFamily,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _currentTheme.primaryColor,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _currentTheme.primaryColor,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.person,
                color: _currentTheme.secondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            enabled: !_isSubmittingWish,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Ucapan & Doa",
              labelStyle: TextStyle(
                fontSize: 14,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w500,
                color: _currentTheme.primaryColor,
                fontFamily: _currentTheme.fontFamily,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _currentTheme.primaryColor,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _currentTheme.primaryColor,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.message,
                color: _currentTheme.secondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _currentTheme.secondaryColor, width: 2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                hint: Text(
                  "Status Kehadiran",
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                    color: _currentTheme.primaryColor,
                    fontFamily: _currentTheme.fontFamily,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: _currentTheme.primaryColor,
                ),
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == "Hadir"
                              ? Icons.check_circle
                              : value == "Tidak Hadir"
                              ? Icons.cancel
                              : Icons.help,
                          color: value == "Hadir"
                              ? Colors.green
                              : value == "Tidak Hadir"
                              ? Colors.red
                              : Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w500,
                            fontFamily: _currentTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isSubmittingWish
                    ? null
                    : (String? newValue) {
                        setState(() {
                          selectedValue = newValue;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmittingWish ? null : _submitWish,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isSubmittingWish
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Mengirim...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 8),
                      Text(
                        "Kirim Ucapan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_wishes.length} Ucapan",
                style: headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: _currentTheme.fontFamily,
                  letterSpacing: 0.5,
                  wordSpacing: 1.2,
                  color: _currentTheme.primaryColor,
                ),
              ),
              Text(
                "$_attendingCount Hadir",
                style: headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: _currentTheme.fontFamily,
                  letterSpacing: 0.5,
                  wordSpacing: 1.2,
                  color: _currentTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _isLoadingWishes
                    ? null
                    : () async {
                        debugPrint('MANUAL RELOAD WISHES TRIGGERED');
                        await _loadWishesByInvitationId();
                      },
                icon: _isLoadingWishes
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _currentTheme.primaryColor,
                        ),
                      )
                    : Icon(Icons.refresh, size: 16),
                label: Text(
                  _isLoadingWishes ? 'Loading...' : 'Refresh Ucapan',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _currentTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: _currentTheme.secondaryColor),

          if (_isLoadingWishes) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: _currentTheme.primaryColor),
                  const SizedBox(height: 8),
                  Text(
                    'Memuat ucapan...',
                    style: TextStyle(
                      color: _currentTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else if (_wishes.isEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _currentTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _currentTheme.secondaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 48,
                    color: _currentTheme.primaryColor.withOpacity(0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada ucapan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _currentTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jadilah yang pertama memberikan ucapan dan doa',
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            for (var wish in _wishes.reversed.take(10)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _currentTheme.primaryColor,
                    child: Text(
                      (wish.guestName?.isNotEmpty == true)
                          ? wish.guestName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          wish.guestName ?? 'Tamu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: _currentTheme.fontFamily,
                            letterSpacing: 0.5,
                            wordSpacing: 1.2,
                            color: _currentTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: wish.attendanceStatus?.toLowerCase() == 'hadir'
                              ? Colors.green.shade100
                              : wish.attendanceStatus?.toLowerCase() ==
                                    'tidak_hadir'
                              ? Colors.red.shade100
                              : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatAttendanceStatus(wish.attendanceStatus ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                wish.attendanceStatus?.toLowerCase() == 'hadir'
                                ? Colors.green.shade800
                                : wish.attendanceStatus?.toLowerCase() ==
                                      'tidak_hadir'
                                ? Colors.red.shade800
                                : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wish.createdAt != null
                            ? _formatWishDate(wish.createdAt!)
                            : 'Tanggal tidak diketahui',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wish.message ?? 'Tidak ada pesan',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_wishes.length > 10) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Menampilkan 10 ucapan terbaru dari ${_wishes.length} total',
                      ),
                      backgroundColor: _currentTheme.primaryColor,
                    ),
                  );
                },
                child: Text(
                  'Lihat ${_wishes.length - 10} ucapan lainnya',
                  style: TextStyle(
                    color: _currentTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatWishDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} menit yang lalu';
        } else {
          return '${difference.inHours} jam yang lalu';
        }
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return DateFormat('d MMM y', 'id_ID').format(date);
      }
    } catch (e) {
      return dateString.substring(0, 19);
    }
  }

  Widget _buildInvitationListTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Undangan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
              fontFamily: _currentTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _allInvitations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard_outlined,
                          size: 64,
                          color: _currentTheme.textPrimary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada undangan.\nSilakan buat undangan baru.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: _currentTheme.textPrimary.withOpacity(0.6),
                            fontFamily: _currentTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _allInvitations.length,
                    itemBuilder: (context, index) {
                      final invitation = _allInvitations[index];
                      final isSelected =
                          _selectedInvitation?.id == invitation.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? _currentTheme.primaryColor.withOpacity(0.2)
                                  : _currentTheme.primaryColor.withOpacity(
                                      0.05,
                                    ),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: isSelected
                              ? _currentTheme.primaryColor.withOpacity(0.1)
                              : _currentTheme.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? _currentTheme.primaryColor.withOpacity(0.3)
                                  : _currentTheme.primaryColor.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          _currentTheme.primaryColor,
                                          _currentTheme.primaryColor
                                              .withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          _currentTheme.textPrimary.withOpacity(
                                            0.1,
                                          ),
                                          _currentTheme.textPrimary.withOpacity(
                                            0.05,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _currentTheme.primaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.card_giftcard,
                                color: isSelected
                                    ? Colors.white
                                    : _currentTheme.textPrimary.withOpacity(
                                        0.6,
                                      ),
                                size: isSelected ? 24 : 22,
                              ),
                            ),
                            title: Text(
                              invitation.title ?? 'Undangan Tanpa Judul',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? _currentTheme.primaryColor
                                    : _currentTheme.textPrimary,
                                fontSize: 16,
                                fontFamily: _currentTheme.fontFamily,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${invitation.groomFullName ?? 'Mempelai Pria'} & ${invitation.brideFullName ?? 'Mempelai Wanita'}',
                                style: TextStyle(
                                  color: isSelected
                                      ? _currentTheme.primaryColor.withOpacity(
                                          0.8,
                                        )
                                      : _currentTheme.textPrimary.withOpacity(
                                          0.7,
                                        ),
                                  fontSize: 14,
                                  fontFamily: _currentTheme.fontFamily,
                                ),
                              ),
                            ),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: _currentTheme.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _currentTheme.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_vert,
                                  color: isSelected
                                      ? _currentTheme.primaryColor
                                      : _currentTheme.textPrimary.withOpacity(
                                          0.6,
                                        ),
                                  size: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: _currentTheme.cardBackground,
                                elevation: 8,
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _showEditInvitationDialog(invitation);
                                      break;
                                    case 'delete':
                                      _showDeleteInvitationDialog(invitation);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: _currentTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: _currentTheme.textPrimary,
                                            fontFamily:
                                                _currentTheme.fontFamily,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Hapus',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontFamily:
                                                _currentTheme.fontFamily,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              setState(() {
                                _selectedInvitation = invitation;
                              });

                              await _storageService.saveInvitationId(
                                invitation.id.toString(),
                              );

                              _getEventsByInvitationId();
                              await _loadWishesByInvitationId();

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Undangan "${invitation.title}" dipilih',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontFamily:
                                                _currentTheme.fontFamily,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: _currentTheme.primaryColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Wedding Gift",
            style: TextStyle(
              fontSize: 28,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Doa restu Bapak/Ibu sekalian merupakan karunia yang sangat berarti bagi kami. "
            "Dan jika memberi merupakan ungkapan tanda kasih, Bapak/Ibu dapat memberi kado "
            "secara cashless. Terima kasih",
            textAlign: TextAlign.center,
            style: italicTextStyle.copyWith(
              fontSize: 16,
              fontFamily: _currentTheme.fontFamily,
              letterSpacing: 0.5,
              wordSpacing: 1.2,
              color: _currentTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showBankDetails = !_showBankDetails;
              });
            },
            icon: Icon(
              _showBankDetails ? Icons.visibility_off : Icons.visibility,
            ),
            label: Text(
              _showBankDetails ? "Sembunyikan Detail" : "Lihat Detail",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          if (_showBankDetails) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _currentTheme.secondaryColor),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/bca_card.jpg',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "BCA: 1234567890",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text("a.n. Ahmad", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nomor rekening disalin')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple.shade700,
                      side: BorderSide(color: _currentTheme.secondaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text("Salin Nomor Rekening"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThankYouSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _currentTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _currentTheme.primaryColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  decoration: circleImageDecoration,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/gallery3.jpeg',
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Merupakan Suatu Kebahagiaan dan Kehormatan bagi Kami, "
                  "Apabila Bapak/Ibu/Saudara/i, Berkenan Hadir di Acara kami",
                  textAlign: TextAlign.center,
                  style: italicTextStyle.copyWith(
                    fontSize: 16,
                    fontFamily: _currentTheme.fontFamily,
                    letterSpacing: 0.5,
                    wordSpacing: 1.2,
                    color: _currentTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Ahmad & Siti",
          textAlign: TextAlign.center,
          style: coupleNameTextStyle.copyWith(
            fontSize: 36,
            fontFamily: 'Cormorant',
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMomenkuSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: Colors.purple.shade900,
      child: Column(
        children: [
          Text(
            'Thank You',
            style: coupleNameTextStyle.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontFamily: 'Cormorant',
            ),
          ),
          sh10,
          Text(
            'For being part of our special day',
            style: bodyTextStyle.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          sh16,
          Text(
            "Created with ❤️ by MomenKu",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
