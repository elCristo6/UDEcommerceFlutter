
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;

import '../models/invoice_model.dart';

class PDFService {
  static final Map<String, Uint8List> _imageCache = {};

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Future<Uint8List?> _fetchBytesWeb(String url) async {
    try {
      final req = await html.HttpRequest.request(
        url,
        method: 'GET',
        responseType: 'arraybuffer',
        withCredentials: false,
      );
      final buffer = req.response as ByteBuffer;
      return buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> preloadInvoiceImages(Invoice invoice) async {
    final futures = <Future<void>>[];

    for (final p in invoice.products) {
      if (p.images.isEmpty) continue;
      final url = p.images.first;
      if (Uri.tryParse(url)?.isAbsolute != true) continue;

      if (p.cachedImageBytes != null || _imageCache.containsKey(url)) continue;

      futures.add(_fetchBytesWeb(url).then((bytes) {
        if (bytes != null) {
          _imageCache[url] = bytes;
          p.cachedImageBytes = bytes;
        }
      }));
    }

    await Future.wait(futures);
  }

  Future<void> printInvoiceStyled(
    Invoice invoice, {
    String docType = 'FACTURA DE VENTA',
  }) async {
    try {
      await preloadInvoiceImages(invoice);

      // 1. Cargar Logo de marca
      final logoData = await rootBundle.load('assets/LogoPDF.png');
      final logoBytes = logoData.buffer.asUint8List();
      final logoBitmap = PdfBitmap(logoBytes);

      // 2. CONFIGURACIÓN DE MÁRGENES Y ANCHOS
      const double marginLeft = 15.0; // Desplazamiento seguro a la derecha
      const double marginRight = 5.0;
      const double pageWidth = 209.0; // Ancho total bobina 80mm
      const double printableWidth = pageWidth - marginLeft - marginRight; // 189pt útiles

      // Cálculo de altura ajustado al nuevo tamaño de fuente
      const double baseHeight = 310.0;
      final double itemsHeight = invoice.products.length * 32.0;
      final double totalCalculatedHeight = baseHeight + itemsHeight;

      final document = PdfDocument();
      document.pageSettings.margins.all = 0;
      document.pageSettings.size = Size(pageWidth, totalCalculatedHeight);

      final page = document.pages.add();
      final graphics = page.graphics;

      // 3. FUENTES AMPLIADAS PARA MÁXIMA LEGIBILIDAD
      final companyTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 10.0, style: PdfFontStyle.bold);
      final companyFont = PdfStandardFont(PdfFontFamily.helvetica, 8.0);
      final companyBoldFont = PdfStandardFont(PdfFontFamily.helvetica, 8.0, style: PdfFontStyle.bold);

      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 10.5, style: PdfFontStyle.bold);
      final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 8.0, style: PdfFontStyle.bold);
      final contentFont = PdfStandardFont(PdfFontFamily.helvetica, 8.0);
      final totalFont = PdfStandardFont(PdfFontFamily.helvetica, 11.0, style: PdfFontStyle.bold);
      final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 7.5);

      final tableHeaderColor = PdfColor(240, 240, 240);
      final linePen = PdfPen(PdfColor(170, 170, 170), width: 0.5);

      double top = 4.0;

      // -------------------------------------------------------------
      // 4. ENCABEZADO (LOGO + DATOS DE EMPRESA)
      // -------------------------------------------------------------
      const double logoWidth = 72;
      const double logoHeight = 72;

      graphics.drawImage(logoBitmap, Rect.fromLTWH(marginLeft, top, logoWidth, logoHeight));

      final double companyTextLeft = marginLeft + logoWidth + 4;
      final double companyTextWidth = pageWidth - companyTextLeft - marginRight;

      double headerTextTop = top;

