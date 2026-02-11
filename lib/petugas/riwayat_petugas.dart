import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_peminjaman.dart';

class RiwayatPetugasPage extends StatefulWidget {
  const RiwayatPetugasPage({super.key});

  @override
  State<RiwayatPetugasPage> createState() => _RiwayatPetugasPageState();
}

class _RiwayatPetugasPageState extends State<RiwayatPetugasPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> riwayatList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('peminjaman')
          .select('''
            *,
            users:user_id(email),
            detail_peminjaman(
              jumlah,
              alat:alat_id(nama, gambar)
            )
          ''')
          .inFilter('status', ['kembali', 'ditolak']) // Ambil status selesai
          .order('created_at', ascending: false);

      setState(() {
        riwayatList = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      debugPrint('Error fetch riwayat: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : riwayatList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat transaksi',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: riwayatList.length,
                  itemBuilder: (context, index) {
                    final item = riwayatList[index];
                    final user = item['users'] ?? {};
                    final email = user['email'] ?? 'Unknown';
                    final status = item['status'];
                    final details = item['detail_peminjaman'] as List? ?? [];
                    
                    // Determine Color based on status
                    final isReturned = status == 'kembali';
                    final statusColor = isReturned ? Colors.green : Colors.red;
                    final statusText = isReturned ? 'Selesai (Kembali)' : 'Ditolak';
                    final statusIcon = isReturned ? Icons.check_circle_outline : Icons.cancel_outlined;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPeminjamanPage(peminjaman: item),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(statusIcon, color: statusColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          email,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          item['tanggal_pinjam'] ?? '-',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                '${details.length} Item Peminjaman',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
