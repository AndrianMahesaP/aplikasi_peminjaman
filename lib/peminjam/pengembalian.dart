import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

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
          .select('*, alat:alat_id(*)') // Join ke tabel alat
          .eq('user_id', userId)
          .eq('status', 'dipinjam') // Filter WAJIB
          .order('tanggal_pinjam');

      setState(() {
        pinjaman = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error fetch: $e');
      setState(() => loading = false);
    }
  }

  Future<void> prosesKembali(int pinjamId, int alatId, int currentStok) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kembalikan Alat?'),
        content: const Text('Pastikan alat sudah dikembalikan dalam kondisi baik.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: greenColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Kembalikan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('peminjaman').update({
          'status': 'selesai',
          'tanggal_kembali': DateTime.now().toIso8601String(),
        }).eq('pinjam_id', pinjamId);

        await supabase.from('alat').update({
          'stok': currentStok + 1
        }).eq('id', alatId); 
       

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alat berhasil dikembalikan!')),
          );
          fetchDipinjam(); // Refresh list
        }
      } catch (e) {
        debugPrint('Error return: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengembalikan: $e')),
          );
        }
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
                        'Dipinjam tgl: ${item['tanggal_pinjam']?.substring(0, 10)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Status: Sedang Dipinjam',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Tombol Aksi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // Panggil fungsi kembalikan
                  prosesKembali(
                    item['pinjam_id'], 
                    alat['id'], // Pastikan nama kolom ID alat benar
                    alat['stok'] ?? 0
                  );
                },
                icon: const Icon(Icons.assignment_return, size: 18),
                label: const Text('KEMBALIKAN BARANG'),
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