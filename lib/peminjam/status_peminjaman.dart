import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatusPeminjamanPage extends StatefulWidget {
  const StatusPeminjamanPage({super.key});

  @override
  State<StatusPeminjamanPage> createState() => _StatusPeminjamanPageState();
}

class _StatusPeminjamanPageState extends State<StatusPeminjamanPage> {
  final supabase = Supabase.instance.client;
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    final user = supabase.auth.currentUser;
    final result = await supabase
        .from('peminjaman')
        .select('*, alat(nama)')
        .eq('user_id', user!.id)
        .order('created_at', ascending: false);

    setState(() {
      data = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Peminjaman')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text(item['alat']['nama']),
                  subtitle: Text('Status: ${item['status']}'),
                );
              },
            ),
    );
  }
}
