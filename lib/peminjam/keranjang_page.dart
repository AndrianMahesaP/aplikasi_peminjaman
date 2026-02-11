import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_provider.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final supabase = Supabase.instance.client;
  DateTime? tanggalPinjam;
  DateTime? tanggalKembali;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Keranjang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Dismissible(
                      key: Key(item.alatId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 28),
                      ),
                      onDismissed: (direction) {
                        cart.removeFromCart(item.alatId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.nama} dihapus dari keranjang'),
                            action: SnackBarAction(
                              label: 'Batal',
                              onPressed: () {
                                // Could implement undo here
                              },
                            ),
                          ),
                        );
                      },
                      child: _buildCartItem(item, cart),
                    );
                  },
                ),
              ),

              // Date Selection & Submit Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Summary
                    _buildSummary(cart),
                    const SizedBox(height: 16),

                    // Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTile(
                            'Tanggal Pinjam',
                            tanggalPinjam,
                            Icons.calendar_today,
                            () => _pilihTanggal(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTile(
                            'Tanggal Kembali',
                            tanggalKembali,
                            Icons.event_available,
                            () => _pilihTanggal(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: loading ? null : _submitPeminjaman,
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Ajukan Semua Peminjaman',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(dynamic item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              image: item.gambar != null
                  ? DecorationImage(
                      image: NetworkImage(item.gambar),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.gambar == null
                ? const Icon(Icons.build, color: Color(0xFF4F46E5), size: 30)
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.kategori,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stok: ${item.stok}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: const Color(0xFF4F46E5),
                  onPressed: () async {
                    await cart.updateQuantity(item.alatId, item.quantity - 1);
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: const Color(0xFF4F46E5),
                  onPressed: () async {
                    final success = await cart.updateQuantity(item.alatId, item.quantity + 1);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stok tidak mencukupi')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4F46E5).withOpacity(0.1),
            const Color(0xFF6366F1).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Item',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            '${cart.uniqueItemCount} jenis • ${cart.totalItems} unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: date != null ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? const Color(0xFF4F46E5) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: date != null ? const Color(0xFF4F46E5) : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date == null ? 'Pilih tanggal' : DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: date != null ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pilihTanggal(bool isPinjam) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPinjam) {
          tanggalPinjam = picked;
        } else {
          tanggalKembali = picked;
        }
      });
    }
  }

  Future<void> _submitPeminjaman() async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong')),
      );
      return;
    }

    if (tanggalPinjam == null || tanggalKembali == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal pinjam dan kembali terlebih dahulu')),
      );
      return;
    }

    if (tanggalKembali!.isBefore(tanggalPinjam!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal kembali harus setelah tanggal pinjam')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // Create single peminjaman record
      final peminjaman = await supabase.from('peminjaman').insert({
        'user_id': user.id,
        'alat_id': cart.items.first.alatId, // Use first item's ID for reference
        'tanggal_pinjam': DateFormat('yyyy-MM-dd').format(tanggalPinjam!),
        'tanggal_kembali': DateFormat('yyyy-MM-dd').format(tanggalKembali!),
        'status': 'menunggu',
      }).select().single();

      // Create multiple detail_peminjaman records
      final details = cart.items.map((item) => {
            'peminjaman_id': peminjaman['peminjaman_id'],
            'alat_id': item.alatId,
            'jumlah': item.quantity,
            'nama_alat': item.nama,
            'nama_kategori': item.kategori,
          }).toList();

      await supabase.from('detail_peminjaman').insert(details);

      // Clear cart
      await cart.clearCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua peminjaman berhasil diajukan!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Keranjang Kosong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan alat ke keranjang untuk meminjam',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
