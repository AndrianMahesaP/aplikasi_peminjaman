import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'peminjaman_petugas.dart';
import 'alat_petugas.dart';
import 'setting.dart';

class HomePetugasPage extends StatefulWidget {
  final Map petugas;

  const HomePetugasPage({super.key, required this.petugas});

  @override
  State<HomePetugasPage> createState() => _HomePetugasPageState();
}

class _HomePetugasPageState extends State<HomePetugasPage> {
  final supabase = Supabase.instance.client;
  final Color primaryColor = const Color(0xFF1E4ED8);

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===== BODY (SAMA DENGAN ADMIN) =====
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _homeContent(),
          const PetugasAlatPage(),
          const PetugasPengaturanPage(),
        ],
      ),

      // ===== BOTTOM NAVBAR (STYLE ADMIN) =====
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
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
            icon: Icon(Icons.settings_outlined),
            label: '',
          ),
        ],
      ),
    );
  }

  // ================= HOME CONTENT =================
  Widget _homeContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Home Petugas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // ===== PROFIL =====
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  widget.petugas['nama'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(widget.petugas['role']),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Menu Petugas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ===== MENU GRID =====
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _menuItem(
                  icon: Icons.assignment_outlined,
                  title: 'Peminjaman',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PeminjamanPetugasPage(),
                      ),
                    );
                  },
                ),
                _menuItem(
                  icon: Icons.history_outlined,
                  title: 'Riwayat',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur riwayat belum tersedia'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
