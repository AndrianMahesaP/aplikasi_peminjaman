import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfService {
  /// Generate PDF struk peminjaman
  static Future<Uint8List> generateStrukPeminjaman({
    required Map<String, dynamic> peminjaman,
  }) async {
    final pdf = pw.Document();

    // Extract data
    final user = peminjaman['users'] ?? {};
    final userName = user['email']?.toString().split('@')[0] ?? 'Unknown';
    final userEmail = user['email'] ?? 'Unknown';
    final peminjamanId = peminjaman['peminjaman_id'] ?? '';
    final details = peminjaman['detail_peminjaman'] as List? ?? [];
    final tanggalPinjam = peminjaman['tanggal_pinjam'] ?? '';
    final tanggalKembali = peminjaman['tanggal_kembali'] ?? '';
    final createdAt = peminjaman['created_at'] ?? DateTime.now().toIso8601String();

    // Format tanggal
    final formatTanggal = (String iso) {
      try {
        final date = DateTime.parse(iso);
        return DateFormat('dd MMMM yyyy').format(date);
      } catch (e) {
        return iso;
      }
    };

    // Build PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(peminjamanId, createdAt),
              pw.SizedBox(height: 30),

              // User Info
              _buildUserInfo(userName, userEmail),
              pw.SizedBox(height: 20),

              // Items Table
              _buildItemsTable(details),
              pw.SizedBox(height: 25),

              // Dates Info
              _buildDatesInfo(formatTanggal(tanggalPinjam), formatTanggal(tanggalKembali)),
              pw.SizedBox(height: 30),

              // Footer
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build header section
  static pw.Widget _buildHeader(String peminjamanId, String createdAt) {
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(createdAt));
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STRUK PEMINJAMAN ALAT LABORATORIUM',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('No. Peminjaman', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    peminjamanId.length > 20 ? '${peminjamanId.substring(0, 20)}...' : peminjamanId,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Tanggal Cetak', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.SizedBox(height: 3),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build user info section
  static pw.Widget _buildUserInfo(String userName, String userEmail) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PEMINJAM',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Nama', userName),
          pw.SizedBox(height: 6),
          _buildInfoRow('Email', userEmail),
        ],
      ),
    );
  }

  /// Build info row helper
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 10)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(List<dynamic> details) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DAFTAR ALAT',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('No', isHeader: true, alignment: pw.Alignment.center),
                _buildTableCell('Nama Alat', isHeader: true),
                _buildTableCell('Jumlah', isHeader: true, alignment: pw.Alignment.center),
              ],
            ),
            // Data rows
            ...details.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final alat = item['alat'] ?? {};
              final namaAlat = alat['nama'] ?? 'Unknown';
              final jumlah = item['jumlah'] ?? 0;

              return pw.TableRow(
                children: [
                  _buildTableCell('${index + 1}', alignment: pw.Alignment.center),
                  _buildTableCell(namaAlat),
                  _buildTableCell('$jumlah', alignment: pw.Alignment.center),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /// Build table cell helper
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build dates info
  static pw.Widget _buildDatesInfo(String tanggalPinjam, String tanggalKembali) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TANGGAL PINJAM',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                tanggalPinjam,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.Container(width: 1, height: 30, color: PdfColors.grey400),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TANGGAL KEMBALI',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                tanggalKembali,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 15),
        
        // Signature area
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Petugas', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 40),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700)),
                  ),
                  padding: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text(
                    '(                           )',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Peminjam', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 40),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700)),
                  ),
                  padding: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text(
                    '(                           )',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Note
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CATATAN:',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '• Harap kembalikan alat tepat waktu sesuai tanggal yang tertera',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '• Keterlambatan akan dikenakan denda Rp 1.000/hari/alat',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '• Pastikan alat dalam kondisi baik saat dikembalikan',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
