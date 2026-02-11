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
  String? namaKategoriReal; // Untuk menyimpan nama kategori asli dari DB
  int jumlahPinjam = 1;

  @override
  void initState() {
    super.initState();
    _ambilDataKategori();
  }

 Future<void> _ambilDataKategori() async {
  try {
    // Gunakan sintaks join tabel yang paling stabil
    final res = await supabase
        .from('alat')
        .select('nama, kategori :kategori (nama)') 
        .eq('alat_id', widget.alat['alat_id'])
        .single();

    if (res['kategori'] != null) {
      setState(() {
        namaKategoriReal = res['kategori']['nama'].toString();
      });
    }
  } catch (e) {
    debugPrint('Error detail: $e');
    setState(() {
      namaKategoriReal = 'Kategori Tidak Ditemukan';
    });
  }
}



  Future<void> simpanPeminjaman() async {
    final user = supabase.auth.currentUser;
    if (user == null || tglPinjam == null || tglKembali == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi tanggal terlebih dahulu!')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 1. Insert Peminjaman
      final peminjaman = await supabase.from('peminjaman').insert({
        'user_id': user.id,
        'alat_id': widget.alat['alat_id'],
        'tanggal_pinjam': DateFormat('yyyy-MM-dd').format(tglPinjam!),
        'tanggal_kembali': DateFormat('yyyy-MM-dd').format(tglKembali!),
        'status': 'menunggu',
      }).select().single();

      // 2. Insert Detail Peminjaman (Data Nama & Kategori Paten)
      await supabase.from('detail_peminjaman').insert({
        'peminjaman_id': peminjaman['peminjaman_id'],
        'alat_id': widget.alat['alat_id'],
        'jumlah': jumlahPinjam,
        'nama_alat': widget.alat['nama'] ?? 'Alat',
        'nama_kategori': namaKategoriReal ?? '',
      });

      // Note: Stok akan dikurangi saat petugas ACC peminjaman, bukan di sini

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil diajukan!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Peminjaman',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Details Card - White Style
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool Image
                  if (widget.alat['gambar'] != null && widget.alat['gambar'].toString().isNotEmpty)
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade100,
                          image: DecorationImage(
                            image: NetworkImage(widget.alat['gambar']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.build, color: Color(0xFF4F46E5), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.alat['nama'] ?? '-',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Detail Alat',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          namaKategoriReal ?? 'Memuat kategori...',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quantity Selector
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.numbers, color: Color(0xFF4F46E5), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Jumlah Pinjam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() { if(jumlahPinjam > 1) jumlahPinjam--; }),
                          icon: const Icon(Icons.remove, color: Colors.red),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$jumlahPinjam',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => jumlahPinjam++),
                          icon: const Icon(Icons.add, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Date Pickers
            _buildModernDateTile(
              'Tanggal Mulai Pinjam',
              tglPinjam,
              Icons.event,
              (d) => setState(() => tglPinjam = d),
            ),
            const SizedBox(height: 12),
            _buildModernDateTile(
              'Tanggal Pengembalian',
              tglKembali,
              Icons.event_available,
              (d) => setState(() => tglKembali = d),
            ),
            
            const SizedBox(height: 32),
            
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : simpanPeminjaman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'KONFIRMASI PINJAM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDateTile(
    String label,
    DateTime? date,
    IconData icon,
    Function(DateTime) onPick,
  ) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF4F46E5),
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: date != null ? const Color(0xFF4F46E5) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF4F46E5), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null
                        ? 'Pilih tanggal'
                        : DateFormat('dd MMMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: date != null ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}