import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'alat_form.dart';

class AlatPage extends StatefulWidget {
  const AlatPage({super.key});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  final supabase = Supabase.instance.client;

  List alat = [];
  bool loading = true;

  String keyword = '';
  String selectedKategori = 'Semua';

 // Ganti deklarasi list sing lawas
List<String> kategoriList = ['Semua', 'Lainnya']; // Default minimal

@override
void initState() {
  super.initState();
  fetchKategori(); // Tambah fungsi iki
  fetchAlat();
}

// Tambah fungsi fetch kategori
Future<void> fetchKategori() async {
  try {
    final res = await supabase.from('kategori').select('nama').order('nama');
    final List<String> loaded = res.map<String>((e) => e['nama'] as String).toList();
    
    setState(() {
      // Gabungne 'Semua' + data seko DB + 'Lainnya' (opsional logika urutane)
      kategoriList = ['Semua', ...loaded];
      if (!kategoriList.contains('Lainnya')) kategoriList.add('Lainnya');
    });
  } catch (e) {
    debugPrint('Error fetch kategori: $e');
  }
}

  // ================= FETCH =================
  Future<void> fetchAlat() async {
    setState(() => loading = true);

    try {
      var query = supabase.from('alat').select();

      if (keyword.isNotEmpty) {
        query = query.ilike('nama', '%$keyword%');
      }

      if (selectedKategori != 'Semua') {
        query = query.eq('jenis', selectedKategori);
      }

      final res = await query.order('created_at', ascending: false);

      debugPrint('FETCH ALAT: ${res.length} data');

      setState(() {
        alat = res;
        loading = false;
      });
    } catch (e) {
      debugPrint('ERROR FETCH: $e');
      setState(() => loading = false);
    }
  }

  // ================= DELETE ALAT =================
  Future<void> confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alat?'),
        content: const Text('Data tidak bisa dikembalikan'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final res = await supabase
            .from('alat')
            .delete()
            .eq('alat_id', id)
            .select();

        debugPrint('DELETE ALAT: $res');

        fetchAlat();
      } catch (e) {
        debugPrint('ERROR DELETE ALAT: $e');
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Daftar Alat'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E4ED8),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
  builder: (_) => AlatFormPage(
    kategoriList: kategoriList,
  ),
),

          );
          fetchAlat();
        },
      ),
      body: Column(
        children: [
          // ================= SEARCH & FILTER =================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    keyword = v;
                    fetchAlat();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama alat...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: kategoriList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final k = kategoriList[i];
                            return _filterChip(k, k == selectedKategori);
                          },
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) {
                        if (v == 'tambah') _tambahKategori();
                        if (v == 'edit') _editKategori();
                        if (v == 'hapus') _hapusKategori();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'tambah',
                          child: ListTile(
                            leading: Icon(Icons.add),
                            title: Text('Tambah Kategori'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit Kategori'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'hapus',
                          child: ListTile(
                            leading:
                                Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Hapus Kategori',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : alat.isEmpty
                    ? const Center(child: Text('Data tidak ditemukan'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: alat.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _alatCard(alat[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // ================= FILTER CHIP =================
  Widget _filterChip(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedKategori = label);
        fetchAlat();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E4ED8) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF1E4ED8)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ================= CARD ALAT =================
  Widget _alatCard(dynamic item) {
    final String gambar = item['gambar'] ?? '';
    final int stok = item['stok'] ?? 0;
    final int denda = item['denda'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: gambar.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(gambar),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp $denda /jam',
                  style:
                      const TextStyle(color: Color(0xFF1E4ED8)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stok: $stok',
                  style: TextStyle(
                      color: stok > 0 ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlatFormPage(
  alat: item,
  kategoriList: kategoriList,
),

                    ),
                  );
                  fetchAlat();
                },
              ),
              IconButton(
                icon:
                    const Icon(Icons.delete, color: Colors.red),
                onPressed: () =>
                    confirmDelete(item['alat_id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= KATEGORI =================
 void _tambahKategori() {
  final c = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Tambah Kategori'),
      content: TextField(
        controller: c,
        decoration: const InputDecoration(hintText: 'Jeneng Kategori'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            if (c.text.trim().isEmpty) return;
            final namaBaru = c.text.trim();

            try {
              // 1. Simpen neng Supabase
              await supabase.from('kategori').insert({'nama': namaBaru});

              // 2. Update UI
              setState(() {
                 // Selipne sakdurunge 'Lainnya' utawa neng mburi
                 kategoriList.insert(kategoriList.length - 1, namaBaru);
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kategori berhasil disimpan!')),
              );
            } catch (e) {
              debugPrint('Gagal nambah: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal: $e')),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

 void _editKategori() {
  if (selectedKategori == 'Semua' || selectedKategori == 'Lainnya') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kategori iki ora bisa diedit!')),
    );
    return;
  }

  final c = TextEditingController(text: selectedKategori);
  final namaLawas = selectedKategori;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit Kategori'),
      content: TextField(controller: c),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            final namaBaru = c.text.trim();
            if (namaBaru.isEmpty) return;

            try {
              // 1. Update Jeneng neng Tabel Kategori
              await supabase
                  .from('kategori')
                  .update({'nama': namaBaru})
                  .eq('nama', namaLawas);

              // 2. Update Jeneng neng Tabel Alat (relasi text)
              // Ben alat sing nganggo kategori lawas melu ganti jeneng
              await supabase
                  .from('alat')
                  .update({'jenis': namaBaru})
                  .eq('jenis', namaLawas);

              // 3. Update UI Lokal
              final index = kategoriList.indexOf(namaLawas);
              setState(() {
                kategoriList[index] = namaBaru;
                selectedKategori = namaBaru; // Ganti seleksi ke jeneng anyar
              });

              Navigator.pop(context);
              fetchAlat(); // Refresh list alat
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kategori sukses diupdate!')),
              );
            } catch (e) {
              debugPrint('Error edit: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal edit: $e')),
              );
            }
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}

  void _hapusKategori() {
  // 1. Cek ben ana reaksine
  if (selectedKategori == 'Semua' || selectedKategori == 'Lainnya') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kategori iki ora bisa dihapus!')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Hapus Kategori'),
      content: Text(
          'Yakin hapus "$selectedKategori"?\nSemua alat bakal pindah ke "Lainnya".'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            try {
              // 1. Pindah alat ke 'Lainnya'
              await supabase
                  .from('alat')
                  .update({'jenis': 'Lainnya'})
                  .eq('jenis', selectedKategori);

              // 2. Hapus seko tabel Kategori
              await supabase
                  .from('kategori')
                  .delete()
                  .eq('nama', selectedKategori);

              // 3. Update UI
              setState(() {
                kategoriList.remove(selectedKategori);
                selectedKategori = 'Semua'; // Balik ke default
              });

              Navigator.pop(context);
              fetchAlat();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kategori wis dihapus')),
              );
            } catch (e) {
              debugPrint('Error hapus: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal hapus: $e')),
              );
            }
          },
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}
}