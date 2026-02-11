import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_dialog.dart';

class DetailPeminjamanPage extends StatelessWidget {
  final Map<String, dynamic> peminjaman;

  const DetailPeminjamanPage({
    super.key,
    required this.peminjaman,
  });

  @override
  Widget build(BuildContext context) {
    final details = peminjaman['detail_peminjaman'] as List? ?? [];
    final user = peminjaman['users'] ?? {'email': 'Unknown'};
    final userName = user['email']?.split('@')[0] ?? 'Unknown';
    final status = peminjaman['status'] ?? '-';
    final tanggalPinjam = peminjaman['tanggal_pinjam'] ?? '-';
    final tanggalKembali = peminjaman['tanggal_kembali'] ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      body: CustomScrollView(
        slivers: [
          // Modern AppBar without heavy gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5), // Indigo
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF4F46E5),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Text(
                            _getInitials(userName),
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernInfoCard(
                          Icons.calendar_today_rounded,
                          'Pinjam',
                          DateFormat('dd MMM yyyy').format(DateTime.parse(tanggalPinjam)),
                          const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernInfoCard(
                          Icons.event_rounded,
                          'Kembali',
                          DateFormat('dd MMM yyyy').format(DateTime.parse(tanggalKembali)),
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Daftar Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${details.length} Item',
                          style: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Item list
                  ...details.asMap().entries.map((entry) {
                    final index = entry.key;
                    final detail = entry.value;
                    final alat = detail['alat'] ?? {};

                    return TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
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
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Image
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: (alat['gambar'] != null && alat['gambar'].toString().isNotEmpty)
                                      ? Image.network(
                                          alat['gambar'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 32);
                                          },
                                        )
                                      : Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 32),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Item info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alat['nama'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Qty: ${detail['jumlah']}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF4F46E5),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
        ],
      ),

      // Actions
      bottomNavigationBar: _buildBottomAction(context, status),
    );
  }

  Widget? _buildBottomAction(BuildContext context, String status) {
    if (status == 'menunggu') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // TOMBOL TOLAK
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => tolakPeminjaman(context),
                child: const Text(
                  'TOLAK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // TOMBOL ACC
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Green
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => accPeminjaman(context),
                child: const Text(
                  'ACC',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  Future<void> tolakPeminjaman(BuildContext context) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('peminjaman')
          .update({'status': 'ditolak'})
          .eq('peminjaman_id', peminjaman['peminjaman_id']);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peminjaman telah DITOLAK.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak: $e')),
      );
    }
  }

  Future<void> accPeminjaman(BuildContext context) async {
    final supabase = Supabase.instance.client;

    try {
      // Ambil semua detail peminjaman
      final details = peminjaman['detail_peminjaman'] as List? ?? [];
      
      if (details.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada item untuk di-ACC'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validasi dan kurangi stok untuk semua item
      for (var detail in details) {
        final jumlahPinjam = detail['jumlah'] ?? 0;
        final alat = detail['alat'] ?? {};
        final alatId = alat['alat_id'];

        if (alatId == null) continue;

        // Check current stock
        final alatData = await supabase
            .from('alat')
            .select('stok, nama')
            .eq('alat_id', alatId)
            .single();

        final stokSekarang = alatData['stok'] ?? 0;
        final namaAlat = alatData['nama'] ?? 'Unknown';

        // Validate stock availability
        if (stokSekarang < jumlahPinjam) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stok "$namaAlat" tidak mencukupi! (Tersedia: $stokSekarang, Diminta: $jumlahPinjam)'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        // Reduce stock
        await supabase
            .from('alat')
            .update({'stok': stokSekarang - jumlahPinjam})
            .eq('alat_id', alatId);
      }

      // Update status to approved
      await supabase
          .from('peminjaman')
          .update({'status': 'disetujui'})
          .eq('peminjaman_id', peminjaman['peminjaman_id']);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Peminjaman berhasil disetujui (${details.length} item, stok dikurangi)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Generate PDF Struk
      try {
        final pdfBytes = await PdfService.generateStrukPeminjaman(
          peminjaman: peminjaman,
        );

        if (!context.mounted) return;

        // Show PDF preview dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PdfPreviewDialog(
            pdfBytes: pdfBytes,
            fileName: 'Struk_Peminjaman_${peminjaman['peminjaman_id']}.pdf',
          ),
        );
      } catch (e) {
        debugPrint('Error generating PDF: $e');
        // Continue even if PDF fails
      }

      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ACC: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildModernInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}