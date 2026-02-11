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
  List<Map<String, dynamic>> groupedPeminjaman = [];
  bool loading = true;
  String? errorMessage;

  Future<void> loadData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    
    try {
      // Query dengan struktur yang benar
      final res = await supabase
          .from('peminjaman')
          .select('''
            peminjaman_id,
            status,
            tanggal_pinjam,
            tanggal_kembali,
            created_at,
            users:user_id(email),
            detail_peminjaman(
              id,
              jumlah,
              alat:alat_id(nama, gambar)
            )
          ''')
          .eq('status', 'menunggu')
          .order('created_at', ascending: false);

      print('Response: $res'); // Debug

      setState(() {
        groupedPeminjaman = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      print('Error loading peminjaman: $e');
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        title: const Text(
          'Peminjaman Masuk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error memuat data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : groupedPeminjaman.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada pengajuan',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: groupedPeminjaman.length,
                        itemBuilder: (c, i) {
                          final p = groupedPeminjaman[i];
                          final details = p['detail_peminjaman'] as List? ?? [];
                          final user = p['users'] ?? {'email': 'Unknown'};
                          final userName = user['email']?.split('@')[0] ?? 'Unknown';

                          return InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailPeminjamanPage(
                                    peminjaman: p,
                                  ),
                                ),
                              );
                              if (result == true) loadData();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
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
                              child: Column(
                                children: [
                                  // Header
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                          child: Text(
                                            _getInitials(userName),
                                            style: const TextStyle(
                                              color: Color(0xFF4F46E5),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user['email'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange.shade100),
                                          ),
                                          child: Text(
                                            'Menunggu',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: Colors.grey.shade100),
                                  
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Item count & date info
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildInfoCard(
                                                Icons.inventory_2_outlined,
                                                '${details.length} Item',
                                                const Color(0xFF4F46E5), // Indigo
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildInfoCard(
                                                Icons.calendar_today_outlined,
                                                p['tanggal_pinjam'] ?? '-',
                                                Colors.teal,
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (details.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          ...details.take(2).map((detail) {
                                            final alat = detail['alat'] ?? {};
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(8),
                                                      image: alat['gambar'] != null && alat['gambar'] != ''
                                                          ? DecorationImage(
                                                              image: NetworkImage(alat['gambar']),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : null,
                                                      border: Border.all(color: Colors.grey.shade200),
                                                    ),
                                                    child: alat['gambar'] == null || alat['gambar'] == ''
                                                        ? Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 20)
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      alat['nama'] ?? 'Unknown',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    'x${detail['jumlah']}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),

                                          if (details.length > 2)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                '+${details.length - 2} item lainnya',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
