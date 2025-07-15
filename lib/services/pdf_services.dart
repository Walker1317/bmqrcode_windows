// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui' as ui;
import 'package:bm_qrcode_windows/models/collection.dart';
import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GeradorCuponsPDF {
  final CupomCollection collection;
  final int digits;

  GeradorCuponsPDF(this.collection, this.digits);

  /// Função principal
  Future gerarPDF() async {
    QuerySnapshot snapshots = await FirebaseFirestore.instance.collection("cupons").where("collection", isEqualTo: collection.id)
    .where("digits", isEqualTo: digits)
    .orderBy("sequence", descending: false).get();

    List<Cupom> cupons = [];

    for(var snapshot in snapshots.docs){
      final cupom = Cupom.fromMap(snapshot.data()! as Map<String, dynamic>);
      cupom.qr = await gerarQrCode(cupom.id!);
      debugPrint("QrCode Gerado");
      cupons.add(cupom);
    }

    const int linhas = 4;
    const int colunas = 4;

    final pdf = pw.Document();
    final folhas = _distribuirCupons(cupons, linhas, colunas);
    final backgroundImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    final Uint8List bytes = await File(backgroundImage!.path).readAsBytes();
    final pw.ImageProvider background = pw.MemoryImage(bytes);

    double digitsTopPadding(){
      switch (digits) {
        case 2:
          return 14;
        case 3:
          return 6;
        case 4:
          return 0;
        default:
          return 0;
      }
    }
    double digitsBottomPadding(){
      switch (digits) {
        case 2:
          return 6;
        case 3:
          return 4;
        case 4:
          return 2;
        default:
          return 0;
      }
    }

    for (var folha in folhas) {
      pdf.addPage(
        pw.Page(
          orientation: pw.PageOrientation.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.GridView(
              crossAxisCount: colunas,
              childAspectRatio: 1.5,
              children: folha.map((cupom) {
                final valores = cupom.value!.split("/");
                return cupom.qr == null ? pw.SizedBox():
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                  child: pw.Stack(
                    children: [
                      pw.Positioned.fill(child: pw.Image(background, fit: pw.BoxFit.cover)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 25),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 20),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.only(top: digitsTopPadding()),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: valores.map((e) {
                                      return pw.Padding(
                                        padding: pw.EdgeInsets.only(left: 23, bottom: digitsBottomPadding()),
                                        child: pw.Text(e),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                pw.SizedBox(width: 24),
                                pw.Container(
                                  height: 50,
                                  width: 50,
                                  margin: const pw.EdgeInsets.only(left: 0),
                                  child: pw.Image(pw.MemoryImage(cupom.qr!)),
                                ),
                                pw.SizedBox(width: 5),
                                /*pw.Container(
                                  width: 60,
                                  decoration: pw.BoxDecoration(
                                    borderRadius: pw.BorderRadius.circular(5),
                                    color: PdfColors.white,
                                  ),
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                                    child: pw.Text(
                                      "RECEBER O PRÊMIO ATÉ 8H DO DIA SEGUINTE PAGÁVEIS AO PORTADOR, AOS DOMINGOS, O PRAZO SE ESTENDE ATÉ ÀS 8H DE TERÇA-FEIRA",
                                      style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
                                      textAlign: pw.TextAlign.center
                                    ),
                                  ),
                                ),*/
                              ],
                            ),
                            /*pw.Container(
                              decoration: pw.BoxDecoration(
                                borderRadius: pw.BorderRadius.circular(5),
                                color: PdfColors.white,
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                                child: pw.Text(
                                  "Ref.${cupom.reference}    Seq.${cupom.sequence}",
                                  style: const pw.TextStyle(fontSize: 8)
                                ),
                              ),
                            ),*/
                          ],
                        ),
                      ),
                      pw.Positioned(
                        left: 35,
                        bottom: 8,
                        child: pw.Container(
                          child: pw.Text(
                            "${cupom.reference}                 ${cupom.sequence}",
                            style: const pw.TextStyle(fontSize: 6)
                          ),
                        ),
                      ),
                      /*pw.Positioned(
                        right: 5,
                        bottom: 5,
                        child: pw.Container(
                          width: 120,
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(5),
                            color: PdfColors.white,
                          ),
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                            child: pw.Text(
                              "OBS: ESTE VILHETE PERDE O VALOR EM CASO DE RASURAS OU ADULTERAÇÕES QUE IMPOSSIBILITEM SUA AUTENTICIDADE",
                              style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center
                            ),
                          ),
                        ),
                      )*/
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    if (!await Permission.storage.request().isGranted) {
      throw Exception("Permissão de armazenamento negada.");
    }

    // Pega o diretório de documentos do usuário
    final Directory? documentosDir = await getDownloadsDirectory();
    final String caminho = '${documentosDir!.path}\\${collection.name}-$digits.pdf';

    // Salva o arquivo
    final File arquivoPdf = File(caminho);
    await arquivoPdf.writeAsBytes(await pdf.save());
  }

  List<List<Cupom>> _distribuirCupons(List<Cupom> cupons, int linhas, int colunas) {
    final cuponsPorFolha = linhas * colunas;
    final totalFolhas = (cupons.length / cuponsPorFolha).ceil();

    // Inicializa as folhas com cupons vazios
    final folhas = List.generate(
      totalFolhas,
      (_) => List<Cupom>.filled(cuponsPorFolha, Cupom(sequence: 0, value: '', text: ''), growable: false),
    );

    for (int i = 0; i < cupons.length; i++) {
      final folhaIndex = i % totalFolhas;
      final posicaoNaColuna = i ~/ totalFolhas;

      final coluna = posicaoNaColuna ~/ linhas; // coluna 0..3
      final linha = posicaoNaColuna % linhas;   // linha 0..3

      final indexNaFolha = linha * colunas + coluna;

      folhas[folhaIndex][indexNaFolha] = cupons[i];
    }

    return folhas;
  }

  Future<Uint8List> gerarQrCode(String data, {double size = 200}) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('QR Code inválido');
    }

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );

    final picData = await painter.toImageData(size, format: ui.ImageByteFormat.png);
    return picData!.buffer.asUint8List();
  }
}
