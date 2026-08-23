import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class DocumentPreviewPage extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() buildPdf;

  const DocumentPreviewPage({
    super.key,
    required this.title,
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: isAr ? 'مشاركة الوثيقة' : 'Share Document',
            onPressed: () async {
              final pdfBytes = await buildPdf();
              await Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: (_) => buildPdf(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        maxPageWidth: 700,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text('Generating PDF Document...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
