import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class QrServices {

  Future<void> generateAndSaveQRCodes(List<String> strings) async {
    // Obtém o diretório padrão para salvar os arquivos
    final directory = await getApplicationDocumentsDirectory();

    for (var i = 0; i < strings.length; i++) {
      final qrCode = strings[i];
      
      // Gera um widget QRCode
      final qrImage = QrPainter(
        data: qrCode,
        version: QrVersions.auto,
        gapless: true,
      );

      // Converte o widget para bytes
      final imageData = await qrImage.toImage(300); // 300 é a resolução da imagem
      final byteData = await imageData.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Salva o arquivo no diretório
      final filePath = '${directory.path}/${qrCode.replaceAll("/", "-")}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      debugPrint('QR Code salvo em: $filePath');
    }
  }

}