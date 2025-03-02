// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:math';
import 'package:bm_qrcode_windows/models/collection.dart';
import 'package:bm_qrcode_windows/models/cupom.dart';
import 'package:bm_qrcode_windows/widgets/dialog_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateNumbers extends StatefulWidget {
  const CreateNumbers({super.key, required this.collection});
  final CupomCollection collection;

  @override
  State<CreateNumbers> createState() => _CreateNumbersState();
}

class _CreateNumbersState extends State<CreateNumbers> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controllerReferencia = TextEditingController();
  final TextEditingController controllerLength = TextEditingController();
  final TextEditingController controllerCollection = TextEditingController();
  final formKey = GlobalKey<FormState>();
  int digits = 2;
  bool loading = false;
  List<Cupom> values = [];
  int? savedsLength;
  int saveds = 0;
  int errors = 0;
  List<int> trueNumbers = List.generate(10001, (index) => index);
  List<int> usedNumbers = [];

  generateNumbers(int length,) async {
    List<Cupom> currentValues = [];
    bool error = false;
    int quantity = 0;
    final allValues = shuffleList(trueNumbers);
    for (int index = 0; index < length; index++) {
      List<int> numbers = [];
      for(int i = 0; i < digits; i++){
        try{
          numbers.add(allValues.last);
          allValues.removeLast();
        } catch (e){
          error = true;
          quantity = quantity + 1;
        }
      }
      if(!error){
        //trueNumbers.removeRange(0, digits);
        String value = numbers.map((e)=>e.toString().padLeft(4, "0")).toList().toString().replaceAll("[", "").replaceAll("]", "").replaceAll(" ", "").replaceAll(",", "/");
        String id = FirebaseFirestore.instance.collection("cupons").doc().id;
        currentValues.add(
          Cupom(
            id: "$digits$id",
            value: value,
            reference: controllerReferencia.text,
            digits: digits,
            status: "",
            created: Timestamp.now(),
            sequence: index + 1,
            collection: widget.collection.id,
          ),
        );
      }
    }
    // Atualiza o estado com os valores gerados
    if(error){
      DialogServices.alertDialog(context, "Não há mais números disponíveis para serem gerados.\nNúmeros faltando: $quantity");
    }
    setState(() {
      values = currentValues;
    });
  }


  List<int> shuffleList(List<int> list) {
    final random = Random();
    List<int> shuffled = List.from(list);
    // Embaralha a lista
    for (int i = shuffled.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      int temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  @override
  void initState() {
    super.initState();
    controllerCollection.text = widget.collection.name!;
    controllerLength.text = 5000.toString();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !loading;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Novos Números"),
        ),
        body: loading ?
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              values.length == (saveds + errors) ? const SizedBox() : const CircularProgressIndicator(),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, color: Colors.greenAccent[700],),
                  const SizedBox(width: 10,),
                  Text("$saveds QrCodes salvos de ${values.length}"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: Colors.redAccent[700],),
                  const SizedBox(width: 10,),
                  Text("$errors erros"),
                ],
              ),
              values.length != (saveds + errors) ? const SizedBox():
              Container(
                height: 50,
                margin: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: ()=> Navigator.pop(context),
                  child: const Text("Concluir")
                ),
              )
            ],
          ),
        ):
        Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(height: 10,),
              loading ? const LinearProgressIndicator() : const SizedBox(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*Flexible(
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
                    ),*/
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Dígitos"),
                        SegmentedButton<int>(
                          onSelectionChanged: (value){
                            setState(() {
                              digits = value.first;
                              switch (digits) {
                                case 2:
                                  controllerLength.text = 5000.toString();
                                case 3:
                                  controllerLength.text = 3333.toString();
                                case 4:
                                  controllerLength.text = 2500.toString();
                                case 6:
                                  controllerLength.text = 1666.toString();
                                default:
                              }
                            });
                          },
                          segments: const [
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                            ButtonSegment(value: 4, label: Text('4')),
                            ButtonSegment(value: 6, label: Text('6')),
                          ],
                          selected: {digits}
                        ),
                      ],
                    ),
                    const SizedBox(width: 20,),
                    Flexible(
                      child: TextFormField(
                        readOnly: true,
                        controller: controllerLength,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4)
                        ],
                        decoration: const InputDecoration(
                          labelText: "Quantidade"
                        ),
                        validator: (text){
                          /*int number = text!.isEmpty ? 0 : int.parse(text);
                          int limit = widget.cartelas.where((e)=> e.digits == digits).first.limit!;
                          int quantity = widget.cartelas.where((e)=> e.digits == digits).first.cupons!.length;*/
                          
                          return text!.isEmpty ? "Digite a quantidade" : null;// : limit < (number + quantity + values.length) ? "Essa quantidade irá atingir o limite de numeros" : null;
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
                    Flexible(
                      child: TextFormField(
                        readOnly: true,
                        controller: controllerCollection,
                        decoration: const InputDecoration(
                          labelText: "Coleção",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10,),
                    SizedBox(
                      height: 40,
                      width: 160, 
                      child: ElevatedButton(
                        onPressed: () async {
                          if(formKey.currentState!.validate()){
                            generateNumbers(int.parse(controllerLength.text));
                          }
      
                          /*if(formKey.currentState!.validate()){
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
                          }*/
                        },
                        child: const Text("Gerar Números")
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
                            SizedBox(width: 60, child: Text("    ${index + 1} |")),
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
        floatingActionButton: loading ? null : ElevatedButton(
          onPressed: () async {
            if(values.isNotEmpty){
              if(values.where((e)=> e.status!.isNotEmpty).isNotEmpty){
                showErrorSnack("Verifique os status dos números.");
              } else {
      
                savedsLength ??= await pickupLength();
      
                if((savedsLength! + values.length) > digitLimit()){
                  DialogServices.alertDialog(context, "Não será possível salvar esses números, pois o limite de será atingido.\nVocê pode gerar somente ${digitLimit() - savedsLength!} númeors");
                } else {
                  setState(() {
                    loading = true;
                  });
                  for(int i = 0; i < values.length; i++){
                    var cupom = values[i];
                    cupom.sequence = savedsLength! + (i+1);
                    cupom.created = Timestamp.now();
                    FirebaseFirestore.instance.collection("cupons").doc(cupom.id).set(cupom.toMap())
                    .then((_){
                      setState(() {
                        saveds = saveds + 1;
                      });
                    }).catchError((e){
                      setState(() {
                        errors = errors + 1;
                      });
                    });
                  }
                  /*FirebaseFirestore.instance.collection('cartelas').doc("$digits digitos").update({
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
                  });*/
                }
              }
            }
          },
          child: const Text("Salvar")
        ),
      ),
    );
  }

  Future<int> pickupLength() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("cupons").where("collection", isEqualTo: widget.collection.id)
    .where("digits", isEqualTo: digits).get();
    return snapshot.docs.length;
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

  int digitLimit(){
    switch (digits) {
      case 2:
        return 6000;
      case 3:
        return 3333;
      case 4:
        return 2500;
      case 6:
        return 1666;
      default:
        return 0;
    }
  }

}