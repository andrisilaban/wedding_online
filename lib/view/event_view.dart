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

      // Perbaikan: Handle nullable invitation ID
      final invitationId = await _storageService.getInvitationID();

      // Check if invitation ID is null or empty
      if (invitationId == null || invitationId.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Invitation ID tidak tersedia. Silakan buat undangan terlebih dahulu.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validate that invitation ID is a valid number
      final parsedInvitationId = int.tryParse(invitationId);
      if (parsedInvitationId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invitation ID tidak valid."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate form fields
      if (nameController.text.isEmpty ||
          venueNameController.text.isEmpty ||
          dateController.text.isEmpty ||
          startTimeController.text.isEmpty ||
          endTimeController.text.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mohon lengkapi semua field yang wajib diisi."),
            backgroundColor: Colors.orange,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Acara berhasil dibuat"),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form after successful submission
        _clearForm();

        widget.onSuccess(); // trigger refresh di home_view

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal membuat acara"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              decoration: const InputDecoration(
                labelText: 'Nama Acara *',
                hintText: 'Contoh: Akad Nikah, Resepsi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: venueNameController,
              decoration: const InputDecoration(
                labelText: 'Tempat *',
                hintText: 'Contoh: Gedung Serbaguna',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: venueAddressController,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                hintText: 'Alamat lengkap tempat acara',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Tanggal *',
                hintText: 'Pilih tanggal acara',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (selectedDate != null) {
                  dateController.text =
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: startTimeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Jam Mulai *',
                hintText: 'Pilih jam mulai',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
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
            const SizedBox(height: 16),
            TextField(
              controller: endTimeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Jam Selesai *',
                hintText: 'Pilih jam selesai',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
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
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Deskripsi singkat tentang acara',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: orderNumberController,
              decoration: const InputDecoration(
                labelText: 'Urutan',
                hintText: 'Urutan acara (1, 2, 3, ...)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Simpan Acara",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              "* Field wajib diisi",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
