import 'dart:io';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_online/constants/styles.dart';
import 'package:wedding_online/models/event_load_model.dart';
import 'package:wedding_online/models/invitation_model.dart';
import 'package:wedding_online/services/auth_service.dart';
import 'package:wedding_online/services/storage_service.dart';
import 'package:wedding_online/view/countdown_timer.dart';
import 'package:wedding_online/view/event_view.dart';
import 'dart:async';

import 'package:wedding_online/view/invitation_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _hasRedirected = false;

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  late Future<List<InvitationModel>> _invitationsFuture;

  // Current selected invitation
  InvitationModel? _selectedInvitation;
  List<InvitationModel> _allInvitations = [];

  // Image management variables
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;
  List<Map<String, dynamic>> _imageData = [];

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

  // Get current invitation data for display
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

  // Image management methods
  Future<void> _loadImages() async {
    print('🔥 LOAD IMAGES STARTED');
    setState(() {
      _isLoading = true;
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
      });
    } catch (e, stackTrace) {
      print('🔥 LOAD ERROR: $e');
      print('🔥 STACK TRACE: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageForReplace() async {
    try {
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
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageName = image.name;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _imageBytes = null;
            _imageName = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking replacement image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _replaceImage(int index) async {
    final imageInfo = _imageData[index];

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Replace Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to replace "${imageInfo['name']}" with a new image?',
              ),
              const SizedBox(height: 8),
              const Text(
                'The old image will be permanently deleted and replaced with the new one.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _pickImageForReplace();

      if ((kIsWeb && _imageBytes == null) || (!kIsWeb && _imageFile == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image selected for replacement.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final client = Supabase.instance.client;
      final newFileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = 'uploads/$newFileName';

      if (kIsWeb) {
        await client.storage
            .from('momenku_images')
            .uploadBinary(newPath, _imageBytes!);
      } else {
        await client.storage
            .from('momenku_images')
            .upload(newPath, _imageFile!);
      }

      await client.storage.from('momenku_images').remove([imageInfo['path']]);

      setState(() {
        _imageData[index] = {
          'name': newFileName,
          'url': client.storage.from('momenku_images').getPublicUrl(newPath),
          'path': newPath,
          'size': kIsWeb ? _imageBytes!.length : _imageFile!.lengthSync(),
          'lastModified': DateTime.now().toIso8601String(),
        };
      });

      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _imageName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image replaced successfully! 🔄'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('🔥 REPLACE ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to replace image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteImage(String path, String name, int index) async {
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
      await Supabase.instance.client.storage.from('momenku_images').remove([
        path,
      ]);

      setState(() {
        _imageData.removeAt(index);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete $name: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pickImage() async {
    try {
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
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageName = image.name;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _imageBytes = null;
            _imageName = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
    });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'uploads/$fileName';

      print('Uploading to path: $path');

      if (kIsWeb) {
        await Supabase.instance.client.storage
            .from('momenku_images')
            .uploadBinary(path, _imageBytes!);
      } else {
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

      await _loadImages();

      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _imageName = null;
      });
    } catch (e) {
      print('Upload error: $e');
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

  // Get image URL from uploaded images or fallback to assets
  String _getImageUrl(String assetPath, int index) {
    if (_imageData.isNotEmpty && index < _imageData.length) {
      return _imageData[index]['url'];
    }
    return assetPath; // fallback to asset
  }

  // Check if image is from Supabase
  bool _isSupabaseImage(String path, int index) {
    return _imageData.isNotEmpty && index < _imageData.length;
  }

  Future<List<InvitationModel>> _loadInvitations() async {
    final token = await _storageService.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await _authService.getInvitations(token);
    final list = response.data ?? [];

    setState(() {
      _allInvitations = list;
      // Set first invitation as selected if none is selected and list is not empty
      if (_selectedInvitation == null && list.isNotEmpty) {
        _selectedInvitation = list.first;
        _storageService.saveInvitationId(_selectedInvitation!.id.toString());
      }
    });

    if (list.isNotEmpty && list.last.id != null) {
      _getEventsByInvitationId();
      _loadImages(); // Load images when invitations are loaded
    }
    return list;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      await _storageService.clearAll();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
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

      if (invitationId == null || invitationId.isEmpty || invitationId == '0') {
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
          tempEvent = response.data!.last;
        } else {
          tempEvent = EventLoadModel();
        }
        _isLoading = false;
      });
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

  void _logout() async {
    await _storageService.clearAll();

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
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
          length: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: Icon(Icons.card_giftcard), text: "Undangan"),
                  Tab(icon: Icon(Icons.event), text: "Acara"),
                  Tab(icon: Icon(Icons.folder_open), text: "Daftar Undangan"),
                  Tab(icon: Icon(Icons.folder_open), text: "Daftar Acara"),
                ],
              ),
              SizedBox(
                height: 450,
                child: TabBarView(
                  children: [
                    InvitationView(onSuccess: _refreshInvitations),
                    EventView(onSuccess: _refreshInvitations),
                    _buildInvitationListTab(),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _getEventsByInvitationId();
                        },
                        child: const Text("Load Event"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _allInvitations.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada undangan.\nSilakan buat undangan baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _allInvitations.length,
                    itemBuilder: (context, index) {
                      final invitation = _allInvitations[index];
                      final isSelected =
                          _selectedInvitation?.id == invitation.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected
                            ? Colors.purple.shade50
                            : Colors.white,
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purple.shade700
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? Icons.check : Icons.card_giftcard,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            invitation.title ?? 'Undangan Tanpa Judul',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.purple.shade700
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${invitation.groomFullName ?? 'Mempelai Pria'} & ${invitation.brideFullName ?? 'Mempelai Wanita'}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.purple.shade600
                                  : Colors.grey.shade600,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: isSelected
                                  ? Colors.purple.shade700
                                  : Colors.grey,
                            ),
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
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            setState(() {
                              _selectedInvitation = invitation;
                            });

                            // Save selected invitation ID to storage
                            await _storageService.saveInvitationId(
                              invitation.id.toString(),
                            );

                            // Reload events for selected invitation
                            _getEventsByInvitationId();

                            // Close the bottom sheet
                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Undangan "${invitation.title}" dipilih',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
          title: Text('Edit Undangan'),
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
                // Show loading dialog
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

                  // Call update invitation API
                  final result = await authService.updateInvitation(
                    token,
                    data,
                    invitation.id!,
                  );

                  // Close loading dialog
                  Navigator.pop(context);

                  if (result.status == 200) {
                    // Close edit dialog
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Berhasil memperbarui undangan'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Simpan'),
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
                // Show loading dialog
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

                  // Close loading dialog
                  Navigator.pop(context);

                  if (result.status == 200) {
                    // Close delete dialog
                    Navigator.pop(context);

                    // If deleted invitation was selected, reset selection
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

                    // Refresh invitations
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
                  // Close loading dialog
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

  void _showAddEventPopup() {
    final nameController = TextEditingController();
    final venueNameController = TextEditingController();
    final venueAddressController = TextEditingController();
    final dateController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final descriptionController = TextEditingController();
    final orderNumberController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Waktu & Tempat'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nama Acara'),
                ),
                TextField(
                  controller: venueNameController,
                  decoration: InputDecoration(labelText: 'Tempat'),
                ),
                TextField(
                  controller: venueAddressController,
                  decoration: InputDecoration(labelText: 'Alamat'),
                ),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Tanggal'),
                  onTap: () async {
                    selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (selectedDate != null) {
                      dateController.text =
                          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                TextField(
                  controller: startTimeController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Jam Mulai'),
                  onTap: () async {
                    selectedStartTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: 9, minute: 0),
                    );
                    if (selectedStartTime != null) {
                      startTimeController.text =
                          "${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}:00";
                    }
                  },
                ),
                TextField(
                  controller: endTimeController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Jam Selesai'),
                  onTap: () async {
                    selectedEndTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: 11, minute: 0),
                    );
                    if (selectedEndTime != null) {
                      endTimeController.text =
                          "${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}:00";
                    }
                  },
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Deskripsi'),
                ),
                TextField(
                  controller: orderNumberController,
                  decoration: InputDecoration(labelText: 'Urutan'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  ),
                );

                try {
                  final token = await _storageService.getToken();
                  String? invitationId = await _storageService
                      .getInvitationID();

                  if (token == null) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _handleTokenErrorOnce('Token tidak valid');
                    return;
                  }

                  if (invitationId == null || invitationId.isEmpty) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Invitation ID tidak tersedia")),
                    );
                    return;
                  }

                  final response = await _authService.createEvent(
                    token: token,
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

                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Terjadi kesalahan: ")),
                  );
                  if (response.status == 201) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Acara berhasil dibuat")),
                    );

                    _getEventsByInvitationId();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal membuat acara")),
                    );
                  }
                } catch (e) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Simpan'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 800), () {
      _confettiController.play();
    });

    _invitationsFuture = _loadInvitations();
    _getEventsByInvitationId();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void logOut() {
    _storageService.clearAll();
  }

  void _calculateAttendingCount() {
    _attendingCount = comments
        .where((comment) => comment['attendance'] == 'Hadir')
        .length;
    setState(() {});
  }

  void _submitComment() {
    if (_nameController.text.isEmpty ||
        _messageController.text.isEmpty ||
        selectedValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mohon lengkapi semua data')));
      return;
    }

    setState(() {
      comments.add({
        'name': _nameController.text,
        'date': DateTime.now().toString().substring(0, 19),
        'message': _messageController.text,
        'attendance': selectedValue,
      });
      _nameController.clear();
      _messageController.clear();
      selectedValue = null;
      _calculateAttendingCount();
      _confettiController.play();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Terima kasih atas ucapannya!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("Home"),
        backgroundColor: Colors.purple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
                  colors: [
                    Colors.purple.shade900,
                    Colors.purple.shade700,
                    Colors.purple.shade400,
                    Colors.purple.shade300,
                  ],
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

          // Use current selected invitation or first invitation
          final currentInvitation = _currentInvitation;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade900,
                  Colors.purple.shade700,
                  Colors.purple.shade400,
                  Colors.purple.shade300,
                ],
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

  Widget _buildLogoutButton() => Align(
    child: ElevatedButton(
      onPressed: () {
        _storageService.clearAll();
        Navigator.pushReplacementNamed(context, '/login');
      },

      child: const Text('Logout'),
    ),
  );

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
          decoration: cardDecoration.copyWith(
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showImageOptions(0, 'couple.jpg'),
                  onLongPress: () =>
                      _showImageManagementDialog(0, 'couple.jpg'),
                  child: Container(
                    decoration: circleImageDecoration.copyWith(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isSupabaseImage('assets/images/couple.jpg', 0)
                          ? Image.network(
                              _getImageUrl('assets/images/couple.jpg', 0),
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/couple.jpg',
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/couple.jpg',
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "The Wedding of",
                  style: headerTextStyle.copyWith(fontFamily: 'Cormorant'),
                ),
                Text(
                  newTitle,
                  textAlign: TextAlign.center,
                  style: coupleNameTextStyle.copyWith(
                    fontSize: 38,
                    fontFamily: 'Cormorant',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.purple.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.purple.shade300,
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.purple.shade200)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Cinta yang sejati bukanlah tentang menemukan seseorang yang sempurna "
                  "tetapi tentang melihat kesempurnaan dalam ketidaksempurnaan.",
                  textAlign: TextAlign.center,
                  style: italicTextStyle.copyWith(
                    fontSize: 16,
                    letterSpacing: 0.5,
                    wordSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Show image options dialog
  void _showImageOptions(int index, String imageName) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manage Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.blue),
                title: Text('Upload New Image'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage().then((_) {
                    if (_imageFile != null || _imageBytes != null) {
                      uploadImage();
                    }
                  });
                },
              ),
              if (_imageData.isNotEmpty && index < _imageData.length) ...[
                ListTile(
                  leading: Icon(Icons.swap_horiz, color: Colors.orange),
                  title: Text('Replace Image'),
                  onTap: () {
                    Navigator.pop(context);
                    _replaceImage(index);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Image'),
                  onTap: () {
                    Navigator.pop(context);
                    if (_imageData.isNotEmpty && index < _imageData.length) {
                      _deleteImage(
                        _imageData[index]['path'],
                        _imageData[index]['name'],
                        index,
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Show image management dialog for long press
  void _showImageManagementDialog(int index, String imageName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Image Management'),
          content: Text('Long press detected on $imageName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            if (_imageData.isNotEmpty && index < _imageData.length)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _replaceImage(index);
                },
                child: Text('Replace'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPresentationCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            "Assalamualaikum Wr. Wb.",
            style: headerTextStyle.copyWith(
              fontSize: 24,
              fontFamily: 'Cormorant',
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Dengan memohon rahmat dan ridho Allah SWT, kami bermaksud menyelenggarakan acara pernikahan kami:",
            textAlign: TextAlign.center,
            style: italicTextStyle.copyWith(fontSize: 16, letterSpacing: 0.5),
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
      decoration: cardDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Save The Date",
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CountdownTimer(eventDate: tempEvent.date),
          const SizedBox(height: 20),
          Text(
            formattedDate ?? "Rabu, 18 Juni 2025",
            style: headerTextStyle.copyWith(
              fontSize: 24,
              fontFamily: 'Cormorant',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Pukul ${tempEvent.startTime} - ${tempEvent.endTime} WIB" ??
                "Pukul 13:30 - 20:00 WIB",
            style: bodyTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${tempEvent.venueAddress}" ??
                "Golden Ballroom - Grand Palace Hotel",
            style: bodyTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "${tempEvent.venueName}"
            "Jl. Raya Utama No. 123, Jakarta",
            style: bodyTextStyle,
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
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
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
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            "Bride & Groom",
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showImageOptions(1, 'groom.jpeg'),
            onLongPress: () => _showImageManagementDialog(1, 'groom.jpeg'),
            child: Container(
              decoration: circleImageDecoration,
              child: ClipOval(
                child: _isSupabaseImage('assets/images/gallery1.jpeg', 1)
                    ? Image.network(
                        _getImageUrl('assets/images/gallery1.jpeg', 1),
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/gallery1.jpeg',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/gallery1.jpeg',
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            groomFullName,
            style: coupleNameTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Putra pertama dari pasangan\n"
            "Bapak $groomFatherName & Ibu $groomMotherName\n"
            "Jakarta",
            textAlign: TextAlign.center,
            style: bodyTextStyle.copyWith(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Icon(Icons.favorite, color: Colors.purple.shade300, size: 32),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showImageOptions(2, 'bride.jpeg'),
            onLongPress: () => _showImageManagementDialog(2, 'bride.jpeg'),
            child: Container(
              decoration: circleImageDecoration,
              child: ClipOval(
                child: _isSupabaseImage('assets/images/gallery1.jpeg', 2)
                    ? Image.network(
                        _getImageUrl('assets/images/gallery1.jpeg', 2),
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/gallery1.jpeg',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/gallery1.jpeg',
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            brideFullName,
            style: coupleNameTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Putri pertama dari pasangan\n"
            "Bapak $brideFatherName & Ibu $brideMotherName\n"
            "Bandung",
            textAlign: TextAlign.center,
            style: bodyTextStyle.copyWith(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSchedule({required EventLoadModel defaultEvent}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            'Susunan Acara',
            style: headerTextStyle.copyWith(
              fontSize: 25,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          sh24,
          _buildScheduleItem(
            icon: Icons.mosque,
            title: defaultEvent.name ?? "Akad Nikah",
            time:
                "${defaultEvent.startTime} - ${defaultEvent.endTime} WIB" ??
                "13:30 - 15:00 WIB",
            description: "Ijab kabul dan penandatanganan buku nikah",
          ),
          const SizedBox(height: 16),
          _buildScheduleItem(
            icon: Icons.celebration,
            title: "Resepsi",
            time:
                "${defaultEvent.startTime} - ${defaultEvent.endTime} WIB" ??
                "15:30 - 20:00 WIB",
            description: "Penyambutan tamu undangan dan jamuan makan",
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required IconData icon,
    required String title,
    required String time,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.purple.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                time,
                style: bodyTextStyle.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(description, style: bodyTextStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      children: [
        _buildSectionHeader("Our Gallery"),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration,
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: galleryImages.asMap().entries.map((entry) {
                  int index =
                      entry.key + 3; // Start from index 3 for gallery images
                  String image = entry.value;
                  return GestureDetector(
                    onTap: () =>
                        _showImageOptions(index, 'gallery${entry.key}.jpeg'),
                    onLongPress: () => _showImageManagementDialog(
                      index,
                      'gallery${entry.key}.jpeg',
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _isSupabaseImage(image, index)
                            ? Image.network(
                                _getImageUrl(image, index),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(image, fit: BoxFit.cover);
                                },
                              )
                            : Image.asset(image, fit: BoxFit.cover),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                "\"Cinta adalah perjalanan yang indah ketika didasari oleh kesetiaan dan komitmen yang tulus.\"",
                textAlign: TextAlign.center,
                style: italicTextStyle.copyWith(
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
                Expanded(child: Divider(color: Colors.purple.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    title,
                    style: headerTextStyle.copyWith(
                      fontFamily: 'Cormorant',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.purple.shade200)),
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
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            "Livestream",
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 50, color: Colors.purple.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Live Streaming akan dimulai pada hari-H",
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              Uri url = Uri.parse('https://youtube.com');

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
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            "Konfirmasi Kehadiran",
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Nama",
              labelStyle: TextStyle(color: Colors.purple.shade700),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
              ),
              prefixIcon: Icon(Icons.person, color: Colors.purple.shade300),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Ucapan & Doa",
              labelStyle: TextStyle(color: Colors.purple.shade700),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
              ),
              prefixIcon: Icon(Icons.message, color: Colors.purple.shade300),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade300, width: 2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                hint: Text(
                  "Status Kehadiran",
                  style: TextStyle(color: Colors.purple.shade700),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.purple.shade700,
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
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedValue = newValue;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text(
                  "Kirim Ucapan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      decoration: cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${comments.length} Ucapan",
                style: headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$_attendingCount Hadir",
                style: headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          for (var comment in comments) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Text(
                  comment['name'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    comment['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: comment['attendance'] == 'Hadir'
                          ? Colors.green.shade100
                          : comment['attendance'] == 'Tidak Hadir'
                          ? Colors.red.shade100
                          : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      comment['attendance'],
                      style: TextStyle(
                        fontSize: 12,
                        color: comment['attendance'] == 'Hadir'
                            ? Colors.green.shade800
                            : comment['attendance'] == 'Tidak Hadir'
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
                    comment['date'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(comment['message']),
                ],
              ),
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }

  Widget _buildGiftSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            "Wedding Gift",
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Doa restu Bapak/lbu sekalian merupakan karunia yang sangat berarti bagi kami. "
            "Dan jika memberi merupakan ungkapan tanda kasih, Bapak/lbu dapat memberi kado "
            "secara cashless. Terima kasih",
            textAlign: TextAlign.center,
            style: italicTextStyle.copyWith(fontSize: 16, letterSpacing: 0.5),
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
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
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
                border: Border.all(color: Colors.purple.shade300),
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
                      side: BorderSide(color: Colors.purple.shade300),
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
          decoration: cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showImageOptions(
                    7,
                    'thank_you.jpeg',
                  ), // Index 7 for thank you image
                  onLongPress: () =>
                      _showImageManagementDialog(7, 'thank_you.jpeg'),
                  child: Container(
                    decoration: circleImageDecoration,
                    child: ClipOval(
                      child: _isSupabaseImage('assets/images/gallery3.jpeg', 7)
                          ? Image.network(
                              _getImageUrl('assets/images/gallery3.jpeg', 7),
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/gallery3.jpeg',
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/gallery3.jpeg',
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
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
                    letterSpacing: 0.5,
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
