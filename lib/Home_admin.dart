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
    // Temp variables
    int tempDipinjam = 0;
    int tempStok = 0;
    int tempDenda = 0;
    Map<String, int> tempDailyData = {};
    List<RiwayatItem> tempRiwayat = [];

    // 1. Hitung Sedang Dipinjam
    try {
      final countDipinjam = await supabase
          .from('peminjaman')
          .count(CountOption.exact)
          .eq('status', 'disetujui');
      tempDipinjam = countDipinjam;
    } catch (e) {
      debugPrint("Error Fetch Dipinjam: $e");
    }

    // 2. Hitung Total Stok
    try {
      final resAlat = await supabase.from('alat').select('stok');
      for (var item in resAlat) {
        tempStok += (item['stok'] ?? 0) as int;
      }
    } catch (e) {
      debugPrint("Error Fetch Stok: $e");
    }

    // 3. Hitung Total Denda Minggu Ini
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final resDenda = await supabase
          .from('pengembalian')
          .select('denda')
          .gte('tgl_dikembalikan', weekAgo.toIso8601String());
      
      for (var item in resDenda) {
        tempDenda += (item['denda'] ?? 0) as int;
      }
    } catch (e) {
      debugPrint("Error Fetch Denda: $e");
    }

    // 4. Data Peminjaman 7 Hari Terakhir untuk Chart
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      // Init 0
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        tempDailyData[dateStr] = 0;
      }

      final resBorrow = await supabase
          .from('peminjaman')
          .select('tanggal_pinjam')
          .gte('tanggal_pinjam', DateFormat('yyyy-MM-dd').format(weekAgo));
      
      for (var item in resBorrow) {
        final dateStr = item['tanggal_pinjam']?.toString().split(' ')[0];
        if (dateStr != null && tempDailyData.containsKey(dateStr)) {
          tempDailyData[dateStr] = (tempDailyData[dateStr] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint("Error Fetch Chart: $e");
    }

    // 5. Ambil Log Aktivitas Terbaru (Log Aktivitas)
    try {
      final dataLog = await supabase
          .from('log_aktivitas')
          .select('*, users:user_id(email)')
          .order('created_at', ascending: false)
          .limit(6);
      
      tempRiwayat = (dataLog as List).map((e) => _mapToModel(e)).toList();
    } catch (e) {
      debugPrint("Error Fetch Log Aktivitas: $e");
      // Fallback ke peminjaman jika log_aktivitas gagal/tidak ada
      try {
         final dataRiwayat = await supabase
          .from('peminjaman')
          .select('*, alat:alat_id(nama), users:user_id(email)')
          .inFilter('status', ['disetujui', 'selesai'])
          .order('created_at', ascending: false)
          .limit(6);
         
         // Mapper khusus fallback (karena log pakai _mapToModel yang asumsi kolom log_aktivitas)
         // Kita pakai mapper manual disini agar aman
         tempRiwayat = (dataRiwayat as List).map((data) {
            final alat = data['alat'] ?? {'nama': 'Alat'};
            final user = data['users'] ?? {'email': 'User'};
            DateTime date = data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now();
            String userName = user['email'] != null ? user['email'].split('@')[0] : 'Guest';
            
            return RiwayatItem(
              waktu: DateFormat('dd MMM HH:mm').format(date.toLocal()),
              nama: userName,
              barang: alat['nama'] ?? '-',
              nominal: '-',
              status: data['status'] == 'disetujui' ? 'Dipinjam' : 'Selesai',
              statusColor: data['status'] == 'disetujui' ? Colors.orange : Colors.green,
            );
         }).toList();

      } catch (e2) {
        debugPrint("Error Fetch Fallback Peminjaman: $e2");
      }
    }

    if (mounted) {
      setState(() {
        _jmlDipinjam = tempDipinjam;
        _jmlTersedia = tempStok;
        _totalDenda = tempDenda;
        _dailyBorrowData = tempDailyData;
        _listRiwayat = tempRiwayat;
        _isLoading = false;
      });
    }
  }

  RiwayatItem _mapToModel(Map<String, dynamic> data) {
    final user = data['users'] ?? {'email': 'System'};
    final aktivitas = data['aktivitas'] ?? 'Aktivitas tidak diketahui';
    
    DateTime date;
    if (data['created_at'] != null) {
      date = DateTime.parse(data['created_at']);
    } else {
      date = DateTime.now();
    }

    String userName = 'Guest';
    if (user['email'] != null) {
      userName = user['email'].split('@')[0];
    } else {
      userName = 'System';
    }

    return RiwayatItem(
      waktu: DateFormat('dd MMM HH:mm').format(date.toLocal()),
      nama: userName,
      barang: aktivitas, // Menampilkan aktivitas di kolom barang
      nominal: '-',
      status: 'Info',
      statusColor: Colors.blueAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5), // Indigo
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
        color: Color(0xFF4F46E5), // Indigo Flat
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
            Colors.orange,
          ),
        ),
        _modernStatCard(
          'Stok Alat',
          '$_jmlTersedia',
          Icons.inventory_2,
          Colors.green,
        ),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekapanDendaPage())),
          child: _modernStatCard(
            'Denda Minggu Ini',
            'Rp ${NumberFormat('#,###', 'id_ID').format(_totalDenda)}',
            Icons.money_off,
            Colors.red,
          ),
        ),
        _modernStatCardWithChart(
          'Total Transaksi',
          '${_jmlDipinjam + _listRiwayat.length}',
          Icons.receipt_long,
          const Color(0xFF4F46E5), // Indigo
        ),
      ],
    );
  }

  Widget _modernStatCard(String label, String val, IconData icon, Color iconColor) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
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

  // Stat card dengan mini chart untuk Total Transaksi
  Widget _modernStatCardWithChart(String label, String val, IconData icon, Color iconColor) {
    final entries = _dailyBorrowData.entries.toList();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value.toDouble()));
    }

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
          // Header with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(
                '7 hari',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Value and label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Mini chart
          SizedBox(
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: iconColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: iconColor.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
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
          maxY: entries.isEmpty 
              ? 10.0 
              : (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 2).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (entries.isEmpty) return const Text('');
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
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)], // Indigo
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
      selectedItemColor: const Color(0xFF4F46E5),
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
        Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
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
                  item.status,
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
    // Monochrome gradients based on Indigo
    final gradients = [
      [const Color(0xFF4F46E5), const Color(0xFF6366F1)], 
      [const Color(0xFF4338CA), const Color(0xFF4F46E5)],
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