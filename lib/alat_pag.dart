import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'alat_form.dart'; // Pastikne file iki ana

class AlatPage extends StatefulWidget {
  const AlatPage({super.key});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  final supabase = Supabase.instance.client;

  // --- Theme Colors ---
  final Color primaryColor = const Color(0xFF4F46E5); // Indigo
  final Color secondaryColor = const Color(0xFF10B981); // Teal
  final Color bgColor = const Color(0xFFF3F4F6); // Soft Grey
  final Color warnColor = const Color(0xFFEF4444); // Red

  List alat = [];
  bool loading = true;
  String keyword = '';
  String selectedKategori = 'Semua';

  List<String> kategoriList = ['Semua', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    fetchKategori();
    fetchAlat();
  }

  // ================= LOGIC KATEGORI (TETEP SAMA) =================
  Future<void> fetchKategori() async {
    try {
      final res =
          await supabase.from('kategori').select('nama').order('nama');
      final List<String> loaded =
          res.map<String>((e) => e['nama'] as String).toList();

      setState(() {
        kategoriList = ['Semua', ...loaded];
        if (!kategoriList.contains('Lainnya')) kategoriList.add('Lainnya');
      });
    } catch (e) {
      debugPrint('Error fetch kategori: $e');
    }
  }

  // ================= LOGIC ALAT (TETEP SAMA) =================
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
      setState(() {
        alat = res;
        loading = false;
      });
    } catch (e) {
      debugPrint('ERROR FETCH: $e');
      setState(() => loading = false);
    }
  }

  Future<void> confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alat?'),
        content: const Text('Data bakal ilang permanen.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: warnColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await supabase.from('alat').delete().eq('alat_id', id);
        fetchAlat();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alat berhasil dihapus')));
      } catch (e) {
        debugPrint('ERROR DELETE: $e');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Inventory Alat',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings, color: primaryColor),
            tooltip: 'Atur Kategori',
            onSelected: (v) {
              if (v == 'tambah') _tambahKategori();
              if (v == 'edit') _editKategori();
              if (v == 'hapus') _hapusKategori();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'tambah',
                child: ListTile(
                  leading: Icon(Icons.add_circle_outline, color: Colors.blue),
                  title: Text('Tambah Kategori'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_note, color: Colors.orange),
                  title: Text('Edit Kategori'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'hapus',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep, color: Colors.red),
                  title: Text('Hapus Kategori'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 4,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AlatFormPage(kategoriList: kategoriList)),
          );
          fetchAlat();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Alat', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildHeaderSearch(),
          _buildFilterList(),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : alat.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: alat.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _alatCard(alat[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // --- Header Search Bar ---
  Widget _buildHeaderSearch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: TextField(
        onChanged: (v) {
          keyword = v;
          fetchAlat();
        },
        decoration: InputDecoration(
          hintText: 'Cari nama alat...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          filled: true,
          fillColor: bgColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- Filter Horizontal ---
  Widget _buildFilterList() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: kategoriList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final k = kategoriList[i];
          final isActive = k == selectedKategori;
          return ChoiceChip(
            label: Text(k),
            selected: isActive,
            selectedColor: primaryColor.withOpacity(0.1),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isActive ? primaryColor : Colors.grey.shade300,
            ),
            labelStyle: TextStyle(
              color: isActive ? primaryColor : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) {
              setState(() => selectedKategori = k);
              fetchAlat();
            },
          );
        },
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada data alat',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --- Card Item Modern ---
  Widget _alatCard(dynamic item) {
    final String gambar = item['gambar'] ?? '';
    final int stok = item['stok'] ?? 0;
    final int denda = item['denda'] ?? 0;
    final bool isAvailable = stok > 0;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
            // Opsional: Detail Page yen perlu
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar
              Hero(
                tag: item['alat_id'],
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                    image: gambar.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(gambar),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: gambar.isEmpty
                      ? Icon(Icons.image_not_supported,
                          color: Colors.grey.shade400)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Denda: Rp $denda /jam',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: isAvailable ? secondaryColor : warnColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable ? 'Stok: $stok' : 'Habis',
                          style: TextStyle(
                            color: isAvailable ? secondaryColor : warnColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.grey.shade600),
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
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: Colors.grey.shade400),
                    onPressed: () => confirmDelete(item['alat_id']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DIALOGS KATEGORI (MODERNIZED) =================
  void _tambahKategori() {
    final c = TextEditingController();
    _showCategoryDialog(
      title: 'Tambah Kategori',
      controller: c,
      btnText: 'Simpan',
      onConfirm: () async {
        if (c.text.trim().isEmpty) return;
        final namaBaru = c.text.trim();
        try {
          await supabase.from('kategori').insert({'nama': namaBaru});
          setState(() {
            kategoriList.insert(kategoriList.length - 1, namaBaru);
          });
          if (mounted) Navigator.pop(context);
          _showSnack('Kategori berhasil disimpan!', true);
        } catch (e) {
          _showSnack('Gagal: $e', false);
        }
      },
    );
  }

  void _editKategori() {
    if (selectedKategori == 'Semua' || selectedKategori == 'Lainnya') {
      _showSnack('Kategori ini sistem (tidak bisa diedit)', false);
      return;
    }
    final c = TextEditingController(text: selectedKategori);
    final namaLawas = selectedKategori;

    _showCategoryDialog(
      title: 'Edit Kategori',
      controller: c,
      btnText: 'Update',
      onConfirm: () async {
        final namaBaru = c.text.trim();
        if (namaBaru.isEmpty) return;
        try {
          await supabase
              .from('kategori')
              .update({'nama': namaBaru}).eq('nama', namaLawas);
          await supabase
              .from('alat')
              .update({'jenis': namaBaru}).eq('jenis', namaLawas);

          final index = kategoriList.indexOf(namaLawas);
          setState(() {
            kategoriList[index] = namaBaru;
            selectedKategori = namaBaru;
          });
          if (mounted) Navigator.pop(context);
          fetchAlat();
          _showSnack('Kategori diupdate!', true);
        } catch (e) {
          _showSnack('Gagal edit: $e', false);
        }
      },
    );
  }

  void _hapusKategori() {
    if (selectedKategori == 'Semua' || selectedKategori == 'Lainnya') {
      _showSnack('Kategori ini sistem (tidak bisa dihapus)', false);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
            'Hapus "$selectedKategori"?\nSemua alat kategori ini akan pindah ke "Lainnya".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: warnColor),
            onPressed: () async {
              try {
                await supabase
                    .from('alat')
                    .update({'jenis': 'Lainnya'}).eq('jenis', selectedKategori);
                await supabase
                    .from('kategori')
                    .delete()
                    .eq('nama', selectedKategori);

                setState(() {
                  kategoriList.remove(selectedKategori);
                  selectedKategori = 'Semua';
                });
                if (mounted) Navigator.pop(context);
                fetchAlat();
                _showSnack('Kategori dihapus', true);
              } catch (e) {
                _showSnack('Gagal hapus: $e', false);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: Dialog Input ---
  void _showCategoryDialog({
    required String title,
    required TextEditingController controller,
    required String btnText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: bgColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onConfirm,
            child: Text(btnText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? secondaryColor : warnColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}