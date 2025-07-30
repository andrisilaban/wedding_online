import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_online/constants/styles.dart';
import 'package:wedding_online/services/storage_service.dart';
import 'package:wedding_online/view/countdown_timer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  StorageService storageService = StorageService();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  String? selectedValue;
  final List<String> options = ["Hadir", "Tidak Hadir", "Mungkin"];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

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

  int _attendingCount = 0;
  bool _showBankDetails = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 800), () {
      _confettiController.play();
    });

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
    storageService.clearAll();
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
      body: Container(
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
              sh100,
              ElevatedButton(
                onPressed: () async {
                  await StorageService().clearAll();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text('Logout'),
              ),
              sh16,
              _buildWeddingInfoCard(),
              const SizedBox(height: 30),
              Container(
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
                      style: italicTextStyle.copyWith(
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              sh32,
              _buildDateSection(),
              sh32,
              _buildCoupleSection(),
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
              Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeddingInfoCard() {
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
                  "Ahmad & Siti",
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

  Widget _buildDateSection() {
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
            'Save The Date',
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          sh16,
          const CountdownTimer(),
          sh20,
          Text(
            'Rabu 18 Juni 2025',
            style: headerTextStyle.copyWith(
              fontSize: 24,
              fontFamily: 'Cormorant',
            ),
          ),
          sh16,
          Text(
            'Pukul 13:30 - 20:00',
            style: bodyTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          sh16,
          Text(
            'Golder Ballroom - Grand Palace Hotel',
            style: bodyTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text('Jl. Raya Utama No. 123, Jakarta', style: bodyTextStyle),
          sh20,
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
            label: Text('Lihat Lokasi'),
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

  Widget _buildCoupleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            'Bride & Groom',
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          sh24,
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
            'Ahmad',
            style: coupleNameTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
            ),
          ),
          sh10,
          Text(
            "Putra pertama dari pasangan\n"
            "Bapak Hadi & Ibu Aminah\n"
            "Jakarta",
            textAlign: TextAlign.center,
            style: bodyTextStyle.copyWith(fontSize: 16, height: 1.5),
          ),
          sh24,
          Container(
            decoration: circleImageDecoration,
            child: ClipOval(
              child: Image.asset(
                'assets/images/gallery1.jpeg',
                width: 140,
                height: 140,
              ),
            ),
          ),
          sh16,
          Text(
            'Siti',
            style: coupleNameTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
            ),
          ),
          sh10,
          Text(
            'Putri pertama dari pasangan\n'
            'Bapak Joko & Ibu Sarah\n'
            'Bandung',
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
        sw16,
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
        _buildSectionHeader('Our Gallery'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration,
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 1,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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
              sh20,
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          if (withDivider)
            Row(
              children: [
                Expanded(child: Divider(color: Colors.purple.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
            'Livestream',
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          sh16,
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
                  sh16,
                  Text(
                    'Live Streamin akan dimulau pada hari-H',
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
          ),
          sh16,
          ElevatedButton.icon(
            onPressed: () async {
              Uri url = Uri.parse('https://youtube.com');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(Icons.play_circle_filled),
            label: Text('Tonton di Youtube'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(30),
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
      padding: EdgeInsets.all(24),
      decoration: cardDecoration,
      child: Column(
        children: [
          Text(
            'Konfirmasi Kehadiran',
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          sh24,
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama',
              labelStyle: TextStyle(color: Colors.purple.shade700),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
            ),
          ),
          sh16,
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Ucapan & Doa',
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
          sh16,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade300, width: 2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                hint: Text(
                  'Status Kehadiran',
                  style: TextStyle(color: Colors.purple.shade300),
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
                          value == 'Hadir' ? Icons.check_circle : Icons.help,
                          color: value == 'Hadir'
                              ? Colors.green
                              : value == 'Tidak Hadir'
                              ? Colors.red
                              : Colors.amber,
                          size: 20,
                        ),
                        sh10,
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
          sh24,
          ElevatedButton(
            onPressed: _submitComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(30),
              ),
              elevation: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send),
                sh10,
                Text(
                  'Kirim Ucapan',
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
                '${comments.length} Ucapan',
                style: headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_attendingCount Hadir',
                style: headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          sh16,
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  sh10,
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
                      'attendance',
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
            Divider(),
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
            'Wedding Gift',
            style: headerTextStyle.copyWith(
              fontSize: 28,
              fontFamily: 'Cormorant',
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          sh16,
          Text(
            "Doa restu Bapak/lbu sekalian merupakan karunia yang sangat berarti bagi kami. "
            "Dan jika memberi merupakan ungkapan tanda kasih, Bapak/lbu dapat memberi kado "
            "secara cashless. Terima kasih",
            textAlign: TextAlign.center,
            style: italicTextStyle.copyWith(fontSize: 16, letterSpacing: 0.5),
          ),
          sh20,
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
              _showBankDetails ? 'Sembunyikan Detail' : 'Lihat Detail',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          if (_showBankDetails) ...[
            sh20,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,

                border: Border.all(color: Colors.purple.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/bca_card.jpg',
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  sh16,
                  Text(
                    'BCA: 1234567890',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('a.n. Afrizal', style: TextStyle(fontSize: 16)),
                  sh16,
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Nomor rekening disalin')),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy),
                        sw10,
                        Text('Salin Nomor Rekening'),
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
            padding: const EdgeInsets.all(24),
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
                sh20,
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
        sh16,
        Text(
          'Ahmad & Siti',
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
}
