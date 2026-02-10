import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Import halaman lain sesuai project kamu
import 'alat_pag.dart';
import 'crud_petugas.dart';
import 'profil_admin.dart';
import 'denda.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  final supabase = Supabase.instance.client;

  // State Data
  int _jmlDipinjam = 0;
  int _jmlTersedia = 0;
  List<RiwayatItem> _listSedangDipinjam = [];
  List<RiwayatItem> _listRiwayatKembali = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // 1. Hitung Sedang Dipinjam
      // Menggunakan count exact untuk akurasi
      final countDipinjam = await supabase
          .from('peminjaman')
          .count(CountOption.exact)
          .eq('status', 'disetujui');

      // 2. Hitung Total Stok (Sum kolom 'stok' dari tabel 'alat')
      final resAlat = await supabase
          .from('alat')
          .select('stok');
      
      int totalStok = 0;
      for (var item in resAlat) {
        // Handle stok null atau tipe bigint
        totalStok += (item['stok'] ?? 0) as int;
      }

      // 3. Ambil Data "Sedang Dipinjam" (Limit 3)
      // Relasi: alat (public.alat), users (public.users)
      final dataDipinjam = await supabase
          .from('peminjaman')
          .select('*, alat:alat_id(nama), users:user_id(email)') 
          .eq('status', 'distujui')
          .order('created_at', ascending: false)
          .limit(3);

      // 4. Ambil Data "Riwayat Pengembalian" (Limit 3)
      final dataKembali = await supabase
          .from('peminjaman')
          .select('*, alat:alat_id(nama), users:user_id(email)')
          .eq('status', 'selesai') // Pastikan status di DB konsisten ('selesai'/'dikembalikan')
          .order('updated_at', ascending: false)
          .limit(3);

      if (mounted) {
        setState(() {
          _jmlDipinjam = countDipinjam;
          _jmlTersedia = totalStok;
          _listSedangDipinjam = (dataDipinjam as List).map((e) => _mapToModel(e)).toList();
          _listRiwayatKembali = (dataKembali as List).map((e) => _mapToModel(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetch Dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  RiwayatItem _mapToModel(Map<String, dynamic> data) {
    final alat = data['alat'] ?? {'nama': 'Alat Dihapus'};
    final user = data['users'] ?? {'email': 'User'};
    
    // Safety check tanggal
    DateTime date;
    if (data['updated_at'] != null) {
      date = DateTime.parse(data['updated_at']);
    } else {
      date = DateTime.parse(data['created_at']);
    }

    // Ambil nama dari email
    String userName = 'Guest';
    if (user['email'] != null) {
      userName = user['email'].split('@')[0];
    }

    return RiwayatItem(
      waktu: DateFormat('dd MMM HH:mm').format(date.toLocal()),
      nama: userName,
      barang: alat['nama'] ?? '-',
      // Nominal strip dulu, bisa diisi denda jika status selesai & ada denda
      nominal: data['status'] == 'selesai' ? 'Selesai' : 'disetujui',
      status: data['status'] == 'disetujui' ? 'disetujui' : 'Dikembalikan',
      statusColor: data['status'] == 'disetujui' ? Colors.orange : Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mengatur status bar agar terlihat rapi
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E4ED8),
        title: const Text('Dashboard Admin', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
                setState(() => _isLoading = true);
                _fetchDashboardData();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _berandaAdmin(),
          const AlatPage(),
          const PetugasPage(),
          PengaturanAdminPage(), 
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _berandaAdmin() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menggeser kartu statistik ke atas agar menumpuk header
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: _buildSummaryStats(),
                ),
                
                // --- SECTION SEDANG DIPINJAM ---
                _buildSectionTitle('Sedang Dipinjam', Icons.timer_outlined),
                const SizedBox(height: 12),
                _listSedangDipinjam.isEmpty
                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Tidak ada peminjaman aktif.")))
                    : _buildTransactionCard(data: _listSedangDipinjam, isBorrowing: true),

                const SizedBox(height: 24),

                // --- SECTION RIWAYAT ---
                _buildSectionTitle('Riwayat Terbaru', Icons.history),
                const SizedBox(height: 12),
                _listRiwayatKembali.isEmpty
                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Belum ada riwayat.")))
                    : _buildTransactionCard(data: _listRiwayatKembali, isBorrowing: false),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS (Header, Nav, Cards) SAMA SEPERTI SEBELUMNYA ---
  // Saya persingkat bagian UI statis agar fokus ke logic database di atas.
  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Halo, Admin', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('Pantau aktivitas laboratorium', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1E4ED8),
      onTap: (i) => setState(() => _currentIndex = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Alat'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Petugas'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }

  Widget _buildSummaryStats() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailBarangDipinjamPage()));
            },
            child: _statCard('Dipinjam', '$_jmlDipinjam', Icons.outbox, Colors.orange.shade100, Colors.orange),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _statCard('Stok Alat', '$_jmlTersedia', Icons.inventory_2, Colors.blue.shade100, Colors.blue),
        ),
      ],
    );
  }

  Widget _statCard(String label, String val, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [Icon(icon, size: 18), const SizedBox(width: 5), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]);
  }

  Widget _buildTransactionCard({required List<RiwayatItem> data, required bool isBorrowing}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final item = data[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: item.statusColor.withOpacity(0.1),
              child: Icon(isBorrowing ? Icons.access_time : Icons.check, color: item.statusColor, size: 20),
            ),
            title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item.barang} • ${item.waktu}"),
            trailing: Text(item.status, style: TextStyle(color: item.statusColor, fontSize: 12)),
          );
        },
      ),
    );
  }
}

// ==========================================
// HALAMAN DETAIL BARANG DIPINJAM
// ==========================================
class DetailBarangDipinjamPage extends StatelessWidget {
  const DetailBarangDipinjamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Peminjaman Aktif"), backgroundColor: const Color(0xFF1E4ED8)),
      body: FutureBuilder(
        // Query yang sama: join ke alat dan users (public)
        future: supabase
            .from('peminjaman')
            .select('*, alat:alat_id(nama, gambar), users:user_id(email)')
            .eq('status', 'disetujui')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text("Tidak ada data."));
          }

          final List data = snapshot.data as List;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final alat = item['alat'] ?? {};
              final user = item['users'] ?? {};
              final tglPinjam = DateTime.parse(item['created_at']).toLocal();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: (alat['gambar'] != null && alat['gambar'].toString().isNotEmpty)
                          ? DecorationImage(image: NetworkImage(alat['gambar']), fit: BoxFit.cover)
                          : null
                    ),
                    child: (alat['gambar'] == null || alat['gambar'] == '') 
                        ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                  ),
                  title: Text(alat['nama'] ?? 'Unknown Alat', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Peminjam: ${user['email'] ?? 'No Email'}", style: const TextStyle(fontSize: 12)),
                      Text("Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(tglPinjam)}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Text("Dipinjam", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Model Sederhana
class RiwayatItem {
  final String waktu;
  final String nama;
  final String barang;
  final String nominal;
  final String status;
  final Color statusColor;

  const RiwayatItem({
    required this.waktu,
    required this.nama,
    required this.barang,
    required this.nominal,
    required this.status,
    required this.statusColor,
  });
}