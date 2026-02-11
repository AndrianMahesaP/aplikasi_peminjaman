import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pinjam_alat/peminjam/pengembalian.dart';
import 'package:pinjam_alat/services/pdf_service.dart';
import 'package:pinjam_alat/widgets/pdf_preview_dialog.dart';


class StatusPeminjamanPage extends StatefulWidget {
  const StatusPeminjamanPage({super.key});

  @override
  State<StatusPeminjamanPage> createState() => _StatusPeminjamanPageState();
}

class _StatusPeminjamanPageState extends State<StatusPeminjamanPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List statusData = [];
  List aktivitasData = [];
  bool loading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

   final statusResult = await supabase
    .from('detail_peminjaman')
    .select('''
      id,
      jumlah,
      peminjaman:peminjaman_id!inner (
        peminjaman_id,
        status,
        user_id
      ),
      alat:alat_id (
        nama_alat,
        nama_kategori
      )
    ''')
    .eq('user_id', user.id)
    .neq('peminjaman.status', 'disetujui')
    .order('created_at', ascending: false);


   final aktivitasResult = await supabase
    .from('peminjaman')
    .select('''
      peminjaman_id,
      status,
      tanggal_pinjam,
      tanggal_kembali,
      users:user_id (email),
      detail_peminjaman (
        id,
        jumlah,
        alat:alat_id (
          nama_alat,
          nama_kategori
        )
      )
    ''')
    .eq('user_id', user.id)
    .eq('status', 'disetujui')
    .order('created_at', ascending: false);



    setState(() {
      statusData = statusResult;
      aktivitasData = aktivitasResult;
      loading = false;
    });
  }

  Widget _buildList(List data, {bool isAktivitas = false}) {
    if (data.isEmpty) {
      return const Center(child: Text('Data kosong'));
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          
          // Handle different data structure untuk aktivitas vs status
          String namaAlat;
          String status;
          String peminjamanId;
          
          if (isAktivitas) {
            // Data dari tabel peminjaman
            final details = item['detail_peminjaman'] as List? ?? [];
            namaAlat = details.isNotEmpty && details[0]['alat'] != null
                ? details[0]['alat']['nama_alat'] ?? '-'
                : '-';
            status = item['status'] ?? '-';
            peminjamanId = item['peminjaman_id'] ?? '';
            
            // Tampilkan semua item jika lebih dari 1
            if (details.length > 1) {
              namaAlat = '$namaAlat (+${details.length - 1} item lainnya)';
            }
          } else {
            // Data dari detail_peminjaman
            namaAlat = item['alat']?['nama_alat'] ?? '-';
            status = item['peminjaman']?['status'] ?? '-';
            peminjamanId = item['peminjaman']?['peminjaman_id'] ?? '';
          }

          return Card(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: ListTile(
    title: Text(namaAlat),
    subtitle: Text('Status: $status'),

    trailing: isAktivitas
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.blue),
                tooltip: 'Lihat Struk',
                onPressed: () async {
                  try {
                    // Generate PDF Struk
                    final pdfBytes = await PdfService.generateStrukPeminjaman(
                      peminjaman: item,
                    );

                    if (!context.mounted) return;

                    // Show PDF preview dialog
                    await showDialog(
                      context: context,
                      builder: (_) => PdfPreviewDialog(
                        pdfBytes: pdfBytes,
                        fileName: 'Struk_Peminjaman_${peminjamanId}.pdf',
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal generate struk: $e')),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PengembalianPage(
                        peminjamanId: peminjamanId,
                      ),
                    ),
                  ).then((_) => fetchData());
                },
                child: const Text(
                  'Kembalikan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          )
        : const Icon(Icons.hourglass_top, color: Colors.orange),
  ),
);

        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('peminjaman'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Status'),
            Tab(text: 'Aktivitas'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(statusData),
                _buildList(aktivitasData, isAktivitas: true),
              ],
            ),
    );
  }
}