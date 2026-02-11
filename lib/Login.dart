import 'package:flutter/material.dart';
import 'package:pinjam_alat/peminjam/peminjam_alat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Home_admin.dart';
import 'petugas/home_petugas.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  static const primaryBlue = Color(0xFF4F46E5); // Indigo

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
          .maybeSingle();


      if (!mounted) return;

      if (data == null) {
        showError('Data user tidak ditemukan di database');
        setState(() => isLoading = false);
        return;
      }

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
          MaterialPageRoute(builder: (_) => const DashboardPeminjamPage()),
        );
        return;
      }
    } on AuthException catch (e) {
      // Jangan tampilkan error dulu, coba petugas login terlebih dahulu
      debugPrint('Auth failed: ${e.message}, trying petugas...');
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

      setState(() => isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePetugasPage(petugas: petugas),
        ),
      );
      return; // Berhasil login, keluar dari fungsi
    } catch (_) {
      // Petugas login gagal, tampilkan error
      if (!mounted) return;
      showError('Username atau password salah');
    } finally {
      setState(() => isLoading = false);
    }
  }



  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      // 1. Setup Google Sign In
      // MENGGUNAKAN WEB CLIENT ID (Wajib untuk running di Browser/Web)
      // Ambil dari Google Cloud Console -> Credentials -> OAuth 2.0 Client IDs -> Web client
      const webClientId = '58193235676-p042sukrt82j9p3h5flvopque8puskga.apps.googleusercontent.com';
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: webClientId, // Wajib untuk Web
      );

      // 2. Trigger Native Sign In Flow
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled
        setState(() => isLoading = false);
        return;
      }

      // 3. Get Auth Details (Tokens)
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found. Make sure Web Client ID is configured ';
      }

      // 4. Sign In to Supabase with Tokens
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 5. Check Session & Role
      final session = response.session;
      final user = response.user;

      if (user != null && mounted) {
        // Check existing role
        final userData = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (!mounted) return;

        if (userData != null) {
          final role = userData['role'];
          if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
          } else if (role == 'peminjam') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPeminjamPage()));
          }
        } else {
          // New User -> Default to 'peminjam'
          await supabase.from('users').insert({
            'id': user.id,
            'email': user.email,
            'role': 'peminjam',
          });

          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPeminjamPage()));
        }
      }

    } catch (e) {
      if (!mounted) return;
      showError('Gagal login Google: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final session = supabase.auth.currentSession;
    if (session != null && mounted) {
      // User sudah login, check role
      final user = session.user;
      
      try {
        final userData = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        
        if (!mounted) return;
        
        if (userData != null) {
          final role = userData['role'];
          
          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          } else if (role == 'peminjam') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPeminjamPage()),
            );
          }
        }
      } catch (e) {
        // Ignore error, biarkan user login manual
      }
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Divider OR
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade200,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ATAU',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade200,
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4), // Google blue
                        ),
                      ),
                    ),
                  ),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 15,
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

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
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