import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wedding_online/models/theme_model.dart';
import 'package:wedding_online/services/theme_service.dart';

class CountdownTimer extends StatefulWidget {
  final String? eventDate;
  final WeddingTheme?
  currentTheme; // Tambahkan parameter untuk menerima theme dari parent

  const CountdownTimer({
    super.key,
    this.eventDate,
    this.currentTheme, // Tambahkan parameter ini
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  WeddingTheme _currentTheme = ThemeService.availableThemes.first;
  final ThemeService _themeService = ThemeService();
  bool _isThemeLoading = true;

  late Timer _timer;
  late DateTime eventDate;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    _initializeTheme();
  }

  // Pisahkan inisialisasi theme
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
      debugPrint('Error loading theme in CountdownTimer: $e');
      if (mounted) {
        setState(() {
          _currentTheme = ThemeService.availableThemes.first;
          _isThemeLoading = false;
        });
      }
    }
  }

  void _initializeTimer() {
    try {
      // Parse string ke DateTime, default ke 1 Okt 2025 jika null/invalid
      eventDate = widget.eventDate != null
          ? DateTime.parse(widget.eventDate!) // format: "2025-12-15"
          : DateTime(2025, 10, 1, 10, 0, 0);
    } catch (e) {
      // kalau parsing gagal, fallback ke default
      eventDate = DateTime(2025, 10, 1, 10, 0, 0);
    }

    _updateRemainingTime();
    _startTimer();
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = eventDate.difference(DateTime.now());
      if (_remainingTime.isNegative) {
        _remainingTime = Duration.zero;
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
      if (_remainingTime == Duration.zero) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika eventDate berubah, reinitialize timer
    if (widget.eventDate != oldWidget.eventDate) {
      debugPrint(
        'EventDate changed from ${oldWidget.eventDate} to ${widget.eventDate}',
      );
      _initializeTimer();
    }

    // PERBAIKAN UTAMA: Update theme ketika theme dari parent berubah
    if (widget.currentTheme != oldWidget.currentTheme &&
        widget.currentTheme != null) {
      debugPrint(
        'Theme changed in CountdownTimer: ${widget.currentTheme!.name}',
      );
      setState(() {
        _currentTheme = widget.currentTheme!;
        _isThemeLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while theme is loading
    if (_isThemeLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    int days = _remainingTime.inDays;
    int hours = _remainingTime.inHours % 24;
    int minutes = _remainingTime.inMinutes % 60;
    int seconds = _remainingTime.inSeconds % 60;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeBox(days, "Hari"),
            const SizedBox(width: 10),
            _buildTimeBox(hours, "Jam"),
            const SizedBox(width: 10),
            _buildTimeBox(minutes, "Menit"),
            const SizedBox(width: 10),
            _buildTimeBox(seconds, "Detik"),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            // Add calendar functionality here if needed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Fitur Save to Calendar akan segera hadir!',
                ),
                backgroundColor: _currentTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text("Save to Calendar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 5,
            shadowColor: _currentTheme.primaryColor.withOpacity(0.3),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: _currentTheme.fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBox(int value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            // Gunakan warna dari theme yang aktif
            color: _currentTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _currentTheme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _currentTheme.primaryColor.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: _currentTheme.primaryColor,
              fontFamily: _currentTheme.fontFamily,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500,
            color: _currentTheme.primaryColor,
            fontFamily: _currentTheme.fontFamily,
          ),
        ),
      ],
    );
  }
}
