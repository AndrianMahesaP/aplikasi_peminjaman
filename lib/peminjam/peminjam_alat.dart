import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ajukan_peminjaman.dart';
import 'pengaturan.dart';
import 'pengembalian.dart';
import 'cart_model.dart';
import 'cart_provider.dart';
import 'keranjang_page.dart';

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
      body: Stack(
        children: [
          _pages[_currentIndex],
          
          // Floating Cart Button
          if (_currentIndex == 0)
            Positioned(
              right: 16,
              bottom: 80,
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -8, end: -8),
                    badgeContent: Text(
                      '${cart.uniqueItemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    showBadge: cart.uniqueItemCount > 0,
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.red,
                    ),
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KeranjangPage(),
                          ),
                        );
                      },
                      child: const Icon(Icons.shopping_cart),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
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
  
  // Category filter
  String selectedCategory = 'Semua';
  List<String> categories = ['Semua'];
  bool loadingCategories = true;

  // Warna Tema
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color bgColor = const Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchAlat();
  }
  
  Future<void> fetchCategories() async {
    try {
      final res = await supabase
          .from('kategori')
          .select('nama')
          .order('nama');
      
      final categoryNames = res.map((e) => e['nama'].toString()).toList();
      
      setState(() {
        categories = ['Semua', ...categoryNames];
        loadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() => loadingCategories = false);
    }
  }

  Future<void> fetchAlat() async {
    setState(() => loading = true);
    try {
      var query = supabase
          .from('alat')
          .select('*')
          .gt('stok', 0);
      
      if (keyword.isNotEmpty) {
        query = query.ilike('nama', '%$keyword%');
      }
      
      // Filter by category using jenis field
      if (selectedCategory != 'Semua') {
        query = query.eq('jenis', selectedCategory);
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
          
          // Category Filter
          SizedBox(
            height: 60,
            child: loadingCategories
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;
                      
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: primaryColor.withOpacity(0.1),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? primaryColor : Colors.grey.shade300,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                            fetchAlat();
                          });
                        },
                      );
                    },
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Gambar Placeholder - Larger
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              image: item['gambar'] != null && item['gambar'].toString().isNotEmpty
                  ? DecorationImage(image: NetworkImage(item['gambar']), fit: BoxFit.cover)
                  : null,
            ),
            child: item['gambar'] == null || item['gambar'].toString().isEmpty
                ? const Icon(Icons.handyman, color: Colors.indigo, size: 35)
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 17,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item['jenis'] ?? '-',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tersedia: ${item['stok']}',
                    style: TextStyle(
                      color: Colors.green.shade700, 
                      fontSize: 13, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Action Buttons - More compact
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add to Cart Button
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  final isInCart = cart.isInCart(item['alat_id']);
                  
                  return SizedBox(
                    width: 100,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInCart ? Colors.green : primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final cartItem = CartItem.fromAlat(item);
                        final success = await cart.addToCart(cartItem);
                        
                        if (!context.mounted) return;
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('${item['nama']} ditambahkan'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stok tidak mencukupi'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isInCart ? 'Keranjang' : 'Keranjang',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              
              // Direct Borrow Button
              SizedBox(
                width: 100,
                height: 32,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    side: BorderSide(color: primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AjukanPeminjamanPage(alat: item),
                      ),
                    ).then((_) {
                      fetchAlat(); 
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Pinjam',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
      tanggal_kembali,
      alat:alat_id (
        alat_id,
        nama,
        gambar
      ),
      detail_peminjaman!inner (
        jumlah
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
        final detailList = item['detail_peminjaman'] as List?;
        final jumlah = detailList != null && detailList.isNotEmpty 
            ? detailList[0]['jumlah'] ?? 1 
            : 1;
        
        // Data untuk trigger stok
        final pinjamId = item['peminjaman_id'];
        final alatId = alat['alat_id'];
        final currentStok = alat['stok'] ?? 0;

        // Status display name
        String statusDisplay;
        Color statusColor;
        IconData statusIcon;
        
        if (status == 'disetujui') {
          statusDisplay = 'Sedang Dipinjam';
          statusColor = const Color(0xFF10B981); // Green
          statusIcon = Icons.autorenew;
        } else if (status == 'menunggu') {
          statusDisplay = 'Menunggu Persetujuan';
          statusColor = const Color(0xFFF59E0B); // Orange
          statusIcon = Icons.hourglass_empty;
        } else if (status == 'selesai') {
          statusDisplay = 'Selesai';
          statusColor = const Color(0xFF6366F1); // Indigo
          statusIcon = Icons.check_circle;
        } else if (status == 'ditolak') {
          statusDisplay = 'Ditolak';
          statusColor = const Color(0xFFEF4444); // Red
          statusIcon = Icons.cancel;
        } else {
          statusDisplay = status.toString().toUpperCase();
          statusColor = Colors.grey;
          statusIcon = Icons.info;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: alat['gambar'] != null && alat['gambar'].toString().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(alat['gambar']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: alat['gambar'] == null || alat['gambar'].toString().isEmpty
                    ? Icon(Icons.build, size: 30, color: statusColor.withOpacity(0.5))
                    : null,
              ),
              title: Text(
                alat['nama'] ?? 'Alat Dihapus',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                // Details section (shown when expanded)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.numbers,
                        label: 'Jumlah',
                        value: '$jumlah unit',
                        color: statusColor,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Tanggal Pinjam',
                        value: item['tanggal_pinjam'] ?? '-',
                        color: statusColor,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        icon: Icons.event_available,
                        label: 'Tanggal Kembali',
                        value: item['tanggal_kembali'] ?? '-',
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                if (status == 'pending' || status == 'disetujui')
                  Row(
                    children: [
                      if (status == 'pending')
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () => _accOlehPetugas(pinjamId, alatId, currentStok),
                            icon: const Icon(Icons.admin_panel_settings, size: 18),
                            label: const Text('Simulasi Petugas: ACC'),
                          ),
                        ),
                      
                      if (status == 'disetujui')
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PengembalianPage(
                                    peminjamanId: item['peminjaman_id'],
                                  ),
                                ),
                              ).then((_) => fetchData());
                            },
                            icon: const Icon(Icons.assignment_return, size: 18),
                            label: const Text('Kembalikan Alat', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}