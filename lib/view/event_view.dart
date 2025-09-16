import 'package:flutter/material.dart';
import '../models/theme_model.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class EventView extends StatefulWidget {
  final VoidCallback onSuccess;
  final WeddingTheme? currentTheme; // Parameter theme dari parent

  const EventView({super.key, required this.onSuccess, this.currentTheme});

  @override
  _EventViewState createState() => _EventViewState();
}

class _EventViewState extends State<EventView> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  // Theme management
  WeddingTheme _currentTheme = ThemeService.availableThemes.first;
  final ThemeService _themeService = ThemeService();
  bool _isThemeLoading = true;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController venueNameController = TextEditingController();
  final TextEditingController venueAddressController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController orderNumberController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  // Inisialisasi theme
  void _initializeTheme() {
    // Jika ada theme yang dikirim dari parent, gunakan itu
    if (widget.currentTheme != null) {
      setState(() {
        _currentTheme = widget.currentTheme!;
        _isThemeLoading = false;
      });
    } else {
      // Jika tidak ada, load dari ThemeService
      _loadCurrentTheme();
    }
  }

  // Load theme dari ThemeService
  Future<void> _loadCurrentTheme() async {
    try {
      final theme = await _themeService.getCurrentTheme();
      if (mounted) {
        setState(() {
          _currentTheme = theme;
          _isThemeLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading theme in EventView: $e');
      if (mounted) {
        setState(() {
          _currentTheme = ThemeService.availableThemes.first;
          _isThemeLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(EventView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update theme ketika theme dari parent berubah
    if (widget.currentTheme != oldWidget.currentTheme &&
        widget.currentTheme != null) {
      debugPrint('Theme changed in EventView: ${widget.currentTheme!.name}');
      setState(() {
        _currentTheme = widget.currentTheme!;
        _isThemeLoading = false;
      });
    }
  }

  // Custom TextField widget with theme styling
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool isRequired = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _currentTheme.textPrimary,
                fontFamily: _currentTheme.fontFamily,
              ),
              children: isRequired
                  ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: _currentTheme.primaryColor),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _currentTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _currentTheme.textPrimary,
                fontFamily: _currentTheme.fontFamily,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: _currentTheme.textPrimary.withOpacity(0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: _currentTheme.fontFamily,
                ),
                prefixIcon: prefixIcon != null
                    ? Container(
                        margin: const EdgeInsets.only(left: 8, right: 8),
                        child: Icon(
                          prefixIcon,
                          color: _currentTheme.primaryColor,
                          size: 22,
                        ),
                      )
                    : null,
                suffixIcon: suffixIcon != null
                    ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          suffixIcon,
                          color: _currentTheme.textPrimary.withOpacity(0.6),
                          size: 22,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: _currentTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _currentTheme.primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _currentTheme.primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _currentTheme.primaryColor,
                    width: 2.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _currentTheme.primaryColor.withRed(255),
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _currentTheme.primaryColor.withRed(255),
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

  Future<void> _submitEvent() async {
    setState(() => _isLoading = true);

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

      final invitationId = await _storageService.getInvitationID();
      debugPrint('----------');
      debugPrint(invitationId.toString());

      if (invitationId == null ||
          invitationId.isEmpty ||
          invitationId == '999999999') {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar(
          "Invitation tidak tersedia. Silakan buat undangan terlebih dahulu.",
          Colors.orange,
        );
        return;
      }

      final parsedInvitationId = int.tryParse(invitationId);
      if (parsedInvitationId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar("Invitation ID tidak valid.", Colors.red);
        return;
      }

      if (nameController.text.isEmpty ||
          venueNameController.text.isEmpty ||
          dateController.text.isEmpty ||
          startTimeController.text.isEmpty ||
          endTimeController.text.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar(
          "Mohon lengkapi semua field yang wajib diisi.",
          Colors.orange,
        );
        return;
      }

      final response = await _authService.createEvent(
        token: token,
        invitationId: parsedInvitationId,
        name: nameController.text,
        venueName: venueNameController.text,
        venueAddress: venueAddressController.text,
        date: dateController.text,
        startTime: startTimeController.text,
        endTime: endTimeController.text,
        description: descriptionController.text,
        orderNumber: int.tryParse(orderNumberController.text) ?? 1,
      );

      if (!mounted) return;

      if (response.status == 201) {
        _showSnackBar("Acara berhasil dibuat", _currentTheme.primaryColor);
        _clearForm();
        widget.onSuccess();

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        _showSnackBar("Gagal membuat acara", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Terjadi kesalahan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: _currentTheme.fontFamily,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearForm() {
    nameController.clear();
    venueNameController.clear();
    venueAddressController.clear();
    dateController.clear();
    startTimeController.clear();
    endTimeController.clear();
    descriptionController.clear();
    orderNumberController.clear();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    venueNameController.dispose();
    venueAddressController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    descriptionController.dispose();
    orderNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while theme is loading
    if (_isThemeLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            "Tambah Acara",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: _currentTheme.fontFamily,
            ),
          ),
          backgroundColor: _currentTheme.primaryColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: _currentTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Tambah Acara",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: _currentTheme.fontFamily,
          ),
        ),
        backgroundColor: _currentTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: _currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _currentTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _currentTheme.primaryColor,
                        _currentTheme.primaryColor.withOpacity(0.8),
                      ],
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
                          Icons.event_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Buat Acara Baru",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: _currentTheme.fontFamily,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Isi detail acara dengan lengkap",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontFamily: _currentTheme.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildStyledTextField(
                  controller: nameController,
                  label: "Nama Acara",
                  hint: "Contoh: Akad Nikah, Resepsi",
                  prefixIcon: Icons.celebration,
                  isRequired: true,
                ),

                _buildStyledTextField(
                  controller: venueNameController,
                  label: "Tempat",
                  hint: "Contoh: Gedung Serbaguna",
                  prefixIcon: Icons.location_city,
                  isRequired: true,
                ),

                _buildStyledTextField(
                  controller: venueAddressController,
                  label: "Alamat",
                  hint: "Alamat lengkap tempat acara",
                  prefixIcon: Icons.map,
                ),

                _buildStyledTextField(
                  controller: dateController,
                  label: "Tanggal",
                  hint: "Pilih tanggal acara",
                  prefixIcon: Icons.calendar_month,
                  suffixIcon: Icons.arrow_drop_down,
                  isRequired: true,
                  readOnly: true,
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: _currentTheme.primaryColor,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selectedDate != null) {
                      dateController.text =
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildStyledTextField(
                        controller: startTimeController,
                        label: "Jam Mulai",
                        hint: "Mulai",
                        prefixIcon: Icons.access_time,
                        isRequired: true,
                        readOnly: true,
                        onTap: () async {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: _currentTheme.primaryColor,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selectedTime != null) {
                            startTimeController.text =
                                "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStyledTextField(
                        controller: endTimeController,
                        label: "Jam Selesai",
                        hint: "Selesai",
                        prefixIcon: Icons.access_time_filled,
                        isRequired: true,
                        readOnly: true,
                        onTap: () async {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 11, minute: 0),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: _currentTheme.primaryColor,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (selectedTime != null) {
                            endTimeController.text =
                                "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";
                          }
                        },
                      ),
                    ),
                  ],
                ),

                _buildStyledTextField(
                  controller: descriptionController,
                  label: "Deskripsi",
                  hint: "Deskripsi singkat tentang acara",
                  prefixIcon: Icons.description,
                  maxLines: 3,
                ),

                _buildStyledTextField(
                  controller: orderNumberController,
                  label: "Urutan",
                  hint: "Urutan acara (1, 2, 3, ...)",
                  prefixIcon: Icons.format_list_numbered,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        _currentTheme.primaryColor,
                        _currentTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _currentTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _submitEvent,
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.save_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Simpan Acara",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: _currentTheme.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Required fields note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: _currentTheme.textPrimary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "* Field wajib diisi",
                      style: TextStyle(
                        color: _currentTheme.textPrimary.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: _currentTheme.fontFamily,
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
}