      graphics.drawString('UD ELECTRONICS', companyTitleFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 12));
      headerTextTop += 12;

      graphics.drawString('Tienda de robótica, electrónica', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('e impresión 3D profesional', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('Régimen simplificado', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('NIT: 1022972666-6', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('KR 9 # 19-30 L 202', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('3208576038 - 3213213756', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('6012105424', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('udelectronics.com', companyBoldFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 10;

      graphics.drawString('UDElectronics Bogota-Colombia', companyFont,
          bounds: Rect.fromLTWH(companyTextLeft, headerTextTop, companyTextWidth, 10));
      headerTextTop += 12;

      top = (headerTextTop > top + logoHeight) ? headerTextTop : top + logoHeight + 4;

      // Línea divisoria
      graphics.drawLine(linePen, Offset(marginLeft, top), Offset(pageWidth - marginRight, top));
      top += 6;

      // -------------------------------------------------------------
      // 5. DATOS DE LA FACTURA Y CLIENTE
      // -------------------------------------------------------------
      graphics.drawString(
        '$docType No. ${invoice.consecutivo ?? '-'}',
        titleFont,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      top += 16;

      final now = DateTime.now();
      final fechaStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final clientName = (invoice.user?.name != null && invoice.user!.name!.trim().isNotEmpty)
          ? invoice.user!.name!.trim()
          : "Cliente Mostrador";

      final clientInfo = '''
Fecha: $fechaStr
Cliente: $clientName
NIT/CC: ${invoice.user?.nit ?? ""}
Teléfono: ${invoice.user?.phone ?? ""}
Medio de pago: ${invoice.medioPago}
''';

      graphics.drawString(
        clientInfo.trim(),
        contentFont,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 58),
      );
      top += 58;

      // -------------------------------------------------------------
      // 6. TABLA DE PRODUCTOS CON MAYOR TAMAÑO Y MARGEN
      // -------------------------------------------------------------
      final grid = PdfGrid();
      grid.columns.add(count: 5);
      grid.headers.add(1);

      final header = grid.headers[0];
      header.cells[0].value = 'Img';
      header.cells[1].value = 'Producto';
      header.cells[2].value = 'Cant';
      header.cells[3].value = 'P.Unit';
      header.cells[4].value = 'Total';
      header.style = PdfGridRowStyle(
        backgroundBrush: PdfSolidBrush(tableHeaderColor),
        font: headerFont,
      );

      // Distribuido en los 189 pt del espacio útil con margen izquierdo
      grid.columns[0].width = 26;
      grid.columns[1].width = 65;
      grid.columns[2].width = 22;
      grid.columns[3].width = 38;
      grid.columns[4].width = 38;

      for (final product in invoice.products) {
        final row = grid.rows.add();

        String? url = product.images.isNotEmpty ? product.images.first : null;
        Uint8List? bytes = product.cachedImageBytes;

        if (bytes == null && url != null && Uri.tryParse(url)?.isAbsolute == true) {
          bytes = _imageCache[url];
          bytes ??= await _fetchBytesWeb(url);
          if (bytes != null) {
            _imageCache[url] = bytes;
            product.cachedImageBytes = bytes;
          }
        }

        try {
          if (bytes != null) {
            final bmp = PdfBitmap(bytes);
            row.cells[0].value = '';
            row.cells[0].style.backgroundImage = bmp;
          } else {
            row.cells[0].value = '';
          }
        } catch (_) {
          row.cells[0].value = '';
        }

        row.height = 30;

        final price = (product.price.isNaN ? 0.0 : product.price);
        final qty = (product.quantity <= 0 ? 1 : product.quantity);
        final subtotal = (price * qty).round();

        row.cells[1].value = product.name;
        row.cells[2].value = '$qty';
        row.cells[3].value = '\$${_formatCurrency(price.round())}';
        row.cells[4].value = '\$${_formatCurrency(subtotal)}';
      }

      grid.style = PdfGridStyle(
        font: smallFont,
        cellPadding: PdfPaddings(left: 1, right: 1, top: 2, bottom: 2),
      );

      final format = PdfLayoutFormat(layoutType: PdfLayoutType.paginate);

      final result = grid.draw(
        page: page,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 0),
        format: format,
      );

      if (result == null) {
        throw Exception('PdfGrid.draw devolvió null.');
      }

      top = result.bounds.bottom + 8;

      // -------------------------------------------------------------
      // 7. BLOQUE DE TOTALES DESTACADO
      // -------------------------------------------------------------
      graphics.drawLine(linePen, Offset(marginLeft, top), Offset(pageWidth - marginRight, top));
      top += 8;

      graphics.drawString(
        'Pago con: \$${_formatCurrency(invoice.pagaCon.round())}',
        contentFont,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 12;

      graphics.drawString(
        'Cambio: \$${_formatCurrency(invoice.cambio.round())}',
        contentFont,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 14;

      graphics.drawString(
        'TOTAL: \$${_formatCurrency(invoice.totalAmount.round())}',
        totalFont,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 16),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 20;

      // -------------------------------------------------------------
      // 8. PIE DE PÁGINA POS
      // -------------------------------------------------------------
      graphics.drawLine(linePen, Offset(marginLeft, top), Offset(pageWidth - marginRight, top));
      top += 6;

      graphics.drawString(
        '¡Gracias por tu compra!',
        headerFont,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      top += 12;

      graphics.drawString(
        'www.udelectronics.com',
        contentFont,
        bounds: Rect.fromLTWH(marginLeft, top, printableWidth, 11),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // -------------------------------------------------------------
      // 9. GENERACIÓN Y APERTURA POPUP SÍNCRONA DE MEMORIA (BLOB)
      // -------------------------------------------------------------
      final bytes = await document.save();
      document.dispose();

      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final urlOut = html.Url.createObjectUrlFromBlob(blob);

      html.window.open(urlOut, '_blank');

      Future.delayed(const Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(urlOut);
      });
    } catch (e, st) {
      print('❌ Error generando PDF: $e');
      print(st);
      rethrow;
    }
  }
}