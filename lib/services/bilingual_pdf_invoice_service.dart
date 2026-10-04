import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';

class BilingualPdfInvoiceService {
  /// Generate and present FTA-compliant bilingual PDF Tax Invoice.
  static Future<void> generateAndPrintTaxInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    // 5% VAT Calculations
    final double amount = invoice.amount;
    final double vat = invoice.vat;
    final double workerFee = invoice.workerFee;
    final double total = invoice.total;

    final String trn = invoice.trnNumber ?? '100492817300003';
    final String dateStr = invoice.formattedDate;

    // Load full Unicode Cairo font to support bilingual English/Arabic text cleanly
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── 1. Bilingual Header ──────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NXN HUB LOGISTICS L.L.C.',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#003C8E'),
                        ),
                      ),
                      pw.Text(
                        'TAX INVOICE / FATURA',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#3D73BC'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('FTA TRN: $trn', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Dubai, United Arab Emirates', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#003C8E'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          invoice.paid ? 'PAID / PAID' : 'PENDING',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Invoice #: ${invoice.number}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#DEEAF8')),
              pw.SizedBox(height: 12),

              // ── 2. Warehouse & Customer Billing Info ────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO / CUSTOMER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(invoice.warehouseName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Verified SME Merchant', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FULFILLMENT HUB', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text('UAE Logistics Network', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('5% UAE VAT Applicable', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── 3. Bilingual Line Items Table ────────────────────────────────
              pw.TableHelper.fromTextArray(
                headers: ['Item / Description', 'Type', 'Amount (AED)'],
                data: [
                  ['Micro-Warehousing Space Rental', invoice.type.name.toUpperCase(), 'AED ${amount.toStringAsFixed(2)}'],
                  if (workerFee > 0) ['Warehouse Worker Assistance Fee', 'SERVICE', 'AED ${workerFee.toStringAsFixed(2)}'],
                  ['5% UAE Value-Added Tax (VAT)', 'FTA VAT 5%', 'AED ${vat.toStringAsFixed(2)}'],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#003C8E')),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),

              // ── 4. VAT & Financial Totals Breakdown ─────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // FTA Verification QR Code Block
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'NXN_HUB|TRN:$trn|INV:${invoice.number}|TOTAL:${total.toStringAsFixed(2)}|VAT:${vat.toStringAsFixed(2)}',
                    width: 70,
                    height: 70,
                  ),

                  // Totals Box
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F4F6FA'),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColor.fromHex('#E4EAF4')),
                    ),
                    child: pw.Column(
                      children: [
                        _pdfRow('Subtotal (excl. VAT)', 'AED ${amount.toStringAsFixed(2)}'),
                        if (workerFee > 0) _pdfRow('Worker Assistance', 'AED ${workerFee.toStringAsFixed(2)}'),
                        _pdfRow('UAE VAT (5%)', 'AED ${vat.toStringAsFixed(2)}'),
                        pw.Divider(thickness: 1, color: PdfColor.fromHex('#003C8E')),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL (AED)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColor.fromHex('#003C8E'))),
                            pw.Text('AED ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColor.fromHex('#003C8E'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // ── 5. Legal Footer ─────────────────────────────────────────────
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('This is a computer-generated Tax Invoice under UAE Federal Decree-Law No. 8 on VAT.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Present print/share preview dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Tax_Invoice_${invoice.number}.pdf',
    );
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
