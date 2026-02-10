import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Import halaman lain sesuai project kamu
import 'alat_pag.dart';
import 'crud_petugas.dart';
import 'profil_admin.dart';
import 'denda.dart';
import 'admin/kelola_peminjaman.dart';

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
  int _totalDenda = 0;
  List<RiwayatItem> _listRiwayat = [];
  Map<String, int> _dailyBorrowData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // 1. Hitung Sedang Dipinjam
      final countDipinjam = await supabase
          .from('peminjaman')
          .count(CountOption.exact)
          .eq('status', 'disetujui');

      // 2. Hitung Total Stok
      final resAlat = await supabase.from('alat').select('stok');
      int totalStok = 0;
      for (var item in resAlat) {
        totalStok += (item['stok'] ?? 0) as int;
      }

      // 3. Hitung Total Denda Minggu Ini
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final resDenda = await supabase
          .from('pengembalian')
          .select('denda')
          .gte('tgl_dikembalikan', weekAgo.toIso8601String());
      
      int totalDenda = 0;
      for (var item in resDenda) {
        totalDenda += (item['denda'] ?? 0) as int;
      }

      // 4. Data Peminjaman 7 Hari Terakhir untuk Chart
      final resBorrow = await supabase
          .from('peminjaman')
          .select('tanggal_pinjam')
          .gte('tanggal_pinjam', DateFormat('yyyy-MM-dd').format(weekAgo));
      
      Map<String, int> dailyData = {};
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        dailyData[dateStr] = 0;
      }
      
      for (var item in resBorrow) {
        final dateStr = item['tanggal_pinjam']?.toString().split(' ')[0];
        if (dateStr != null && dailyData.containsKey(dateStr)) {
          dailyData[dateStr] = (dailyData[dateStr] ?? 0) + 1;
        }
      }

      // 5. Ambil Semua Riwayat (Dipinjam + Selesai)
      final dataRiwayat = await supabase
          .from('peminjaman')
          .select('*, alat:alat_id(nama), users:user_id(email)')
          .inFilter('status', ['disetujui', 'selesai'])
          .order('created_at', ascending: false)
          .limit(6);

      if (mounted) {
        setState(() {
          _jmlDipinjam = countDipinjam;
          _jmlTersedia = totalStok;
          _totalDenda = totalDenda;
          _dailyBorrowData = dailyData;
          _listRiwayat = (dataRiwayat as List).map((e) => _mapToModel(e)).toList();
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
    
    DateTime date;
    if (data['updated_at'] != null) {
      date = DateTime.parse(data['updated_at']);
    } else {
      date = DateTime.parse(data['created_at']);
    }

    String userName = 'Guest';
    if (user['email'] != null) {
      userName = user['email'].split('@')[0];
    }

    return RiwayatItem(
      waktu: DateFormat('dd MMM HH:mm').format(date.toLocal()),
      nama: userName,
      barang: alat['nama'] ?? '-',
      nominal: data['status'] == 'selesai' ? 'Selesai' : 'disetujui',
      status: data['status'] == 'disetujui' ? 'disetujui' : 'Dikembalikan',
      statusColor: data['status'] == 'disetujui' ? Colors.orange : Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E4ED8),
        toolbarHeight: 0, // Remove AppBar content
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
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _fetchDashboardData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildModernHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards Grid
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: _buildStatsGrid(),
                  ),
                  
                  // Chart Section
                  const Text(
                    'Peminjaman 7 Hari Terakhir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildChart(),
                  const SizedBox(height: 32),
                  
                  // Riwayat Section (Combined)
                  _buildSectionTitle('Aktivitas Terbaru', Icons.history_outlined),
                  const SizedBox(height: 16),
                  _listRiwayat.isEmpty
                      ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Belum ada aktivitas.")))
                      : _buildModernActivityCards(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 80),
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
          Text('Halo, Admin', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Pantau aktivitas laboratorium', style: TextStyle(color: Colors.white70, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailBarangDipinjamPage())),
          child: _modernStatCard(
            'Dipinjam',
            '$_jmlDipinjam',
            Icons.outbox,
            const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), // Purple
          ),
        ),
        _modernStatCard(
          'Stok Alat',
          '$_jmlTersedia',
          Icons.inventory_2,
          const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]), // Blue
        ),
        _modernStatCard(
          'Denda Minggu Ini',
          'Rp ${NumberFormat('#,###', 'id_ID').format(_totalDenda)}',
          Icons.money_off,
          const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]), // Orange
        ),
        _modernStatCard(
          'Total Transaksi',
          '${_jmlDipinjam + _listRiwayat.length}',
          Icons.receipt_long,
          const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)]), // Teal
        ),
      ],
    );
  }

  Widget _modernStatCard(String label, String val, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final entries = _dailyBorrowData.entries.toList();
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 2).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < entries.length) {
                    final date = DateTime.parse(entries[value.toInt()].key);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(date),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E4ED8)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModernActivityCards() {
    return Column(
      children: _listRiwayat.asMap().entries.map((entry) {
        final item = entry.value;
        final isLast = entry.key == _listRiwayat.length - 1;
        
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Avatar with Initials
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGradientForName(item.nama),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(item.nama),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.barang,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          item.waktu,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
              ),
                child: Text(
                  item.status == 'disetujui' ? 'Dipinjam' : 'Selesai',
                  style: TextStyle(
                    color: item.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // Get initials from name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  
  // Get gradient colors based on name hash (reduced to 4 colors)
  List<Color> _getGradientForName(String name) {
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)], // Purple
      [const Color(0xFF4F46E5), const Color(0xFF6366F1)], // Blue
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)], // Orange
      [const Color(0xFF14B8A6), const Color(0xFF06B6D4)], // Teal
    ];
    final index = name.hashCode.abs() % gradients.length;
    return gradients[index];
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