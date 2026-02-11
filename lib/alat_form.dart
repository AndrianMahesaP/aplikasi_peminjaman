import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatFormPage extends StatefulWidget {
  final dynamic alat;
  final List<String> kategoriList;

  const AlatFormPage({
    super.key,
    this.alat,
    required this.kategoriList,
  });

  @override
  State<AlatFormPage> createState() => _AlatFormPageState();
}


class _AlatFormPageState extends State<AlatFormPage> {
  final supabase = Supabase.instance.client;

  final namaController = TextEditingController();
  final dendaController = TextEditingController();
  final stokController = TextEditingController();

  String? jenisAlat;
  Uint8List? imageBytes;
  String? imageUrl;

  bool loading = false;

  late List<String> jenisList;

 @override
void initState() {
  super.initState();

  // 🔥 ambil kategori dari parent
  jenisList = List.from(widget.kategoriList)..removeWhere((element) => element == 'Semua');

  if (widget.alat != null) {
    namaController.text = widget.alat['nama'] ?? '';
    dendaController.text = widget.alat['denda'].toString();
    stokController.text = widget.alat['stok'].toString();
    jenisAlat = widget.alat['jenis'];
    imageUrl = widget.alat['gambar'];

    if (jenisAlat != null && !jenisList.contains(jenisAlat)) {
      jenisList.add(jenisAlat!);
    }
  } else {
    stokController.text = '1';
  }
}

  Future<void> pilihGambar() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => imageBytes = bytes);
  }

  Future<String?> uploadGambar() async {
    if (imageBytes == null) return imageUrl;

    final fileName = 'alat_${DateTime.now().millisecondsSinceEpoch}.png';

    await supabase.storage.from('alat').uploadBinary(
          fileName,
          imageBytes!,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

    return supabase.storage.from('alat').getPublicUrl(fileName);
  }

  // ================= SAVE =================
  Future<void> simpan() async {
    if (namaController.text.isEmpty ||
        dendaController.text.isEmpty ||
        stokController.text.isEmpty ||
        jenisAlat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final gambar = await uploadGambar();

      final data = {
        'nama': namaController.text,
        'jenis': jenisAlat,
        'denda': int.parse(dendaController.text),
        'stok': int.parse(stokController.text),
        'gambar': gambar,
      };

      if (widget.alat == null) {
        await supabase.from('alat').insert(data);
      } else {
        await supabase
            .from('alat')
            .update(data)
            .eq('alat_id', widget.alat['alat_id']);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      setState(() => loading = false);
    }
  }



  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Soft Grey
      appBar: AppBar(
        title: Text(
          widget.alat == null ? 'Tambah Alat Baru' : 'Edit Alat',
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: loading ? null : simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5), // Indigo
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'SIMPAN DATA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card Container for Form
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   /// ====== FIX GAMBAR (AMAN ERROR) ======
                  GestureDetector(
                    onTap: pilihGambar,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Builder(
                          builder: (_) {
                            if (imageBytes != null) {
                              return Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            }

                            if (imageUrl != null && imageUrl!.isNotEmpty) {
                              return Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: Text('Gagal memuat gambar')),
                              );
                            }

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 40, color: Colors.indigo.shade200),
                                const SizedBox(height: 8),
                                Text('Ketuk untuk upload gambar',
                                    style:
                                        TextStyle(color: Colors.grey.shade500)),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Utama',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      _buildLabel('Nama Alat'),
                      _buildTextField(
                          controller: namaController,
                          hint: 'Contoh: Bola Voli'),

                      const SizedBox(height: 20),

                      _buildLabel('Kategori'),
                      _buildDropdown(),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Denda / Hari'),
                                _buildTextField(
                                  controller: dendaController,
                                  hint: '0',
                                  isNumber: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _buildLabel('Stok'),
                                _buildTextField(
                                  controller: stokController,
                                  hint: '0',
                                  isNumber: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMPONENT =================
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

 Widget _buildDropdown() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: jenisList.contains(jenisAlat) ? jenisAlat : null,
        hint: const Text('Pilih Kategori'),
        isExpanded: true,
        items: jenisList
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => jenisAlat = v),
      ),
    ),
  );
}
}