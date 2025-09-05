import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class InvitationView extends StatefulWidget {
  const InvitationView({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<InvitationView> createState() => _InvitationViewState();
}

class _InvitationViewState extends State<InvitationView>
    with TickerProviderStateMixin {
  // Controllers
  final groomFullNameController = TextEditingController();
  final groomNickNameController = TextEditingController();
  final groomFatherNameController = TextEditingController();
  final groomMotherNameController = TextEditingController();
  final brideFullNameController = TextEditingController();
  final brideNickNameController = TextEditingController();
  final brideFatherNameController = TextEditingController();
  final brideMotherNameController = TextEditingController();

  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    groomFullNameController.dispose();
    groomNickNameController.dispose();
    groomFatherNameController.dispose();
    groomMotherNameController.dispose();
    brideFullNameController.dispose();
    brideNickNameController.dispose();
    brideFatherNameController.dispose();
    brideMotherNameController.dispose();
    super.dispose();
  }

  // Custom styled TextField widget
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
              decoration: InputDecoration(
                hintText: hint ?? "Masukkan $label",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 12, right: 12),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFFE91E63),
                    size: 22,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: iconColor ?? const Color(0xFFE91E63),
                    width: 2.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section header widget
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitInvitation() async {
    // Validate required fields
    if (groomFullNameController.text.isEmpty ||
        brideFullNameController.text.isEmpty ||
        groomFatherNameController.text.isEmpty ||
        groomMotherNameController.text.isEmpty ||
        brideFatherNameController.text.isEmpty ||
        brideMotherNameController.text.isEmpty) {
      _showSnackBar(
        "Mohon lengkapi semua field yang diperlukan",
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/login');
        return;
      }

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

      await authService.createInvitation(token, data);

      if (mounted) {
        _showSnackBar(
          'Undangan berhasil dibuat!',
          Colors.green,
          Icons.check_circle,
        );
        widget.onSuccess();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membuat undangan: $e', Colors.red, Icons.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resetForm() {
    groomFullNameController.clear();
    groomNickNameController.clear();
    groomFatherNameController.clear();
    groomMotherNameController.clear();
    brideFullNameController.clear();
    brideNickNameController.clear();
    brideFatherNameController.clear();
    brideMotherNameController.clear();

    _showSnackBar('Form berhasil direset', Colors.blue, Icons.refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Buat Undangan",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Undangan Pernikahan",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Isi data mempelai dengan lengkap",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Groom Section
                      _buildSectionHeader(
                        title: "Data Mempelai Pria",
                        subtitle: "Informasi lengkap mempelai pria",
                        icon: Icons.person,
                        color: const Color(0xFF2196F3),
                      ),

                      _buildStyledTextField(
                        controller: groomFullNameController,
                        label: "Nama Lengkap Pria",
                        icon: Icons.person,
                        iconColor: const Color(0xFF2196F3),
                        hint: "Contoh: Ahmad Rizki Pratama",
                      ),

                      _buildStyledTextField(
                        controller: groomNickNameController,
                        label: "Nama Panggilan Pria",
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF2196F3),
                        hint: "Contoh: Rizki",
                      ),

                      _buildStyledTextField(
                        controller: groomFatherNameController,
                        label: "Nama Ayah Pria",
                        icon: Icons.family_restroom,
                        iconColor: const Color(0xFF2196F3),
                        hint: "Contoh: Bapak Suharto",
                      ),

                      _buildStyledTextField(
                        controller: groomMotherNameController,
                        label: "Nama Ibu Pria",
                        icon: Icons.family_restroom,
                        iconColor: const Color(0xFF2196F3),
                        hint: "Contoh: Ibu Siti Aminah",
                      ),

                      const SizedBox(height: 24),

                      // Bride Section
                      _buildSectionHeader(
                        title: "Data Mempelai Wanita",
                        subtitle: "Informasi lengkap mempelai wanita",
                        icon: Icons.person,
                        color: const Color(0xFFE91E63),
                      ),

                      _buildStyledTextField(
                        controller: brideFullNameController,
                        label: "Nama Lengkap Wanita",
                        icon: Icons.person,
                        iconColor: const Color(0xFFE91E63),
                        hint: "Contoh: Siti Nurhaliza Putri",
                      ),

                      _buildStyledTextField(
                        controller: brideNickNameController,
                        label: "Nama Panggilan Wanita",
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFFE91E63),
                        hint: "Contoh: Siti",
                      ),

                      _buildStyledTextField(
                        controller: brideFatherNameController,
                        label: "Nama Ayah Wanita",
                        icon: Icons.family_restroom,
                        iconColor: const Color(0xFFE91E63),
                        hint: "Contoh: Bapak Bambang",
                      ),

                      _buildStyledTextField(
                        controller: brideMotherNameController,
                        label: "Nama Ibu Wanita",
                        icon: Icons.family_restroom,
                        iconColor: const Color(0xFFE91E63),
                        hint: "Contoh: Ibu Dewi Sari",
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF95A5A6),
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _loading ? null : _resetForm,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          color: _loading
                                              ? Colors.grey
                                              : const Color(0xFF95A5A6),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Reset",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _loading
                                                ? Colors.grey
                                                : const Color(0xFF95A5A6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE91E63),
                                    Color(0xFFAD1457),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE91E63,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _loading ? null : _submitInvitation,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.send,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Buat Undangan",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Info Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Pastikan semua data sudah benar sebelum membuat undangan",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
        },
      ),
    );
  }
}
