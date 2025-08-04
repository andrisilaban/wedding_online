import 'package:flutter/material.dart';
import 'package:wedding_online/services/auth_service.dart';
import 'package:wedding_online/view/login_view.dart';
import 'package:wedding_online/constants/styles.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = AuthService();
        final response = await authService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Register Berhasil: ${response.message ?? 'Register Berhasil'}',
            ),
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: screenPadding,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            child: Padding(
              padding: formCardPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Selamat Datang!', style: headingStyle),
                    const SizedBox(height: 8),
                    Text('Register untuk melanjutkan', style: subheadingStyle),
                    formTopSpacing,

                    TextFormField(
                      controller: _nameController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Name',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Name tidak boleh kosong'
                          : null,
                    ),
                    formFieldSpacing,

                    TextFormField(
                      controller: _emailController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Email tidak boleh kosong'
                          : null,
                    ),
                    formFieldSpacing,

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password minimal 6 karakter'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text('Register', style: buttonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                        );
                      },
                      child: Text(
                        "Sudah punya akun? Login di sini.",
                        style: subheadingStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
