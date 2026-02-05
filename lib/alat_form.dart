import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatFormPage extends StatefulWidget {
  final dynamic alat;
  const AlatFormPage({super.key, this.alat});

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

  final jenisList = ['Bola Sepak', 'Bola Voli', 'Bola Basket'];

  @override
  void initState() {
    super.initState();
    if (widget.alat != null) {
      namaController.text = widget.alat['nama'];
      dendaController.text = widget.alat['denda'].toString();
      stokController.text = widget.alat['stok'].toString();
      jenisAlat = widget.alat['jenis'];
      imageUrl = widget.alat['gambar'];
    } else {
      stokController.text = '0';
    }
  }

  Future<void> pilihGambar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => imageBytes = bytes);
  }

  Future<String?> uploadGambar() async {
    if (imageBytes == null) return imageUrl;

    final fileName =
        'alat_${DateTime.now().millisecondsSinceEpoch}.png';

    await supabase.storage.from('alat').uploadBinary(
          fileName,
          imageBytes!,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

    return supabase.storage.from('alat').getPublicUrl(fileName);
  }

  Future<void> simpan() async {
    if (namaController.text.isEmpty ||
        dendaController.text.isEmpty ||
        stokController.text.isEmpty ||
        jenisAlat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data belum lengkap')),
      );
      return;
    }

    try {
      setState(() => loading = true);

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
      setState(() => loading = false);
      Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.alat == null ? 'Tambah Alat' : 'Edit Alat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // GAMBAR
            GestureDetector(
              onTap: pilihGambar,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : imageUrl != null
                        ? Image.network(imageUrl!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.cloud_upload, size: 40),
                          ),
              ),
            ),
            const SizedBox(height: 20),

            _input(namaController, 'Nama Alat'),

            DropdownButtonFormField<String>(
              value: jenisAlat,
              items: jenisList
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => jenisAlat = v),
              decoration: InputDecoration(
                hintText: 'Jenis Alat',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _input(dendaController, 'Denda per Jam', number: true),

            const SizedBox(height: 16),

            // STOK
            Row(
              children: [
                const Text(
                  'Stok Alat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    int stok = int.parse(stokController.text);
                    if (stok > 0) stok--;
                    stokController.text = stok.toString();
                    setState(() {});
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                ),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: stokController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    int stok = int.parse(stokController.text);
                    stok++;
                    stokController.text = stok.toString();
                    setState(() {});
                  },
                  icon:
                      const Icon(Icons.add_circle, color: Colors.green),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : simpan,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SIMPAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
