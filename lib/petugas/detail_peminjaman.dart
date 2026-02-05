import 'package:flutter/material.dart';

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
