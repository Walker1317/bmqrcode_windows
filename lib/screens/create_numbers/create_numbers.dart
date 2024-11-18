// ignore_for_file: use_build_context_synchronously

import 'package:bm_qrcode_windows/models/cartela.dart';
import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateNumbers extends StatefulWidget {
  const CreateNumbers({super.key, required this.cartelas});
  final List<Cartela> cartelas;

  @override
  State<CreateNumbers> createState() => _CreateNumbersState();
}

class _CreateNumbersState extends State<CreateNumbers> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controllerReferencia = TextEditingController();
  final formKey = GlobalKey<FormState>();
  int digits = 2;
  bool loading = false;
  List<Cupom> values = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Novos Números"),
      ),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            const SizedBox(height: 10,),
            loading ? const LinearProgressIndicator() : const SizedBox(),
            SegmentedButton<int>(
              onSelectionChanged: (value){
                /*setState(() {
                  digits = value.first;
                });*/
              },
              segments: const [
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 6, label: Text('6')),
              ],
              selected: {digits}
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 2,
                    child: TextFormField(
                      readOnly: false,
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Cole seus números aqui",
                      ),
                      validator: (text){
                        return text!.isEmpty ? "Digite os Números" : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Flexible(
                    child: TextFormField(
                      controller: controllerReferencia,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2)
                      ],
                      decoration: const InputDecoration(
                        labelText: "Referência",
                      ),
                      validator: (text){
                        return text!.isEmpty ? "Digite a Referência" : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10,),
                  SizedBox(
                    height: 40,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () async {
                        if(formKey.currentState!.validate()){
                          values.clear();
                            final rows = controller.text.split(RegExp(r'\r?\n|\r'));
                            List<String> cleanedRows = rows.map((row) => row.trim()).toList();
                            //final currentDigits = cleanedRows.first.split("/").length;
                            //if(currentDigits == 2 && currentDigits == 3 && currentDigits == 4 && currentDigits == 5){
                              setState(() {
                                digits = cleanedRows.first.split("/").length;
                                for(int i = 0; i < cleanedRows.length; i++){
                                  final value = cleanedRows[i];
                                  final currentCartela = widget.cartelas.where((e)=> e.digits == digits).first;
                                  final index = (currentCartela.length! + 1) + i;
                                  String id = "$value-Ref${controllerReferencia.text}-Seq_$index";

                                  String status(){
                                    if(repetido(value)){
                                      return "REPETIDO";
                                    } else if(currentCartela.cupons!.where((e)=> e.value == value).isNotEmpty){
                                      return "NÚMERO JÁ PRESENTE NA LISTA";
                                    } else {
                                      return "";
                                    }
                                  }

                                  values.add(
                                    Cupom(
                                      id: id,
                                      value: value,
                                      reference: controllerReferencia.text,
                                      digits: digits,
                                      status: status(),
                                      created: Timestamp.now(),
                                      sequence: index,
                                    )
                                  );
                                }
                                controller.clear();
                              });
                            /*} else {
                              controller.clear();
                              showDialog(
                                context: context,
                                builder: (context)=> AlertDialog(
                                  title: const Text("Oops"),
                                  content: const Text("Os números inseridos ou alguns deles não estão entre os dígitos 2, 3, 4 ou 6"),
                                  actions: [
                                    TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("OK"))
                                  ],
                                )
                              );
                            }*/
                        }
                      },
                      child: const Text("Colar")
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10,),
            Container(
              height: 30,
              color: const Color(0xFF021625),
              child:const  Row(
                children: [
                  SizedBox(width: 40, child:  Text("SEQ |")),
                  Expanded(flex: 2,child: Text("NUM"),),
                  Expanded(child: Text("REFERÊNCIA", textAlign: TextAlign.center,)),
                  Expanded(child: Text("STATUS", textAlign: TextAlign.center,)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: values.length,
                itemBuilder: (context, index){
                  final cupom = values[index];
                  return Container(
                    color: index.isEven ? Colors.white10 : Colors.transparent,
                    child: SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text("    ${index + 1} |")),
                          Expanded(flex: 2,child: Text(cupom.value!),),
                          Expanded(child: Text(cupom.reference!, textAlign: TextAlign.center,)),
                          Expanded(child: Text(cupom.status!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent[700]),)),
                        ],
                      ),
                    ),
                  );
                }
              ),
            )
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          if(values.isNotEmpty){
            if(values.where((e)=> e.status!.isNotEmpty).isNotEmpty){
              showErrorSnack("Verifique os status dos números.");
            } else {
              final currentCartela = widget.cartelas.where((e)=> e.digits == digits).first;
              if((currentCartela.length! + values.length) > currentCartela.limit!){
                showErrorSnack("Se salvar esses novos números o limite será atingido.");
              } else {
                setState(() {
                  loading = true;
                });
                FirebaseFirestore.instance.collection('cartelas').doc("$digits digitos").update({
                  "cupons" : FieldValue.arrayUnion(values.map((e)=> e.toMap()).toList()),
                  'length' : FieldValue.increment(values.length),
                }).then((e){
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Salvo com sucesso!",),
                      backgroundColor: Colors.greenAccent[700],
                      duration: const Duration(seconds: 1),)
                  );
                  setState(() {
                    loading = false;
                  });
                }).catchError((e){
                  debugPrint(e.toString());
                  setState(() {
                    showErrorSnack("Erro ao Salvar");
                    loading = false;
                  });
                });
              }
            }
          }
        },
        child: const Text("Salvar")
      ),
    );
  }

  showErrorSnack(String messege){
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messege),
        backgroundColor: Colors.redAccent[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool repetido(String reference){
    final currentDigits = reference.split("/");
    bool result = false;
    for(var item in currentDigits){
      if(currentDigits.where((e)=> e == item).length > 1){
        result = true;
      } else {
        result = false;
      }
    }
    return result;
  }
}