import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeDetails extends StatelessWidget {
  const QRCodeDetails({super.key, required this.cupom});
  final Cupom cupom;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(20),
      title: Text(cupom.id!),
      children: [
        Center(
          child: Card(
            color: Colors.white,
            child: SizedBox(
              height: 200,
              width: 200,
              child: QrImageView(
                data: cupom.id!,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 
        20,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Referência:"),
            Text(cupom.reference!),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Criado em:"),
            Text('${DateFormat(DateFormat.YEAR_MONTH_DAY, "pt_BR").format(cupom.created!.toDate())} às ${DateFormat(DateFormat.HOUR24_MINUTE, "pt_BR").format(cupom.created!.toDate())}'),
          ],
        ),
      ],
    );
  }
}