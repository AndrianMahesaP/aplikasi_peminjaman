import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    // 🔹 STATUS = belum disetujui
    final statusResult = await supabase
    .from('peminjaman')
    .select('peminjaman_id, status, alat(nama)')
    .eq('user_id', user.id)
    .neq('status', 'disetujui')
    .order('created_at', ascending: false);


    // 🔹 AKTIVITAS = sudah disetujui
    final aktivitasResult = await supabase
    .from('peminjaman')
    .select('peminjaman_id, status, alat(nama)')
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
                isAktivitas
                    ? 'Status: Disetujui'
                    : 'Status: ${item['status']}',
              ),
              trailing: Icon(
                isAktivitas
                    ? Icons.check_circle
                    : Icons.hourglass_top,
                color: isAktivitas ? Colors.green : Colors.orange,
              ),
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
        title: const Text('Peminjaman'),
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
