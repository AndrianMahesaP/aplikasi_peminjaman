import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AjukanPeminjamanPage extends StatefulWidget {
  final dynamic alat;
  const AjukanPeminjamanPage({super.key, required this.alat});

  @override
  State<AjukanPeminjamanPage> createState() => _AjukanPeminjamanPageState();
}

class _AjukanPeminjamanPageState extends State<AjukanPeminjamanPage> {
  final supabase = Supabase.instance.client;
  DateTime? tglPinjam;
  DateTime? tglKembali;
  bool loading = false;

  Future<void> simpanPeminjaman() async {
  final user = supabase.auth.currentUser;
  if (user == null || tglPinjam == null || tglKembali == null) return;

  setState(() => loading = true);

  try {
    await supabase.from('peminjaman').insert({
      'user_id': user.id,
      'alat_id': widget.alat['alat_id'],
      'tanggal_pinjam': DateFormat('yyyy-MM-dd').format(tglPinjam!),
'tanggal_kembali': DateFormat('yyyy-MM-dd').format(tglKembali!),

      'status': 'menunggu',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peminjaman berhasil diajukan')),
    );
    Navigator.pop(context);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal: $e')),
    );
  } finally {
    if (mounted) setState(() => loading = false);
  }
}

  Future<void> pilihTanggal(bool pinjam) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        pinjam ? tglPinjam = date : tglKembali = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Peminjaman')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alat: ${widget.alat['nama']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            ListTile(
              title: Text(tglPinjam == null
                  ? 'Pilih Tanggal Pinjam'
                  : DateFormat('dd MMM yyyy').format(tglPinjam!)),
              trailing: const Icon(Icons.date_range),
              onTap: () => pilihTanggal(true),
            ),
            ListTile(
              title: Text(tglKembali == null
                  ? 'Pilih Tanggal Kembali'
                  : DateFormat('dd MMM yyyy').format(tglKembali!)),
              trailing: const Icon(Icons.date_range),
              onTap: () => pilihTanggal(false),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : simpanPeminjaman,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajukan Peminjaman'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
