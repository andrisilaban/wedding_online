import 'package:flutter/material.dart';
import 'package:wedding_online/constants/styles.dart';
import 'package:wedding_online/services/auth_service.dart';
import 'package:wedding_online/view/home_view.dart';
import 'package:wedding_online/view/register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  String tempToken = 'kosong';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = AuthService();
        final response = await authService.login(
          _usernameController.text,
          _passwordController.text,
        );
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login Berhasil: ${response.data?.user?.name ?? 'Anda Berhasil Login'}',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeView()),
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
                    Text('Login untuk melanjutkan', style: subheadingStyle),
                    formTopSpacing,

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Username tidak boleh kosong'
                          : null,
                    ),
                    formFieldSpacing,

                    // Password
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
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Password minimal 6 karakter'
                          : null,
                    ),
                    formTopSpacing,

                    // Login Button
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
                            : Text('Login', style: buttonTextStyle),
                      ),
                    ),
                    formFieldSpacing,

                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur belum tersedia')),
                        );
                      },
                      child: Text(
                        'Lupa password?',
                        style: TextStyle(color: themeColor),
                      ),
                    ),
                    formFieldSpacing,
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterView(),
                          ),
                        );
                      },
                      child: const Text("Belum punya akun? Daftar di sini."),
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
