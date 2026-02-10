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

  // --- Theme Colors (Disamakan dengan AlatPage) ---
  final Color primaryColor = const Color(0xFF4F46E5); // Indigo
  final Color secondaryColor = const Color(0xFF10B981); // Teal
  final Color bgColor = const Color(0xFFF3F4F6); // Soft Grey
  final Color warnColor = const Color(0xFFEF4444); // Red

  List petugas = [];
  bool loading = true;
  String keyword = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= LOGIC FETCH =================
  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      var query = supabase.from('petugas').select();

      if (keyword.isNotEmpty) {
        // Search by nama OR username
        query = query.or('nama.ilike.%$keyword%,username.ilike.%$keyword%');
      }

      final res = await query.order('nama');
      
      setState(() {
        petugas = res;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading: $e');
      setState(() => loading = false);
    }
  }

  // ================= LOGIC HAPUS =================
  Future<void> hapus(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Petugas?'),
        content: const Text('Data petugas bakal dibusak permanen.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: warnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('petugas').delete().eq('petugas_id', id);
        loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Petugas berhasil dihapus')),
          );
        }
      } catch (e) {
        debugPrint('Error delete: $e');
      }
    }
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Data Petugas',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 4,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PetugasFormPage()),
          );
          loadData();
        },
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Tambah Petugas', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              onChanged: (v) {
                keyword = v;
                loadData();
              },
              decoration: InputDecoration(
                hintText: 'Cari nama atau username...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- List Content ---
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : petugas.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: petugas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _buildPetugasCard(petugas[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Data petugas tidak ditemukan',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  // --- Modern Card Widget ---
  Widget _buildPetugasCard(dynamic p) {
    final String role = p['role'] ?? 'Petugas';
    final bool isAdmin = role.toLowerCase() == 'admin';

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
            // Edit shortcut yen diklik card-e
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PetugasFormPage(petugas: p)),
            );
            loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar Inisial
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    p['nama'][0].toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info Petugas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nama'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${p['username']}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    // Badge Role
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.purple.shade50 : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAdmin ? Colors.purple.shade100 : Colors.teal.shade100
                        )
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? Colors.purple : Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.grey.shade600),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PetugasFormPage(petugas: p)),
                      );
                      loadData();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade400),
                    onPressed: () => hapus(p['petugas_id']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}