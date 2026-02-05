import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,

      // ===== BODY =====
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _berandaAdmin(),          
          const AlatPage(),         
          const PetugasPage(),
           PengaturanAdminPage(),      
        ],
      ),

      // ===== BOTTOM NAVBAR =====
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '',
          ),
        ],
      ),
    );
  }

  // ===== BERANDA ADMIN =====
  Widget _berandaAdmin() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beranda Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildRiwayatCard(
              title: 'Riwayat Peminjaman',
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
            ),

            const SizedBox(height: 16),

            _buildRiwayatCard(
              title: 'Riwayat Pengembalian',
              data: const [
                RiwayatItem(
                  waktu: '10:20',
                  nama: 'Neymar',
                  barang: 'Bola Sepak',
                  nominal: 'Rp 15.000',
                  status: 'Selesai',
                  statusColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== CARD RIWAYAT =====
  Widget _buildRiwayatCard({
    required String title,
    required List<RiwayatItem> data,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E4ED8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: data.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(item.waktu,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(item.barang,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.nominal,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(item.status,
                            style: TextStyle(
                                fontSize: 12,
                                color: item.statusColor)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ===== MODEL =====
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
