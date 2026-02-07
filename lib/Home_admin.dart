import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahan untuk status bar style
import 'alat_pag.dart';
import 'crud_petugas.dart';
import 'profil_admin.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Mengatur warna status bar agar menyatu dengan header
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      // Mengubah background jadi sedikit abu-abu agar card putih lebih pop-up
      backgroundColor: const Color(0xFFF5F7FA),

      // ===== BODY =====
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _berandaAdmin(),
          const AlatPage(),
          const PetugasPage(),
          PengaturanAdminPage(), // Pastikan nama class sesuai file Anda
        ],
      ),

      // ===== BOTTOM NAVBAR =====
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
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E4ED8), // Warna biru utama
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Alat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Petugas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }

  // ===== BERANDA ADMIN (REDESIGNED) =====
  Widget _berandaAdmin() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. HEADER BAGIAN ATAS
          _buildHeader(),

          // 2. KONTEN UTAMA (Digeser ke atas sedikit agar menumpuk header)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STATISTIK RINGKAS (Opsional: Visualisasi agar tidak monoton)
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: _buildSummaryStats(),
                ),

                const SizedBox(height: 0), // Adjust spacing after translate

                // SECTION 1: PEMINJAMAN
                _buildSectionTitle('Sedang Dipinjam', Icons.timer_outlined),
                const SizedBox(height: 12),
                _buildTransactionCard(
                  data: const [
                    RiwayatItem(
                      waktu: '09:37',
                      nama: 'Ronaldo',
                      barang: 'Bola Voli',
                      nominal: 'Rp 50.000',
                      status: 'Dipinjam',
                      statusColor: Colors.orange,
                    ),
                  ],
                  isBorrowing: true,
                ),

                const SizedBox(height: 24),

                // SECTION 2: PENGEMBALIAN
                _buildSectionTitle('Riwayat Pengembalian', Icons.history),
                const SizedBox(height: 12),
                _buildTransactionCard(
                  data: const [
                    RiwayatItem(
                      waktu: '10:20',
                      nama: 'Neymar',
                      barang: 'Bola Sepak',
                      nominal: 'Rp 15.000',
                      status: 'Selesai',
                      statusColor: Colors.green,
                    ),
                    // Tambahkan dummy data lain jika ingin melihat scroll
                  ],
                  isBorrowing: false,
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER DESAIN BARU ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E4ED8), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Selamat Pagi, Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Kelola peminjaman alat dengan mudah',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Dipinjam',
            '12 Item',
            Icons.outbox_rounded,
            Colors.orange.shade50,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _statCard(
            'Tersedia',
            '45 Item',
            Icons.inventory_2_outlined,
            Colors.blue.shade50,
            const Color(0xFF1E4ED8),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E4ED8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard({
    required List<RiwayatItem> data,
    required bool isBorrowing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: data.length,
        separatorBuilder: (ctx, index) => Divider(
          color: Colors.grey.shade100,
          height: 1,
          indent: 20,
          endIndent: 20,
        ),
        itemBuilder: (context, index) {
          final item = data[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBorrowing ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isBorrowing ? Icons.access_time_filled : Icons.check_circle,
                color: isBorrowing ? Colors.orange : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              item.nama,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    item.barang,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.waktu,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.nominal,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E4ED8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: item.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===== MODEL (TIDAK BERUBAH) =====
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