import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Data model untuk denda harian
class DailyPenaltyData {
  final DateTime date;
  final num totalDenda;
  final List<PenaltyDetail> details;

  DailyPenaltyData({
    required this.date,
    required this.totalDenda,
    required this.details,
  });
}

class PenaltyDetail {
  final String alatNama;
  final String userEmail;
  final num denda;
  final String pengembalianId;

  PenaltyDetail({
    required this.alatNama,
    required this.userEmail,
    required this.denda,
    required this.pengembalianId,
  });
}

class RekapanDendaPage extends StatefulWidget {
  const RekapanDendaPage({super.key});

  @override
  State<RekapanDendaPage> createState() => _RekapanDendaPageState();
}

class _RekapanDendaPageState extends State<RekapanDendaPage> {
  final supabase = Supabase.instance.client;

  Map<String, DailyPenaltyData> dailyData = {};
  DateTime? selectedDate;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDendaData();
  }

  Future<void> fetchDendaData() async {
    setState(() => loading = true);

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 6));

      // Fetch data pengembalian dengan denda > 0, dengan join ke peminjaman -> alat dan users
      final data = await supabase
          .from('pengembalian')
          .select('''
            pengembalian_id,
            tgl_dikembalikan,
            denda,
            peminjaman:peminjaman_id(
              peminjaman_id,
              alat:alat_id(nama),
              users:user_id(email)
            )
          ''')
          .gte('tgl_dikembalikan', sevenDaysAgo.toIso8601String())
          .gt('denda', 0)  // HANYA ambil yang ada denda
          .order('tgl_dikembalikan', ascending: true);

      // Group by date
      Map<String, DailyPenaltyData> grouped = {};

      for (var item in data) {
        final tglDikembalikan = DateTime.parse(item['tgl_dikembalikan']);
        final dateKey = DateFormat('yyyy-MM-dd').format(tglDikembalikan);
        final denda = item['denda'] ?? 0;

        // CRITICAL: Skip jika denda <= 0 (hanya tampilkan yang kena denda)
        if (denda == null || denda <= 0) {
          debugPrint('Skipping item with denda: $denda');
          continue;
        }

        // Extract relational data
        final peminjaman = item['peminjaman'] ?? {};
        final alat = peminjaman['alat'] ?? {};
        final user = peminjaman['users'] ?? {};

        final detail = PenaltyDetail(
          alatNama: alat['nama'] ?? 'Unknown',
          userEmail: user['email'] ?? 'Unknown',
          denda: denda,
          pengembalianId: item['pengembalian_id'] ?? '',
        );

        if (grouped.containsKey(dateKey)) {
          grouped[dateKey]!.details.add(detail);
          grouped[dateKey] = DailyPenaltyData(
            date: grouped[dateKey]!.date,
            totalDenda: grouped[dateKey]!.totalDenda + denda,
            details: grouped[dateKey]!.details,
          );
        } else {
          grouped[dateKey] = DailyPenaltyData(
            date: tglDikembalikan,
            totalDenda: denda,
            details: [detail],
          );
        }
      }

      // Fill missing days with zero (untuk konsistensi grafik)
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = DailyPenaltyData(
            date: date,
            totalDenda: 0,
            details: [],
          );
        }
      }

      setState(() {
        dailyData = grouped;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching denda: $e');
      setState(() => loading = false);
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    final sortedKeys = dailyData.keys.toList()..sort();
    
    return sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final data = dailyData[key]!;
      final isSelected = selectedDate != null &&
          DateFormat('yyyy-MM-dd').format(selectedDate!) == key;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.totalDenda.toDouble(),
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8), // Indigo vs Slate
            width: 28,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildChart() {
    if (dailyData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Belum ada data denda',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final sortedKeys = dailyData.keys.toList()..sort();
    final maxY = dailyData.values
        .map((e) => e.totalDenda)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY * 1.15 : 100,
          barGroups: _buildBarGroups(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  return Text(
                    'Rp ${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedKeys.length) return const Text('');
                  final dateKey = sortedKeys[value.toInt()];
                  final date = dailyData[dateKey]!.date;
                  // Nama hari dalam Bahasa Indonesia
                  final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
                  final dayName = dayNames[date.weekday % 7];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
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
            horizontalInterval: maxY > 0 ? maxY / 4 : 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade100,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF1E293B),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dateKey = sortedKeys[group.x.toInt()];
                final data = dailyData[dateKey]!;
                // Format tanggal dalam Bahasa Indonesia
                final bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
                final tglFormat = '${data.date.day} ${bulan[data.date.month]}';
                return BarTooltipItem(
                  'Rp ${NumberFormat('#,###').format(data.totalDenda)}\n$tglFormat',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (event is FlTapUpEvent && barTouchResponse != null) {
                final index = barTouchResponse.spot?.touchedBarGroupIndex;
                if (index != null && index < sortedKeys.length) {
                  final dateKey = sortedKeys[index];
                  setState(() {
                    selectedDate = dailyData[dateKey]!.date;
                  });
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    if (selectedDate == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.touch_app_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Klik pada grafik untuk melihat detail',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final data = dailyData[dateKey];

    if (data == null || data.details.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Tidak ada denda pada ${_formatTanggalIndonesia(selectedDate!)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5), // Indigo
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatTanggalIndonesia(selectedDate!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Denda',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${NumberFormat('#,###').format(data.totalDenda)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${data.details.length} Item',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List detail dengan denda
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Barang Terkena Denda',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.details.map((detail) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.build_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.alatNama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      detail.userEmail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rp ${NumberFormat('#,###').format(detail.denda)}',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function untuk format tanggal dalam Bahasa Indonesia
  String _formatTanggalIndonesia(DateTime date) {
    final hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final bulan = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                   'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    final namaHari = hari[date.weekday % 7];
    final namaBulan = bulan[date.month];
    
    return '$namaHari, ${date.day} $namaBulan ${date.year}';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        title: const Text(
          'Rekapan Denda',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDendaData,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Grafik Denda 7 Hari Terakhir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildChart(),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}