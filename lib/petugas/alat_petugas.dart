import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetugasAlatPage extends StatefulWidget {
  const PetugasAlatPage({super.key});

  @override
  State<PetugasAlatPage> createState() => _PetugasAlatPageState();
}

class _PetugasAlatPageState extends State<PetugasAlatPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final Color primaryColor = const Color(0xFF1E4ED8);

  List alatList = [];
  String keyword = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadAlat();
    _tabController.addListener(loadAlat);
  }

  // ================= IMAGE URL =================
  String? getImageUrl(String? gambar) {
    if (gambar == null || gambar.isEmpty) return null;
    if (gambar.startsWith('http')) return gambar;
    return supabase.storage.from('alat').getPublicUrl(gambar);
  }

  // ================= LOAD DATA =================
  Future<void> loadAlat() async {
    try {
      var query = supabase.from('alat').select();

      if (keyword.isNotEmpty) {
        query = query.ilike('nama', '%$keyword%');
      }

      if (_tabController.index == 1) {
        query = query.or('kondisi.eq.Rusak,kondisi.eq.Lecet');
      }

      final res = await query.order('nama');
      setState(() => alatList = res);
    } catch (e) {
      debugPrint('ERROR LOAD ALAT: $e');
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Data Alat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Semua Alat'),
            Tab(text: 'Rusak / Lecet'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari alat...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (v) {
                keyword = v;
                loadAlat();
              },
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: alatList.isEmpty
                ? const Center(child: Text('Data alat kosong'))
                : ListView.builder(
                    itemCount: alatList.length,
                    itemBuilder: (context, index) {
                      final alat = alatList[index];

                      final String nama = alat['nama'] ?? '-';
                      final String jenis = alat['jenis'] ?? '-';
                      final String kondisi = alat['kondisi'] ?? '-';
                      final int stok = alat['stok'] ?? 0;
                      final String? gambar = alat['gambar'];

                      final imageUrl = getImageUrl(gambar);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.image, size: 40),
                          ),
                          title: Text(
                            nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jenis   : $jenis'),
                              Text('Stok    : $stok'),
                              Text('Kondisi : $kondisi'),
                            ],
                          ),
                          // ❌ trailing dihapus (ora ono abang-abang maneh)
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
