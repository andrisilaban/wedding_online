import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CountdownTimer extends StatefulWidget {
  final String? eventDate; // ubah jadi String

  const CountdownTimer({super.key, this.eventDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late DateTime eventDate;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
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
  Widget build(BuildContext context) {
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
          onPressed: () {},
          icon: const Icon(Icons.calendar_today),
          label: const Text("Save to Calendar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
