import 'dart:io';
import 'dart:ui';
import 'package:bm_qrcode_windows/models/collection.dart';
import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class QrServices {

  Future<void> generateAndSaveQRCodes(CupomCollection collection, int digits) async {
    // Obtém o diretório padrão para salvar os arquivos
    final directory = await getDownloadsDirectory();

    QuerySnapshot snapshots = await FirebaseFirestore.instance.collection("cupons").where("collection", isEqualTo: collection.id)
    .where("digits", isEqualTo: digits)
    .orderBy("sequence", descending: false).get();

    List<Cupom> cupons = snapshots.docs.map((e)=> Cupom.fromMap(e.data()! as Map<String, dynamic>)).toList();

    for (var i = 0; i < cupons.length; i++) {
      final cupom = cupons[i];

      //await Future.delayed(const Duration(milliseconds: 50));
      //String dateId = Timestamp.now().toDate().toIso8601String().replaceAll("-", "").replaceAll(":", "").replaceAll(".", "").replaceAll(":", "");
      
      // Gera um widget QRCode
      final qrImage = QrPainter(
        data: cupom.id!,
        version: QrVersions.auto,
        gapless: true,
      );

      // Converte o widget para bytes
      final imageData = await qrImage.toImage(300); // 300 é a resolução da imagem
      final byteData = await imageData.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Salva o arquivo no diretório
      final filePath = '${directory!.path}\\${cupom.sequence}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      debugPrint('QR Code salvo em: $filePath');
    }
  }

  Future<void> createTxtFile(CupomCollection collection, int digits) async {
    // Converter a lista de objetos para uma string
    QuerySnapshot snapshots = await FirebaseFirestore.instance.collection("cupons").where("collection", isEqualTo: collection.id)
    .where("digits", isEqualTo: digits)
    .orderBy("sequence", descending: false).get();

    List<Cupom> items = snapshots.docs.map((e)=> Cupom.fromMap(e.data()! as Map<String, dynamic>)).toList();

    StringBuffer buffer = StringBuffer();
    buffer.writeln(_txtheader(items.first.digits!));
    for (var item in items) {
      buffer.writeln(item.toPrintString());
    }

    // Obter o diretório onde salvar o arquivo (funciona para dispositivos móveis)
    final directory = await getDownloadsDirectory();
    final filePath = '${directory!.path}\\items-${items.first.digits}digitos.txt';

    // Criar o arquivo e escrever o conteúdo
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    debugPrint('Arquivo salvo em: $filePath');
  }

  String _txtheader(int digits){
    switch (digits) {
      case 2:
        return "1\t2\tREF\tSEQ";
      case 3:
        return "1\t2\t3\tREF\tSEQ";
      case 4:
        return "1\t2\t3\t4\tREF\tSEQ";
      case 6:
        return "1\t2\t3\t4\t5\t6\tREF\tSEQ";
      default:
        return "";
    }
  }

}