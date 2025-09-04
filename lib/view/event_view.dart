import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class EventView extends StatefulWidget {
  final VoidCallback onSuccess;

  const EventView({super.key, required this.onSuccess});

  @override
  _EventViewState createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

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
      if (!mounted) return;
      setState(() => _isLoading = false);

      final invitationId = await _storageService.getInvitationID();

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

      if (response.status == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Acara berhasil dibuat")));
        widget.onSuccess(); // trigger refresh di home_view
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal membuat acara")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
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
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Acara")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Acara'),
            ),
            TextField(
              controller: venueNameController,
              decoration: const InputDecoration(labelText: 'Tempat'),
            ),
            TextField(
              controller: venueAddressController,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Tanggal'),
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (selectedDate != null) {
                  dateController.text =
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                }
              },
            ),
            TextField(
              controller: startTimeController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Jam Mulai'),
              onTap: () async {
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                );
                if (selectedTime != null) {
                  startTimeController.text =
                      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";
                }
              },
            ),
            TextField(
              controller: endTimeController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Jam Selesai'),
              onTap: () async {
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 11, minute: 0),
                );
                if (selectedTime != null) {
                  endTimeController.text =
                      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";
                }
              },
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: orderNumberController,
              decoration: const InputDecoration(labelText: 'Urutan'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitEvent,
                    child: const Text("Simpan"),
                  ),
          ],
        ),
      ),
    );
  }
}
