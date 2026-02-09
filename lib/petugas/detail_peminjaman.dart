import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPeminjamanPage extends StatelessWidget {
  final Map<String, dynamic> peminjaman;

  const DetailPeminjamanPage({
    super.key,
    required this.peminjaman,
  });

  @override
  Widget build(BuildContext context) {
    final namaAlat = peminjaman['alat'] != null
        ? peminjaman['alat']['nama'] ?? '-'
        : '-';

    final status = peminjaman['status'] ?? '-';
    final tanggal = peminjaman['tanggal_pinjam'] ?? '-';
    final keterangan = peminjaman['keterangan'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Peminjaman'),
        backgroundColor: Colors.blue,
      ),

      bottomNavigationBar: status == 'menunggu'
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => accPeminjaman(context),
                child: const Text(
                  'ACC PEMINJAMAN',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _item('Nama Alat', namaAlat),
            _item('Status', status),
            _item('Tanggal Pinjam', tanggal),
            _item('Keterangan', keterangan),
          ],
        ),
      ),
    );
  }

  // ================= ACC =================
  Future<void> accPeminjaman(BuildContext context) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from('peminjaman')
          .update({'status': 'disetujui'})
          .eq('peminjaman_id', peminjaman['peminjaman_id']);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil disetujui')),
      );

      Navigator.pop(context, true); // ⬅️ penting buat refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ACC: $e')),
      );
    }
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
