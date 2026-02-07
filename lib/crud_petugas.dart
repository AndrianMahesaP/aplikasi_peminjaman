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
  bool loading = true;

  Future<void> loadData() async {
    setState(() => loading = true);
    final res = await supabase.from('petugas').select().order('nama');
    setState(() {
      petugas = res;
      loading = false;
    });
  }

  Future<void> hapus(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Petugas'),
        content: const Text('Apakah Anda yakin ingin menghapus petugas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('petugas').delete().eq('petugas_id', id);
      loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Data Petugas', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E4ED8),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PetugasFormPage()),
          );
          loadData();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Petugas'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : petugas.isEmpty
              ? const Center(child: Text('Tidak ada data petugas'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: petugas.length,
                  itemBuilder: (c, i) {
                    final p = petugas[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E4ED8).withOpacity(0.1),
                          child: Text(
                            p['nama'][0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFF1E4ED8), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${p['username']}'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: p['role'] == 'Admin' ? Colors.purple.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p['role'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: p['role'] == 'Admin' ? Colors.purple : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PetugasFormPage(petugas: p)),
                                );
                                loadData();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
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