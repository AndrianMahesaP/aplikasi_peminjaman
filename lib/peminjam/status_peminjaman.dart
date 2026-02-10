import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pinjam_alat/peminjam/pengembalian.dart';


class StatusPeminjamanPage extends StatefulWidget {
  const StatusPeminjamanPage({super.key});

  @override
  State<StatusPeminjamanPage> createState() => _StatusPeminjamanPageState();
}

class _StatusPeminjamanPageState extends State<StatusPeminjamanPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List statusData = [];
  List aktivitasData = [];
  bool loading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

   final statusResult = await supabase
    .from('detail_peminjaman')
    .select('''
      id,
      jumlah,
      peminjaman:peminjaman_id (
        peminjaman_id,
        status,
        user_id
      ),
      alat:alat_id (
        nama_alat,
        nama_kategori
      )
    ''')
    .eq('user_id', user.id)
    .neq('status', 'disetujui')
    .order('created_at', ascending: false);


   final aktivitasResult = await supabase
    .from('detail_peminjaman')
    .select('''
      id,
      jumlah,
      peminjaman:peminjaman_id (
        peminjaman_id,
        status,
        user_id
      ),
      alat:alat_id (
        nama_alat,
        nama_kategori
      )
    ''')
    .eq('user_id', user.id)
    .eq('status', 'disetujui')
    .order('created_at', ascending: false);



    setState(() {
      statusData = statusResult;
      aktivitasData = aktivitasResult;
      loading = false;
    });
  }

  Widget _buildList(List data, {bool isAktivitas = false}) {
    if (data.isEmpty) {
      return const Center(child: Text('Data kosong'));
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final namaAlat = item['alat']?['nama'] ?? '-';

          return Card(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: ListTile(
    title: Text(namaAlat),
    subtitle: Text(
      'Status: ${item['peminjaman']['status']}',
    ),

    trailing: isAktivitas
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PengembalianPage(
      peminjamanId: item['peminjaman']['peminjaman_id'],
    ),
  ),
              ).then((_) => fetchData());
            },
            child: const Text(
              'Kembalikan',
              style: TextStyle(color: Colors.white),
            ),
          )
        : const Icon(Icons.hourglass_top, color: Colors.orange),
  ),
);

        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('peminjaman'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Status'),
            Tab(text: 'Aktivitas'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(statusData),
                _buildList(aktivitasData, isAktivitas: true),
              ],
            ),
    );
  }
}
