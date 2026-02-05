import 'package:flutter/material.dart';
import 'package:pinjam_alat/alat_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    fetchAlat();
  }

  Future<void> fetchAlat() async {
    setState(() => loading = true);

    final response = await supabase
        .from('alat')
        .select()
        .ilike('nama', '%$keyword%')
        .order('created_at', ascending: false);

    setState(() {
      alat = response;
      loading = false;
    });
  }

  // ================= DELETE DATA (FIX) =================
  Future<void> deleteAlat(String alatId) async {
    final response = await supabase
        .from('alat')
        .delete()
        .eq('alat_id', alatId) // 🔥 SESUAI PK TABEL
        .select();

    if (response.isEmpty) {
      throw 'Gagal menghapus data';
    }

    fetchAlat();
  }

  // ================= KONFIRMASI DELETE =================
  Future<void> confirmDelete(String alatId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah anda yakin ingin hapus produk ini?'),
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

    if (result == true) {
      try {
        await deleteAlat(alatId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil dihapus')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus produk')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Alat',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      // ================= TAMBAH DATA =================
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E4ED8),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlatFormPage()),
          );
          fetchAlat();
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) {
                keyword = val;
                fetchAlat();
              },
              decoration: InputDecoration(
                hintText: 'Cari Alat',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ================= LIST =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: alat.length,
                    itemBuilder: (context, index) {
                      final item = alat[index];
                      return _alatItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================= ITEM =================
  Widget _alatItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: item['gambar'] != null &&
                      item['gambar'].toString().isNotEmpty
                  ? NetworkImage(item['gambar'])
                  : null,
              child: item['gambar'] == null
                  ? const Icon(Icons.image_not_supported)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nama'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4ED8),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['jenis'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Denda / jam : Rp ${item['denda']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok : ${item['stok']} unit',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlatFormPage(alat: item),
                      ),
                    );
                    fetchAlat();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    confirmDelete(item['alat_id']); // 🔥 PASTI ILANG
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
