// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;

import '../models/invoice_model.dart';

class PDFService {
  // Caché estático, compartido entre instancias (importante porque en tu código
  // a veces creas un PDFService nuevo en diferentes lugares).
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
      // CORS o 404, etc.
      // print('⚠️ No se pudo descargar imagen $url: $e');
      return null;
    }
  }

  /// Precarga imágenes para un invoice (para primer render).

  Future<void> preloadInvoiceImages(Invoice invoice) async {
    final futures = <Future<void>>[];

    for (final p in invoice.products) {
      if (p.images.isEmpty) continue;
      final url = p.images.first;
      if (Uri.tryParse(url)?.isAbsolute != true) continue;

      // si ya está en el propio producto o en el cache, no bajes de nuevo
      if (p.cachedImageBytes != null || _imageCache.containsKey(url)) continue;

      futures.add(_fetchBytesWeb(url).then((bytes) {
        if (bytes != null) {
          _imageCache[url] = bytes; // cache global
          p.cachedImageBytes = bytes; // cache en el propio producto
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
      // Logo
      final logoData = await rootBundle.load('assets/LogoPDF.png');
      final logoBytes = logoData.buffer.asUint8List();
      final logoBitmap = PdfBitmap(logoBytes);

      // Documento
      final document = PdfDocument();
      final page = document.pages.add();
      final graphics = page.graphics;
      final pageSize = page.getClientSize();

      // Estilos
      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 14,
          style: PdfFontStyle.bold);
      final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);
      final contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final tableHeaderColor = PdfColor(350, 270, 255);

      double top = 10;

      // Logo
      graphics.drawImage(logoBitmap, Rect.fromLTWH(20, top - 20, 120, 120));
      // Empresa
      graphics.drawString(
        '''
UD ELECTRONICS
Desarrollo de software, electrónica, robótica, programación e impresión 3D
NIT: 1022972666-6 REGIMEN SIMPLIFICADO
KR 9 # 19  30 Local 202
3208576038 * 3213213756 * 6012105424
WWW.UDELECTRONICS.COM - udelectronicsbogota@gmail.com 
        ''',
        contentFont,
        bounds: Rect.fromLTWH(150, top, pageSize.width - 100, 80),
      );
      top += 90;

      // Título
      graphics.drawString(
        '${docType} No. ${invoice.consecutivo ?? '-'}',
        titleFont,
        bounds: Rect.fromLTWH(0, top, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      top += 10;

      // Fecha
      final now = DateTime.now();
      final fechaStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      graphics.drawString('Fecha: $fechaStr', contentFont,
          bounds: Rect.fromLTWH(20, top, pageSize.width - 40, 20));
      top += 10;

      // Cliente
      final clientInfo = '''
Cliente: ${invoice.user?.name ?? "Cliente Mostrador"}
NIT/CC: ${invoice.user?.nit ?? ""}
Teléfono: ${invoice.user?.phone ?? ""}
Medio de pago: ${invoice.medioPago}
      ''';
      graphics.drawString(clientInfo, contentFont,
          bounds: Rect.fromLTWH(20, top, pageSize.width - 40, 60));
      top += 70;

      // Tabla
      final grid = PdfGrid();
      grid.columns.add(count: 5);
      grid.headers.add(1);

      final header = grid.headers[0];
      header.cells[0].value = 'Imagen';
      header.cells[1].value = 'Producto';
      header.cells[2].value = 'Cantidad';
      header.cells[3].value = 'Precio Unitario';
      header.cells[4].value = 'Subtotal';
      header.style = PdfGridRowStyle(
        backgroundBrush: PdfSolidBrush(tableHeaderColor),
        font: headerFont,
      );
      for (final product in invoice.products) {
        final row = grid.rows.add();

        // 1) elegir URL (primer imagen)
        String? url = product.images.isNotEmpty ? product.images.first : null;

        // 2) obtener bytes (prioriza precarga en el modelo)
        Uint8List? bytes = product.cachedImageBytes;
        if (bytes == null &&
            url != null &&
            Uri.tryParse(url)?.isAbsolute == true) {
          bytes = _imageCache[url];
          bytes ??= await _fetchBytesWeb(url);
          if (bytes != null) {
            _imageCache[url] = bytes;
            product.cachedImageBytes = bytes; // guarda para siguientes PDFs
          }
        }

        // 3) pintar imagen / placeholder
        if (bytes != null) {
          final bmp = PdfBitmap(bytes);
          row.cells[0].value = '';
          row.cells[0].style.backgroundImage = bmp;
        } else {
          row.cells[0].value = '[img]';
        }

        // ⚠️ MUY IMPORTANTE: dar espacio a la miniatura
        row.height = 56; // alto de la fila con imagen
        // …

        final price = product.price;
        final qty = product.quantity;
        final subtotal = (price * qty).round();
        row.cells[1].value = product.name;
        row.cells[2].value = '$qty';
        row.cells[3].value = '\$${_formatCurrency(price.round())}';
        row.cells[4].value = '\$${_formatCurrency(subtotal)}';
      }

// Ancho de la columna de imagen (para que se vea)
      grid.columns[0].width = 56;

      grid.style = PdfGridStyle(
        font: contentFont,
        cellPadding: PdfPaddings(left: 5, right: 5, top: 2, bottom: 2),
      );

      final result = grid.draw(
        page: page,
        bounds:
            Rect.fromLTWH(20, top, pageSize.width - 40, pageSize.height - top),
      )!;
      top = result.bounds.bottom + 20;

      // Totales
      graphics.drawString(
        'Pago con: \$${_formatCurrency(invoice.pagaCon.round())}',
        contentFont,
        bounds: Rect.fromLTWH(pageSize.width - 160, top, 140, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 15;

      graphics.drawString(
        'Cambio: \$${_formatCurrency(invoice.cambio.round())}',
        contentFont,
        bounds: Rect.fromLTWH(pageSize.width - 160, top, 140, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 15;

      graphics.drawString(
        'TOTAL: \$${_formatCurrency(invoice.totalAmount.round())}',
        titleFont,
        bounds: Rect.fromLTWH(0, top, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      // Salida
      final bytes = await document.save();
      document.dispose();

      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final urlOut = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(urlOut, '_blank');

      Future.delayed(const Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(urlOut);
      });
    } catch (e) {
      // No rompas el flujo; si falla una imagen, igual se genera el PDF.
      // print('Error generando el PDF: $e');
    }
  }
}

/*
// lib/services/pdfService.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;

import '../models/invoice_model.dart';

class PDFService {
  // ===== Knobs de layout =====
  static const double kMargin = 15.0;
  static const double kImgW   = 140.0; // imágenes grandes
  static const double kRowH   = 125.0; // filas altas para lucir miniatura
  static const double kQtyW   = 42.0;  // “Cantidad” angosta
  static const double kUnitW  = 100.0;
  static const double kSubW   = 100.0;

  // Caché global de miniaturas
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
    } catch (_) {
      return null;
    }
  }

  /// Precarga imágenes para mejorar el primer render del PDF.
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
      // ===== Documento y fuentes =====
      final logoData = await rootBundle.load('assets/LogoPDF.png');
      final logoBytes = logoData.buffer.asUint8List();
      final logoBitmap = PdfBitmap(logoBytes);

      final document = PdfDocument();
      final page = document.pages.add();
      final graphics = page.graphics;
      final pageSize = page.getClientSize();

      final contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final bold10 = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);

      double top = 20;

      // ===== Encabezado (logo + datos) =====
      graphics.drawImage(logoBitmap, Rect.fromLTWH(0, -20, 150, 170));
      graphics.drawString(
        '''
UD ELECTRONICS
Desarrollo de software, electrónica, robótica, programación e impresión 3D
NIT: 1022972666-6  REGIMEN SIMPLIFICADO
KR 9 # 19  30 Local 202
3208576038  *  3213213756  *  6012105424
WWW.UDELECTRONICS.COM  -  udelectronicsbogota@gmail.com
''',
        contentFont,
        bounds: Rect.fromLTWH(kMargin + 130, top + 6, pageSize.width - (kMargin * 2 + 130), 80),
      );
      top += 90;

      // ===== Título =====
      graphics.drawString(
        '${docType.toUpperCase()}  No. ${invoice.consecutivo ?? '-'}',
        titleFont,
        bounds: Rect.fromLTWH(0, top, pageSize.width, 22),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      top += 8;
      graphics.drawLine(
        PdfPen(PdfColor(200, 200, 200), width: 0.8),
        Offset(kMargin, top + 20),
        Offset(pageSize.width - kMargin, top + 20),
      );
      top += 26;

      // ===== Datos del cliente / fecha =====
      final now = DateTime.now();
      final fechaStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      graphics.drawString(
        '''
Fecha: $fechaStr
Cliente: ${invoice.user?.name ?? "Cliente Mostrador"}
NIT/CC: ${invoice.user?.nit ?? ""}
Teléfono: ${invoice.user?.phone ?? ""}
Medio de pago: ${invoice.medioPago}
''',
        contentFont,
        bounds: Rect.fromLTWH(kMargin, top, pageSize.width - kMargin * 2, 62),
      );
      top += 70;

      // ===== Tabla =====
      final grid = PdfGrid();
      grid.columns.add(count: 5);
      grid.headers.add(1);

      // Repetir encabezado en cada página
      grid.repeatHeader = true;

      // Encabezado
      final header = grid.headers[0];
      header.cells[0].value = 'Imagen';
      header.cells[1].value = 'Producto';
      header.cells[2].value = 'Cantidad';
      header.cells[3].value = 'Precio Unitario';
      header.cells[4].value = 'Subtotal';
      header.style = PdfGridRowStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(220, 240, 255)),
        textBrush: PdfSolidBrush(PdfColor(35, 35, 35)),
        font: bold10,
      );

      // Alineaciones por columna
      final leftFmt   = PdfStringFormat(alignment: PdfTextAlignment.left,   lineAlignment: PdfVerticalAlignment.middle);
      final centerFmt = PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle);
      final rightFmt  = PdfStringFormat(alignment: PdfTextAlignment.right,  lineAlignment: PdfVerticalAlignment.middle);

      grid.columns[0].format = centerFmt; // imagen
      grid.columns[1].format = leftFmt;   // producto
      grid.columns[2].format = centerFmt; // cantidad
      grid.columns[3].format = rightFmt;  // unitario
      grid.columns[4].format = rightFmt;  // subtotal

      // Medidas de columnas
      final double tableWidth = pageSize.width - kMargin * 2;
      final double prodW = tableWidth - (kImgW + kQtyW + kUnitW + kSubW);

      grid.columns[0].width = kImgW; // imagen grande
      grid.columns[1].width = prodW; // nombre ocupa lo que queda
      grid.columns[2].width = kQtyW; // cantidad angosta
      grid.columns[3].width = kUnitW;
      grid.columns[4].width = kSubW;

      // Estilo general
      grid.style = PdfGridStyle(
        font: contentFont,
        cellPadding: PdfPaddings(left: 7, right: 7, top: 7, bottom: 7),
        borderOverlapStyle: PdfBorderOverlapStyle.inside,
      );

      // Filas con zebra suave y miniaturas grandes
      for (final product in invoice.products) {
        final row = grid.rows.add();

        // Bytes de imagen (precarga o caché)
        Uint8List? bytes = product.cachedImageBytes;
        final url = product.images.isNotEmpty ? product.images.first : null;
        if (bytes == null && url != null && Uri.tryParse(url)?.isAbsolute == true) {
          bytes = _imageCache[url] ?? await _fetchBytesWeb(url);
          if (bytes != null) {
            _imageCache[url] = bytes;
            product.cachedImageBytes = bytes;
          }
        }

        if (bytes != null) {
          final bmp = PdfBitmap(bytes);
          row.cells[0].value = '';
          row.cells[0].style.backgroundImage = bmp; // llena la celda
        } else {
          row.cells[0].value = '—';
        }

        // Altura generosa para lucir la miniatura
        row.height = kRowH;

        // Datos
        row.cells[1].value = product.name;
        row.cells[2].value = '${product.quantity}';
        row.cells[3].value = '\$${_formatCurrency(product.price.round())}';
        final subtotal = (product.price * product.quantity).round();
        row.cells[4].value = '\$${_formatCurrency(subtotal)}';

        // Zebra
        if ((grid.rows.count - 1).isOdd) {
          row.style = PdfGridRowStyle(
            backgroundBrush: PdfSolidBrush(PdfColor(248, 251, 255)),
          );
        }
      }

      // 1) DIBUJAR LA TABLA CON PAGINADO AUTOMÁTICO
      final PdfLayoutResult result = grid.draw(
        page: page,
        bounds: Rect.fromLTWH(kMargin, top, tableWidth, page.getClientSize().height - top),
        format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
      )!;

      // 2) CONTINUAR EN LA ÚLTIMA PÁGINA DONDE ACABÓ LA TABLA
      PdfPage lastPage = result.page;
      PdfGraphics g = lastPage.graphics;
      Size lastSize = lastPage.getClientSize();
      double y = result.bounds.bottom + 16; // siguiente posición tras la tabla

      // 3) SI NO CABEN LOS TOTALES, CREA UNA PÁGINA NUEVA
      const double blockHeight = 60; // alto aproximado del bloque “pago/cambio/total”
      if (y + blockHeight > lastSize.height - 20) {
        lastPage = document.pages.add();
        g = lastPage.graphics;
        lastSize = lastPage.getClientSize();
        y = kMargin;
      }

      // 4) DIBUJAR TOTALES EN LA PÁGINA CORRECTA
      final rightFmtTotals = PdfStringFormat(
        alignment: PdfTextAlignment.right,
        lineAlignment: PdfVerticalAlignment.middle,
      );

      final labelW = 140.0;
      final xRight = lastSize.width - kMargin;

      g.drawString(
        'Pago con:',
        contentFont,
        bounds: Rect.fromLTWH(xRight - labelW - 100, y, labelW, 16),
        format: rightFmtTotals,
      );
      g.drawString(
        '\$${_formatCurrency(invoice.pagaCon.round())}',
        contentFont,
        bounds: Rect.fromLTWH(xRight - 100, y, 100, 16),
        format: rightFmtTotals,
      );
      y += 16;

      g.drawString(
        'Cambio:',
        contentFont,
        bounds: Rect.fromLTWH(xRight - labelW - 100, y, labelW, 16),
        format: rightFmtTotals,
      );
      g.drawString(
        '\$${_formatCurrency(invoice.cambio.round())}',
        contentFont,
        bounds: Rect.fromLTWH(xRight - 100, y, 100, 16),
        format: rightFmtTotals,
      );
      y += 18;

      final totalFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
      g.drawString(
        'TOTAL:',
        totalFont,
        bounds: Rect.fromLTWH(xRight - labelW - 100, y, labelW, 20),
        format: rightFmtTotals,
      );
      g.drawString(
        '\$${_formatCurrency(invoice.totalAmount.round())}',
        totalFont,
        bounds: Rect.fromLTWH(xRight - 100, y, 100, 20),
        format: rightFmtTotals,
      );

      // ===== Salida Web =====
      final bytes = await document.save();
      document.dispose();
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final urlOut = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(urlOut, '_blank');
      Future.delayed(const Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(urlOut);
      });
    } catch (_) {
      // silencioso para no romper el flujo si alguna imagen falla
    }
  }
}*/
