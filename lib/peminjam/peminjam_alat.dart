import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ajukan_peminjaman.dart';

class PeminjamAlatPage extends StatefulWidget {
  const PeminjamAlatPage({super.key});

  @override
  State<PeminjamAlatPage> createState() => _PeminjamAlatPageState();
}

class _PeminjamAlatPageState extends State<PeminjamAlatPage> {
  final supabase = Supabase.instance.client;
  List alat = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAlat();
  }

  Future<void> fetchAlat() async {
    final data = await supabase
        .from('alat')
        .select()
        .gt('stok', 0);

    setState(() {
      alat = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Alat')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: alat.length,
              itemBuilder: (context, index) {
                final item = alat[index];
                return ListTile(
                  title: Text(item['nama']),
                  subtitle: Text('Stok: ${item['stok']}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AjukanPeminjamanPage(alat: item),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
