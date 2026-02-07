import 'package:flutter/material.dart';
import 'package:pinjam_alat/Login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengaturanPeminjamPage extends StatelessWidget {
  const PengaturanPeminjamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    Future<void> logout() async {
      await supabase.auth.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Role'),
              subtitle: Text('Peminjam'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }
}
