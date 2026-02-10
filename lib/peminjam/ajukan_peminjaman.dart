import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AjukanPeminjamanPage extends StatefulWidget {
  final dynamic alat;
  const AjukanPeminjamanPage({super.key, required this.alat});

  @override
  State<AjukanPeminjamanPage> createState() => _AjukanPeminjamanPageState();
}

class _AjukanPeminjamanPageState extends State<AjukanPeminjamanPage> {
  final supabase = Supabase.instance.client;
  DateTime? tglPinjam;
  DateTime? tglKembali;
  bool loading = false;
  String? namaKategoriReal; // Untuk menyimpan nama kategori asli dari DB
  int jumlahPinjam = 1;

  @override
  void initState() {
    super.initState();
    _ambilDataKategori();
  }

 Future<void> _ambilDataKategori() async {
  try {
    // Gunakan sintaks join tabel yang paling stabil
    final res = await supabase
        .from('alat')
        .select('nama, kategori :kategori (nama)') 
        .eq('alat_id', widget.alat['alat_id'])
        .single();

    if (res['kategori'] != null) {
      setState(() {
        namaKategoriReal = res['kategori']['nama'].toString();
      });
    }
  } catch (e) {
    debugPrint('Error detail: $e');
    setState(() {
      namaKategoriReal = 'Kategori Tidak Ditemukan';
    });
  }
}



  Future<void> simpanPeminjaman() async {
    final user = supabase.auth.currentUser;
    if (user == null || tglPinjam == null || tglKembali == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi tanggal terlebih dahulu!')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 1. Cek stok terbaru
      final resAlat = await supabase
          .from('alat')
          .select('stok')
          .eq('alat_id', widget.alat['alat_id'])
          .single();

      int stokTersedia = resAlat['stok'] ?? 0;
      if (stokTersedia < jumlahPinjam) throw 'Stok tidak mencukupi!';

      // 2. Insert Peminjaman
      final peminjaman = await supabase.from('peminjaman').insert({
        'user_id': user.id,
        'alat_id': widget.alat['alat_id'],
        'tanggal_pinjam': DateFormat('yyyy-MM-dd').format(tglPinjam!),
        'tanggal_kembali': DateFormat('yyyy-MM-dd').format(tglKembali!),
        'status': 'menunggu',
      }).select().single();

      // 3. Insert Detail Peminjaman (Data Nama & Kategori Paten)
      await supabase.from('detail_peminjaman').insert({
        'peminjaman_id': peminjaman['peminjaman_id'],
        'alat_id': widget.alat['alat_id'],
        'jumlah': jumlahPinjam,
        'nama_alat': widget.alat['nama'] ?? 'Alat',
        'nama_kategori': namaKategoriReal ?? '',
      });

      // 4. Update Stok
      await supabase
          .from('alat')
          .update({'stok': stokTersedia - jumlahPinjam})
          .eq('alat_id', widget.alat['alat_id']);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil diajukan!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Peminjaman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // STRUK VALIDASI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  _itemStruk("Nama Alat", widget.alat['nama'] ?? "-"),
                  _itemStruk("Kategori", namaKategoriReal ?? "Memuat..."),
                  const Divider(height: 30),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jumlah Pinjam", style: TextStyle(color: Colors.black54)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() { if(jumlahPinjam > 1) jumlahPinjam--; }),
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                          ),
                          Text("$jumlahPinjam", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () => setState(() => jumlahPinjam++),
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // PICKER TANGGAL
            _buildDateTile("Mulai Pinjam", tglPinjam, (d) => setState(() => tglPinjam = d)),
            const SizedBox(height: 10),
            _buildDateTile("Kembali", tglKembali, (d) => setState(() => tglKembali = d)),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : simpanPeminjaman,
                child: loading ? const CircularProgressIndicator() : const Text("KONFIRMASI PINJAM"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _itemStruk(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, Function(DateTime) onPick) {
    return ListTile(
      tileColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(label),
      subtitle: Text(date == null ? "Pilih Tanggal" : DateFormat('dd MMM yyyy').format(date)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
        if (d != null) onPick(d);
      },
    );
  }
}