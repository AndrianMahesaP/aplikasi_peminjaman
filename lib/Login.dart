import 'package:flutter/material.dart';
import 'package:pinjam_alat/peminjam/peminjam_alat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Home_admin.dart';
import 'petugas/home_petugas.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isObscure = true;

  static const primaryBlue = Color(0xFF1E4ED8);

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // ===== VALIDASI =====
    if (username.isEmpty || password.isEmpty) {
      showError('Username / email dan password wajib diisi');
      return;
    }

    if (username.contains('@')) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(username)) {
        showError('Format email tidak valid');
        return;
      }
    }

    if (password.length < 3) {
      showError('Password minimal 3 karakter');
      return;
    }

    setState(() => isLoading = true);

    // ===== LOGIN ADMIN & PEMINJAM =====
    try {
      final auth = await supabase.auth.signInWithPassword(
        email: username,
        password: password,
      );

      final user = auth.user;

      if (user == null) {
        showError('Akun tidak ditemukan');
        setState(() => isLoading = false);
        return;
      }

      final data = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      if (data['role'] == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
        return;
      }

      if (data['role'] == 'peminjam') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PeminjamAlatPage()),
        );
        return;
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid')) {
        showError('Email atau password salah');
      } else {
        showError(e.message);
      }
    } catch (_) {
      // lanjut cek petugas
    }

    // ===== LOGIN PETUGAS =====
    try {
      final petugas = await supabase
          .from('petugas')
          .select()
          .eq('username', username)
          .eq('password', password)
          .single();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePetugasPage(petugas: petugas),
        ),
      );
    } catch (_) {
      showError('Username atau password salah');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 30),

              _inputField(
                controller: usernameController,
                hint: 'Username / Email',
                icon: Icons.person_outline,
                obscure: false,
              ),
              const SizedBox(height: 18),

              _inputField(
                controller: passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: isObscure,
                suffix: IconButton(
                  icon: Icon(
                    isObscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: primaryBlue,
                  ),
                  onPressed: () {
                    setState(() => isObscure = !isObscure);
                  },
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryBlue),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
