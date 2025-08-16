import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_online/constants/styles.dart';
import 'package:wedding_online/models/event_load_model.dart';
import 'package:wedding_online/models/event_model.dart';
import 'package:wedding_online/models/invitation_model.dart';
import 'package:wedding_online/services/auth_service.dart';
import 'package:wedding_online/services/storage_service.dart';
import 'package:wedding_online/view/countdown_timer.dart';
import 'dart:async';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _hasRedirected = false;

  //   void _handleTokenErrorOnce(String error) {
  //   if (_hasRedirected) return;

  //   _hasRedirected = true;

  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     await _storageService.clearAll();
  //     if (!mounted) return;
  //     Navigator.pushReplacementNamed(context, '/login');
  //   });
  // }

  void _handleTokenErrorOnce(String error) {
    if (_hasRedirected) return;

    _hasRedirected = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Tampilkan snackbar sebelum redirect
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(
        const Duration(seconds: 2),
      ); // beri waktu tampil snackbar
      await _storageService.clearAll();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  late Future<List<InvitationModel>> _invitationsFuture;

  List<EventLoadModel> _events = [];
  bool _isLoading = true;

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
  Future<List<InvitationModel>> _loadInvitations() async {
    final token = await _storageService.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await _authService.getInvitations(token);
    if (response.data?.last.id != null) {
      _loadEvents();
    }
    return response.data ?? [];
  }

  void _loadEvents() async {
    try {
      final token = await _storageService.getToken();
      String invitationId = await _storageService
          .getInvitationID(); // pastikan ada method ini
      debugPrint('------');
      debugPrint('load event invitation id: $invitationId');
      if (token == null) {
        _handleTokenErrorOnce('Token tidak valid');
        return;
      }

      final response = await _authService.getEventsByInvitationId(
        token: token,
        invitationId: int.parse(invitationId),
      );

      setState(() {
        _events = response.data ?? [];
        tempEvent = response.data?.last ?? EventLoadModel();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal load events: $e');
      _handleTokenErrorOnce(e.toString());
    }
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

                Navigator.pop(context);

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
                // Tampilkan loading
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
                  String invitationId = await _storageService.getInvitationID();

                  final response = await _authService.createEvent(
                    token: token!,
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

                  Navigator.pop(context); // Tutup loading dialog

                  if (response.status == 201) {
                    Navigator.pop(context); // Tutup form popup
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Acara berhasil dibuat")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal membuat acara")),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context); // Tutup loading dialog jika error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Terjadi kesalahan: $e")),
                  );
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
    _loadEvents();

    // _calculateAttendingCount();
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
      body: FutureBuilder<List<InvitationModel>>(
        future: _invitationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _handleTokenErrorOnce(
              snapshot.error.toString(),
            ); // 🟢 Panggil fungsi khusus
          }

          // if (snapshot.hasError) {
          //   return Center(
          //     child: Text('Terjadi kesalahan bro: ${snapshot.error}'),
          //   );
          // }

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
                    sh32,
                    Row(
                      children: [
                        _buildLogoutButton(),
                        ElevatedButton(
                          onPressed: () {
                            showCreateInvitationPopup(
                              context,
                            ); // Ganti `token` sesuai yang kamu simpan
                          },
                          child: Text("Buat Undangan"),
                        ),
                        sw10,
                        ElevatedButton(
                          onPressed: _showAddEventPopup,
                          child: Text("Tambah Acara"),
                        ),
                      ],
                    ),
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
                    _buildEventSchedule(),
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
          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
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
                      sh32,
                      Row(
                        children: [
                          _buildLogoutButton(),
                          ElevatedButton(
                            onPressed: () {
                              showCreateInvitationPopup(
                                context,
                              ); // Ganti `token` sesuai yang kamu simpan
                            },
                            child: Text("Buat Undangan"),
                          ),
                          sw10,
                          ElevatedButton(
                            onPressed: _showAddEventPopup,
                            child: Text("Tambah Acara"),
                          ),
                        ],
                      ),
                      sh16,
                      ElevatedButton(
                        onPressed: () {
                          _loadEvents();
                        },
                        child: Text("Load Event"),
                      ),
                      sh16,
                      _buildWeddingInfoCard(invitation.title),
                      sh32,
                      _buildPresentationCard(),
                      sh32,
                      _buildDateSection(tempEvent),
                      sh32,
                      _buildCoupleSection(
                        groomFullName:
                            invitation.groomFullName ?? groomFullName,
                        brideFullName:
                            invitation.brideFullName ?? brideFullName,
                        groomFatherName:
                            invitation.groomFatherName ?? groomFatherName,
                        groomMotherName:
                            invitation.groomMotherName ?? groomMotherName,
                        brideFatherName:
                            invitation.brideFatherName ?? brideFatherName,
                        brideMotherName:
                            invitation.brideMotherName ?? brideMotherName,
                      ),
                      sh32,
                      _buildEventSchedule(),
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
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton() => Align(
    alignment: Alignment.centerRight,
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
                Container(
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
        DateTime.tryParse(tempEvent.date ?? '') ??
        DateTime(2025, 1, 1); // default kalau null/invalid

    // Format: Rabu, 18 Juni 2025
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
          // CountdownTimer(eventDate: tempEvent.date),
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
          Container(
            decoration: circleImageDecoration,
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
          Container(
            decoration: circleImageDecoration,
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

  Widget _buildEventSchedule() {
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
            title: "Akad Nikah",
            time: "13:30 - 15:00 WIB",
            description: "Ijab kabul dan penandatanganan buku nikah",
          ),
          const SizedBox(height: 16),
          _buildScheduleItem(
            icon: Icons.celebration,
            title: "Resepsi",
            time: "15:30 - 20:00 WIB",
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
                children: galleryImages.map((image) {
                  return Container(
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
                      child: Image.asset(image, fit: BoxFit.cover),
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
            'For beind part of our special day',
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
