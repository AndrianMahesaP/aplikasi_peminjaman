import 'dart:convert';

class CartItem {
  final String alatId;
  final String nama;
  final String kategori;
  final String? gambar;
  final int stok;
  final int denda;
  int quantity;

  CartItem({
    required this.alatId,
    required this.nama,
    required this.kategori,
    this.gambar,
    required this.stok,
    required this.denda,
    this.quantity = 1,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'alat_id': alatId,
        'nama': nama,
        'kategori': kategori,
        'gambar': gambar,
        'stok': stok,
        'denda': denda,
        'quantity': quantity,
      };

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        alatId: json['alat_id'],
        nama: json['nama'],
        kategori: json['kategori'],
        gambar: json['gambar'],
        stok: json['stok'],
        denda: json['denda'],
        quantity: json['quantity'],
      );

  // Create from alat data
  factory CartItem.fromAlat(Map<String, dynamic> alat) => CartItem(
        alatId: alat['alat_id'],
        nama: alat['nama'] ?? 'Unknown',
        kategori: alat['jenis'] ?? 'Unknown',
        gambar: alat['gambar'],
        stok: alat['stok'] ?? 0,
        denda: alat['denda'] ?? 0,
        quantity: 1,
      );
}
