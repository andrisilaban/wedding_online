import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class InvitationView extends StatefulWidget {
  const InvitationView({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<InvitationView> createState() => _InvitationViewState();
}

class _InvitationViewState extends State<InvitationView> {
  final groomFullNameController = TextEditingController();
  final groomNickNameController = TextEditingController();
  final groomFatherNameController = TextEditingController();
  final groomMotherNameController = TextEditingController();
  final brideFullNameController = TextEditingController();
  final brideNickNameController = TextEditingController();
  final brideFatherNameController = TextEditingController();
  final brideMotherNameController = TextEditingController();

  bool _loading = false;

  Future<void> _submitInvitation() async {
    setState(() => _loading = true);

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

      await authService.createInvitation(token, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Undangan berhasil dibuat!')),
        );
      }

      widget.onSuccess(); // refresh daftar undangan di HomeView
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat undangan: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Data Diri",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: groomFullNameController,
            decoration: const InputDecoration(labelText: 'Nama Pria'),
          ),
          TextField(
            controller: groomNickNameController,
            decoration: const InputDecoration(labelText: 'Nama Singkatan Pria'),
          ),
          TextField(
            controller: groomFatherNameController,
            decoration: const InputDecoration(labelText: 'Nama Bapak Pria'),
          ),
          TextField(
            controller: groomMotherNameController,
            decoration: const InputDecoration(labelText: 'Nama Ibu Pria'),
          ),
          TextField(
            controller: brideFullNameController,
            decoration: const InputDecoration(labelText: 'Nama Wanita'),
          ),
          TextField(
            controller: brideNickNameController,
            decoration: const InputDecoration(
              labelText: 'Nama Singkatan Wanita',
            ),
          ),
          TextField(
            controller: brideFatherNameController,
            decoration: const InputDecoration(labelText: 'Nama Bapak Wanita'),
          ),
          TextField(
            controller: brideMotherNameController,
            decoration: const InputDecoration(labelText: 'Nama Ibu Wanita'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _resetForm,
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitInvitation,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Kirim"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
