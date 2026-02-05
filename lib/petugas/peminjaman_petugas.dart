import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_peminjaman.dart';

class PeminjamanPetugasPage extends StatefulWidget {
  const PeminjamanPetugasPage({super.key});

  @override
  State<PeminjamanPetugasPage> createState() =>
      _PeminjamanPetugasPageState();
}

class _PeminjamanPetugasPageState extends State<PeminjamanPetugasPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> peminjaman = [];
  bool loading = true;

  Future<void> loadData() async {
    final res = await supabase
        .from('peminjaman')
        .select('*, alat(nama)')
        .eq('status', 'menunggu')
        .order('tanggal_pinjam', ascending: false);

    print(res);

    setState(() {
      peminjaman = List<Map<String, dynamic>>.from(res);
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'menunggu':
        return Colors.orange;
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman Masuk'),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : peminjaman.isEmpty
              ? const Center(child: Text('Tidak ada pengajuan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: peminjaman.length,
                  itemBuilder: (c, i) {
                    final p = peminjaman[i];
                    final namaAlat = p['alat'] != null
                        ? p['alat']['nama']
                        : 'Alat tidak ditemukan';

                    return Card(
                      child: ListTile(
                        title: Text(namaAlat),
                        subtitle: Text(
                          'Status: ${p['status']}',
                          style: TextStyle(
                            color: statusColor(p['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing:
                            const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPeminjamanPage(
                                peminjaman: p,
                              ),
                            ),
                          );
                          loadData();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
