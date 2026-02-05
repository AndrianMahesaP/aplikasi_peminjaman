import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'form_petugas.dart';

class PetugasPage extends StatefulWidget {
  const PetugasPage({super.key});

  @override
  State<PetugasPage> createState() => _PetugasPageState();
}

class _PetugasPageState extends State<PetugasPage> {
  final supabase = Supabase.instance.client;
  List petugas = [];

  Future<void> loadData() async {
    final res = await supabase.from('petugas').select().order('nama');
    setState(() => petugas = res);
  }

  Future<void> hapus(int id) async {
    await supabase.from('petugas').delete().eq('petugas_id', id);
    loadData();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Petugas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PetugasFormPage()),
          );
          loadData();
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: petugas.length,
        itemBuilder: (c, i) {
          final p = petugas[i];
          return Card(
            child: ListTile(
              title: Text(p['nama']),
              subtitle: Text('${p['username']} • ${p['role']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PetugasFormPage(petugas: p),
                        ),
                      );
                      loadData();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => hapus(p['petugas_id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
