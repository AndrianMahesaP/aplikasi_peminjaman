import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ==========================================
// MANAGEMENT PEMINJAMAN PAGE WITH CRUD
// ==========================================
class DetailBarangDipinjamPage extends StatefulWidget {
  const DetailBarangDipinjamPage({super.key});

  @override
  State<DetailBarangDipinjamPage> createState() => _DetailBarangDipinjamPageState();
}

class _DetailBarangDipinjamPageState extends State<DetailBarangDipinjamPage> {
  final supabase = Supabase.instance.client;

  Future<void> _showEditMenu(BuildContext context, String peminjamanId, DateTime currentDate) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Aksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_calendar, color: Color(0xFF1E4ED8)),
              title: const Text('Edit Tanggal Kembali'),
              onTap: () => Navigator.pop(context, 'edit_date'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Tambah Item'),
              onTap: () => Navigator.pop(context, 'add_item'),
            ),
          ],
        ),
      ),
    );

    if (result == 'edit_date' && mounted) {
      await _editReturnDate(peminjamanId, currentDate);
    } else if (result == 'add_item' && mounted) {
      await _addItemToBorrowing(peminjamanId);
    }
  }

  Future<void> _editReturnDate(String peminjamanId, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E4ED8)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      try {
        await supabase.from('peminjaman').update({
          'tanggal_kembali': DateFormat('yyyy-MM-dd').format(picked),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('peminjaman_id', peminjamanId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tanggal kembali berhasil diubah'), backgroundColor: Colors.green),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  Future<void> _addItemToBorrowing(String peminjamanId) async {
    final alat = await supabase.from('alat').select('*').gt('stok', 0);
    
    if (!mounted) return;
    
    if (alat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada alat tersedia')));
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddItemDialog(alatList: alat),
    );

    if (selected != null && mounted) {
      try {
        await supabase.from('detail_peminjaman').insert({
          'peminjaman_id': peminjamanId,
          'alat_id': selected['alat_id'],
          'jumlah': selected['jumlah'],
          'nama_alat': selected['nama'],
          'nama_kategori': selected['jenis'] ?? '',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item berhasil ditambahkan'), backgroundColor: Colors.green),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Kelola Peminjaman", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(000000),
        elevation: 0,
      ),
      body: FutureBuilder(
        future: supabase
            .from('peminjaman')
            .select('*, detail_peminjaman(*, alat:alat_id(nama, gambar)), users:user_id(email)')
            .eq('status', 'disetujui')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E4ED8)),
              ),
            );
          }
          
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada peminjaman aktif",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final List data = snapshot.data as List;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final user = item['users'] ?? {'email': 'Unknown'};
              final details = item['detail_peminjaman'] as List? ?? [];
              final tglKembali = DateTime.parse(item['tanggal_kembali']).toLocal();
              // Compare dates only: overdue if return date is BEFORE today (not including today)
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              final returnDate = DateTime(tglKembali.year, tglKembali.month, tglKembali.day);
              final isOverdue = returnDate.isBefore(todayDate);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPeminjamanPage(
                        peminjamanId: item['peminjaman_id'],
                        userName: user['email'].split('@')[0],
                        tglKembali: tglKembali,
                        details: details,
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
                      width: isOverdue ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header dengan solid Indigo background
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOverdue 
                            ? Colors.red.shade600
                            : const Color(0xFF4F46E5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(user['email'].split('@')[0]),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['email'].split('@')[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.mail_outline, size: 14, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          user['email'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOverdue ? 'Terlambat' : 'Aktif',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Info cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    Icons.inventory_2_outlined,
                                    '${details.length} Item',
                                    const Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoCard(
                                    Icons.calendar_today_outlined,
                                    DateFormat('dd MMM yyyy').format(tglKembali),
                                    isOverdue ? Colors.red.shade600 : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Item preview dengan gambar
                            if (details.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      // Preview image
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          image: details[0]['alat'] != null &&
                                                  details[0]['alat']['gambar'] != null &&
                                                  details[0]['alat']['gambar'] != ''
                                              ? DecorationImage(
                                                  image: NetworkImage(details[0]['alat']['gambar']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: (details[0]['alat'] == null ||
                                                details[0]['alat']['gambar'] == null ||
                                                details[0]['alat']['gambar'] == '')
                                            ? Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              details[0]['alat']?['nama'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (details.length > 1)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  '+${details.length - 1} item lainnya',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      
                                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildInfoCard(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ==========================================
// DIALOG TAMBAH ITEM
// ==========================================
class AddItemDialog extends StatefulWidget {
  final List alatList;
  const AddItemDialog({super.key, required this.alatList});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  Map<String, dynamic>? selectedAlat;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Item'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: const InputDecoration(labelText: 'Pilih Alat', border: OutlineInputBorder()),
              value: selectedAlat,
              items: widget.alatList.map<DropdownMenuItem<Map<String, dynamic>>>((alat) {
                return DropdownMenuItem<Map<String, dynamic>>(value: alat, child: Text('${alat['nama']} (Stok: ${alat['stok']})'));
              }).toList(),
              onChanged: (value) => setState(() => selectedAlat = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              initialValue: '1',
              onChanged: (value) => quantity = int.tryParse(value) ?? 1,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E4ED8)),
          onPressed: () {
            if (selectedAlat != null && quantity > 0) {
              Navigator.pop(context, {...selectedAlat!, 'jumlah': quantity});
            }
          },
          child: const Text('Tambah', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ==========================================
// DETAIL PEMINJAMAN PAGE
// ==========================================
class DetailPeminjamanPage extends StatefulWidget {
  final String peminjamanId;
  final String userName;
  final DateTime tglKembali;
  final List details;

  const DetailPeminjamanPage({
    super.key,
    required this.peminjamanId,
    required this.userName,
    required this.tglKembali,
    required this.details,
  });

  @override
  State<DetailPeminjamanPage> createState() => _DetailPeminjamanPageState();
}

class _DetailPeminjamanPageState extends State<DetailPeminjamanPage> {
  final supabase = Supabase.instance.client;

  Future<void> _editReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.tglKembali,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E4ED8)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      try {
        await supabase.from('peminjaman').update({
          'tanggal_kembali': DateFormat('yyyy-MM-dd').format(picked),
        }).eq('peminjaman_id', widget.peminjamanId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tanggal berhasil diubah'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  Future<void> _addItem() async {
    final alat = await supabase.from('alat').select('*').gt('stok', 0);
    
    if (!mounted) return;
    
    if (alat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada alat')));
      return;
    }

    // Filter out items that are already borrowed
    final borrowedIds = widget.details.map((d) => d['alat']?['alat_id']).where((id) => id != null).toSet();
    final availableAlat = alat.where((a) => !borrowedIds.contains(a['alat_id'])).toList();

    if (availableAlat.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua alat sudah ada di peminjaman ini')),
        );
      }
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddItemDialog(alatList: availableAlat),
    );

    if (selected != null && mounted) {
      try {
        await supabase.from('detail_peminjaman').insert({
          'peminjaman_id': widget.peminjamanId,
          'alat_id': selected['alat_id'],
          'jumlah': selected['jumlah'],
          'nama_alat': selected['nama'],
          'nama_kategori': selected['jenis'] ?? '',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item ditambahkan'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compare dates only: overdue if return date is BEFORE today (not including today)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final returnDate = DateTime(widget.tglKembali.year, widget.tglKembali.month, widget.tglKembali.day);
    final isOverdue = returnDate.isBefore(todayDate);
    final daysRemaining = returnDate.difference(todayDate).inDays;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Simple AppBar dengan solid color
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF4F46E5),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(widget.userName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${widget.details.length} Item Dipinjam',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards dengan design lebih modern
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernInfoCard(
                          Icons.calendar_today_rounded,
                          'Tanggal Kembali',
                          DateFormat('dd MMM yyyy').format(widget.tglKembali),
                          isOverdue ? Colors.red.shade600 : const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernInfoCard(
                          isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                          isOverdue ? 'Terlambat' : 'Sisa Waktu',
                          isOverdue ? '${-daysRemaining} hari' : '$daysRemaining hari',
                          isOverdue ? Colors.red.shade600 : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Daftar Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Item list dengan design card modern
                  ...widget.details.asMap().entries.map((entry) {
                    final index = entry.key;
                    final detail = entry.value;
                    final alat = detail['alat'] ?? {};
                    
                    return TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Image with premium styling
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey.shade100, Colors.grey.shade200],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: (alat['gambar'] != null && alat['gambar'].toString().isNotEmpty)
                                      ? Image.network(
                                          alat['gambar'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 32);
                                          },
                                        )
                                      : Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 32),
                                ),
                              ),
                              const SizedBox(width: 14),
                              
                              // Item info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alat['nama'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.straighten, size: 14, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Qty: ${detail['jumlah']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 100), // Space for FABs
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Modern floating action buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Edit date button
          FloatingActionButton.extended(
            onPressed: _editReturnDate,
            heroTag: 'edit_date',
            backgroundColor: Colors.white,
            elevation: 4,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_calendar, color: Colors.white, size: 20),
            ),
            label: const Text(
              'Edit Tanggal',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Add item button
          FloatingActionButton.extended(
            onPressed: _addItem,
            heroTag: 'add_item',
            backgroundColor: const Color(0xFF14B8A6),
            elevation: 4,
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text(
              'Tambah Item',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
