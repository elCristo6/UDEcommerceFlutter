import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/invoice_model.dart';

class PDFService {
  /// Función para formatear con puntos de mil
  /// e.g. 1234567 -> "1.234.567"
  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  /// Genera un PDF con los datos completos de la factura y lo muestra en una nueva pestaña.
  Future<void> printInvoiceStyled(
    Invoice invoice, {
    String docType = 'FACTURA DE VENTA',
  }) async {
    try {
      // Carga la imagen del logo
      ByteData logoData = await rootBundle.load('assets/UDSinfondo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final PdfBitmap logoBitmap = PdfBitmap(logoBytes);

      // Crea el documento
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;
      final Size pageSize = page.getClientSize();

      // Estilos
      final PdfFont titleFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        14,
        style: PdfFontStyle.bold,
      );
      final PdfFont headerFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        10,
        style: PdfFontStyle.bold,
      );
      final PdfFont contentFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        10,
      );
      final PdfColor tableHeaderColor = PdfColor(220, 240, 255);

      double top = 20;

      // Dibuja el logo
      graphics.drawImage(logoBitmap, Rect.fromLTWH(20, top, 120, 70));

      // Información de la empresa
      graphics.drawString(
        '''
                    UD ELECTRONICS
                    Desarrollo de software, electrónica, robótica, programación e impresión 3D
                    NIT: 1022972666-6 REGIMEN SIMPLIFICADO
                    KR 9 # 19  30 Local 202
                    3208576038 * 3213213756 * 6012105424
                    udelectronics.net@gmail.com
        ''',
        contentFont,
        bounds: Rect.fromLTWH(90, top, pageSize.width - 100, 80),
      );
      top += 90;

      // Título (factura o cotización, según docType)
      graphics.drawString(
        docType,
        titleFont,
        bounds: Rect.fromLTWH(0, top, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      top += 30;

      // Fecha actual (dd/MM/yyyy)
      final DateTime now = DateTime.now();
      final String fechaStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      graphics.drawString(
        'Fecha: $fechaStr',
        contentFont,
        bounds: Rect.fromLTWH(20, top, pageSize.width - 40, 20),
      );
      top += 10;

      // Información del cliente
      final clientInfo = '''
Cliente: ${invoice.user?.name ?? "Cliente Mostrador"}
NIT/CC: ${invoice.user?.nit ?? ""}
Teléfono: ${invoice.user?.phone ?? ""}
Medio de pago: ${invoice.medioPago}
      ''';
      graphics.drawString(
        clientInfo,
        contentFont,
        bounds: Rect.fromLTWH(20, top, pageSize.width - 40, 60),
      );
      top += 70;

      // ================== Tabla de productos ==================
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 4);
      grid.headers.add(1);

      // Encabezado de la tabla
      PdfGridRow header = grid.headers[0];
      header.cells[0].value = 'Producto';
      header.cells[1].value = 'Cantidad';
      header.cells[2].value = 'Precio Unitario';
      header.cells[3].value = 'Subtotal';

      header.style = PdfGridRowStyle(
        backgroundBrush: PdfSolidBrush(tableHeaderColor),
        font: headerFont,
      );

      // Filas de productos
      for (var product in invoice.products) {
        final String name = product.name;
        final double price = product.price;
        final int quantity = product.quantity;
        final double productSubtotal = price * quantity;

        // Convertimos a int para formatear con puntos de mil
        final int priceInt = price.round(); // o toInt()
        final int subtotalInt = productSubtotal.round();

        final row = grid.rows.add();
        row.cells[0].value = name; // Nombre del producto
        row.cells[1].value = '$quantity'; // Cantidad
        row.cells[2].value =
            '\$${_formatCurrency(priceInt)}'; // Precio unitario formateado
        row.cells[3].value =
            '\$${_formatCurrency(subtotalInt)}'; // Subtotal formateado
      }

      // Estilo de la tabla
      grid.style = PdfGridStyle(
        font: contentFont,
        cellPadding: PdfPaddings(left: 5, right: 5, top: 2, bottom: 2),
      );

      // Dibuja la tabla
      final PdfLayoutResult result = grid.draw(
        page: page,
        bounds:
            Rect.fromLTWH(20, top, pageSize.width - 40, pageSize.height - top),
      )!;
      top = result.bounds.bottom + 20;

      // ================== Totales ==================
      // Cambio
      graphics.drawString(
        'Pago con: \$${_formatCurrency(invoice.pagaCon.round())}',
        contentFont,
        bounds: Rect.fromLTWH(pageSize.width - 160, top, 140, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 15;

      // Pago con
      graphics.drawString(
        'Cambio: \$${_formatCurrency(invoice.cambio.round())}',
        contentFont,
        bounds: Rect.fromLTWH(pageSize.width - 160, top, 140, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 15;

      // Total final
      graphics.drawString(
        'TOTAL: \$${_formatCurrency(invoice.totalAmount.round())}',
        titleFont,
        bounds: Rect.fromLTWH(0, top, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      top += 30;

      // Guarda el PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Crea un Blob con los datos del PDF
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Abre el PDF en una nueva pestaña
      html.window.open(url, '_blank');

      // Limpia la URL del blob después de un tiempo
      Future.delayed(const Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      print('Error generando el PDF: $e');
    }
  }
}
