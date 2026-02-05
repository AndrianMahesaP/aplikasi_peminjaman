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
        const SnackBar(content: Text('Data belum lengkap')),
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
        SnackBar(content: Text('Gagal simpan: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petugas == null
            ? 'Tambah Petugas'
            : 'Edit Petugas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(namaController, 'Nama Petugas'),
            _input(usernameController, 'Username'),

            if (widget.petugas == null)
              _input(passwordController, 'Password'),

            DropdownButtonFormField<String>(
              value: role,
              items: roleList
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => role = v!),
              decoration: InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : simpan,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SIMPAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        obscureText: hint.toLowerCase().contains('password'),
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
