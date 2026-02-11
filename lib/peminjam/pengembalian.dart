import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengembalianPage extends StatefulWidget {
  final String peminjamanId;

  const PengembalianPage({
    super.key,
    required this.peminjamanId,
  });

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}



  @override
  State<PengembalianPage> createState() => _PengembalianPageState();


class _PengembalianPageState extends State<PengembalianPage> {
  final supabase = Supabase.instance.client;
  List pinjaman = [];
  bool loading = true;

  // Warna Tema (Konsisten)
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color greenColor = const Color(0xFF10B981);
  final Color bgColor = const Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    fetchDipinjam();
  }

  Future<void> fetchDipinjam() async {
    setState(() => loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('peminjaman')
          .select('''
            *,
            alat:alat_id(*),
            detail_peminjaman!inner(jumlah)
          ''')
          .eq('peminjaman_id', widget.peminjamanId)
          .eq('status', 'disetujui')
          .single();

      setState(() {
        pinjaman = [data];
        loading = false;
      });
    } catch (e) {
      debugPrint('Error fetch: $e');
      setState(() => loading = false);
    }
  }

  Future<void> prosesKembali(
    String pinjamId,
    String alatId,
    int currentStok,
    String tanggalKembali,
    int dendaPerHari,
    int jumlahPinjam,
  ) async {
    try {
      // Calculate penalty if late
      final today = DateTime.now();
      final returnDate = DateTime.parse(tanggalKembali);
      final daysLate = today.difference(returnDate).inDays;
      final totalDenda = daysLate > 0 ? (daysLate * dendaPerHari * jumlahPinjam) : 0;

      // 1. update status peminjaman
      await supabase.from('peminjaman').update({
        'status': 'selesai',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('peminjaman_id', pinjamId);

      // 2. insert ke tabel pengembalian with calculated penalty
      await supabase.from('pengembalian').insert({
        'peminjaman_id': pinjamId,
        'tgl_dikembalikan': DateTime.now().toIso8601String(),
        'denda': totalDenda,
      });

      // 3. kembalikan stok alat
      await supabase.from('alat').update({
        'stok': currentStok + jumlahPinjam,
      }).eq('alat_id', alatId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              totalDenda > 0
                  ? 'Dikembalikan dengan denda Rp ${totalDenda.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
                  : 'Barang berhasil dikembalikan tepat waktu!',
            ),
            backgroundColor: totalDenda > 0 ? Colors.orange : Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error pengembalian: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengembalikan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Pengembalian Alat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : pinjaman.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pinjaman.length,
                  itemBuilder: (context, index) {
                    final item = pinjaman[index];
                    final alat = item['alat'] ?? {};
                    
                    return _buildReturnCard(item, alat);
                  },
                ),
    );
  }

  Widget _buildReturnCard(Map item, Map alat) {
    final tanggalKembali = item['tanggal_kembali'] ?? '';
    final tanggalPinjam = item['tanggal_pinjam'] ?? '';
    final dendaPerHari = alat['denda'] ?? 0;
    final jumlahPinjam = (item['detail_peminjaman'] is List && (item['detail_peminjaman'] as List).isNotEmpty)
        ? (item['detail_peminjaman'][0]['jumlah'] ?? 1)
        : 1;
    
    // Calculate if late
    final today = DateTime.now();
    final returnDate = tanggalKembali.isNotEmpty ? DateTime.parse(tanggalKembali) : today;
    final daysLate = today.difference(returnDate).inDays;
    final isLate = daysLate > 0;
    final totalDenda = isLate ? (daysLate * dendaPerHari * jumlahPinjam) : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLate ? Border.all(color: Colors.red.shade200, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isLate ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: alat['gambar'] != null
                        ? DecorationImage(
                            image: NetworkImage(alat['gambar']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: alat['gambar'] == null
                      ? Icon(Icons.build, color: primaryColor)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Detail Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alat['nama'] ?? 'Alat Tidak Dikenal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jumlah: $jumlahPinjam unit',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dipinjam: ${tanggalPinjam.substring(0, 10)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      Text(
                        'Harus kembali: ${tanggalKembali.substring(0, 10)}',
                        style: TextStyle(
                          color: isLate ? Colors.red : Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: isLate ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Late warning
            if (isLate) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TERLAMBAT $daysLate HARI',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Denda: Rp ${totalDenda.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Rp $dendaPerHari/hari × $daysLate hari × $jumlahPinjam unit',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Masih dalam waktu / tepat waktu - Tidak ada denda',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Divider(height: 24),
            
            // Tombol Aksi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLate ? Colors.orange : primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(isLate ? 'Konfirmasi Pengembalian + Denda' : 'Konfirmasi Pengembalian'),
                      content: Text(
                        isLate
                            ? 'Anda akan mengembalikan barang dengan denda Rp ${totalDenda.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} karena terlambat $daysLate hari.'
                            : 'Anda akan mengembalikan barang tepat waktu tanpa denda.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLate ? Colors.orange : primaryColor,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            prosesKembali(
                              item['peminjaman_id'],
                              alat['alat_id'],
                              alat['stok'] ?? 0,
                              tanggalKembali,
                              dendaPerHari,
                              jumlahPinjam,
                            );
                          },
                          child: const Text('Ya, Kembalikan'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_return, size: 18),
                label: Text(isLate ? 'KEMBALIKAN + BAYAR DENDA' : 'KEMBALIKAN BARANG'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
          const SizedBox(height: 16),
          Text(
            'Tidak ada barang yang dipinjam',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua aman terkendali!',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}