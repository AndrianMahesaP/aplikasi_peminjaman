import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_peminjaman.dart';

class PengembalianPetugasPage extends StatefulWidget {
  const PengembalianPetugasPage({super.key});

  @override
  State<PengembalianPetugasPage> createState() =>
      _PengembalianPetugasPageState();
}

class _PengembalianPetugasPageState extends State<PengembalianPetugasPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> activeLoans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchActiveLoans();
  }

  Future<void> fetchActiveLoans() async {
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
          .eq('status', 'disetujui') // Hanya yang sedang dipinjam
          .order('tanggal_kembali', ascending: true); // Urutkan berdasarkan tenggat waktu

      setState(() {
        activeLoans = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      debugPrint('Error fetch active loans: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        title: const Text(
          'Monitoring Pengembalian',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : activeLoans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada barang yang sedang dipinjam',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchActiveLoans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: activeLoans.length,
                    itemBuilder: (context, index) {
                      final item = activeLoans[index];
                      final user = item['users'] ?? {};
                      final email = user['email'] ?? 'Unknown';
                      final details = item['detail_peminjaman'] as List? ?? [];
                      final tanggalKembali = DateTime.parse(item['tanggal_kembali']);
                      final isOverdue = DateTime.now().isAfter(tanggalKembali);

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
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPeminjamanPage(peminjaman: item),
                              ),
                            );
                            fetchActiveLoans(); // Refresh after return
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
                                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person, color: Color(0xFF4F46E5), size: 20),
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
                                            'Dipinjam: ${item['tanggal_pinjam']}',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isOverdue)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade100),
                                        ),
                                        child: Text(
                                          'Terlambat',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Icon(Icons.event_busy, size: 16, color: Colors.orange.shade700),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tenggat: ${item['tanggal_kembali']}',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${details.length} Item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
