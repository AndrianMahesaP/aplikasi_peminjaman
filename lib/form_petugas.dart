import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetugasFormPage extends StatefulWidget {
  final dynamic petugas;
  const PetugasFormPage({super.key, this.petugas});

  @override
  State<PetugasFormPage> createState() => _PetugasFormPageState();
}

class _PetugasFormPageState extends State<PetugasFormPage> {
  final supabase = Supabase.instance.client;

  final namaController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String role = 'Petugas';
  bool loading = false;
  final roleList = ['Admin', 'Petugas'];

  @override
  void initState() {
    super.initState();
    if (widget.petugas != null) {
      namaController.text = widget.petugas['nama'];
      usernameController.text = widget.petugas['username'];
      role = widget.petugas['role'];
    }
  }

  Future<void> simpan() async {
    if (namaController.text.isEmpty ||
        usernameController.text.isEmpty ||
        (widget.petugas == null && passwordController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    try {
      setState(() => loading = true);

      final data = {
        'nama': namaController.text,
        'username': usernameController.text,
        'role': role,
      };

      if (widget.petugas == null) {
        data['password'] = passwordController.text;
        await supabase.from('petugas').insert(data);
      } else {
        await supabase
            .from('petugas')
            .update(data)
            .eq('petugas_id', widget.petugas['petugas_id']);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        title: Text(widget.petugas == null ? 'Tambah Petugas' : 'Edit Petugas',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Akun',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _input(namaController, 'Nama Lengkap', Icons.person_outline),
                  _input(usernameController, 'Username', Icons.alternate_email),
                  
                  if (widget.petugas == null)
                    _input(passwordController, 'Password', Icons.lock_outline, obscure: true),

                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: roleList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => role = v!),
                    decoration: InputDecoration(
                      labelText: 'Role Akses',
                      prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5), // Indigo
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: loading ? null : simpan,
                      child: loading
                          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                          : const Text(
                              'SIMPAN DATA',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
        ),
      ),
    );
  }
}