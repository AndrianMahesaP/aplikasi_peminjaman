import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RekapanDendaPage extends StatefulWidget {
  const RekapanDendaPage({super.key});

  @override
  State<RekapanDendaPage> createState() => _RekapanDendaPageState();
}

class _RekapanDendaPageState extends State<RekapanDendaPage> {
  final supabase = Supabase.instance.client;

  num totalMingguan = 0;
  num totalBulanan = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRekapan();
  }

  Future<void> fetchRekapan() async {
    final now = DateTime.now();
    final mingguLalu = now.subtract(const Duration(days: 7));
    final bulanLalu = DateTime(now.year, now.month - 1, now.day);

    final data = await supabase
        .from('pengembalian')
        .select('tgl_dikembalikan, denda');

    num minggu = 0;
    num bulan = 0;

    for (var item in data) {
      final tgl = DateTime.parse(item['tgl_dikembalikan']);
      final denda = item['denda'] ?? 0;

      if (tgl.isAfter(mingguLalu)) {
        minggu += denda;
      }
      if (tgl.isAfter(bulanLalu)) {
        bulan += denda;
      }
    }

    setState(() {
      totalMingguan = minggu;
      totalBulanan = bulan;
      loading = false;
    });
  }

  Widget kartu(String title, num total) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'Rp ${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapan Denda'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  kartu('Total Denda 1 Minggu', totalMingguan),
                  const SizedBox(height: 16),
                  kartu('Total Denda 1 Bulan', totalBulanan),
                ],
              ),
            ),
    );
  }
}
