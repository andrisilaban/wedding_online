import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_online/models/package_model.dart';
import 'package:wedding_online/models/theme_model.dart';
import 'package:wedding_online/services/auth_service.dart';

class PackageView extends StatefulWidget {
  final WeddingTheme currentTheme;

  const PackageView({super.key, required this.currentTheme});

  @override
  State<PackageView> createState() => _PackageViewState();
}

class _PackageViewState extends State<PackageView> {
  final AuthService _authService = AuthService();
  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load active packages (public endpoint)
      final response = await _authService.getActivePackages();

      if (response.status == 200 && response.data != null) {
        setState(() {
          _packages = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Gagal memuat paket';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
      debugPrint('Error loading packages: $e');
    }
  }

  // Ganti method _contactWhatsApp di file package_view.dart dengan kode ini:

  Future<void> _contactWhatsApp(PackageModel package) async {
    final phoneNumber = '6281234567890'; // Ganti dengan nomor WhatsApp bisnis
    final message = Uri.encodeComponent(
      'Halo, saya tertarik dengan ${package.name}.\n'
      'Detail paket:\n'
      '- Maksimal tamu: ${package.guestsDisplay}\n'
      '- Masa berlaku: ${package.validityDisplay}\n'
      '- Harga: ${package.formattedPrice}\n\n'
      'Bisakah dijelaskan lebih detail?',
    );

    // Coba beberapa format URL WhatsApp
    final List<String> whatsappUrls = [
      'whatsapp://send?phone=$phoneNumber&text=$message',
      'https://wa.me/$phoneNumber?text=$message',
      'https://api.whatsapp.com/send?phone=$phoneNumber&text=$message',
    ];

    bool launched = false;

    for (String whatsappUrl in whatsappUrls) {
      try {
        final Uri url = Uri.parse(whatsappUrl);

        // Cek apakah URL bisa dilaunch
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        debugPrint('Error trying URL $whatsappUrl: $e');
        continue;
      }
    }

    if (!launched && mounted) {
      // Jika semua URL gagal, tampilkan dialog dengan opsi alternatif
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Buka WhatsApp',
            style: TextStyle(
              color: widget.currentTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WhatsApp tidak dapat dibuka secara otomatis. Silakan hubungi kami melalui:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.currentTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.currentTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: widget.currentTheme.primaryColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Nomor WhatsApp:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.currentTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesan untuk disalin:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      Uri.decodeComponent(message),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Copy nomor telepon ke clipboard
                Clipboard.setData(ClipboardData(text: phoneNumber));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nomor WhatsApp disalin ke clipboard'),
                    backgroundColor: widget.currentTheme.primaryColor,
                  ),
                );
              },
              child: Text(
                'Salin Nomor',
                style: TextStyle(color: widget.currentTheme.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                // Copy pesan ke clipboard
                Clipboard.setData(
                  ClipboardData(text: Uri.decodeComponent(message)),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesan disalin ke clipboard'),
                    backgroundColor: widget.currentTheme.primaryColor,
                  ),
                );
              },
              child: Text(
                'Salin Pesan',
                style: TextStyle(color: widget.currentTheme.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.currentTheme.primaryColor,
              ),
              child: Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showPackageDetails(PackageModel package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: widget.currentTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      package.name ?? 'Paket',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.currentTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: widget.currentTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.currentTheme.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.currentTheme.primaryColor.withOpacity(
                              0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            package.formattedPrice,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Sekali bayar untuk ${package.validityDisplay}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    if (package.description != null) ...[
                      Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.currentTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.currentTheme.primaryColor.withOpacity(
                            0.05,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.currentTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                          ),
                        ),
                        child: Text(
                          package.description!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: widget.currentTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Features
                    Text(
                      'Yang Anda Dapatkan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.currentTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureItem(
                      Icons.people,
                      'Maksimal Tamu',
                      package.guestsDisplay,
                    ),
                    _buildFeatureItem(
                      Icons.schedule,
                      'Masa Berlaku',
                      package.validityDisplay,
                    ),
                    _buildFeatureItem(
                      Icons.phone_android,
                      'Undangan Digital',
                      'Responsive & mobile-friendly',
                    ),
                    _buildFeatureItem(
                      Icons.palette,
                      'Tema Custom',
                      'Berbagai pilihan tema menarik',
                    ),
                    _buildFeatureItem(
                      Icons.support_agent,
                      'Customer Support',
                      '24/7 via WhatsApp',
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _contactWhatsApp(package),
                      icon: const Icon(Icons.phone, size: 20),
                      label: const Text(
                        'Hubungi via WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF25D366,
                        ), // WhatsApp green
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.currentTheme.primaryColor,
                        side: BorderSide(
                          color: widget.currentTheme.primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.currentTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: widget.currentTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.currentTheme.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.currentTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.currentTheme.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.currentTheme.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPackageDetails(package),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        package.name ?? 'Paket',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        package.formattedPrice,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (package.description != null) ...[
                  Text(
                    package.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    _buildPackageInfo(Icons.people, package.guestsDisplay),
                    const SizedBox(width: 20),
                    _buildPackageInfo(Icons.schedule, package.validityDisplay),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showPackageDetails(package),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Detail'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _contactWhatsApp(package),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widget.currentTheme.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Pesan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_membership,
                color: widget.currentTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Paket Berlangganan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.currentTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.currentTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.currentTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: widget.currentTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upgrade untuk fitur premium dan kapasitas lebih besar',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.currentTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat paket...'),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.currentTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadPackages,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.currentTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : _packages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada paket tersedia',
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.currentTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      return _buildPackageCard(_packages[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
