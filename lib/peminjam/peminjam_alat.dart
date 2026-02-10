import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ajukan_peminjaman.dart';
import 'pengaturan.dart';

class DashboardPeminjamPage extends StatefulWidget {
  const DashboardPeminjamPage({super.key});

  @override
  State<DashboardPeminjamPage> createState() => _DashboardPeminjamPageState();
}

class _DashboardPeminjamPageState extends State<DashboardPeminjamPage> {
  int _currentIndex = 0;

  // List Halaman untuk Bottom Navbar
  final List<Widget> _pages = [
    const HomeAlatView(),      // Halaman Daftar Alat
    const AktivitasView(),     // Halaman Peminjaman/Pengembalian/Riwayat
    const PengaturanPeminjamPage(), // Halaman Pengaturan (Imported)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4F46E5), // Indigo
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu),
              label: 'Aktivitas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeAlatView extends StatefulWidget {
  const HomeAlatView({super.key});

  @override
  State<HomeAlatView> createState() => _HomeAlatViewState();
}

class _HomeAlatViewState extends State<HomeAlatView> {
  final supabase = Supabase.instance.client;
  List alat = [];
  bool loading = true;
  String keyword = '';

  // Warna Tema
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color bgColor = const Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    fetchAlat();
  }

  Future<void> fetchAlat() async {
    setState(() => loading = true);
    try {
      var query = supabase.from('alat').select().gt('stok', 0); // Hanya stok > 0
      
      if (keyword.isNotEmpty) {
        query = query.ilike('nama', '%$keyword%');
      }

      final res = await query.order('nama');
      setState(() {
        alat = res;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error fetch: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Pinjam Alat',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              onChanged: (v) {
                keyword = v;
                fetchAlat();
              },
              decoration: InputDecoration(
                hintText: 'Cari alat yang tersedia...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // List Alat
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : alat.isEmpty
                    ? Center(child: Text('Tidak ada alat tersedia', style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: alat.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final item = alat[i];
                          return _buildAlatCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlatCard(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Gambar Placeholder
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              image: item['gambar'] != null && item['gambar'].toString().isNotEmpty
                  ? DecorationImage(image: NetworkImage(item['gambar']), fit: BoxFit.cover)
                  : null,
            ),
            child: item['gambar'] == null || item['gambar'].toString().isEmpty
                ? const Icon(Icons.handyman, color: Colors.indigo)
                : null,
          ),
          const SizedBox(width: 14),
          
          // Info Alat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Tersedia: ${item['stok']}',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(70, 40), 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AjukanPeminjamanPage(alat: item),
                ),
              ).then((_) {
                 // Refresh list saat kembali (agar stok update)
                 fetchAlat(); 
              });
            },
            child: const Text(
              'Pinjam',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AktivitasView extends StatelessWidget {
  const AktivitasView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('Aktivitas Saya', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF4F46E5),
            tabs: [
              Tab(text: 'Berjalan'), // Peminjaman & Pengembalian
              Tab(text: 'Riwayat'), // Selesai
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StatusList(statusFilter: ['menunggu', 'disetujui']), // Sesuaikan status DB
            StatusList(statusFilter: ['selesai', 'ditolak']),
          ],
        ),
      ),
    );
  }
}

// Widget List Transaksi (Bisa dipakai ulang)
class StatusList extends StatefulWidget {
  final List<String> statusFilter;
  const StatusList({super.key, required this.statusFilter});

  @override
  State<StatusList> createState() => _StatusListState();
}

class _StatusListState extends State<StatusList> {
  final supabase = Supabase.instance.client;
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final res = await supabase
    .from('peminjaman')
    .select('''
      peminjaman_id,
      status,
      tanggal_pinjam,
      alat:alat_id (
        alat_id,
        nama,
        gambar
      )
    ''')
    .eq('user_id', userId)
    .inFilter('status', widget.statusFilter)
    .order('created_at', ascending: false);


      if (mounted) {
        setState(() {
          data = res;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error history: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _accOlehPetugas(String pinjamId, String alatId, int stokSaatIni) async {
    try {
      if (stokSaatIni <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok habis! Tidak bisa ACC.')));
        return;
      }
      
      // Update Status jadi 'dipinjam' & Kurangi Stok
      await supabase.from('peminjaman').update({'status': 'dipinjam'}).eq('peminjaman_id', pinjamId);
      await supabase.from('alat').update({'stok': stokSaatIni - 1}).eq('alat_id', alatId);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ACC Berhasil. Stok berkurang.')));
      fetchData(); // Refresh
    } catch (e) {
      debugPrint("Error ACC: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('Belum ada data', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final alat = item['alat'] ?? {};
        final status = item['status'] ?? 'unknown';
        
        // Data untuk trigger stok
        final pinjamId = item['id'];
        final alatId = alat['id'];
        final currentStok = alat['stok'] ?? 0;

        Color statusColor;
        if (status == 'dipinjam') {
          statusColor = Colors.orange;
        } else if (status == 'selesai') statusColor = Colors.green;
        else if (status == 'ditolak') statusColor = Colors.red;
        else statusColor = Colors.blue;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile( // Ubah jadi ExpansionTile agar ada tombol aksi di bawah
            tilePadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.build, color: Colors.grey),
            ),
            title: Text(alat['nama'] ?? 'Alat Dihapus', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Tgl: ${item['tanggal_pinjam'] ?? '-'}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                status.toString().toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            children: [
              // AREA TOMBOL AKSI (TRIGGER STOK)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                   
                    if (status == 'pending')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _accOlehPetugas(pinjamId, alatId, currentStok),
                        icon: const Icon(Icons.admin_panel_settings, size: 16),
                        label: const Text('Simulasi Petugas: ACC'),
                      ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}